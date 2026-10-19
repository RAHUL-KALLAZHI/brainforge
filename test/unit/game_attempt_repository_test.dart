import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_result.dart';
import 'package:brainforge/features/games/shared/domain/game_score.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';

void main() {
  group('GameAttempt & GameAttemptRepository Unit Tests', () {
    late InMemoryGameAttemptRepository repo;

    setUp(() {
      repo = InMemoryGameAttemptRepository();
    });

    test('GameAttempt median response time calculation', () {
      final oddAttempt = GameAttempt(
        id: '1',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 800,
        accuracy: 1.0,
        correctCount: 5,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [
          400,
          200,
          800
        ], // sorted: 200, 400, 800 -> median = 400
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
      expect(oddAttempt.medianResponseTimeMs, 400);

      final evenAttempt = GameAttempt(
        id: '2',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 800,
        accuracy: 1.0,
        correctCount: 4,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [
          300,
          100,
          500,
          700
        ], // sorted: 100, 300, 500, 700 -> median = (300+500)/2 = 400
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
      expect(evenAttempt.medianResponseTimeMs, 400);

      final emptyAttempt = GameAttempt(
        id: '3',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.abandoned,
        finalScore: 0,
        accuracy: 0.0,
        correctCount: 0,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [],
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
      expect(emptyAttempt.medianResponseTimeMs, isNull);
    });

    test('GameAttempt.fromResult maps properties faithfully', () {
      final result = GameResult(
        gameId: 'color_echo',
        difficulty: const GameDifficulty(4),
        status: GameStatus.completed,
        score: const GameScore(
          accuracy: 0.9,
          efficiency: 0.85,
          completion: 1.0,
          scaledScore: 885,
          correctCount: 9,
          incorrectCount: 1,
          missedCount: 0,
          duration: Duration(seconds: 15),
          isAbandoned: false,
        ),
        startedAt: DateTime(2026, 10, 19, 10, 0),
        completedAt: DateTime(2026, 10, 19, 10, 1),
        seed: 456,
        completedRounds: 5,
        targetRounds: 5,
        averageResponseTime: const Duration(milliseconds: 650),
      );

      final attempt = GameAttempt.fromResult(
        id: 'attempt_abc',
        result: result,
        responseTimesMs: const [600, 700],
      );

      expect(attempt.id, 'attempt_abc');
      expect(attempt.gameId, 'color_echo');
      expect(attempt.difficultyLevel, 4);
      expect(attempt.status, GameStatus.completed);
      expect(attempt.finalScore, 885);
      expect(attempt.accuracy, 0.9);
      expect(attempt.seed, 456);
      expect(attempt.responseTimesMs, [600, 700]);
    });

    test(
        'InMemoryGameAttemptRepository saves and queries attempts latest first',
        () async {
      final now = DateTime.now();

      final attempt1 = GameAttempt(
        id: 'a1',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 700,
        accuracy: 0.8,
        correctCount: 4,
        incorrectCount: 1,
        missedCount: 0,
        responseTimesMs: const [500],
        startedAt: now.subtract(const Duration(minutes: 10)),
        completedAt: now.subtract(const Duration(minutes: 9)),
      );

      final attempt2 = GameAttempt(
        id: 'a2',
        gameId: 'memory_grid',
        difficultyLevel: 2,
        status: GameStatus.completed,
        finalScore: 920,
        accuracy: 1.0,
        correctCount: 5,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [400],
        startedAt: now.subtract(const Duration(minutes: 5)),
        completedAt: now.subtract(const Duration(minutes: 4)),
      );

      final attemptOtherGame = GameAttempt(
        id: 'a3',
        gameId: 'color_echo',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 850,
        accuracy: 1.0,
        correctCount: 5,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [300],
        startedAt: now.subtract(const Duration(minutes: 1)),
        completedAt: now,
      );

      await repo.saveAttempt(attempt1);
      await repo.saveAttempt(attempt2);
      await repo.saveAttempt(attemptOtherGame);

      final memoryGridAttempts = await repo.getAttempts(gameId: 'memory_grid');
      expect(memoryGridAttempts.length, 2);
      // Latest first: attempt2 followed by attempt1
      expect(memoryGridAttempts.first.id, 'a2');
      expect(memoryGridAttempts.last.id, 'a1');

      // Personal best
      final best = await repo.getPersonalBest('memory_grid');
      expect(best, isNotNull);
      expect(best!.finalScore, 920);
      expect(best.id, 'a2');

      // Recent attempts limit
      final recentOne =
          await repo.getRecentAttempts(gameId: 'memory_grid', count: 1);
      expect(recentOne.length, 1);
      expect(recentOne.first.id, 'a2');

      // Clear all
      await repo.clearAll();
      final afterClear = await repo.getAttempts(gameId: 'memory_grid');
      expect(afterClear, isEmpty);
      expect(await repo.getPersonalBest('memory_grid'), isNull);
    });
  });
}
