import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/focus_hunter/domain/focus_hunter_config.dart';
import 'package:brainforge/features/games/focus_hunter/logic/focus_hunter_engine.dart';
import 'package:brainforge/features/games/focus_hunter/logic/focus_hunter_generator.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';

void main() {
  group('FocusHunterConfig & Difficulty Mapping Tests', () {
    test('Game ID and Title constants are correct', () {
      expect(FocusHunterConfig.gameId, 'focus_hunter');
      expect(FocusHunterConfig.gameTitle, 'Focus Hunter');
    });

    test('Symbols have 8 distinct shapes with accessible semantics', () {
      expect(FocusSymbolType.values.length, 8);
      final names = FocusSymbolType.values.map((s) => s.label).toSet();
      expect(names.length, 8);
      for (final s in FocusSymbolType.values) {
        expect(s.semanticDescription.isNotEmpty, isTrue);
        expect(s.icon, isNotNull);
      }
    });

    test('Colors have 6 distinct accessible color definitions', () {
      expect(FocusColorType.values.length, 6);
      final names = FocusColorType.values.map((c) => c.label).toSet();
      expect(names.length, 6);
      for (final c in FocusColorType.values) {
        expect(c.darkSurfaceColor, isNotNull);
        expect(c.lightSurfaceColor, isNotNull);
      }
    });

    test(
        'Levels 1 to 10 scale grid size, target count, and time deterministically',
        () {
      final expectedGridSizes = {
        1: 9, // 3x3
        2: 9, // 3x3
        3: 12, // 4x3
        4: 16, // 4x4
        5: 16, // 4x4
        6: 20, // 5x4
        7: 20, // 5x4
        8: 25, // 5x5
        9: 25, // 5x5
        10: 30, // 6x5
      };

      for (var level = 1; level <= 10; level++) {
        final config = FocusHunterConfig.forDifficulty(
          GameDifficulty(level),
          seed: 42,
        );

        final totalItems = config.gridRows! * config.gridColumns!;
        expect(
          totalItems,
          expectedGridSizes[level],
          reason: 'Failed total items for Level $level',
        );
        expect(config.sequenceLength, greaterThanOrEqualTo(1));
        expect(config.sequenceLength, lessThan(totalItems));
        expect(FocusHunterConfig.maxErrorsForDifficulty(GameDifficulty(level)),
            greaterThanOrEqualTo(1));
        expect(config.responseTimeLimit!.inSeconds, inInclusiveRange(8, 15));
      }
    });

    test('Error allowance strictly tightens at higher levels', () {
      expect(
          FocusHunterConfig.maxErrorsForDifficulty(const GameDifficulty(1)), 3);
      expect(
          FocusHunterConfig.maxErrorsForDifficulty(const GameDifficulty(2)), 3);
      expect(
          FocusHunterConfig.maxErrorsForDifficulty(const GameDifficulty(3)), 3);
      expect(
          FocusHunterConfig.maxErrorsForDifficulty(const GameDifficulty(4)), 3);
      expect(
          FocusHunterConfig.maxErrorsForDifficulty(const GameDifficulty(5)), 2);
      expect(
          FocusHunterConfig.maxErrorsForDifficulty(const GameDifficulty(6)), 2);
      expect(
          FocusHunterConfig.maxErrorsForDifficulty(const GameDifficulty(7)), 2);
      expect(
          FocusHunterConfig.maxErrorsForDifficulty(const GameDifficulty(8)), 2);
      expect(
          FocusHunterConfig.maxErrorsForDifficulty(const GameDifficulty(9)), 1);
      expect(FocusHunterConfig.maxErrorsForDifficulty(const GameDifficulty(10)),
          1);
    });
  });

  group('SeededFocusHunterGenerator Tests', () {
    const generator = SeededFocusHunterGenerator();

    test('Same seed produces an identical challenge', () {
      final config = FocusHunterConfig.forDifficulty(
        const GameDifficulty(3),
        seed: 777,
      );

      final challenge1 = generator.generate(roundIndex: 0, config: config);
      final challenge2 = generator.generate(roundIndex: 0, config: config);

      expect(challenge1.targetSymbol, equals(challenge2.targetSymbol));
      expect(challenge1.targetColor, equals(challenge2.targetColor));
      expect(challenge1.targetIndices, equals(challenge2.targetIndices));
      expect(challenge1.items.length, equals(challenge2.items.length));
      for (var i = 0; i < challenge1.items.length; i++) {
        expect(challenge1.items[i], equals(challenge2.items[i]));
      }
    });

    test('Different seeds produce different challenges', () {
      final config1 = FocusHunterConfig.forDifficulty(
        const GameDifficulty(4),
        seed: 111,
      );
      final config2 = FocusHunterConfig.forDifficulty(
        const GameDifficulty(4),
        seed: 999,
      );

      final challenge1 = generator.generate(roundIndex: 0, config: config1);
      final challenge2 = generator.generate(roundIndex: 0, config: config2);

      final sameItems = challenge1.items == challenge2.items;
      final sameIndices = challenge1.targetIndices == challenge2.targetIndices;
      expect(sameItems && sameIndices, isFalse);
    });

    test('Challenge has valid solution and correct target count', () {
      for (var level = 1; level <= 10; level++) {
        final config = FocusHunterConfig.forDifficulty(
          GameDifficulty(level),
          seed: 100 + level,
        );
        final challenge = generator.generate(roundIndex: 0, config: config);

        final totalItems = config.gridRows! * config.gridColumns!;
        expect(challenge.targetIndices.length, config.sequenceLength);
        expect(challenge.items.length, totalItems);

        // Every target index must contain an item matching target criteria
        for (final idx in challenge.targetIndices) {
          final item = challenge.items[idx];
          expect(item.isTarget, isTrue);
          expect(item.symbol, challenge.targetSymbol);
          expect(item.color, challenge.targetColor);
        }

        // Distractor items must have isTarget == false
        for (var i = 0; i < challenge.items.length; i++) {
          if (!challenge.targetIndices.contains(i)) {
            final item = challenge.items[i];
            expect(item.isTarget, isFalse);
            // Must not match both symbol and color
            final bothMatch = item.symbol == challenge.targetSymbol &&
                item.color == challenge.targetColor;
            expect(bothMatch, isFalse,
                reason: 'Distractor at $i matches target at level $level');
          }
        }
      }
    });

    test('Conjunction search feature overlap occurs on Level 5 and above', () {
      final config = FocusHunterConfig.forDifficulty(
        const GameDifficulty(6),
        seed: 42,
      );
      final challenge = generator.generate(roundIndex: 0, config: config);

      final distractors = challenge.items.where((it) => !it.isTarget).toList();
      final hasSameSymbolDistractor =
          distractors.any((it) => it.symbol == challenge.targetSymbol);
      final hasSameColorDistractor =
          distractors.any((it) => it.color == challenge.targetColor);

      // Conjunction search generates distractors sharing at least one feature
      expect(
        hasSameSymbolDistractor || hasSameColorDistractor,
        isTrue,
        reason: 'Level 6 should feature visual conjunction distractors',
      );
    });
  });

  group('FocusHunterEngine Tests', () {
    const engine = FocusHunterEngine();

    test('Initializes with canonical IDs and default generator', () {
      expect(engine.gameId, FocusHunterConfig.gameId);
      expect(engine.gameTitle, FocusHunterConfig.gameTitle);
      expect(engine.challengeGenerator, isA<SeededFocusHunterGenerator>());
    });

    test('generateHunterChallenge creates validated challenge for config', () {
      final config = FocusHunterConfig.forDifficulty(
        const GameDifficulty(2),
        seed: 42,
      );
      final challenge = engine.generateHunterChallenge(config: config);

      expect(challenge.targetIndices.length, config.sequenceLength);
      expect(challenge.items.length, config.gridRows! * config.gridColumns!);
    });

    test('evaluateInput correctly identifies targets and distractors', () {
      final config = FocusHunterConfig.forDifficulty(
        const GameDifficulty(1),
        seed: 42,
      );
      final challenge = engine.generateHunterChallenge(config: config);
      final targetIdx = challenge.targetIndices.first;
      final distractorIdx = Iterable<int>.generate(challenge.items.length)
          .firstWhere((i) => !challenge.targetIndices.contains(i));

      // Correct target tap
      final targetResult = engine.evaluateInput(
        challenge: challenge,
        input: targetIdx,
        stepIndex: 0,
      );
      expect(targetResult, isTrue);

      // Distractor tap
      final distractorResult = engine.evaluateInput(
        challenge: challenge,
        input: distractorIdx,
        stepIndex: 1,
      );
      expect(distractorResult, isFalse);

      // Out of bounds
      final outOfBoundsResult = engine.evaluateInput(
        challenge: challenge,
        input: 999,
        stepIndex: 2,
      );
      expect(outOfBoundsResult, isFalse);

      final negativeResult = engine.evaluateInput(
        challenge: challenge,
        input: -1,
        stepIndex: 3,
      );
      expect(negativeResult, isFalse);
    });
  });
}
