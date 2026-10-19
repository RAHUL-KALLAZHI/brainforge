import 'package:equatable/equatable.dart';
import 'game_config.dart';
import 'game_result.dart';
import 'game_status.dart';

/// Immutable snapshot representing the entire state of a game session.
class GameSessionState extends Equatable {
  final GameConfig config;
  final GameStatus status;
  final GamePhase phase;
  final int currentRound;
  final int countdownSecondsRemaining;
  final Duration remainingResponseTime;
  final int correctCount;
  final int incorrectCount;
  final int missedCount;
  final List<int> responseTimesMs;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final GameResult? result;

  const GameSessionState({
    required this.config,
    this.status = GameStatus.initial,
    this.phase = GamePhase.preview,
    this.currentRound = 1,
    this.countdownSecondsRemaining = 3,
    this.remainingResponseTime = Duration.zero,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.missedCount = 0,
    this.responseTimesMs = const [],
    this.startedAt,
    this.completedAt,
    this.result,
  });

  /// Factory initializing a fresh session state for the provided [config].
  factory GameSessionState.initial(GameConfig config) {
    config.validate();
    return GameSessionState(
      config: config,
      status: GameStatus.initial,
      phase: GamePhase.preview,
      currentRound: 1,
      countdownSecondsRemaining: 3,
      remainingResponseTime: config.responseTimeLimit ?? Duration.zero,
    );
  }

  /// Whether player touch/keyboard input is currently allowed.
  bool get isInputAllowed => status.canAcceptInput && phase.isInputAllowed;

  /// Total recorded opportunities.
  int get totalOpportunities => correctCount + incorrectCount + missedCount;

  GameSessionState copyWith({
    GameConfig? config,
    GameStatus? status,
    GamePhase? phase,
    int? currentRound,
    int? countdownSecondsRemaining,
    Duration? remainingResponseTime,
    int? correctCount,
    int? incorrectCount,
    int? missedCount,
    List<int>? responseTimesMs,
    DateTime? startedAt,
    DateTime? completedAt,
    GameResult? result,
  }) {
    return GameSessionState(
      config: config ?? this.config,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      currentRound: currentRound ?? this.currentRound,
      countdownSecondsRemaining:
          countdownSecondsRemaining ?? this.countdownSecondsRemaining,
      remainingResponseTime:
          remainingResponseTime ?? this.remainingResponseTime,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      missedCount: missedCount ?? this.missedCount,
      responseTimesMs: responseTimesMs ?? this.responseTimesMs,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
        config,
        status,
        phase,
        currentRound,
        countdownSecondsRemaining,
        remainingResponseTime,
        correctCount,
        incorrectCount,
        missedCount,
        responseTimesMs,
        startedAt,
        completedAt,
        result,
      ];
}
