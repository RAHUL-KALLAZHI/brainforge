import 'package:flutter_bloc/flutter_bloc.dart';
import '../../games/shared/data/adaptive_difficulty_repository.dart';
import '../../games/shared/data/game_attempt_repository.dart';
import '../../games/shared/domain/game_attempt.dart';
import '../../games/shared/domain/game_difficulty.dart';
import '../../games/shared/domain/game_status.dart';
import 'progress_state.dart';

/// Cubit managing loading, computing, and streaming user gameplay analytics.
class ProgressCubit extends Cubit<ProgressState> {
  final GameAttemptRepository _repository;
  final AdaptiveDifficultyRepository? _difficultyRepository;

  ProgressCubit(
    this._repository, {
    AdaptiveDifficultyRepository? difficultyRepository,
  })  : _difficultyRepository = difficultyRepository,
        super(const ProgressLoading()) {
    _init();
  }

  void _init() {
    loadProgress();
  }

  /// Refreshes all statistics from the persistent database.
  Future<void> loadProgress() async {
    try {
      emit(const ProgressLoading());
      final attempts = await _repository.getAllAttempts(limit: 100);
      GameDifficulty? mgDifficulty;
      if (_difficultyRepository != null) {
        try {
          mgDifficulty =
              await _difficultyRepository.getDifficulty('memory_grid');
        } catch (_) {}
      }
      if (!isClosed) {
        emit(ProgressLoaded(
            _computeStats(attempts, memoryGridDifficulty: mgDifficulty)));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ProgressError('Failed to load performance metrics: $e'));
      }
    }
  }

  /// Clears local attempt history.
  Future<void> clearHistory() async {
    try {
      await _repository.clearAll();
      await loadProgress();
    } catch (e) {
      if (!isClosed) {
        emit(ProgressError('Failed to clear game history: $e'));
      }
    }
  }

  ProgressStats _computeStats(
    List<GameAttempt> attempts, {
    GameDifficulty? memoryGridDifficulty,
  }) {
    if (attempts.isEmpty) {
      return ProgressStats(memoryGridDifficulty: memoryGridDifficulty);
    }

    final memoryGridAttempts =
        attempts.where((a) => a.gameId == 'memory_grid').length;
    final successfulAttempts =
        attempts.where((a) => a.status == GameStatus.completed).length;
    final failedAttempts =
        attempts.where((a) => a.status == GameStatus.failed).length;
    final abandonedAttempts =
        attempts.where((a) => a.status == GameStatus.abandoned).length;

    int? bestScore;
    for (final a in attempts) {
      if (bestScore == null || a.finalScore > bestScore) {
        bestScore = a.finalScore;
      }
    }

    double? avgAccuracy;
    final attemptsWithAccuracy = attempts.where(
      (a) => a.status == GameStatus.completed || a.status == GameStatus.failed,
    );
    if (attemptsWithAccuracy.isNotEmpty) {
      final totalAcc = attemptsWithAccuracy.fold<double>(
        0.0,
        (sum, a) => sum + a.accuracy,
      );
      avgAccuracy = totalAcc / attemptsWithAccuracy.length;
    }

    int? medianReactionMs;
    final allLatencies = <int>[];
    for (final a in attempts) {
      allLatencies.addAll(a.responseTimesMs);
    }
    if (allLatencies.isNotEmpty) {
      allLatencies.sort();
      final mid = allLatencies.length ~/ 2;
      medianReactionMs = allLatencies.length.isOdd
          ? allLatencies[mid]
          : ((allLatencies[mid - 1] + allLatencies[mid]) / 2).round();
    }

    final streak = _computeDayStreak(attempts);

    return ProgressStats(
      totalAttempts: attempts.length,
      memoryGridAttempts: memoryGridAttempts,
      successfulAttempts: successfulAttempts,
      failedAttempts: failedAttempts,
      abandonedAttempts: abandonedAttempts,
      bestScore: bestScore,
      averageAccuracy: avgAccuracy,
      medianReactionTimeMs: medianReactionMs,
      currentStreakDays: streak,
      completedWorkouts: 0, // Distinct from single game attempts
      recentAttempts: attempts.take(10).toList(),
      memoryGridDifficulty: memoryGridDifficulty,
    );
  }

  int _computeDayStreak(List<GameAttempt> attempts) {
    if (attempts.isEmpty) return 0;
    final days = attempts
        .where((a) => a.status == GameStatus.completed)
        .map((a) => DateTime(
              a.completedAt.year,
              a.completedAt.month,
              a.completedAt.day,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (days.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    if (!days.contains(today) && !days.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDay = days.contains(today) ? today : yesterday;
    for (final day in days) {
      if (day == checkDay) {
        streak++;
        checkDay = DateTime(checkDay.year, checkDay.month, checkDay.day - 1);
      } else if (day.isBefore(checkDay)) {
        break;
      }
    }
    return streak;
  }
}
