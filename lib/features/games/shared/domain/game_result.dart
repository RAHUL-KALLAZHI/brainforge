import 'package:equatable/equatable.dart';
import 'game_difficulty.dart';
import 'game_score.dart';
import 'game_status.dart';

/// Immutable summary result emitted upon game session completion or termination.
class GameResult extends Equatable {
  final String gameId;
  final GameDifficulty difficulty;
  final GameStatus status;
  final GameScore score;
  final DateTime startedAt;
  final DateTime completedAt;
  final int? seed;
  final int completedRounds;
  final int targetRounds;
  final Duration averageResponseTime;

  const GameResult({
    required this.gameId,
    required this.difficulty,
    required this.status,
    required this.score,
    required this.startedAt,
    required this.completedAt,
    this.seed,
    required this.completedRounds,
    required this.targetRounds,
    required this.averageResponseTime,
  });

  /// Total duration elapsed during the session.
  Duration get totalDuration => completedAt.difference(startedAt);

  /// True if the session was completed successfully.
  bool get isSuccess => status == GameStatus.completed;

  @override
  List<Object?> get props => [
        gameId,
        difficulty,
        status,
        score,
        startedAt,
        completedAt,
        seed,
        completedRounds,
        targetRounds,
        averageResponseTime,
      ];
}
