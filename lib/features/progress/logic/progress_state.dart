import 'package:equatable/equatable.dart';
import '../../games/shared/domain/game_attempt.dart';
import '../../games/shared/domain/game_difficulty.dart';

/// Aggregated gameplay performance statistics.
class ProgressStats extends Equatable {
  final int totalAttempts;
  final int memoryGridAttempts;
  final int successfulAttempts;
  final int failedAttempts;
  final int abandonedAttempts;
  final int? bestScore;
  final double? averageAccuracy;
  final int? medianReactionTimeMs;
  final int currentStreakDays;
  final int completedWorkouts;
  final List<GameAttempt> recentAttempts;
  final GameDifficulty? memoryGridDifficulty;

  const ProgressStats({
    this.totalAttempts = 0,
    this.memoryGridAttempts = 0,
    this.successfulAttempts = 0,
    this.failedAttempts = 0,
    this.abandonedAttempts = 0,
    this.bestScore,
    this.averageAccuracy,
    this.medianReactionTimeMs,
    this.currentStreakDays = 0,
    this.completedWorkouts = 0,
    this.recentAttempts = const [],
    this.memoryGridDifficulty,
  });

  bool get hasData => totalAttempts > 0;

  @override
  List<Object?> get props => [
        totalAttempts,
        memoryGridAttempts,
        successfulAttempts,
        failedAttempts,
        abandonedAttempts,
        bestScore,
        averageAccuracy,
        medianReactionTimeMs,
        currentStreakDays,
        completedWorkouts,
        recentAttempts,
        memoryGridDifficulty,
      ];
}

/// Base state for Progress dashboard.
abstract class ProgressState extends Equatable {
  const ProgressState();

  @override
  List<Object?> get props => [];
}

/// Loading state while querying local SQLite database.
class ProgressLoading extends ProgressState {
  const ProgressLoading();
}

/// State with loaded progress statistics.
class ProgressLoaded extends ProgressState {
  final ProgressStats stats;

  const ProgressLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

/// Error state if database reading fails.
class ProgressError extends ProgressState {
  final String message;

  const ProgressError(this.message);

  @override
  List<Object?> get props => [message];
}
