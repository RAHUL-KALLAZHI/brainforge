import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/logic/scoring_service.dart';

void main() {
  group('ScoringService Unit Tests', () {
    const scoring = ScoringService();

    test('perfect session yields maximum score of 1000', () {
      final score = scoring.calculateScore(
        correctCount: 10,
        incorrectCount: 0,
        missedCount: 0,
        completedRounds: 5,
        targetRounds: 5,
        totalResponseTime:
            const Duration(seconds: 10), // 1.0s avg <= 2.0s target
        targetResponseTime: const Duration(seconds: 2),
        maxResponseTime: const Duration(seconds: 10),
      );

      expect(score.accuracy, 1.0);
      expect(score.completion, 1.0);
      expect(score.efficiency, 1.0);
      expect(score.scaledScore, 1000);
      expect(score.isAbandoned, isFalse);
    });

    test('abandoned session yields score of 0', () {
      final score = scoring.calculateScore(
        correctCount: 8,
        incorrectCount: 1,
        missedCount: 0,
        completedRounds: 4,
        targetRounds: 5,
        totalResponseTime: const Duration(seconds: 8),
        isAbandoned: true,
      );

      expect(score.scaledScore, 0);
      expect(score.accuracy, 0.0);
      expect(score.completion, 0.0);
      expect(score.efficiency, 0.0);
      expect(score.isAbandoned, isTrue);
    });

    test('zero opportunities yields score of 0', () {
      final score = scoring.calculateScore(
        correctCount: 0,
        incorrectCount: 0,
        missedCount: 0,
        completedRounds: 0,
        targetRounds: 5,
        totalResponseTime: Duration.zero,
      );

      expect(score.scaledScore, 0);
      expect(score.accuracy, 0.0);
      expect(score.completion, 0.0);
    });

    test(
        'speed guessing guard: zero accuracy yields score of 0 despite maximum speed',
        () {
      // 0 correct, 10 incorrect, response time is ultra-fast (100ms avg)
      final score = scoring.calculateScore(
        correctCount: 0,
        incorrectCount: 10,
        missedCount: 0,
        completedRounds: 5,
        targetRounds: 5,
        totalResponseTime: const Duration(milliseconds: 1000),
      );

      expect(score.accuracy, 0.0);
      // Efficiency is scaled by accuracy, so speed does not reward pure guessing:
      expect(score.efficiency, 0.0);
      // Only completion can contribute: 0.10 * 1.0 * 1000 = 100 max
      expect(score.scaledScore, 100);
    });

    test('efficiency scales linearly between target and max response times',
        () {
      // Target: 2.0s, Max: 10.0s. Range = 8.0s.
      // Average: 6.0s (midpoint) => rawEfficiency = (10 - 6) / 8 = 0.50
      final score = scoring.calculateScore(
        correctCount: 10,
        incorrectCount: 0,
        missedCount: 0,
        completedRounds: 5,
        targetRounds: 5,
        totalResponseTime:
            const Duration(seconds: 60), // 10 opportunities * 6s = 60s
        targetResponseTime: const Duration(seconds: 2),
        maxResponseTime: const Duration(seconds: 10),
      );

      expect(score.accuracy, 1.0);
      expect(score.completion, 1.0);
      expect(score.efficiency, closeTo(0.50, 0.01));
      // Expected: 1000 * (0.70*1.0 + 0.20*0.50 + 0.10*1.0) = 1000 * (0.70 + 0.10 + 0.10) = 900
      expect(score.scaledScore, 900);
    });

    test('efficiency is 0 when average response time exceeds maxResponseTime',
        () {
      final score = scoring.calculateScore(
        correctCount: 10,
        incorrectCount: 0,
        missedCount: 0,
        completedRounds: 5,
        targetRounds: 5,
        totalResponseTime: const Duration(seconds: 120), // 12s avg > 10s max
        targetResponseTime: const Duration(seconds: 2),
        maxResponseTime: const Duration(seconds: 10),
      );

      expect(score.accuracy, 1.0);
      expect(score.efficiency, 0.0);
      expect(score.completion, 1.0);
      // Expected: 1000 * (0.70*1.0 + 0.20*0.0 + 0.10*1.0) = 800
      expect(score.scaledScore, 800);
    });

    test('partial accuracy and completion compute deterministic expected score',
        () {
      // 8 correct, 2 incorrect (total 10) => accuracy = 0.8
      // completedRounds 4 of 5 => completion = 0.8
      // totalResponseTime: 20s (2s avg <= 2s target) => rawEfficiency = 1.0
      // efficiency = rawEfficiency * accuracy = 1.0 * 0.8 = 0.8
      // Expected weighted = 0.70 * 0.8 + 0.20 * 0.8 + 0.10 * 0.8 = 0.56 + 0.16 + 0.08 = 0.80
      // Scaled = 800
      final score = scoring.calculateScore(
        correctCount: 8,
        incorrectCount: 2,
        missedCount: 0,
        completedRounds: 4,
        targetRounds: 5,
        totalResponseTime: const Duration(seconds: 20),
        targetResponseTime: const Duration(seconds: 2),
        maxResponseTime: const Duration(seconds: 10),
      );

      expect(score.accuracy, 0.8);
      expect(score.completion, 0.8);
      expect(score.efficiency, 0.8);
      expect(score.scaledScore, 800);
    });

    test('score clamping stays strictly within [0, 1000]', () {
      final minScore = scoring.calculateScore(
        correctCount: 0,
        incorrectCount: 10,
        missedCount: 10,
        completedRounds: 0,
        targetRounds: 10,
        totalResponseTime: const Duration(minutes: 5),
      );
      expect(minScore.scaledScore, 0);

      final maxScore = scoring.calculateScore(
        correctCount: 20,
        incorrectCount: 0,
        missedCount: 0,
        completedRounds: 10,
        targetRounds: 10,
        totalResponseTime: const Duration(seconds: 1),
      );
      expect(maxScore.scaledScore, 1000);
    });
  });
}
