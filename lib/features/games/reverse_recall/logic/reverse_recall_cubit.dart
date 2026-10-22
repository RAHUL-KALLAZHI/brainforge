import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_session_state.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
import 'package:brainforge/features/games/shared/logic/game_state_machine.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import '../domain/reverse_recall_config.dart';
import 'reverse_recall_engine.dart';
import 'reverse_recall_state.dart';

/// Cubit orchestrating the state machine, sequential presentation, and reverse input
/// validation for Reverse Recall.
class ReverseRecallCubit extends Cubit<ReverseRecallState> {
  final ReverseRecallEngine _engine;
  final GameAttemptRepository _attemptRepository;
  final AdaptiveDifficultyService? _adaptiveService;
  final GameTimer _timer;
  final bool _fastPreviewForTesting;
  final int? _initialSeed;

  late GameStateMachine _stateMachine;
  int _currentSessionId = 0;
  bool _attemptSaved = false;
  DateTime? _lastActionTimestamp;
  GameStatus _lastObservedStatus = GameStatus.initial;

  ReverseRecallCubit({
    ReverseRecallEngine engine = const ReverseRecallEngine(),
    GameAttemptRepository? attemptRepository,
    AdaptiveDifficultyService? adaptiveService,
    GameTimer? timer,
    GameDifficulty? initialDifficulty,
    int? initialSeed,
    bool fastPreviewForTesting = false,
  })  : _engine = engine,
        _attemptRepository =
            attemptRepository ?? getIt<GameAttemptRepository>(),
        _adaptiveService = adaptiveService ??
            (getIt.isRegistered<AdaptiveDifficultyService>()
                ? getIt<AdaptiveDifficultyService>()
                : null),
        _timer = timer ?? GameTimer(),
        _initialSeed = initialSeed,
        _fastPreviewForTesting = fastPreviewForTesting,
        super(_createInitialState(
          engine: engine,
          timer: timer ?? GameTimer(),
          difficulty: initialDifficulty ?? const GameDifficulty(1),
          seed: initialSeed,
        )) {
    _initStateMachine();
    if (initialDifficulty == null) {
      _loadAdaptiveDifficulty();
    }
  }

  /// Asynchronously hydrates the effective adaptive difficulty if not explicitly overridden.
  Future<void> _loadAdaptiveDifficulty() async {
    if (_adaptiveService == null) return;
    try {
      final effectiveDifficulty = await _adaptiveService
          .getEffectiveDifficulty(ReverseRecallConfig.gameId);
      debugPrint(
        '[ReverseRecall] HydrateDifficulty: loaded=L${effectiveDifficulty.level}, current=L${state.difficulty.level}',
      );
      if (!isClosed &&
          state.sessionState.status == GameStatus.initial &&
          effectiveDifficulty.level != state.difficulty.level) {
        final newConfig = ReverseRecallConfig.forDifficulty(
          effectiveDifficulty,
          seed: _initialSeed,
        );
        final newChallenge =
            _engine.generateReverseChallenge(config: newConfig);

        _stateMachine.restart(newConfig);
        emit(ReverseRecallState.initial(
          config: newConfig,
          challenge: newChallenge,
          sessionState: _stateMachine.state,
        ));
      }
    } catch (e) {
      debugPrint('[ReverseRecall] HydrateDifficulty failed: $e');
    }
  }

  static ReverseRecallState _createInitialState({
    required ReverseRecallEngine engine,
    required GameTimer timer,
    required GameDifficulty difficulty,
    int? seed,
  }) {
    final config = ReverseRecallConfig.forDifficulty(difficulty, seed: seed);
    final challenge = engine.generateReverseChallenge(config: config);
    final sessionState =
        engine.createSession(config: config, timer: timer).state;

    return ReverseRecallState.initial(
      config: config,
      challenge: challenge,
      sessionState: sessionState,
    );
  }

  void _initStateMachine() {
    _stateMachine = _engine.createSession(
      config: state.config,
      timer: _timer,
    );

    _stateMachine.addListener(_onStateMachineUpdated);
  }

