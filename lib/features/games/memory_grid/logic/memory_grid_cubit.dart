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
import '../domain/memory_grid_config.dart';
import 'memory_grid_engine.dart';
import 'memory_grid_state.dart';

/// Cubit managing presentation state and coordinating the pure-Dart game engine for Memory Grid.
class MemoryGridCubit extends Cubit<MemoryGridState> {
  final MemoryGridEngine _engine;
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

  MemoryGridCubit({
    MemoryGridEngine engine = const MemoryGridEngine(),
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
      final effectiveDifficulty =
          await _adaptiveService.getEffectiveDifficulty('memory_grid');
      debugPrint(
        '[MemoryGrid] HydrateDifficulty: loaded=L${effectiveDifficulty.level}, current=L${state.difficulty.level}',
      );
      if (!isClosed &&
          state.sessionState.status == GameStatus.initial &&
          effectiveDifficulty.level != state.difficulty.level) {
        final newConfig = MemoryGridConfig.forDifficulty(
          effectiveDifficulty,
          seed: _initialSeed,
        );
        final newChallenge = _engine.generateGridChallenge(config: newConfig);

        _stateMachine.restart(newConfig);
        emit(MemoryGridState.initial(
          config: newConfig,
          challenge: newChallenge,
          sessionState: _stateMachine.state,
        ));
      }
    } catch (e) {
      debugPrint('[MemoryGrid] HydrateDifficulty failed: $e');
    }
  }

