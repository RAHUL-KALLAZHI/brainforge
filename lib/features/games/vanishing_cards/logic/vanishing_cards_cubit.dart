import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
import 'package:brainforge/features/games/shared/logic/game_state_machine.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import '../domain/vanishing_cards_config.dart';
import 'vanishing_cards_engine.dart';
import 'vanishing_cards_state.dart';

/// Cubit managing presentation state and lifecycle for the Vanishing Cards mini-game.
class VanishingCardsCubit extends Cubit<VanishingCardsState> {
  final VanishingCardsEngine _engine;
  final GameAttemptRepository _attemptRepository;
  final AdaptiveDifficultyService? _adaptiveService;
  final GameTimer _timer;
  final int? _initialSeed;
  final bool _fastPreviewForTesting;

  late GameStateMachine _stateMachine;
  int _currentSessionId = 0;
  bool _attemptSaved = false;
  DateTime? _lastActionTimestamp;
  GameStatus _lastObservedStatus = GameStatus.initial;
  Timer? _previewTimer;

  VanishingCardsCubit({
    VanishingCardsEngine engine = const VanishingCardsEngine(),
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
          .getEffectiveDifficulty(VanishingCardsConfig.gameId);
      debugPrint(
        '[VanishingCards] HydrateDifficulty: loaded=L${effectiveDifficulty.level}, current=L${state.difficulty.level}',
      );
      if (!isClosed &&
          state.sessionState.status == GameStatus.initial &&
          effectiveDifficulty.level != state.difficulty.level) {
        final newConfig = VanishingCardsConfig.forDifficulty(
          effectiveDifficulty,
          seed: _initialSeed,
        );
        final newChallenge = _engine.generateCardsChallenge(config: newConfig);

        _stateMachine.restart(newConfig);
        emit(VanishingCardsState.initial(
          config: newConfig,
          challenge: newChallenge,
          sessionState: _stateMachine.state,
        ));
      }
    } catch (e) {
      debugPrint('[VanishingCards] HydrateDifficulty failed: $e');
    }
  }

