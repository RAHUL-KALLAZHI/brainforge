import 'package:flutter/foundation.dart';
import '../domain/game_config.dart';
import '../domain/game_result.dart';
import '../domain/game_session_state.dart';
import '../domain/game_status.dart';
import 'game_timer.dart';
import 'scoring_service.dart';

/// Exception thrown when attempting an invalid or illegal state transition.
class InvalidStateTransitionException implements Exception {
  final GameStatus from;
  final GameStatus to;
  final String? reason;

  const InvalidStateTransitionException({
    required this.from,
    required this.to,
    this.reason,
  });

  @override
  String toString() =>
      'InvalidStateTransitionException: Cannot transition from $from to $to.'
      '${reason != null ? ' Reason: $reason' : ''}';
}

/// Pure Dart state machine coordinating game session lifecycle and input gating.
class GameStateMachine extends ChangeNotifier {
  final GameTimer _timer;
  final ScoringService _scoringService;

  GameSessionState _state;
  bool _isCompleted = false;

  GameStateMachine({
    required GameConfig config,
    GameTimer? timer,
    ScoringService scoringService = const ScoringService(),
  })  : _timer = timer ?? GameTimer(),
        _scoringService = scoringService,
        _state = GameSessionState.initial(config);

  /// Current session state.
  GameSessionState get state => _state;

  /// Game timer instance.
  GameTimer get timer => _timer;

  /// Scoring service instance.
  ScoringService get scoringService => _scoringService;

  /// Valid state transitions matrix.
  static const Map<GameStatus, Set<GameStatus>> _allowedTransitions = {
    GameStatus.initial: {
      GameStatus.instructions,
      GameStatus.countdown,
      GameStatus.abandoned,
    },
    GameStatus.instructions: {
      GameStatus.countdown,
      GameStatus.abandoned,
    },
    GameStatus.countdown: {
      GameStatus.playing,
      GameStatus.abandoned,
    },
    GameStatus.playing: {
      GameStatus.paused,
      GameStatus.completed,
      GameStatus.failed,
      GameStatus.abandoned,
    },
    GameStatus.paused: {
      GameStatus.playing,
      GameStatus.abandoned,
    },
    // Terminal states can only be transitioned via restart() to initial
    GameStatus.completed: {
      GameStatus.initial,
    },
    GameStatus.failed: {
      GameStatus.initial,
    },
    GameStatus.abandoned: {
      GameStatus.initial,
    },
  };

  void _verifyTransition(GameStatus target) {
    final current = _state.status;
    final allowed = _allowedTransitions[current];
    if (allowed == null || !allowed.contains(target)) {
      throw InvalidStateTransitionException(from: current, to: target);
    }
  }

  /// Transitions to [GameStatus.instructions].
  void showInstructions() {
    _verifyTransition(GameStatus.instructions);
    _state = _state.copyWith(status: GameStatus.instructions);
    notifyListeners();
  }

  /// Begins the pre-game countdown (defaults to 3 seconds).
  void startCountdown(
      {int seconds = 3, Duration interval = const Duration(seconds: 1)}) {
    _verifyTransition(GameStatus.countdown);
    _state = _state.copyWith(
      status: GameStatus.countdown,
      countdownSecondsRemaining: seconds,
    );
    notifyListeners();

    _timer.startCountdown(
      seconds: seconds,
      interval: interval,
      onTick: (remaining) {
        if (_state.status == GameStatus.countdown) {
          _state = _state.copyWith(countdownSecondsRemaining: remaining);
          notifyListeners();
        }
      },
      onComplete: () {
        if (_state.status == GameStatus.countdown) {
          startPlaying();
        }
      },
    );
  }