  void _onStateMachineUpdated() {
    if (isClosed) return;

    final session = _stateMachine.state;
    final previousStatus = _lastObservedStatus;
    _lastObservedStatus = session.status;

    emit(state.copyWith(sessionState: session));

    // When countdown completes and transitions to playing preview, run playback automatically
    if (previousStatus == GameStatus.countdown &&
        session.status == GameStatus.playing &&
        session.phase == GamePhase.preview) {
      _runPreviewSequence();
    }

    // Auto-save attempt upon terminal resolution (completed, failed, abandoned)
    if (session.status.isTerminal && !_attemptSaved) {
      _saveAttempt();
    }
  }

  /// Begins the pre-game countdown (3..2..1) before sequence playback.
  void startGame({
    int countdownSeconds = 3,
    Duration interval = const Duration(seconds: 1),
  }) {
    if (state.sessionState.status != GameStatus.initial) return;

    _stateMachine.startCountdown(
      seconds: countdownSeconds,
      interval: interval,
    );
  }

  /// Skips countdown to start playback immediately (useful in testing).
  void startPlayingImmediately() {
    if (state.sessionState.status == GameStatus.initial) {
      _stateMachine.startCountdown(seconds: 1);
      _timer.startSessionTimer();
    }
    if (state.sessionState.status == GameStatus.countdown) {
      _stateMachine.startPlaying();
    }
    _beginRecallInput();
  }

  void _beginRecallInput() {
    _stateMachine.setPhase(GamePhase.input);
    emit(state.copyWith(activePresentedDigit: () => null));
    _lastActionTimestamp = DateTime.now();

    if (state.config.responseTimeLimit != null) {
      _stateMachine.startRoundResponseTimer(
        timeLimit: state.config.responseTimeLimit!,
      );
    }
  }

  /// Executes the forward sequential presentation of digits.
  Future<void> _runPreviewSequence() async {
    final sessionId = ++_currentSessionId;
    _stateMachine.setPhase(GamePhase.preview);

    final sequence = state.challenge.sequence;
    final flashDuration = _fastPreviewForTesting
        ? Duration.zero
        : state.config.presentationDuration;
    final gapDuration = _fastPreviewForTesting
        ? Duration.zero
        : ReverseRecallConfig.gapDurationForDifficulty(state.difficulty);

    for (var i = 0; i < sequence.length; i++) {
      if (_currentSessionId != sessionId || isClosed) return;
      if (_stateMachine.state.status != GameStatus.playing) return;

      final digit = sequence[i];

      // Flash active digit
      emit(state.copyWith(
        activePresentedDigit: () => digit,
        presentedStepIndex: i,
      ));

      if (flashDuration > Duration.zero) {
        await Future<void>.delayed(flashDuration);
      }

      if (_currentSessionId != sessionId || isClosed) return;

      // Extinguish digit (gap interval)
      emit(state.copyWith(activePresentedDigit: () => null));

      if (gapDuration > Duration.zero) {
        await Future<void>.delayed(gapDuration);
      }
    }

    if (_currentSessionId != sessionId || isClosed) return;
    if (_stateMachine.state.status != GameStatus.playing) return;

    // Transition into active interactive reverse recall phase
    _beginRecallInput();
  }

