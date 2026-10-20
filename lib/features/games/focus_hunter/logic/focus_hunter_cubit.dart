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
import '../domain/focus_hunter_config.dart';
import 'focus_hunter_engine.dart';
import 'focus_hunter_state.dart';

/// Cubit managing presentation state and coordinating the pure-Dart game engine for Focus Hunter.
class FocusHunterCubit extends Cubit<FocusHunterState> {
  final FocusHunterEngine _engine;
  final GameAttemptRepository _attemptRepository;
  final AdaptiveDifficultyService? _adaptiveService;
  final GameTimer _timer;
  final int? _initialSeed;

  late GameStateMachine _stateMachine;
  int _currentSessionId = 0;
  bool _attemptSaved = false;
  DateTime? _lastActionTimestamp;
  GameStatus _lastObservedStatus = GameStatus.initial;

  FocusHunterCubit({
    FocusHunterEngine engine = const FocusHunterEngine(),
    GameAttemptRepository? attemptRepository,
    AdaptiveDifficultyService? adaptiveService,
    GameTimer? timer,
    GameDifficulty? initialDifficulty,
    int? initialSeed,
  })  : _engine = engine,
        _attemptRepository =
            attemptRepository ?? getIt<GameAttemptRepository>(),
        _adaptiveService = adaptiveService ??
            (getIt.isRegistered<AdaptiveDifficultyService>()
                ? getIt<AdaptiveDifficultyService>()
                : null),
        _timer = timer ?? GameTimer(),
        _initialSeed = initialSeed,
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
          .getEffectiveDifficulty(FocusHunterConfig.gameId);
      debugPrint(
        '[FocusHunter] HydrateDifficulty: loaded=L${effectiveDifficulty.level}, current=L${state.difficulty.level}',
      );
      if (!isClosed &&
          state.sessionState.status == GameStatus.initial &&
          effectiveDifficulty.level != state.difficulty.level) {
        final newConfig = FocusHunterConfig.forDifficulty(
          effectiveDifficulty,
          seed: _initialSeed,
        );
        final newChallenge = _engine.generateHunterChallenge(config: newConfig);

        _stateMachine.restart(newConfig);
        emit(FocusHunterState.initial(
          config: newConfig,
          challenge: newChallenge,
          sessionState: _stateMachine.state,
        ));
      }
    } catch (e) {
      debugPrint('[FocusHunter] HydrateDifficulty failed: $e');
    }
  }

  static FocusHunterState _createInitialState({
    required FocusHunterEngine engine,
    required GameTimer timer,
    required GameDifficulty difficulty,
    int? seed,
  }) {
    final config = FocusHunterConfig.forDifficulty(difficulty, seed: seed);
    final challenge = engine.generateHunterChallenge(config: config);
    final sessionState =
        engine.createSession(config: config, timer: timer).state;

    return FocusHunterState.initial(
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

    // When countdown completes and transitions to playing, activate input and start timer
    if (previousStatus == GameStatus.countdown &&
        session.status == GameStatus.playing) {
      _stateMachine.setPhase(GamePhase.input);
      _lastActionTimestamp = DateTime.now();

      if (state.config.responseTimeLimit != null) {
        _stateMachine.startRoundResponseTimer(
          timeLimit: state.config.responseTimeLimit!,
        );
      }
    }

    // Auto-save attempt upon terminal resolution (completed, failed, abandoned)
    if (session.status.isTerminal && !_attemptSaved) {
      _saveAttempt();
    }
  }

  /// Begins the pre-game countdown (3..2..1) before board interaction.
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

  /// Skips instructions or countdown to start playing immediately (useful in tests/direct launch).
  void startPlayingImmediately() {
    if (state.sessionState.status == GameStatus.initial) {
      _stateMachine.startCountdown(seconds: 1);
      _timer.startSessionTimer();
    }
    if (state.sessionState.status == GameStatus.countdown) {
      _stateMachine.startPlaying();
    }
    _stateMachine.setPhase(GamePhase.input);
    _lastActionTimestamp = DateTime.now();
    if (state.config.responseTimeLimit != null) {
      _stateMachine.startRoundResponseTimer(
        timeLimit: state.config.responseTimeLimit!,
      );
    }
  }

  /// Handles user tapping an item tile on the Focus Hunter grid.
  void onItemTapped(int index) {
    if (!state.isInputAllowed) {
      return; // Reject taps outside active input phase
    }

    // Double-tap guard: ignore already selected items
    if (state.selectedIndices.contains(index)) {
      return;
    }

    if (index < 0 || index >= state.challenge.items.length) {
      return;
    }

    final now = DateTime.now();
    final latency = now.difference(_lastActionTimestamp ?? now);
    _lastActionTimestamp = now;

    final isTarget = _engine.evaluateInput(
      challenge: state.challenge,
      input: index,
      stepIndex: state.targetsFound,
    );

    if (isTarget) {
      _stateMachine.recordInput(
        isCorrect: true,
        responseLatency: latency,
      );

      final updatedFound = Set<int>.from(state.foundTargetIndices)..add(index);

      emit(state.copyWith(
        foundTargetIndices: updatedFound,
        lastTappedIndex: () => index,
        lastInputCorrect: () => true,
      ));

      // Check if all targets have been successfully discovered
      if (updatedFound.length >= state.challenge.targetCount) {
        _stateMachine.completeSession();
      }
    } else {
      _stateMachine.recordInput(
        isCorrect: false,
        responseLatency: latency,
      );

      final updatedMistakes = Set<int>.from(state.mistakeIndices)..add(index);

      emit(state.copyWith(
        mistakeIndices: updatedMistakes,
        lastTappedIndex: () => index,
        lastInputCorrect: () => false,
      ));

      // Check if errors exceeded maximum allowed
      if (updatedMistakes.length >= state.challenge.maxErrorsAllowed) {
        _stateMachine.failSession(reason: 'Exceeded maximum allowed errors.');
      }
    }
  }

  /// Pauses the active game session (e.g. app backgrounding).
  void pause() {
    if (state.sessionState.status == GameStatus.playing) {
      _stateMachine.pause();
    }
  }

  /// Resumes from a paused state.
  void resume() {
    if (state.sessionState.status == GameStatus.paused) {
      _stateMachine.resume();
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
      '[FocusHunter] PlayAgainAtCompletedDifficulty: replaying L${replayDifficulty.level}',
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
        '[FocusHunter] proceedToRecommendedLevel ignored: terminal=${state.isTerminal}, canProceed=${state.canProceedToNextLevel}',
      );
      return;
    }
    final targetDifficulty = state.recommendedDifficulty;
    debugPrint(
      '[FocusHunter] ProceedToRecommendedLevel: launching L${targetDifficulty.level}',
    );
    restart(
      difficulty: targetDifficulty,
      seed: seed,
      startImmediately: true,
    );
  }

  /// Returns to the Focus Hunter ready/setup screen using the current recommended difficulty.
  void returnToReadyView({int? seed}) {
    if (!state.isTerminal) return;
    final targetDifficulty = state.recommendedDifficulty;
    debugPrint(
      '[FocusHunter] ReturnToReadyView: opening ready view at recommended L${targetDifficulty.level}',
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
      '[FocusHunter] Restart: targetDifficulty=L${targetDifficulty.level} (from ${difficulty != null ? "explicit" : "config"}), startImmediately=$startImmediately',
    );

    final newConfig = FocusHunterConfig.forDifficulty(
      targetDifficulty,
      seed: seed ?? _initialSeed,
    );
    final newChallenge = _engine.generateHunterChallenge(config: newConfig);

    emit(FocusHunterState(
      config: newConfig,
      challenge: newChallenge,
      sessionState: GameSessionState.initial(newConfig),
      foundTargetIndices: const {},
      mistakeIndices: const {},
      lastTappedIndex: null,
      lastInputCorrect: null,
      isExitDialogOpen: false,
      adaptationDecision: null,
    ));

    _stateMachine.restart(newConfig);

    if (startImmediately) {
      startGame(
        countdownSeconds: 3,
        interval: const Duration(seconds: 1),
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
      '[FocusHunter] Result: status=${result.status.name}, '
      'difficulty=L${result.difficulty.level}, '
      'correct=${result.score.correctCount}, '
      'total=$totalResponses, '
      'accuracy=${(result.score.accuracy * 100).toStringAsFixed(1)}%, '
      'score=${result.score.scaledScore}',
    );

    final attempt = GameAttempt.fromResult(
      id: 'fh_${DateTime.now().millisecondsSinceEpoch}_${state.config.seed ?? 0}',
      result: result,
      responseTimesMs: _stateMachine.state.responseTimesMs,
    );

    bool saveSucceeded = false;
    try {
      await _attemptRepository.saveAttempt(attempt);
      saveSucceeded = true;
      debugPrint(
        '[FocusHunter] Persistence: id=${attempt.id}, gameId=${attempt.gameId}, status=${attempt.status.name}, saved=true',
      );
    } catch (e) {
      debugPrint(
        '[FocusHunter] Persistence FAILED for attempt ${attempt.id}: $e',
      );
    }

    // Only evaluate adaptation if save succeeded and session was not abandoned
    if (saveSucceeded &&
        _adaptiveService != null &&
        result.status != GameStatus.abandoned) {
      try {
        final decision = await _adaptiveService.evaluateAndPersist(
          gameId: FocusHunterConfig.gameId,
          currentDifficulty: state.difficulty,
        );
        debugPrint(
          '[FocusHunter] StateUpdate: decision=${decision.action.name}, '
          'target=L${decision.targetDifficulty.level}, '
          'current=L${state.difficulty.level}',
        );
        if (!isClosed && _currentSessionId == sessionId) {
          emit(state.copyWith(
            adaptationDecision: () => decision,
          ));
        }
      } catch (e) {
        debugPrint('[FocusHunter] Adaptive evaluation FAILED: $e');
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