  /// Transitions into active [GameStatus.playing] state.
  void startPlaying() {
    _verifyTransition(GameStatus.playing);
    _timer.startSessionTimer();
    _state = _state.copyWith(
      status: GameStatus.playing,
      phase: GamePhase.preview,
      startedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Switches active phase (e.g. from [GamePhase.preview] to [GamePhase.input]).
  void setPhase(GamePhase phase) {
    if (_state.status != GameStatus.playing) return;
    _state = _state.copyWith(phase: phase);
    notifyListeners();
  }

  /// Starts the round response timer window.
  void startRoundResponseTimer({
    required Duration timeLimit,
    Duration interval = const Duration(milliseconds: 100),
  }) {
    if (!_state.status.canAcceptInput) return;
    _state = _state.copyWith(remainingResponseTime: timeLimit);
    notifyListeners();

    _timer.startResponseWindow(
      timeLimit: timeLimit,
      interval: interval,
      onTick: (remaining) {
        if (_state.status == GameStatus.playing) {
          _state = _state.copyWith(remainingResponseTime: remaining);
          notifyListeners();
        }
      },
      onTimeout: () {
        if (_state.status == GameStatus.playing) {
          failSession(reason: 'Response time window expired.');
        }
      },
    );
  }

  /// Records player response evaluation.
  ///
  /// Rejects input if [state.isInputAllowed] is false (e.g. in preview phase or timeout).
  bool recordInput({
    required bool isCorrect,
    required Duration responseLatency,
    bool isMissed = false,
  }) {
    if (!_state.isInputAllowed) {
      return false; // Rejected late or disallowed input
    }

    _timer.stopResponseWindow();

    final latencyMs = responseLatency.inMilliseconds;
    final updatedLatencies = List<int>.from(_state.responseTimesMs)
      ..add(latencyMs);

    _state = _state.copyWith(
      correctCount: isCorrect ? _state.correctCount + 1 : _state.correctCount,
      incorrectCount: (!isCorrect && !isMissed)
          ? _state.incorrectCount + 1
          : _state.incorrectCount,
      missedCount: isMissed ? _state.missedCount + 1 : _state.missedCount,
      responseTimesMs: updatedLatencies,
    );
    notifyListeners();
    return true;
  }

  /// Pauses the game session (e.g. user tap or app backgrounding).
  void pause() {
    if (_state.status != GameStatus.playing) return;
    _verifyTransition(GameStatus.paused);
    _timer.pause();
    _state = _state.copyWith(status: GameStatus.paused);
    notifyListeners();
  }

  /// Resumes the game session from a paused state.
  void resume() {
    if (_state.status != GameStatus.paused) return;
    _verifyTransition(GameStatus.playing);
    _timer.resume();
    _state = _state.copyWith(status: GameStatus.playing);
    notifyListeners();
  }

  /// Completes the game session successfully.
  ///
  /// Idempotent: repeated completion calls are ignored to prevent duplicate rewards.
  void completeSession() {
    if (_isCompleted || _state.status.isTerminal) return;
    _verifyTransition(GameStatus.completed);

    _isCompleted = true;
    _timer.stop();

    final now = DateTime.now();
    final started = _state.startedAt ?? now;
    final duration = _timer.elapsedActiveTime;

    final score = _scoringService.calculateScore(
      correctCount: _state.correctCount,
      incorrectCount: _state.incorrectCount,
      missedCount: _state.missedCount,
      completedRounds: _state.currentRound,
      targetRounds: _state.config.targetRounds,
      totalResponseTime: duration,
    );

    final avgLatencyMs = _state.responseTimesMs.isNotEmpty
        ? (_state.responseTimesMs.reduce((a, b) => a + b) /
                _state.responseTimesMs.length)
            .round()
        : 0;

    final result = GameResult(
      gameId: _state.config.gameId,
      difficulty: _state.config.difficulty,
      status: GameStatus.completed,
      score: score,
      startedAt: started,
      completedAt: now,
      seed: _state.config.seed,
      completedRounds: _state.currentRound,
      targetRounds: _state.config.targetRounds,
      averageResponseTime: Duration(milliseconds: avgLatencyMs),
    );

    _state = _state.copyWith(
      status: GameStatus.completed,
      completedAt: now,
      result: result,
    );
    notifyListeners();
  }

  /// Terminates session as failed (timeout or max errors).
  void failSession({String? reason}) {
    if (_isCompleted || _state.status.isTerminal) return;
    _verifyTransition(GameStatus.failed);

    _isCompleted = true;
    _timer.stop();

    final now = DateTime.now();
    final started = _state.startedAt ?? now;
    final duration = _timer.elapsedActiveTime;

    final score = _scoringService.calculateScore(
      correctCount: _state.correctCount,
      incorrectCount: _state.incorrectCount,
      missedCount: _state.missedCount + 1,
      completedRounds: _state.currentRound > 0 ? _state.currentRound - 1 : 0,
      targetRounds: _state.config.targetRounds,
      totalResponseTime: duration,
    );

    final avgLatencyMs = _state.responseTimesMs.isNotEmpty
        ? (_state.responseTimesMs.reduce((a, b) => a + b) /
                _state.responseTimesMs.length)
            .round()
        : 0;

    final result = GameResult(
      gameId: _state.config.gameId,
      difficulty: _state.config.difficulty,
      status: GameStatus.failed,
      score: score,
      startedAt: started,
      completedAt: now,
      seed: _state.config.seed,
      completedRounds: _state.currentRound > 0 ? _state.currentRound - 1 : 0,
      targetRounds: _state.config.targetRounds,
      averageResponseTime: Duration(milliseconds: avgLatencyMs),
    );

    _state = _state.copyWith(
      status: GameStatus.failed,
      completedAt: now,
      result: result,
    );
    notifyListeners();
  }

  /// Player abandoned the game.
  void abandonSession() {
    if (_state.status.isTerminal) return;
    _verifyTransition(GameStatus.abandoned);

    _isCompleted = true;
    _timer.stop();

    final now = DateTime.now();
    final started = _state.startedAt ?? now;
    final duration = _timer.elapsedActiveTime;

    final score = _scoringService.calculateScore(
      correctCount: _state.correctCount,
      incorrectCount: _state.incorrectCount,
      missedCount: _state.missedCount,
      completedRounds: 0,
      targetRounds: _state.config.targetRounds,
      totalResponseTime: duration,
      isAbandoned: true,
    );

    final result = GameResult(
      gameId: _state.config.gameId,
      difficulty: _state.config.difficulty,
      status: GameStatus.abandoned,
      score: score,
      startedAt: started,
      completedAt: now,
      seed: _state.config.seed,
      completedRounds: 0,
      targetRounds: _state.config.targetRounds,
      averageResponseTime: Duration.zero,
    );

    _state = _state.copyWith(
      status: GameStatus.abandoned,
      completedAt: now,
      result: result,
    );
    notifyListeners();
  }

  /// Restarts the game back to [GameStatus.initial].
  void restart([GameConfig? newConfig]) {
    _timer.stop();
    _isCompleted = false;
    final configToUse = newConfig ?? _state.config;
    configToUse.validate();
    _state = GameSessionState.initial(configToUse);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }
}
