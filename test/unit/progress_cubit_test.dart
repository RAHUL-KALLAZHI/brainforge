import 'package:brainforge/core/database/app_database.dart';
import 'package:brainforge/features/games/shared/data/drift_game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/progress/logic/progress_cubit.dart';
import 'package:brainforge/features/progress/logic/progress_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftGameAttemptRepository repository;
  late ProgressCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftGameAttemptRepository(db);
    cubit = ProgressCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  GameAttempt makeAttempt({
    required String id,
    String gameId = 'memory_grid',
    int difficultyLevel = 1,
    GameStatus status = GameStatus.completed,
    int finalScore = 1000,
    double accuracy = 1.0,
    List<int> responseTimes = const [300, 400],
    DateTime? completedAt,
  }) {
    final now = DateTime.now();
    return GameAttempt(
      id: id,
      gameId: gameId,
      difficultyLevel: difficultyLevel,
      status: status,
      finalScore: finalScore,
      accuracy: accuracy,
      correctCount: 4,
      incorrectCount: 0,
      missedCount: 0,
      responseTimesMs: responseTimes,
      startedAt: now.subtract(const Duration(seconds: 15)),
      completedAt: completedAt ?? now,
    );
  }

  group('ProgressCubit Unit Tests', () {
    test('initial state calculates empty stats when database has no records',
        () async {
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<ProgressLoaded>());
      final state = cubit.state as ProgressLoaded;
      expect(state.stats.hasData, isFalse);
      expect(state.stats.totalAttempts, equals(0));
      expect(state.stats.memoryGridAttempts, equals(0));
      expect(state.stats.bestScore, isNull);
      expect(state.stats.averageAccuracy, isNull);
      expect(state.stats.medianReactionTimeMs, isNull);
      expect(state.stats.currentStreakDays, equals(0));
      expect(state.stats.completedWorkouts, equals(0));
    });

    test('accurately computes metrics from persisted game attempts', () async {
      final now = DateTime.now();
      await repository.saveAttempt(
        makeAttempt(
          id: 'a1',
          finalScore: 1200,
          accuracy: 1.0,
          responseTimes: [200, 300],
          completedAt: now,
        ),
      );
      await repository.saveAttempt(
        makeAttempt(
          id: 'a2',
          finalScore: 1800,
          accuracy: 0.8,
          responseTimes: [400, 500],
          completedAt: now.subtract(const Duration(hours: 1)),
        ),
      );
      await repository.saveAttempt(
        makeAttempt(
          id: 'a3',
          status: GameStatus.failed,
          finalScore: 0,
          accuracy: 0.5,
          responseTimes: [600],
          completedAt: now.subtract(const Duration(hours: 2)),
        ),
      );

      await cubit.loadProgress();

      expect(cubit.state, isA<ProgressLoaded>());
      final state = cubit.state as ProgressLoaded;
      expect(state.stats.hasData, isTrue);
      expect(state.stats.totalAttempts, equals(3));
      expect(state.stats.memoryGridAttempts, equals(3));
      expect(state.stats.successfulAttempts, equals(2));
      expect(state.stats.failedAttempts, equals(1));
      expect(state.stats.bestScore, equals(1800));

      // Accuracy: (1.0 + 0.8 + 0.5) / 3 = 0.7666...
      expect(state.stats.averageAccuracy, closeTo(0.766, 0.01));

      // Response times: [200, 300, 400, 500, 600] -> median is 400
      expect(state.stats.medianReactionTimeMs, equals(400));
      expect(state.stats.recentAttempts.length, equals(3));
    });

    test('clearHistory wipes analytics and updates state to empty', () async {
      await repository.saveAttempt(makeAttempt(id: 'a1'));
      await cubit.loadProgress();

      expect((cubit.state as ProgressLoaded).stats.hasData, isTrue);

      await cubit.clearHistory();

      expect((cubit.state as ProgressLoaded).stats.hasData, isFalse);
      expect((cubit.state as ProgressLoaded).stats.totalAttempts, equals(0));
    });

    test('computes active consecutive day streak', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBefore = today.subtract(const Duration(days: 2));

      await repository.saveAttempt(
        makeAttempt(id: 's1', completedAt: today),
      );
      await repository.saveAttempt(
        makeAttempt(id: 's2', completedAt: yesterday),
      );
      await repository.saveAttempt(
        makeAttempt(id: 's3', completedAt: dayBefore),
      );

      await cubit.loadProgress();

      final state = cubit.state as ProgressLoaded;
      expect(state.stats.currentStreakDays, equals(3));
    });
  });
}
