import '../../shared/domain/game_config.dart';
import '../../shared/logic/challenge_generator.dart';
import '../domain/vanishing_cards_config.dart';

/// Deterministic, PRNG-seeded challenge generator for Vanishing Cards.
class SeededVanishingCardsGenerator
    extends ChallengeGenerator<VanishingCardsChallenge> {
  const SeededVanishingCardsGenerator();

  @override
  VanishingCardsChallenge generate({
    int roundIndex = 0,
    required GameConfig config,
  }) {
    config.validate();

    final rows = config.gridRows!;
    final columns = config.gridColumns!;
    final totalCards = rows * columns;
    final targetCount = config.sequenceLength!;

    final random = createRandom(roundIndex: roundIndex, config: config);

    // 1. Shuffle all available symbols and select totalCards unique symbols
    final availableSymbols =
        List<VanishingCardSymbol>.from(VanishingCardSymbol.values)
          ..shuffle(random);

    final selectedSymbols = availableSymbols.take(totalCards).toList();

    // 2. Instantiate board cards with assigned positions
    final cards = <VanishingCard>[];
    for (var i = 0; i < totalCards; i++) {
      cards.add(
        VanishingCard(
          id: i,
          symbol: selectedSymbols[i],
          positionIndex: i,
        ),
      );
    }

    // 3. Select targetCount unique cards from the board to recall
    final shuffledCardPool = List<VanishingCard>.from(cards)..shuffle(random);
    final targetCards = shuffledCardPool.take(targetCount).toList();

    return VanishingCardsChallenge(
      roundIndex: roundIndex,
      seed: config.seed,
      cards: cards,
      targetCards: targetCards,
      gridRows: rows,
      gridColumns: columns,
      previewDuration: config.presentationDuration,
      maxErrorsAllowed:
          VanishingCardsConfig.maxErrorsForDifficulty(config.difficulty),
    );
  }
}
