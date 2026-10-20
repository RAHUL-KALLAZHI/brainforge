import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_action.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_decision.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_policy.dart';

void main() {
  group('AdaptiveDifficultyPolicy Unit Tests', () {
    const policy = AdaptiveDifficultyPolicy();
    final baseTime = DateTime(2026, 10, 20, 10, 0, 0);

    GameAttempt makeAttempt({
      required String id,
      required double accuracy,
      GameStatus status = GameStatus.completed,
      int minutesAgo = 0,
      int difficultyLevel = 0,
    }) {
      return GameAttempt(
        id: id,
        gameId: 'memory_grid',
        difficultyLevel: difficultyLevel,
        status: status,
        finalScore: accuracy.isFinite ? (accuracy * 1000).round() : 0,
        accuracy: accuracy,
        correctCount: accuracy.isFinite ? (accuracy * 5).round() : 0,
        incorrectCount: accuracy.isFinite ? ((1.0 - accuracy) * 5).round() : 0,
        missedCount: 0,
        responseTimesMs: const [500, 600, 700],
        startedAt: baseTime.subtract(Duration(minutes: minutesAgo + 1)),
        completedAt: baseTime.subtract(Duration(minutes: minutesAgo)),
      );
    }

    AdaptationDecision evaluatePolicy({
      required GameDifficulty currentDifficulty,
      required List<GameAttempt> recentAttempts,
    }) {
      final normalized = recentAttempts.map((a) {
        if (a.difficultyLevel == 0) {
          return a.copyWith(difficultyLevel: currentDifficulty.level);
        }
        return a;
      }).toList();
      return policy.evaluate(
        currentDifficulty: currentDifficulty,
        recentAttempts: normalized,
      );
    }

    test(
        'no gameplay history returns insufficientData and maintains difficulty',
        () {
      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(3),
        recentAttempts: const [],
      );

      expect(decision.action, AdaptationAction.insufficientData);
      expect(decision.targetDifficulty, const GameDifficulty(3));
      expect(decision.hasDifficultyChanged, false);
      expect(decision.evaluatedAttemptsCount, 0);
      expect(decision.reason, contains('Keep practising'));
    });

    test('one or two eligible attempts returns insufficientData', () {
      final attempts = [
        makeAttempt(id: '1', accuracy: 1.0, minutesAgo: 2),
        makeAttempt(id: '2', accuracy: 1.0, minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(3),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.insufficientData);
      expect(decision.targetDifficulty, const GameDifficulty(3));
      expect(decision.evaluatedAttemptsCount, 2);
    });

    test('abandoned attempts are excluded from eligible evaluation', () {
      final attempts = [
        makeAttempt(
            id: '1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 3),
        makeAttempt(
            id: '2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 2),
        makeAttempt(
            id: '3',
            accuracy: 0.0,
            status: GameStatus.abandoned,
            minutesAgo: 1),
      ];

      // Only 2 eligible attempts remain (completed/failed), which is < 3 required
      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(3),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.insufficientData);
      expect(decision.targetDifficulty, const GameDifficulty(3));
    });

    test(
        'exactly minimum required history (3) with high accuracy triggers promotion',
        () {
      final attempts = [
        makeAttempt(id: '1', accuracy: 1.0, minutesAgo: 3),
        makeAttempt(id: '2', accuracy: 1.0, minutesAgo: 2),
        makeAttempt(id: '3', accuracy: 0.95, minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(3),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.promote);
      expect(decision.targetDifficulty, const GameDifficulty(4));
      expect(decision.hasDifficultyChanged, true);
      expect(decision.reason, contains('performing consistently well'));
    });

    test('accuracy exactly at promotion threshold (0.90) triggers promotion',
        () {
      final attempts = [
        makeAttempt(id: '1', accuracy: 0.90, minutesAgo: 3),
        makeAttempt(id: '2', accuracy: 0.90, minutesAgo: 2),
        makeAttempt(id: '3', accuracy: 0.90, minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(4),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.promote);
      expect(decision.targetDifficulty, const GameDifficulty(5));
    });

    test('accuracy just below promotion threshold (0.89) maintains difficulty',
        () {
      final attempts = [
        makeAttempt(id: '1', accuracy: 0.89, minutesAgo: 3),
        makeAttempt(id: '2', accuracy: 0.89, minutesAgo: 2),
        makeAttempt(id: '3', accuracy: 0.89, minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(4),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.maintain);
      expect(decision.targetDifficulty, const GameDifficulty(4));
    });

    test(
        'promotion requires all attempts to be completed (failures prevent promotion)',
        () {
      final attempts = [
        makeAttempt(
            id: '1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 3),
        makeAttempt(
            id: '2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 2),
        makeAttempt(
            id: '3', accuracy: 0.90, status: GameStatus.failed, minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(3),
        recentAttempts: attempts,
      );

      // Average accuracy is 0.967, but failure in window prevents promotion
      expect(decision.action, AdaptationAction.maintain);
      expect(decision.targetDifficulty, const GameDifficulty(3));
    });

    test('promotion is clamped at maxLevel (10)', () {
      final attempts = [
        makeAttempt(id: '1', accuracy: 1.0, minutesAgo: 3),
        makeAttempt(id: '2', accuracy: 1.0, minutesAgo: 2),
        makeAttempt(id: '3', accuracy: 1.0, minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(10),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.maintain);
      expect(decision.targetDifficulty, const GameDifficulty(10));
      expect(decision.reason, contains('Maximum difficulty level reached'));
    });

    test('low accuracy (< 0.60) triggers demotion', () {
      final attempts = [
        makeAttempt(
            id: '1', accuracy: 0.50, status: GameStatus.failed, minutesAgo: 3),
        makeAttempt(
            id: '2', accuracy: 0.40, status: GameStatus.failed, minutesAgo: 2),
        makeAttempt(
            id: '3', accuracy: 0.55, status: GameStatus.failed, minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(4),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.demote);
      expect(decision.targetDifficulty, const GameDifficulty(3));
      expect(decision.hasDifficultyChanged, true);
      expect(decision.reason, contains('help you progress'));
    });

    test(
        'consecutive failures (>= 2) trigger demotion even if accuracy was previously high',
        () {
      final attempts = [
        makeAttempt(
            id: '1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 3),
        makeAttempt(
            id: '2', accuracy: 0.60, status: GameStatus.failed, minutesAgo: 2),
        makeAttempt(
            id: '3', accuracy: 0.60, status: GameStatus.failed, minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(5),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.demote);
      expect(decision.targetDifficulty, const GameDifficulty(4));
    });

    test(
        'single isolated failure does not demote if average accuracy is adequate',
        () {
      final attempts = [
        makeAttempt(
            id: '1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 3),
        makeAttempt(
            id: '2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 2),
        makeAttempt(
            id: '3', accuracy: 0.40, status: GameStatus.failed, minutesAgo: 1),
      ];

      // Average accuracy = (1.0 + 1.0 + 0.4) / 3 = 0.80 (> 0.60)
      // Only 1 consecutive failure (< 2)
      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(5),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.maintain);
      expect(decision.targetDifficulty, const GameDifficulty(5));
    });

    test(
        'accuracy exactly at demotion threshold (0.60) maintains difficulty without demoting',
        () {
      final attempts = [
        makeAttempt(
            id: '1',
            accuracy: 0.60,
            status: GameStatus.completed,
            minutesAgo: 3),
        makeAttempt(
            id: '2',
            accuracy: 0.60,
            status: GameStatus.completed,
            minutesAgo: 2),
        makeAttempt(
            id: '3',
            accuracy: 0.60,
            status: GameStatus.completed,
            minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(5),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.maintain);
      expect(decision.targetDifficulty, const GameDifficulty(5));
    });

    test('demotion is clamped at minLevel (1)', () {
      final attempts = [
        makeAttempt(
            id: '1', accuracy: 0.20, status: GameStatus.failed, minutesAgo: 3),
        makeAttempt(
            id: '2', accuracy: 0.20, status: GameStatus.failed, minutesAgo: 2),
        makeAttempt(
            id: '3', accuracy: 0.20, status: GameStatus.failed, minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(1),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.maintain);
      expect(decision.targetDifficulty, const GameDifficulty(1));
      expect(decision.reason, contains('Minimum difficulty level reached'));
    });

    test('step change is strictly bounded to maximum one level change', () {
      // 5 flawless attempts
      final attempts = List.generate(
        5,
        (i) => makeAttempt(id: '$i', accuracy: 1.0, minutesAgo: 5 - i),
      );

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(2),
        recentAttempts: attempts,
      );

      expect(
          decision.targetDifficulty.level - decision.previousDifficulty.level,
          1);
    });

    test(
        'input order does not affect evaluation (chronological sorting enforced)',
        () {
      final attempt1 = makeAttempt(id: '1', accuracy: 1.0, minutesAgo: 10);
      final attempt2 = makeAttempt(
          id: '2', accuracy: 0.4, status: GameStatus.failed, minutesAgo: 5);
      final attempt3 = makeAttempt(
          id: '3', accuracy: 0.4, status: GameStatus.failed, minutesAgo: 1);

      // Order A: Latest first
      final decisionA = evaluatePolicy(
        currentDifficulty: const GameDifficulty(4),
        recentAttempts: [attempt3, attempt2, attempt1],
      );

      // Order B: Oldest first
      final decisionB = evaluatePolicy(
        currentDifficulty: const GameDifficulty(4),
        recentAttempts: [attempt1, attempt2, attempt3],
      );

      // Order C: Shuffled
      final decisionC = evaluatePolicy(
        currentDifficulty: const GameDifficulty(4),
        recentAttempts: [attempt2, attempt1, attempt3],
      );

      expect(decisionA, equals(decisionB));
      expect(decisionA, equals(decisionC));
    });

    test('one qualifying win does not promote (insufficientData)', () {
      final attempts = [
        makeAttempt(id: '1', accuracy: 1.0, status: GameStatus.completed),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(1),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.insufficientData);
      expect(decision.targetDifficulty, const GameDifficulty(1));
      expect(decision.hasDifficultyChanged, false);
      expect(decision.evaluatedAttemptsCount, 1);
    });

    test('two qualifying wins do not promote (insufficientData)', () {
      final attempts = [
        makeAttempt(
            id: '1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 2),
        makeAttempt(
            id: '2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(1),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.insufficientData);
      expect(decision.targetDifficulty, const GameDifficulty(1));
      expect(decision.hasDifficultyChanged, false);
      expect(decision.evaluatedAttemptsCount, 2);
    });

    test(
        'three qualifying wins trigger promotion when all conditions satisfied',
        () {
      final attempts = [
        makeAttempt(
            id: '1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 3),
        makeAttempt(
            id: '2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 2),
        makeAttempt(
            id: '3',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(1),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.promote);
      expect(decision.targetDifficulty, const GameDifficulty(2));
      expect(decision.hasDifficultyChanged, true);
    });

    test(
        'a failure in the qualifying promotion window prevents promotion even if accuracy is high',
        () {
      // 3 attempts: attempt 2 was failed, attempts 1 and 3 were completed with 100%
      final attempts = [
        makeAttempt(
            id: '1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 3),
        makeAttempt(
            id: '2', accuracy: 0.85, status: GameStatus.failed, minutesAgo: 2),
        makeAttempt(
            id: '3',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(1),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.maintain);
      expect(decision.targetDifficulty, const GameDifficulty(1));
      expect(decision.hasDifficultyChanged, false);
    });

    test(
        'three qualifying wins trigger promotion even when preceded by older historical failures',
        () {
      // 5 attempts total: 2 older failed attempts from prior testing, followed by 3 consecutive 100% wins
      final attempts = [
        makeAttempt(
            id: 'old_1',
            accuracy: 0.0,
            status: GameStatus.failed,
            minutesAgo: 5),
        makeAttempt(
            id: 'old_2',
            accuracy: 0.5,
            status: GameStatus.failed,
            minutesAgo: 4),
        makeAttempt(
            id: 'win_1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 3),
        makeAttempt(
            id: 'win_2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 2),
        makeAttempt(
            id: 'win_3',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(1),
        recentAttempts: attempts,
      );

      // The 3 consecutive qualifying victories must trigger promotion
      // regardless of older attempts outside the qualifying window
      expect(decision.action, AdaptationAction.promote);
      expect(decision.targetDifficulty, const GameDifficulty(2));
      expect(decision.hasDifficultyChanged, true);
    });

    test('handles NaN and infinite accuracy safely without crashing', () {
      final attempts = [
        makeAttempt(id: '1', accuracy: double.nan, minutesAgo: 3),
        makeAttempt(id: '2', accuracy: double.infinity, minutesAgo: 2),
        makeAttempt(id: '3', accuracy: 1.0, minutesAgo: 1),
      ];

      final decision = evaluatePolicy(
        currentDifficulty: const GameDifficulty(3),
        recentAttempts: attempts,
      );

      // Should not throw or crash
      expect(decision.action, isA<AdaptationAction>());
    });

    test(
        'one qualifying win at Level 2 does not promote even when preceded by Level 1 wins',
        () {
      // Prior Level 1 completed attempts
      final attempts = [
        makeAttempt(
            id: 'l1_1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 10,
            difficultyLevel: 1),
        makeAttempt(
            id: 'l1_2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 8,
            difficultyLevel: 1),
        makeAttempt(
            id: 'l1_3',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 6,
            difficultyLevel: 1),
        // Just 1 win at Level 2
        makeAttempt(
            id: 'l2_1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 1,
            difficultyLevel: 2),
      ];

      final decision = policy.evaluate(
        currentDifficulty: const GameDifficulty(2),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.insufficientData);
      expect(decision.targetDifficulty, const GameDifficulty(2));
      expect(decision.qualifyingWinsCount, 1);
      expect(decision.hasDifficultyChanged, false);
    });

    test(
        'two qualifying wins at Level 2 does not promote even when preceded by Level 1 wins',
        () {
      final attempts = [
        makeAttempt(
            id: 'l1_1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 10,
            difficultyLevel: 1),
        makeAttempt(
            id: 'l1_2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 8,
            difficultyLevel: 1),
        makeAttempt(
            id: 'l1_3',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 6,
            difficultyLevel: 1),
        // 2 wins at Level 2
        makeAttempt(
            id: 'l2_1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 3,
            difficultyLevel: 2),
        makeAttempt(
            id: 'l2_2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 1,
            difficultyLevel: 2),
      ];

      final decision = policy.evaluate(
        currentDifficulty: const GameDifficulty(2),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.insufficientData);
      expect(decision.targetDifficulty, const GameDifficulty(2));
      expect(decision.qualifyingWinsCount, 2);
      expect(decision.hasDifficultyChanged, false);
    });

    test(
        'three qualifying wins at Level 2 promotes to Level 3 regardless of past Level 1 history',
        () {
      final attempts = [
        makeAttempt(
            id: 'l1_1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 10,
            difficultyLevel: 1),
        makeAttempt(
            id: 'l1_2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 8,
            difficultyLevel: 1),
        makeAttempt(
            id: 'l1_3',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 6,
            difficultyLevel: 1),
        // 3 wins at Level 2
        makeAttempt(
            id: 'l2_1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 5,
            difficultyLevel: 2),
        makeAttempt(
            id: 'l2_2',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 3,
            difficultyLevel: 2),
        makeAttempt(
            id: 'l2_3',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 1,
            difficultyLevel: 2),
      ];

      final decision = policy.evaluate(
        currentDifficulty: const GameDifficulty(2),
        recentAttempts: attempts,
      );

      expect(decision.action, AdaptationAction.promote);
      expect(decision.targetDifficulty, const GameDifficulty(3));
      expect(decision.qualifyingWinsCount, 3);
      expect(decision.hasDifficultyChanged, true);
    });

    test(
        'representative higher level (Level 5) requires exactly three qualifying wins at Level 5 to promote',
        () {
      // 2 wins at Level 5 -> insufficientData
      final twoWins = [
        makeAttempt(
            id: 'l5_1',
            accuracy: 1.0,
            status: GameStatus.completed,
            minutesAgo: 3,
            difficultyLevel: 5),
        makeAttempt(
            id: 'l5_2',
            accuracy: 0.95,
            status: GameStatus.completed,
            minutesAgo: 1,
            difficultyLevel: 5),
      ];

      final decision2 = policy.evaluate(
        currentDifficulty: const GameDifficulty(5),
        recentAttempts: twoWins,
      );
      expect(decision2.action, AdaptationAction.insufficientData);
      expect(decision2.targetDifficulty, const GameDifficulty(5));

      // 3rd win at Level 5 -> promotes to Level 6
      final threeWins = [
        ...twoWins,
        makeAttempt(
            id: 'l5_3',
            accuracy: 0.92,
            status: GameStatus.completed,
            minutesAgo: 0,
            difficultyLevel: 5),
      ];

      final decision3 = policy.evaluate(
        currentDifficulty: const GameDifficulty(5),
        recentAttempts: threeWins,
      );
      expect(decision3.action, AdaptationAction.promote);
      expect(decision3.targetDifficulty, const GameDifficulty(6));
    });
  });
}
