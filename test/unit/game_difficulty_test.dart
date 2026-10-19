import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';

void main() {
  group('GameDifficulty Unit Tests', () {
    test(
        'clamps values to minLevel (1) and maxLevel (10) via GameDifficulty.clamped',
        () {
      final belowMin = GameDifficulty.clamped(0);
      expect(belowMin.level, 1);

      final negative = GameDifficulty.clamped(-5);
      expect(negative.level, 1);

      final aboveMax = GameDifficulty.clamped(15);
      expect(aboveMax.level, 10);

      final valid = GameDifficulty.clamped(5);
      expect(valid.level, 5);
    });

    test('const constructor asserts level is between 1 and 10', () {
      expect(() => GameDifficulty(0), throwsAssertionError);
      expect(() => GameDifficulty(11), throwsAssertionError);
      expect(const GameDifficulty(1).level, 1);
      expect(const GameDifficulty(10).level, 10);
    });

    test('increase increments level up to 10', () {
      const diff1 = GameDifficulty(9);
      final diff2 = diff1.increase();
      expect(diff2.level, 10);

      final diff3 = diff2.increase();
      expect(diff3.level, 10); // does not exceed 10
    });

    test('decrease decrements level down to 1', () {
      const diff2 = GameDifficulty(2);
      final diff1 = diff2.decrease();
      expect(diff1.level, 1);

      final diff0 = diff1.decrease();
      expect(diff0.level, 1); // does not go below 1
    });

    test('maps levels to correct tierName descriptors', () {
      expect(const GameDifficulty(1).tierName, 'Beginner');
      expect(const GameDifficulty(2).tierName, 'Beginner');

      expect(const GameDifficulty(3).tierName, 'Intermediate');
      expect(const GameDifficulty(4).tierName, 'Intermediate');

      expect(const GameDifficulty(5).tierName, 'Advanced');
      expect(const GameDifficulty(6).tierName, 'Advanced');

      expect(const GameDifficulty(7).tierName, 'Expert');
      expect(const GameDifficulty(8).tierName, 'Expert');

      expect(const GameDifficulty(9).tierName, 'Master');
      expect(const GameDifficulty(10).tierName, 'Master');
    });

    test('comparison and equatable equality work correctly', () {
      const a = GameDifficulty(4);
      const b = GameDifficulty(4);
      const c = GameDifficulty(6);

      expect(a, equals(b));
      expect(a.compareTo(b), 0);
      expect(a.compareTo(c), isNegative);
      expect(c.compareTo(a), isPositive);
    });
  });
}
