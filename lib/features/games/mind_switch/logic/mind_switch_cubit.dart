import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_session_state.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
import 'package:brainforge/features/games/shared/logic/game_state_machine.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_challenge.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_config.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_engine.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_state.dart';

/// Cubit managing Mind Switch cognitive training session lifecycle,
/// rapid rule switches, trial countdowns, mistake tolerance, and score persistence.
class MindSwitchCubit extends Cubit<MindSwitchState> {
  final MindSwitchEngine _engine;
  final GameTimer _timer;
  final Ticker _trialTicker;
  final GameAttemptRepository _attemptRepository;
  final AdaptiveDifficultyService? _adaptiveService;
  final int? _initialSeed;
  final bool _fastPreviewForTesting;

  late GameStateMachine _stateMachine;
  StreamSubscription<int>? _trialSubscription;
  DateTime? _trialStartTimestamp;
  bool _attemptSaved = false;
  int _currentSessionId = 0;
  GameStatus _lastObservedStatus = GameStatus.initial;

  MindSwitchCubit({
    MindSwitchEngine engine = const MindSwitchEngine(),
    GameTimer? timer,
    Ticker? trialTicker,
    GameAttemptRepository? attemptRepository,
    AdaptiveDifficultyService? adaptiveService,
    GameDifficulty? initialDifficulty,
    int? seed,
    bool fastPreviewForTesting = false,
  })  : _engine = engine,
        _timer = timer ?? GameTimer(),
        _trialTicker = trialTicker ?? const RealTicker(),
        _attemptRepository =
            attemptRepository ?? getIt<GameAttemptRepository>(),
        _adaptiveService = adaptiveService ??
            (getIt.isRegistered<AdaptiveDifficultyService>()
                ? getIt<AdaptiveDifficultyService>()
                : null),
        _initialSeed = seed,
        _fastPreviewForTesting = fastPreviewForTesting,
        super(_createInitialState(
          engine: engine,
          timer: timer ?? GameTimer(),
          difficulty: initialDifficulty ?? GameDifficulty.baseline,
          seed: seed,
        )) {
    _initStateMachine();
    if (initialDifficulty == null) {
      _loadAdaptiveDifficulty();
    }
  }

  /// Hydrates adaptive difficulty if available.
  Future<void> _loadAdaptiveDifficulty() async {
    if (_adaptiveService == null) return;
    try {
      final effectiveDifficulty = await _adaptiveService
          .getEffectiveDifficulty(MindSwitchConfig.gameId);
      debugPrint(
        '[MindSwitch] HydrateDifficulty: loaded=L${effectiveDifficulty.level}, current=L${state.difficulty.level}',
      );
      if (!isClosed &&
          state.sessionState.status == GameStatus.initial &&
          effectiveDifficulty.level != state.difficulty.level) {
        final newConfig = MindSwitchConfig.forDifficulty(
          effectiveDifficulty,
          seed: _initialSeed,
        );
        final newChallenge =
            _engine.generateMindSwitchChallenge(config: newConfig);

        _stateMachine.restart(newConfig);
        emit(MindSwitchState.initial(
          config: newConfig,
          challenge: newChallenge,
          sessionState: _stateMachine.state,
        ));
      }
    } catch (e) {
      debugPrint('[MindSwitch] HydrateDifficulty failed: $e');
    }
  }