  static MemoryGridState _createInitialState({
    required MemoryGridEngine engine,
    required GameTimer timer,
    required GameDifficulty difficulty,
    int? seed,
  }) {
    final config = MemoryGridConfig.forDifficulty(difficulty, seed: seed);
    final challenge = engine.generateGridChallenge(config: config);
    final sessionState =
        engine.createSession(config: config, timer: timer).state;

    return MemoryGridState.initial(
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

    // When countdown completes and transitions to playing preview, run preview automatically
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
  void startGame(
      {int countdownSeconds = 3,
      Duration interval = const Duration(seconds: 1)}) {
    if (state.sessionState.status != GameStatus.initial) return;

    _stateMachine.startCountdown(
      seconds: countdownSeconds,
      interval: interval,
    );
  }

  /// Skips instructions or countdown to start playing immediately (useful in tests/direct launch).
  void startPlayingImmediately() {
    if (state.sessionState.status == GameStatus.initial) {
      _stateMachine.startCountdown(seconds: 1);
      _timer.startSessionTimer();
    }
    if (state.sessionState.status == GameStatus.countdown) {
      _stateMachine.startPlaying();
      _runPreviewSequence();
    }
  }

  /// Executes the sequential illumination of tiles for the active challenge.
  Future<void> _runPreviewSequence() async {
    final sessionId = ++_currentSessionId;
    _stateMachine.setPhase(GamePhase.preview);

    final sequence = state.challenge.sequence;
    final flashDuration = _fastPreviewForTesting
        ? Duration.zero
        : state.config.presentationDuration;
    final gapDuration = _fastPreviewForTesting
        ? Duration.zero
        : const Duration(milliseconds: 150);

    for (final tileIndex in sequence) {
      if (_currentSessionId != sessionId || isClosed) return;
      if (_stateMachine.state.status != GameStatus.playing) return;

      // Illuminate current tile
      emit(state.copyWith(activePreviewTileIndex: () => tileIndex));

      if (flashDuration > Duration.zero) {
        await Future<void>.delayed(flashDuration);
      }

      if (_currentSessionId != sessionId || isClosed) return;

      // Extinguish tile
      emit(state.copyWith(activePreviewTileIndex: () => null));

      if (gapDuration > Duration.zero) {
        await Future<void>.delayed(gapDuration);
      }
    }

    if (_currentSessionId != sessionId || isClosed) return;
    if (_stateMachine.state.status != GameStatus.playing) return;

    // Transition into interactive recall phase
    _stateMachine.setPhase(GamePhase.input);
    _lastActionTimestamp = DateTime.now();

    if (state.config.responseTimeLimit != null) {
      _stateMachine.startRoundResponseTimer(
        timeLimit: state.config.responseTimeLimit!,
      );
    }
  }

  /// Handles user tapping a grid tile during the recall phase.
  void onTileTapped(int tileIndex) {
    if (!state.isInputAllowed) {
      return; // Reject taps outside active input phase
    }

    final now = DateTime.now();
    final latency = now.difference(_lastActionTimestamp ?? now);
    _lastActionTimestamp = now;

    final isCorrect = _engine.evaluateInput(
      challenge: state.challenge,
      input: tileIndex,
      stepIndex: state.currentStepIndex,
    );

    if (isCorrect) {
      _stateMachine.recordInput(
        isCorrect: true,
        responseLatency: latency,
      );

      final updatedSelections = List<int>.from(state.playerSelections)
        ..add(tileIndex);
      final nextStep = state.currentStepIndex + 1;

      emit(state.copyWith(
        currentStepIndex: nextStep,
        playerSelections: updatedSelections,
        lastTappedTile: () => tileIndex,
        lastInputCorrect: () => true,
      ));

      // Check if entire sequence was correctly reproduced
      if (nextStep >= state.challenge.sequence.length) {
        _stateMachine.completeSession();
      }
    } else {
      _stateMachine.recordInput(
        isCorrect: false,
        responseLatency: latency,
      );

      emit(state.copyWith(
        lastTappedTile: () => tileIndex,
        lastInputCorrect: () => false,
      ));

      _stateMachine.failSession(reason: 'Incorrect tile selected.');
    }
  }

  /// Immediately completes the preview sequence for deterministic unit/widget tests.
  void completePreviewForTesting() {
    ++_currentSessionId; // Cancel any running preview sequence
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
      activePreviewTileIndex: () => null,
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
      ++_currentSessionId; // Cancel any running preview
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
      '[MemoryGrid] PlayAgainAtCompletedDifficulty: replaying L${replayDifficulty.level}',
    );
    restart(
      difficulty: replayDifficulty,
      seed: seed,
      startImmediately: true,
    );
  }

  /// Begins a new game session immediately using the difficulty of the game that just completed.
  void playAgain({int? seed}) => playAgainAtCompletedDifficulty(seed: seed);

  /// Begins a new game session immediately using the recommended promoted difficulty.
  void proceedToRecommendedLevel({int? seed}) {
    if (!state.isTerminal || !state.canProceedToNextLevel) {
      debugPrint(
        '[MemoryGrid] proceedToRecommendedLevel ignored: terminal=${state.isTerminal}, canProceed=${state.canProceedToNextLevel}',
      );
      return;
    }
    final targetDifficulty = state.recommendedDifficulty;
    debugPrint(
      '[MemoryGrid] ProceedToRecommendedLevel: launching L${targetDifficulty.level}',
    );
    restart(
      difficulty: targetDifficulty,
      seed: seed,
      startImmediately: true,
    );
  }

  /// Begins a new game session immediately using the recommended promoted difficulty.
  void proceedToNextLevel({int? seed}) => proceedToRecommendedLevel(seed: seed);

  /// Returns to the Memory Grid ready/setup screen using the current recommended difficulty.
  void returnToReadyView({int? seed}) {
    if (!state.isTerminal) return;
    final targetDifficulty = state.recommendedDifficulty;
    debugPrint(
      '[MemoryGrid] ReturnToReadyView: opening ready view at recommended L${targetDifficulty.level}',
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

    // Use explicitly requested difficulty, or current difficulty.
    final targetDifficulty = difficulty ?? state.config.difficulty;
    debugPrint(
      '[MemoryGrid] Restart: targetDifficulty=L${targetDifficulty.level} (from ${difficulty != null ? "explicit" : "config"}), startImmediately=$startImmediately',
    );

    final newConfig = MemoryGridConfig.forDifficulty(
      targetDifficulty,
      seed: seed ?? _initialSeed,
    );
    final newChallenge = _engine.generateGridChallenge(config: newConfig);

    emit(MemoryGridState(
      config: newConfig,
      challenge: newChallenge,
      sessionState: GameSessionState.initial(newConfig),
      activePreviewTileIndex: null,
      currentStepIndex: 0,
      playerSelections: const [],
      lastTappedTile: null,
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
      '[MemoryGrid] Result: status=${result.status.name}, '
      'difficulty=L${result.difficulty.level}, '
      'correct=${result.score.correctCount}, '
      'total=$totalResponses, '
      'accuracy=${(result.score.accuracy * 100).toStringAsFixed(1)}%, '
      'score=${result.score.scaledScore}',
    );

    final attempt = GameAttempt.fromResult(
      id: 'mg_${DateTime.now().millisecondsSinceEpoch}_${state.config.seed ?? 0}',
      result: result,
      responseTimesMs: _stateMachine.state.responseTimesMs,
    );

    bool saveSucceeded = false;
    try {
      await _attemptRepository.saveAttempt(attempt);
      saveSucceeded = true;
      debugPrint(
        '[MemoryGrid] Persistence: id=${attempt.id}, gameId=${attempt.gameId}, status=${attempt.status.name}, saved=true',
      );
    } catch (e) {
      debugPrint(
        '[MemoryGrid] Persistence FAILED for attempt ${attempt.id}: $e',
      );
    }

    // Only evaluate adaptation if save succeeded and session was not abandoned
    if (saveSucceeded &&
        _adaptiveService != null &&
        result.status != GameStatus.abandoned) {
      try {
        final decision = await _adaptiveService.evaluateAndPersist(
          gameId: 'memory_grid',
          currentDifficulty: state.difficulty,
        );
        debugPrint(
          '[MemoryGrid] StateUpdate: decision=${decision.action.name}, '
          'target=L${decision.targetDifficulty.level}, '
          'current=L${state.difficulty.level}',
        );
        if (!isClosed && _currentSessionId == sessionId) {
          emit(state.copyWith(
            adaptationDecision: () => decision,
          ));
        }
      } catch (e) {
        debugPrint('[MemoryGrid] Adaptive evaluation FAILED: $e');
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
