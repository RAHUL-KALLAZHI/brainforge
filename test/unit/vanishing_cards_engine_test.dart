import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/vanishing_cards/domain/vanishing_cards_config.dart';
import 'package:brainforge/features/games/vanishing_cards/logic/vanishing_cards_engine.dart';
import 'package:brainforge/features/games/vanishing_cards/logic/vanishing_cards_generator.dart';

void main() {
  group('VanishingCardsConfig & Difficulty Mapping Tests', () {
    test('Game ID and Title constants are correct', () {
      expect(VanishingCardsConfig.gameId, 'vanishing_cards');
      expect(VanishingCardsConfig.gameTitle, 'Vanishing Cards');
    });

    test('Symbols have 16 distinct geometric symbols with accessible semantics',
        () {
      expect(VanishingCardSymbol.values.length, 16);
      final labels = VanishingCardSymbol.values.map((s) => s.label).toSet();
      expect(labels.length, 16);
      for (final s in VanishingCardSymbol.values) {
        expect(s.semanticDescription.isNotEmpty, isTrue);
        expect(s.icon, isNotNull);
      }
    });

    test(
        'Levels 1 to 10 scale grid size, cards to recall, and preview duration deterministically',
        () {
      final expectedGridSizes = {
        1: 9, // 3x3
        2: 9, // 3x3
        3: 9, // 3x3
        4: 12, // 4x3
        5: 12, // 4x3
        6: 12, // 4x3
        7: 16, // 4x4
        8: 16, // 4x4
        9: 16, // 4x4
        10: 16, // 4x4
      };

      for (var level = 1; level <= 10; level++) {
        final config = VanishingCardsConfig.forDifficulty(
          GameDifficulty(level),
          seed: 42,
        );

        final totalCards = config.gridRows! * config.gridColumns!;
        expect(
          totalCards,
          expectedGridSizes[level],
          reason: 'Failed total cards for Level $level',
        );
        expect(config.sequenceLength, greaterThanOrEqualTo(2));
        expect(config.sequenceLength, lessThanOrEqualTo(totalCards));
        expect(
          VanishingCardsConfig.previewDurationForDifficulty(
                  GameDifficulty(level))
              .inMilliseconds,
          inInclusiveRange(1500, 4000),
        );
        expect(
          VanishingCardsConfig.maxErrorsForDifficulty(GameDifficulty(level)),
          greaterThanOrEqualTo(0),
        );
      }
    });

    test('Preview duration and error allowances tighten at higher levels', () {
      final l1Duration = VanishingCardsConfig.previewDurationForDifficulty(
          const GameDifficulty(1));
      final l5Duration = VanishingCardsConfig.previewDurationForDifficulty(
          const GameDifficulty(5));
      final l10Duration = VanishingCardsConfig.previewDurationForDifficulty(
          const GameDifficulty(10));

      expect(l1Duration.inMilliseconds, greaterThan(l5Duration.inMilliseconds));
      expect(
          l5Duration.inMilliseconds, greaterThan(l10Duration.inMilliseconds));

      expect(
          VanishingCardsConfig.maxErrorsForDifficulty(const GameDifficulty(1)),
          2);
      expect(
          VanishingCardsConfig.maxErrorsForDifficulty(const GameDifficulty(5)),
          1);
      expect(
          VanishingCardsConfig.maxErrorsForDifficulty(const GameDifficulty(10)),
          0);
    });
  });

  group('SeededVanishingCardsGenerator Tests', () {
    const generator = SeededVanishingCardsGenerator();

    test('Same seed produces identical challenge', () {
      final config = VanishingCardsConfig.forDifficulty(
        const GameDifficulty(3),
        seed: 777,
      );

      final c1 = generator.generate(config: config, roundIndex: 0);
      final c2 = generator.generate(config: config, roundIndex: 0);

      expect(c1.cards.length, c2.cards.length);
      for (var i = 0; i < c1.cards.length; i++) {
        expect(c1.cards[i].id, c2.cards[i].id);
        expect(c1.cards[i].symbol, c2.cards[i].symbol);
        expect(c1.cards[i].positionIndex, c2.cards[i].positionIndex);
      }
      expect(c1.targetCards.length, c2.targetCards.length);
      for (var i = 0; i < c1.targetCards.length; i++) {
        expect(c1.targetCards[i].id, c2.targetCards[i].id);
      }
    });

    test('Different seeds produce distinct challenge layouts', () {
      final config1 = VanishingCardsConfig.forDifficulty(
        const GameDifficulty(4),
        seed: 111,
      );
      final config2 = VanishingCardsConfig.forDifficulty(
        const GameDifficulty(4),
        seed: 999,
      );

      final c1 = generator.generate(config: config1, roundIndex: 0);
      final c2 = generator.generate(config: config2, roundIndex: 0);

      final symbols1 = c1.cards.map((c) => c.symbol).toList();
      final symbols2 = c2.cards.map((c) => c.symbol).toList();

      expect(symbols1, isNot(equals(symbols2)));
    });

    test(
        'Every generated challenge is fully solvable and internally consistent',
        () {
      for (var level = 1; level <= 10; level++) {
        final config = VanishingCardsConfig.forDifficulty(
          GameDifficulty(level),
          seed: level * 101,
        );
        final challenge = generator.generate(config: config, roundIndex: 0);

        final totalCards = config.gridRows! * config.gridColumns!;
        expect(challenge.cards.length, totalCards);
        expect(challenge.targetCards.length, config.sequenceLength);

        // All cards on grid must have distinct positions
        final positions = challenge.cards.map((c) => c.positionIndex).toSet();
        expect(positions.length, totalCards);

        // All cards on grid must have unique symbols
        final symbols = challenge.cards.map((c) => c.symbol).toSet();
        expect(symbols.length, totalCards);

        // Every target card must exist in the grid
        for (final target in challenge.targetCards) {
          final found = challenge.cards
              .any((c) => c.positionIndex == target.positionIndex);
          expect(found, isTrue);
          expect(challenge.cards[target.positionIndex].symbol, target.symbol);
        }
      }
    });
  });

  group('VanishingCardsEngine Tests', () {
    const generator = SeededVanishingCardsGenerator();
    const engine = VanishingCardsEngine();

    test('evaluateInput returns true for matching target card position', () {
      final config = VanishingCardsConfig.forDifficulty(
        const GameDifficulty(2),
        seed: 42,
      );
      final challenge = generator.generate(config: config, roundIndex: 0);

      final firstTarget = challenge.targetCards[0];
      final isCorrect = engine.evaluateInput(
        challenge: challenge,
        input: firstTarget.positionIndex,
        stepIndex: 0,
      );

      expect(isCorrect, isTrue);
    });

    test('evaluateInput returns false for non-matching position or wrong step',
        () {
      final config = VanishingCardsConfig.forDifficulty(
        const GameDifficulty(2),
        seed: 42,
      );
      final challenge = generator.generate(config: config, roundIndex: 0);

      final firstTarget = challenge.targetCards[0];
      // Pick a position different from first target
      final wrongPosition =
          (firstTarget.positionIndex + 1) % challenge.cards.length;

      final isWrong = engine.evaluateInput(
        challenge: challenge,
        input: wrongPosition,
        stepIndex: 0,
      );
      expect(isWrong, isFalse);

      // Testing out-of-range step index returns false
      final isInvalidStep = engine.evaluateInput(
        challenge: challenge,
        input: firstTarget.positionIndex,
        stepIndex: 999,
      );
      expect(isInvalidStep, isFalse);
    });
  });
}