  /// Handles user tapping a digit button on the keypad during reverse recall.
  void onDigitEntered(int digit) {
    if (!state.isInputAllowed) {
      return; // Input rejected outside active recall phase
    }

    final now = DateTime.now();
    final latency = now.difference(_lastActionTimestamp ?? now);
    _lastActionTimestamp = now;

    final isCorrect = _engine.evaluateInput(
      challenge: state.challenge,
      input: digit,
      stepIndex: state.currentStepIndex,
    );

    if (isCorrect) {
      _stateMachine.recordInput(
        isCorrect: true,
        responseLatency: latency,
      );

      final updatedEntries = List<int>.from(state.playerEntries)..add(digit);
      final nextStep = state.currentStepIndex + 1;

      emit(state.copyWith(
        currentStepIndex: nextStep,
        playerEntries: updatedEntries,
        lastEnteredDigit: () => digit,
        lastInputCorrect: () => true,
      ));

      // Check if player has reproduced the entire reverse sequence
      if (nextStep >= state.challenge.expectedReverse.length) {
        _stateMachine.completeSession();
      }
    } else {
      _stateMachine.recordInput(
        isCorrect: false,
        responseLatency: latency,
      );

      final updatedEntries = List<int>.from(state.playerEntries)..add(digit);

      emit(state.copyWith(
        playerEntries: updatedEntries,
        lastEnteredDigit: () => digit,
        lastInputCorrect: () => false,
      ));

      _stateMachine.failSession(reason: 'Incorrect reverse digit entered.');
    }
  }

  /// Immediately completes the preview sequence for deterministic unit/widget tests.
  void completePreviewForTesting() {
    ++_currentSessionId;
    if (state.sessionState.status == GameStatus.initial) {
      _stateMachine.startCountdown(seconds: 1);
      _stateMachine.startPlaying();
    } else if (state.sessionState.status == GameStatus.countdown) {
      _stateMachine.startPlaying();
    }
    _stateMachine.setPhase(GamePhase.input);
    _lastActionTimestamp = DateTime.now();
    emit(state.copyWith(
      sessionState: _stateMachine.state,
      activePresentedDigit: () => null,
    ));
    if (state.config.responseTimeLimit != null) {
      _stateMachine.startRoundResponseTimer(
        timeLimit: state.config.responseTimeLimit!,
      );
    }
  }

  /// Pauses the active game session (e.g. app backgrounding).
  void pause() {
    if (state.sessionState.status == GameStatus.playing) {
      ++_currentSessionId;
      _stateMachine.pause();
    }
  }

  /// Resumes from a paused state.
  void resume() {
    if (state.sessionState.status == GameStatus.paused) {
      _stateMachine.resume();
      if (state.sessionState.phase == GamePhase.preview) {
        _runPreviewSequence();
      }
    }
  }

  /// Abandons the active game session.
  void abandonGame() {
    ++_currentSessionId;
    if (!state.sessionState.status.isTerminal) {
      _stateMachine.abandonSession();
    }
  }

  /// Toggles visibility of the exit confirmation dialog.
  void setExitDialogVisible(bool isVisible) {
    emit(state.copyWith(isExitDialogOpen: isVisible));
  }

  /// Begins a new game session immediately using the difficulty of the game that just completed.
  void playAgainAtCompletedDifficulty({int? seed}) {
    if (!state.isTerminal) return;
    final replayDifficulty = state.playedDifficulty;
    debugPrint(
      '[ReverseRecall] PlayAgainAtCompletedDifficulty: replaying L${replayDifficulty.level}',
    );
    restart(
      difficulty: replayDifficulty,
      seed: seed,
      startImmediately: true,
    );
  }

  /// Alias for replaying at completed difficulty.
  void playAgain({int? seed}) => playAgainAtCompletedDifficulty(seed: seed);

  /// Begins a new game session immediately using the recommended promoted difficulty.
  void proceedToRecommendedLevel({int? seed}) {
    if (!state.isTerminal || !state.canProceedToNextLevel) {
      debugPrint(
        '[ReverseRecall] proceedToRecommendedLevel ignored: terminal=${state.isTerminal}, canProceed=${state.canProceedToNextLevel}',
      );
      return;
    }
    final targetDifficulty = state.recommendedDifficulty;
    debugPrint(
      '[ReverseRecall] ProceedToRecommendedLevel: launching L${targetDifficulty.level}',
    );
    restart(
      difficulty: targetDifficulty,
      seed: seed,
      startImmediately: true,
    );
  }

  /// Returns to the ready/setup screen using the current recommended difficulty.
  void returnToReadyView({int? seed}) {
    if (!state.isTerminal) return;
    final targetDifficulty = state.recommendedDifficulty;
    debugPrint(
      '[ReverseRecall] ReturnToReadyView: opening ready view at recommended L${targetDifficulty.level}',
    );
    restart(
      difficulty: targetDifficulty,
      seed: seed,
      startImmediately: false,
    );
  }