  static MindSwitchState _createInitialState({
    required MindSwitchEngine engine,
    required GameTimer timer,
    required GameDifficulty difficulty,
    int? seed,
  }) {
    final config = MindSwitchConfig.forDifficulty(difficulty, seed: seed);
    final challenge = engine.generateMindSwitchChallenge(config: config);
    final sessionState =
        engine.createSession(config: config, timer: timer).state;

    return MindSwitchState.initial(
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

    // When countdown completes and transitions to playing, activate first trial
    if (previousStatus == GameStatus.countdown &&
        session.status == GameStatus.playing) {
      _stateMachine.setPhase(GamePhase.input);
      _startCurrentTrial();
    }

    // Auto-save attempt upon terminal resolution (completed, failed, abandoned)
    if (session.status.isTerminal && !_attemptSaved) {
      _cancelTrialTimer();
      _saveAttempt();
    }
  }

  /// Initiates pre-game countdown (3..2..1) before first trial.
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

  /// Starts playing immediately (used in tests/direct launch).
  void startPlayingImmediately() {
    if (state.sessionState.status == GameStatus.initial) {
      _stateMachine.startCountdown(seconds: 1);
      _timer.startSessionTimer();
    }
    if (state.sessionState.status == GameStatus.countdown) {
      _stateMachine.startPlaying();
    }
    _stateMachine.setPhase(GamePhase.input);
    _startCurrentTrial();
  }

  /// Begins response window for the current trial.
  Future<void> _startCurrentTrial() async {
    final trial = state.currentTrial;
    if (trial == null) return;

    final limit = state.config.responseTimeLimit ??
        MindSwitchConfig.trialTimeLimitForDifficulty(state.difficulty);

    emit(state.copyWith(
      trialTimeLimit: limit,
      trialTimeRemaining: limit,
    ));

    // Check if we need to display the rule switch banner
    if (trial.isRuleSwitch) {
      final sessionId = _currentSessionId;
      emit(state.copyWith(showRuleSwitchBanner: true));
      if (!_fastPreviewForTesting) {
        await Future<void>.delayed(const Duration(milliseconds: 650));
      }
      if (isClosed || _currentSessionId != sessionId || state.isTerminal) {
        return;
      }
      emit(state.copyWith(showRuleSwitchBanner: false));
    }

    _startTrialTimer(limit);
  }

  void _startTrialTimer(Duration limit) {
    _cancelTrialTimer();
    _trialStartTimestamp = DateTime.now();

    const interval = Duration(milliseconds: 100);
    final totalTicks = (limit.inMilliseconds / interval.inMilliseconds).ceil();

    if (totalTicks <= 0) {
      _handleTrialTimeout();
      return;
    }

    _trialSubscription =
        _trialTicker.countdown(ticks: totalTicks, interval: interval).listen(
      (remainingTicks) {
        if (isClosed || state.isTerminal) return;
        final remainingMs = remainingTicks * interval.inMilliseconds;
        emit(state.copyWith(
          trialTimeRemaining: Duration(milliseconds: remainingMs),
        ));
      },
      onDone: () {
        if (isClosed || state.isTerminal) return;
        emit(state.copyWith(trialTimeRemaining: Duration.zero));
        _handleTrialTimeout();
      },
      cancelOnError: true,
    );
  }

  void _cancelTrialTimer() {
    _trialSubscription?.cancel();
    _trialSubscription = null;
  }

  /// Handles expiration of the per-trial response timer window.
  void _handleTrialTimeout() {
    if (!state.isPlaying || state.isTerminal) return;

    final newMistakes = state.mistakeCount + 1;
    _stateMachine.recordInput(
      isCorrect: false,
      responseLatency: state.trialTimeLimit,
      isMissed: true,
    );

    emit(state.copyWith(
      mistakeCount: newMistakes,
      lastInputCorrect: () => false,
      lastSelectedColor: () => null,
    ));

    if (newMistakes > state.challenge.maxMistakesAllowed) {
      _stateMachine.failSession(
        reason:
            'Maximum mistakes exceeded (${state.challenge.maxMistakesAllowed}).',
      );
      return;
    }

    _proceedToNextTrial();
  }

  /// Handles user tapping one of the 4 color option buttons.
  void onColorSelected(MindSwitchColor color) {
    if (!state.isInputAllowed) return;

    _cancelTrialTimer();

    final now = DateTime.now();
    final latency = now.difference(_trialStartTimestamp ?? now);

    final isCorrect = _engine.evaluateInput(
      challenge: state.challenge,
      input: color,
      stepIndex: state.currentTrialIndex,
    );

    _stateMachine.recordInput(
      isCorrect: isCorrect,
      responseLatency: latency,
    );

    if (isCorrect) {
      final newCorrect = state.correctCount + 1;
      emit(state.copyWith(
        correctCount: newCorrect,
        lastSelectedColor: () => color,
        lastInputCorrect: () => true,
      ));
      _proceedToNextTrial();
    } else {
      final newMistakes = state.mistakeCount + 1;
      emit(state.copyWith(
        mistakeCount: newMistakes,
        lastSelectedColor: () => color,
        lastInputCorrect: () => false,
      ));

      if (newMistakes > state.challenge.maxMistakesAllowed) {
        _stateMachine.failSession(
          reason:
              'Maximum mistakes exceeded (${state.challenge.maxMistakesAllowed}).',
        );
      } else {
        _proceedToNextTrial();
      }
    }
  }

  void _proceedToNextTrial() {
    final nextIndex = state.currentTrialIndex + 1;
    if (nextIndex >= state.challenge.totalTrials) {
      _stateMachine.completeSession();
    } else {
      emit(state.copyWith(currentTrialIndex: nextIndex));
      _startCurrentTrial();
    }
  }

  /// Requests session termination with user confirmation.
  void requestExit() {
    if (state.isTerminal) return;
    _cancelTrialTimer();
    emit(state.copyWith(isExitDialogOpen: true));
  }

  /// Dismisses exit confirmation and resumes active play.
  void cancelExit() {
    if (!state.isExitDialogOpen) return;
    emit(state.copyWith(isExitDialogOpen: false));
    if (state.isPlaying && !state.isTerminal) {
      _startTrialTimer(state.trialTimeRemaining);
    }
  }

  /// Confirms exit and marks session as abandoned.
  void confirmExit() {
    emit(state.copyWith(isExitDialogOpen: false));
    _cancelTrialTimer();
    _stateMachine.abandonSession();
  }

  /// Pauses the active game session.
  void pause() {
    if (state.sessionState.status != GameStatus.playing) return;
    _cancelTrialTimer();
    _stateMachine.pause();
  }

  /// Resumes the game session from paused state.
  void resume() {
    if (state.sessionState.status != GameStatus.paused) return;
    _stateMachine.resume();
    _startTrialTimer(state.trialTimeRemaining);
  }

  /// Abandons the active session.
  void abandonGame() {
    confirmExit();
  }

  /// Advances directly to recommended difficulty upon promotion.
  void proceedToRecommendedLevel() {
    restart(
      difficulty: state.recommendedDifficulty,
      startImmediately: true,
    );
  }

  /// Replays at the recently played difficulty.
  void playAgainAtCompletedDifficulty() {
    restart(
      difficulty: state.playedDifficulty,
      startImmediately: true,
    );
  }

  /// Returns to the pre-game configuration view.
  void returnToReadyView({int? seed}) {
    if (!state.isTerminal) return;
    final targetDifficulty = state.recommendedDifficulty;
    debugPrint(
      '[MindSwitch] ReturnToReadyView: opening ready view at recommended L${targetDifficulty.level}',
    );
    restart(
      difficulty: targetDifficulty,
      seed: seed,
      startImmediately: false,
    );
  }

  /// Restarts session with existing or updated difficulty/seed.
  void restart({
    GameDifficulty? difficulty,
    int? seed,
    bool startImmediately = false,
  }) {
    ++_currentSessionId;
    _attemptSaved = false;
    _cancelTrialTimer();

    final targetDifficulty = difficulty ?? state.config.difficulty;
    final newConfig = MindSwitchConfig.forDifficulty(
      targetDifficulty,
      seed: seed ?? _initialSeed,
    );
    final newChallenge = _engine.generateMindSwitchChallenge(config: newConfig);

    emit(MindSwitchState.initial(
      config: newConfig,
      challenge: newChallenge,
      sessionState: GameSessionState.initial(newConfig),
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
      '[MindSwitch] Result: status=${result.status.name}, '
      'difficulty=L${result.difficulty.level}, '
      'correct=${result.score.correctCount}, '
      'total=$totalResponses, '
      'accuracy=${(result.score.accuracy * 100).toStringAsFixed(1)}%, '
      'score=${result.score.scaledScore}',
    );

    final attempt = GameAttempt.fromResult(
      id: 'ms_${DateTime.now().millisecondsSinceEpoch}_${state.config.seed ?? 0}',
      result: result,
      responseTimesMs: _stateMachine.state.responseTimesMs,
    );

    bool saveSucceeded = false;
    try {
      await _attemptRepository.saveAttempt(attempt);
      saveSucceeded = true;
      debugPrint(
        '[MindSwitch] Persistence: id=${attempt.id}, gameId=${attempt.gameId}, status=${attempt.status.name}, saved=true',
      );
    } catch (e) {
      debugPrint('[MindSwitch] Persistence FAILED: $e');
    }

    if (saveSucceeded &&
        _adaptiveService != null &&
        result.status != GameStatus.abandoned) {
      try {
        final decision = await _adaptiveService.evaluateAndPersist(
          gameId: MindSwitchConfig.gameId,
          currentDifficulty: state.difficulty,
        );
        debugPrint(
          '[MindSwitch] StateUpdate: decision=${decision.action.name}, '
          'target=L${decision.targetDifficulty.level}, '
          'current=L${state.difficulty.level}',
        );
        if (!isClosed && _currentSessionId == sessionId) {
          emit(state.copyWith(
            adaptationDecision: () => decision,
          ));
        }
      } catch (e) {
        debugPrint('[MindSwitch] Adaptive evaluation FAILED: $e');
      }
    }
  }

  @override
  Future<void> close() {
    ++_currentSessionId;
    _cancelTrialTimer();
    _stateMachine.removeListener(_onStateMachineUpdated);
    _stateMachine.dispose();
    return super.close();
  }
}
