import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/memory_grid/domain/memory_grid_config.dart';
import 'package:brainforge/features/games/memory_grid/logic/memory_grid_engine.dart';
import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/logic/challenge_generator.dart';

void main() {
  group('MemoryGridEngine & MemoryGridConfig Unit Tests', () {
    const engine = MemoryGridEngine();

    test(
        'MemoryGridConfig presets generate validated configs across all difficulty tiers',
        () {
      for (var lvl = 1; lvl <= 10; lvl++) {
        final config = MemoryGridConfig.forDifficulty(GameDifficulty(lvl));
        expect(() => config.validate(), returnsNormally);
        expect(config.gameId, 'memory_grid');
        expect(config.difficulty.level, lvl);
        expect(config.allowDuplicates, isFalse);

        final totalTiles = config.gridRows! * config.gridColumns!;
        expect(config.sequenceLength! <= totalTiles, isTrue);

        if (lvl <= 3) {
          expect(config.gridRows, 3);
          expect(config.gridColumns, 3);
        } else if (lvl <= 6) {
          expect(config.gridRows, 4);
          expect(config.gridColumns, 4);
        } else {
          expect(config.gridRows, 5);
          expect(config.gridColumns, 5);
        }
      }
    });

    test(
        'generateGridChallenge produces deterministic sequences without duplicates',
        () {
      final config = MemoryGridConfig.forDifficulty(
        const GameDifficulty(2),
        seed: 42,
      );

      final challenge1 = engine.generateGridChallenge(config: config);
      final challenge2 = engine.generateGridChallenge(config: config);

      expect(challenge1.sequence, equals(challenge2.sequence));
      expect(challenge1.sequence.length, 4);

      // Verify no duplicate tiles in the sequence
      final uniqueSet = challenge1.sequence.toSet();
      expect(uniqueSet.length, challenge1.sequence.length);

      // Verify all tile indices are within the 3x3 grid (0 to 8)
      for (final tile in challenge1.sequence) {
        expect(tile, inInclusiveRange(0, 8));
      }
    });

    test('evaluateInput validates tile selections in exact sequential order',
        () {
      const challenge = SequenceChallenge(
        roundIndex: 0,
        sequence: [4, 0, 7, 2],
        totalPoolSize: 9,
      );

      // Step 0: tile 4 is expected
      expect(engine.evaluateInput(challenge: challenge, input: 4, stepIndex: 0),
          isTrue);
      expect(engine.evaluateInput(challenge: challenge, input: 0, stepIndex: 0),
          isFalse);

      // Step 1: tile 0 is expected
      expect(engine.evaluateInput(challenge: challenge, input: 0, stepIndex: 1),
          isTrue);
      expect(engine.evaluateInput(challenge: challenge, input: 4, stepIndex: 1),
          isFalse);

      // Step 2: tile 7 is expected
      expect(engine.evaluateInput(challenge: challenge, input: 7, stepIndex: 2),
          isTrue);

      // Step 3: tile 2 is expected
      expect(engine.evaluateInput(challenge: challenge, input: 2, stepIndex: 3),
          isTrue);

      // Out-of-bounds stepIndex
      expect(engine.evaluateInput(challenge: challenge, input: 2, stepIndex: 4),
          isFalse);
      expect(
          engine.evaluateInput(challenge: challenge, input: 2, stepIndex: -1),
          isFalse);
    });

    test('generateGridChallenge rejects invalid configuration constraints', () {
      const invalidConfig = GameConfig(
        gameId: 'memory_grid',
        difficulty: GameDifficulty(1),
        gridRows: 2,
        gridColumns: 2,
        sequenceLength: 5, // 5 > 4 total tiles with allowDuplicates = false
        allowDuplicates: false,
      );

      expect(
        () => engine.generateGridChallenge(config: invalidConfig),
        throwsA(isA<GameConfigException>()),
      );
    });
  });
}