  static VanishingCardsState _createInitialState({
    required VanishingCardsEngine engine,
    required GameTimer timer,
    required GameDifficulty difficulty,
    int? seed,
  }) {
    final config = VanishingCardsConfig.forDifficulty(difficulty, seed: seed);
    final challenge = engine.generateCardsChallenge(config: config);
    final sessionState =
        engine.createSession(config: config, timer: timer).state;

    return VanishingCardsState.initial(
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

    // When countdown completes and transitions to playing, begin preview phase
    if (previousStatus == GameStatus.countdown &&
        session.status == GameStatus.playing) {
      _startPreviewPhase();
    }

    // Auto-save attempt upon terminal resolution (completed, failed, abandoned)
    if (session.status.isTerminal && !_attemptSaved) {
      _saveAttempt();
    }
  }

  /// Begins the pre-game countdown (3..2..1) before card presentation.
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

  /// Begins the preview phase where cards are revealed face-up for study.
  void _startPreviewPhase() {
    _previewTimer?.cancel();
    _stateMachine.setPhase(GamePhase.preview);
    emit(state.copyWith(isPreviewing: true));

    final previewDuration = _fastPreviewForTesting
        ? const Duration(milliseconds: 10)
        : state.challenge.previewDuration;

    final sessionId = ++_currentSessionId;

    _previewTimer = Timer(previewDuration, () {
      if (isClosed || sessionId != _currentSessionId) return;
      _endPreviewAndBeginRecall();
    });
  }

  /// Concludes the preview phase, flips cards face-down, and enables recall input.
  void _endPreviewAndBeginRecall() {
    _previewTimer?.cancel();
    _stateMachine.setPhase(GamePhase.input);
    _lastActionTimestamp = DateTime.now();

    emit(state.copyWith(
      isPreviewing: false,
      currentTargetStepIndex: 0,
    ));

    if (state.config.responseTimeLimit != null) {
      _stateMachine.startRoundResponseTimer(
        timeLimit: state.config.responseTimeLimit!,
      );
    }
  }

  /// Test helper to immediately complete preview phase without real-time delay.
  void completePreviewForTesting() {
    if (state.sessionState.status == GameStatus.playing && state.isPreviewing) {
      _endPreviewAndBeginRecall();
    }
  }

  /// Directly starts playing in active recall phase (useful in tests/direct launch).
  void startPlayingImmediately() {
    _previewTimer?.cancel();
    if (state.sessionState.status == GameStatus.initial) {
      _stateMachine.startCountdown(seconds: 1);
      _timer.startSessionTimer();
    }
    if (state.sessionState.status == GameStatus.countdown) {
      _stateMachine.startPlaying();
    }
    _endPreviewAndBeginRecall();
  }

  /// Handles user tapping a concealed card on the board.
  void onCardTapped(int positionIndex) {
    if (!state.isInputAllowed) {
      return; // Reject taps outside interactive recall phase
    }

    // Double-tap guard: ignore already selected positions
    if (state.selectedPositions.contains(positionIndex)) {
      return;
    }

    if (positionIndex < 0 || positionIndex >= state.challenge.cards.length) {
      return;
    }

    final now = DateTime.now();
    final latency = now.difference(_lastActionTimestamp ?? now);
    _lastActionTimestamp = now;

    final isCorrect = _engine.evaluateInput(
      challenge: state.challenge,
      input: positionIndex,
      stepIndex: state.currentTargetStepIndex,
    );

    if (isCorrect) {
      _stateMachine.recordInput(
        isCorrect: true,
        responseLatency: latency,
      );

      final updatedFound = Set<int>.from(state.foundCardPositions)
        ..add(positionIndex);
      final nextStep = state.currentTargetStepIndex + 1;

      emit(state.copyWith(
        foundCardPositions: updatedFound,
        currentTargetStepIndex: nextStep,
        lastTappedPosition: () => positionIndex,
        lastInputCorrect: () => true,
      ));

      // Check if all requested target cards have been found
      if (updatedFound.length >= state.challenge.targetCards.length) {
        _stateMachine.completeSession();
      }
    } else {
      _stateMachine.recordInput(
        isCorrect: false,
        responseLatency: latency,
      );

      final updatedMistakes = Set<int>.from(state.mistakePositions)
        ..add(positionIndex);

      emit(state.copyWith(
        mistakePositions: updatedMistakes,
        lastTappedPosition: () => positionIndex,
        lastInputCorrect: () => false,
      ));

      // Check if mistakes exceeded allowed limit
      if (updatedMistakes.length > state.maxErrorsAllowed) {
        _stateMachine.failSession(reason: 'Exceeded maximum allowed errors.');
      }
    }
  }

  /// Pauses the active game session (e.g. app backgrounding).
  void pause() {
    _previewTimer?.cancel();
    if (state.sessionState.status == GameStatus.playing) {
      _stateMachine.pause();
    }
  }

  /// Resumes a paused game session.
  void resume() {
    if (state.sessionState.status == GameStatus.paused) {
      _stateMachine.resume();
      if (state.isPreviewing) {
        _startPreviewPhase();
      } else {
        _lastActionTimestamp = DateTime.now();
      }
    }
  }

  /// Abandons the active game session with score clamped to 0.
  void abandonGame() {
    _previewTimer?.cancel();
    _stateMachine.abandonSession();
  }

  /// Restarts the session cleanly, applying an optional difficulty override.
  void restart({GameDifficulty? difficulty, bool startImmediately = false}) {
    _previewTimer?.cancel();
    _currentSessionId++;
    _attemptSaved = false;
    _lastActionTimestamp = null;
    _lastObservedStatus = GameStatus.initial;

    final targetDiff = difficulty ?? state.difficulty;
    final newConfig = VanishingCardsConfig.forDifficulty(
      targetDiff,
      seed: _initialSeed,
    );
    final newChallenge = _engine.generateCardsChallenge(config: newConfig);

    _stateMachine.restart(newConfig);

    emit(VanishingCardsState.initial(
      config: newConfig,
      challenge: newChallenge,
      sessionState: _stateMachine.state,
      initialHydratedDifficulty: state.initialHydratedDifficulty,
    ));

    if (startImmediately) {
      startGame();
    }
  }

  /// Replays a game at the difficulty level that was just completed.
  void playAgainAtCompletedDifficulty() {
    debugPrint(
      '[VanishingCards] PlayAgainAtCompletedDifficulty: replaying L${state.playedDifficulty.level}',
    );
    restart(difficulty: state.playedDifficulty, startImmediately: true);
  }

  /// Progresses to the newly promoted adaptive difficulty level.
  void proceedToRecommendedLevel() {
    final nextLevel = state.recommendedDifficulty;
    debugPrint(
      '[VanishingCards] ProceedToRecommendedLevel: launching L${nextLevel.level}',
    );
    restart(difficulty: nextLevel, startImmediately: true);
  }

  /// Returns to the initial setup / ready view.
  void returnToReadyView() {
    final targetLevel = state.recommendedDifficulty;
    debugPrint(
      '[VanishingCards] ReturnToReadyView: opening ready view at recommended L${targetLevel.level}',
    );
    restart(difficulty: targetLevel, startImmediately: false);
  }

  /// Automatically persists the session's attempt and triggers adaptive difficulty evaluation.
  Future<void> _saveAttempt() async {
    if (_attemptSaved) return;
    _attemptSaved = true;
    _previewTimer?.cancel();
    final sessionId = _currentSessionId;

    final result = _stateMachine.state.result;
    if (result == null) return;

    final totalResponses = result.score.correctCount +
        result.score.incorrectCount +
        result.score.missedCount;
    debugPrint(
      '[VanishingCards] Result: status=${result.status.name}, '
      'difficulty=L${result.difficulty.level}, '
      'correct=${result.score.correctCount}, '
      'total=$totalResponses, '
      'accuracy=${(result.score.accuracy * 100).toStringAsFixed(1)}%, '
      'score=${result.score.scaledScore}',
    );

    final attempt = GameAttempt.fromResult(
      id: 'vc_${DateTime.now().millisecondsSinceEpoch}_${state.config.seed ?? 0}',
      result: result,
      responseTimesMs: _stateMachine.state.responseTimesMs,
    );

    bool saveSucceeded = false;
    try {
      await _attemptRepository.saveAttempt(attempt);
      saveSucceeded = true;
      debugPrint(
        '[VanishingCards] Persistence: id=${attempt.id}, gameId=${attempt.gameId}, status=${attempt.status.name}, saved=true',
      );
    } catch (e) {
      debugPrint(
        '[VanishingCards] Persistence FAILED for attempt ${attempt.id}: $e',
      );
    }

    if (saveSucceeded &&
        _adaptiveService != null &&
        result.status != GameStatus.abandoned) {
      try {
        final decision = await _adaptiveService.evaluateAndPersist(
          gameId: VanishingCardsConfig.gameId,
          currentDifficulty: state.difficulty,
        );
        debugPrint(
          '[VanishingCards] StateUpdate: decision=${decision.action.name}, '
          'target=L${decision.targetDifficulty.level}, '
          'current=L${state.difficulty.level}',
        );
        if (!isClosed && _currentSessionId == sessionId) {
          emit(state.copyWith(
            adaptationDecision: () => decision,
          ));
        }
      } catch (e) {
        debugPrint('[VanishingCards] Adaptive evaluation FAILED: $e');
      }
    }
  }

  @override
  Future<void> close() {
    _previewTimer?.cancel();
    _stateMachine.removeListener(_onStateMachineUpdated);
    _stateMachine.dispose();
    return super.close();
  }
}
