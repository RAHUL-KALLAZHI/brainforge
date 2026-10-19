import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/logic/challenge_generator.dart';

void main() {
  group('ChallengeGenerator Unit Tests', () {
    const generator = SeededSequenceGenerator(allowDuplicates: false);
    const repeatingGenerator = SeededSequenceGenerator(allowDuplicates: true);

    const configWithSeedA = GameConfig(
      gameId: 'memory_grid',
      difficulty: GameDifficulty(3),
      gridRows: 3,
      gridColumns: 3,
      sequenceLength: 4,
      seed: 12345,
    );

    const configWithSeedB = GameConfig(
      gameId: 'memory_grid',
      difficulty: GameDifficulty(3),
      gridRows: 3,
      gridColumns: 3,
      sequenceLength: 4,
      seed: 98765,
    );

    test('identical seeds and parameters produce identical challenges', () {
      final challenge1 =
          generator.generate(roundIndex: 0, config: configWithSeedA);
      final challenge2 =
          generator.generate(roundIndex: 0, config: configWithSeedA);

      expect(challenge1.sequence, equals(challenge2.sequence));
      expect(challenge1.roundIndex, challenge2.roundIndex);
      expect(challenge1.seed, challenge2.seed);
      expect(challenge1.totalPoolSize, challenge2.totalPoolSize);
    });

    test('different seeds produce different challenges', () {
      final challengeA =
          generator.generate(roundIndex: 0, config: configWithSeedA);
      final challengeB =
          generator.generate(roundIndex: 0, config: configWithSeedB);

      expect(challengeA.sequence, isNot(equals(challengeB.sequence)));
    });

    test(
        'successive rounds with the same seed produce distinct deterministic sequences',
        () {
      final round0 = generator.generate(roundIndex: 0, config: configWithSeedA);
      final round1 = generator.generate(roundIndex: 1, config: configWithSeedA);
      final round0Again =
          generator.generate(roundIndex: 0, config: configWithSeedA);

      expect(round0.sequence, equals(round0Again.sequence));
      expect(round0.sequence, isNot(equals(round1.sequence)));
    });

    test('unique mode ensures no duplicate items in sequence', () {
      final challenge =
          generator.generate(roundIndex: 0, config: configWithSeedA);

      final distinctCount = challenge.sequence.toSet().length;
      expect(distinctCount, challenge.sequence.length);
      expect(challenge.sequence.length, 4);
      for (final index in challenge.sequence) {
        expect(index, inInclusiveRange(0, 8)); // 3x3 grid = 9 tiles (0 to 8)
      }
    });

    test('repeating mode allows sequences from pool with repeatable elements',
        () {
      const smallPoolConfig = GameConfig(
        gameId: 'color_echo',
        difficulty: GameDifficulty(5),
        sequenceLength: 10,
        gridRows: 2,
        gridColumns: 2, // poolSize = 4
        seed: 777,
        allowDuplicates: true,
      );

      final challenge =
          repeatingGenerator.generate(roundIndex: 0, config: smallPoolConfig);
      expect(challenge.sequence.length, 10);
      for (final val in challenge.sequence) {
        expect(val, inInclusiveRange(0, 3));
      }
    });

    test('generate validates config and rejects invalid configurations', () {
      const invalidConfig = GameConfig(
        gameId: '', // invalid empty id
        difficulty: GameDifficulty(1),
      );

      expect(
        () => generator.generate(roundIndex: 0, config: invalidConfig),
        throwsA(isA<GameConfigException>()),
      );
    });
  });
}
