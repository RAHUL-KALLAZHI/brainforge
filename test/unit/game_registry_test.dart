import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_registry.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRegistry Unit Tests', () {
    test('resolves canonical names for known games', () {
      expect(
        GameRegistry.getDisplayName(GameRegistry.memoryGrid),
        equals('Memory Grid'),
      );
      expect(
        GameRegistry.getDisplayName(GameRegistry.colorEcho),
        equals('Color Echo'),
      );
      expect(
        GameRegistry.getDisplayName(GameRegistry.focusHunter),
        equals('Focus Hunter'),
      );
      expect(
        GameRegistry.getDisplayName(GameRegistry.vanishingCards),
        equals('Vanishing Cards'),
      );
      expect(
        GameRegistry.getDisplayName(GameRegistry.reverseRecall),
        equals('Reverse Recall'),
      );
      expect(
        GameRegistry.getDisplayName(GameRegistry.mindSwitch),
        equals('Mind Switch'),
      );
    });

    test('safely formats unregistered and unknown game IDs into Title Case',
        () {
      expect(
        GameRegistry.getDisplayName('speed_math'),
        equals('Speed Math'),
      );
      expect(
        GameRegistry.getDisplayName('pattern-matrix'),
        equals('Pattern Matrix'),
      );
      expect(
        GameRegistry.getDisplayName('spatial_reasoning_game'),
        equals('Spatial Reasoning Game'),
      );
      // Ensures unknown game never defaults to Memory Grid
      expect(
        GameRegistry.getDisplayName('unknown_custom_mode'),
        isNot(equals('Memory Grid')),
      );
    });

    test('handles null, empty, or whitespace-only game IDs with safe fallback',
        () {
      expect(GameRegistry.getDisplayName(null), equals('Unknown Game'));
      expect(GameRegistry.getDisplayName(''), equals('Unknown Game'));
      expect(GameRegistry.getDisplayName('   '), equals('Unknown Game'));
    });
  });

  group('GameAttempt gameDisplayName', () {
    test(
        'dynamically derives human-readable title without altering stored gameId',
        () {
      final now = DateTime.now();

      final colorEchoAttempt = GameAttempt(
        id: 'att_ce',
        gameId: 'color_echo',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 1200,
        accuracy: 1.0,
        correctCount: 4,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [300],
        startedAt: now,
        completedAt: now,
      );
      expect(colorEchoAttempt.gameId, equals('color_echo'));
      expect(colorEchoAttempt.gameDisplayName, equals('Color Echo'));

      final memoryGridAttempt = GameAttempt(
        id: 'att_mg',
        gameId: 'memory_grid',
        difficultyLevel: 2,
        status: GameStatus.completed,
        finalScore: 1500,
        accuracy: 1.0,
        correctCount: 5,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [250],
        startedAt: now,
        completedAt: now,
      );
      expect(memoryGridAttempt.gameId, equals('memory_grid'));
      expect(memoryGridAttempt.gameDisplayName, equals('Memory Grid'));

      final reverseRecallAttempt = GameAttempt(
        id: 'att_rr',
        gameId: 'reverse_recall',
        difficultyLevel: 3,
        status: GameStatus.completed,
        finalScore: 1800,
        accuracy: 1.0,
        correctCount: 5,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [350],
        startedAt: now,
        completedAt: now,
      );
      expect(reverseRecallAttempt.gameId, equals('reverse_recall'));
      expect(reverseRecallAttempt.gameDisplayName, equals('Reverse Recall'));

      final unknownAttempt = GameAttempt(
        id: 'att_unknown',
        gameId: 'quantum_focus',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 500,
        accuracy: 0.8,
        correctCount: 3,
        incorrectCount: 1,
        missedCount: 0,
        responseTimesMs: const [400],
        startedAt: now,
        completedAt: now,
      );
      expect(unknownAttempt.gameId, equals('quantum_focus'));
      expect(unknownAttempt.gameDisplayName, equals('Quantum Focus'));
      expect(unknownAttempt.gameDisplayName, isNot(equals('Memory Grid')));
    });

    test('copyWith preserves gameId and dynamic gameDisplayName', () {
      final now = DateTime.now();
      final mgAttempt = GameAttempt(
        id: 'mg_copy',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 1000,
        accuracy: 1.0,
        correctCount: 3,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [200],
        startedAt: now,
        completedAt: now,
      );

      final updated = mgAttempt.copyWith(finalScore: 2000);
      expect(updated.gameId, equals('memory_grid'));
      expect(updated.gameDisplayName, equals('Memory Grid'));

      final ceAttempt = GameAttempt(
        id: 'ce_copy',
        gameId: 'color_echo',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 1000,
        accuracy: 1.0,
        correctCount: 3,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [200],
        startedAt: now,
        completedAt: now,
      );

      final updatedCe = ceAttempt.copyWith(finalScore: 3000);
      expect(updatedCe.gameId, equals('color_echo'));
      expect(updatedCe.gameDisplayName, equals('Color Echo'));
    });
  });
}