  /// Restarts the game session with current or updated difficulty/seed.
  void restart({
    GameDifficulty? difficulty,
    int? seed,
    bool startImmediately = false,
  }) {
    ++_currentSessionId;
    _attemptSaved = false;

    final targetDifficulty = difficulty ?? state.config.difficulty;
    debugPrint(
      '[ReverseRecall] Restart: targetDifficulty=L${targetDifficulty.level} (from ${difficulty != null ? "explicit" : "config"}), startImmediately=$startImmediately',
    );

    final newConfig = ReverseRecallConfig.forDifficulty(
      targetDifficulty,
      seed: seed ?? _initialSeed,
    );
    final newChallenge = _engine.generateReverseChallenge(config: newConfig);

    emit(ReverseRecallState(
      config: newConfig,
      challenge: newChallenge,
      sessionState: GameSessionState.initial(newConfig),
      activePresentedDigit: null,
      presentedStepIndex: 0,
      currentStepIndex: 0,
      playerEntries: const [],
      lastEnteredDigit: null,
      lastInputCorrect: null,
      isExitDialogOpen: false,
      adaptationDecision: null,
    ));

    _stateMachine.restart(newConfig);

    if (startImmediately) {
      startGame(
        countdownSeconds: _fastPreviewForTesting ? 1 : 3,
        interval:
            _fastPreviewForTesting ? Duration.zero : const Duration(seconds: 1),
      );
    }
  }

  Future<void> _saveAttempt() async {
    if (_attemptSaved) return;
    _attemptSaved = true;
    final sessionId = _currentSessionId;

    final result = _stateMachine.state.result;
    if (result == null) return;

    final totalResponses = result.score.correctCount +
        result.score.incorrectCount +
        result.score.missedCount;
    debugPrint(
      '[ReverseRecall] Result: status=${result.status.name}, '
      'difficulty=L${result.difficulty.level}, '
      'correct=${result.score.correctCount}, '
      'total=$totalResponses, '
      'accuracy=${(result.score.accuracy * 100).toStringAsFixed(1)}%, '
      'score=${result.score.scaledScore}',
    );

    final attempt = GameAttempt.fromResult(
      id: 'rr_${DateTime.now().millisecondsSinceEpoch}_${state.config.seed ?? 0}',
      result: result,
      responseTimesMs: _stateMachine.state.responseTimesMs,
    );

    bool saveSucceeded = false;
    try {
      await _attemptRepository.saveAttempt(attempt);
      saveSucceeded = true;
      debugPrint(
        '[ReverseRecall] Persistence: id=${attempt.id}, gameId=${attempt.gameId}, status=${attempt.status.name}, saved=true',
      );
    } catch (e) {
      debugPrint(
        '[ReverseRecall] Persistence FAILED for attempt ${attempt.id}: $e',
      );
    }

    if (saveSucceeded &&
        _adaptiveService != null &&
        result.status != GameStatus.abandoned) {
      try {
        final decision = await _adaptiveService.evaluateAndPersist(
          gameId: ReverseRecallConfig.gameId,
          currentDifficulty: state.difficulty,
        );
        debugPrint(
          '[ReverseRecall] StateUpdate: decision=${decision.action.name}, '
          'target=L${decision.targetDifficulty.level}, '
          'current=L${state.difficulty.level}',
        );
        if (!isClosed && _currentSessionId == sessionId) {
          emit(state.copyWith(
            adaptationDecision: () => decision,
          ));
        }
      } catch (e) {
        debugPrint('[ReverseRecall] Adaptive evaluation FAILED: $e');
      }
    }
  }

  @override
  Future<void> close() {
    ++_currentSessionId;
    _stateMachine.removeListener(_onStateMachineUpdated);
    _stateMachine.dispose();
    return super.close();
  }
}
