import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/game_state_machine.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import '../domain/memory_grid_config.dart';
import 'memory_grid_engine.dart';
import 'memory_grid_state.dart';

/// Cubit managing presentation state and coordinating the pure-Dart game engine for Memory Grid.
class MemoryGridCubit extends Cubit<MemoryGridState> {
  final MemoryGridEngine _engine;
  final GameAttemptRepository _attemptRepository;
  final GameTimer _timer;
  final bool _fastPreviewForTesting;

  late GameStateMachine _stateMachine;
  int _currentSessionId = 0;
  bool _attemptSaved = false;
  DateTime? _lastActionTimestamp;
  GameStatus _lastObservedStatus = GameStatus.initial;

  MemoryGridCubit({
    MemoryGridEngine engine = const MemoryGridEngine(),
    GameAttemptRepository? attemptRepository,
    GameTimer? timer,
    GameDifficulty initialDifficulty = const GameDifficulty(1),
    int? initialSeed,
    bool fastPreviewForTesting = false,
  })  : _engine = engine,
        _attemptRepository =
            attemptRepository ?? getIt<GameAttemptRepository>(),
        _timer = timer ?? GameTimer(),
        _fastPreviewForTesting = fastPreviewForTesting,
        super(_createInitialState(
          engine: engine,
          timer: timer ?? GameTimer(),
          difficulty: initialDifficulty,
          seed: initialSeed,
        )) {
    _initStateMachine();
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

  /// Restarts the game session with current or updated difficulty/seed.
  void restart({GameDifficulty? difficulty, int? seed}) {
    ++_currentSessionId;
    _attemptSaved = false;

    final targetDifficulty = difficulty ?? state.config.difficulty;
    final newConfig =
        MemoryGridConfig.forDifficulty(targetDifficulty, seed: seed);
    final newChallenge = _engine.generateGridChallenge(config: newConfig);

    _stateMachine.restart(newConfig);

    emit(MemoryGridState.initial(
      config: newConfig,
      challenge: newChallenge,
      sessionState: _stateMachine.state,
    ));
  }

  Future<void> _saveAttempt() async {
    if (_attemptSaved) return;
    _attemptSaved = true;

    final result = _stateMachine.state.result;
    if (result == null) return;

    final attempt = GameAttempt.fromResult(
      id: 'mg_${DateTime.now().millisecondsSinceEpoch}_${state.config.seed ?? 0}',
      result: result,
      responseTimesMs: _stateMachine.state.responseTimesMs,
    );

    try {
      await _attemptRepository.saveAttempt(attempt);
    } catch (_) {
      // Repository failures are handled gracefully without interrupting user flow
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
