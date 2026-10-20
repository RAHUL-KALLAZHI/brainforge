import 'dart:math';
import '../../shared/domain/game_config.dart';
import '../../shared/logic/challenge_generator.dart';
import '../domain/focus_hunter_config.dart';

/// Seeded, deterministic challenge generator for Focus Hunter boards.
class SeededFocusHunterGenerator
    extends ChallengeGenerator<FocusHunterChallenge> {
  const SeededFocusHunterGenerator();

  @override
  FocusHunterChallenge generate({
    required int roundIndex,
    required GameConfig config,
  }) {
    config.validate();

    final random = createRandom(roundIndex: roundIndex, config: config);
    final rows = config.gridRows ?? 3;
    final columns = config.gridColumns ?? 3;
    final totalTiles = rows * columns;
    final targetCount = config.sequenceLength ?? 1;

    // 1. Pick target feature tuple (symbol + color)
    const allSymbols = FocusSymbolType.values;
    const allColors = FocusColorType.values;

    final targetSymbol = allSymbols[random.nextInt(allSymbols.length)];
    final targetColor = allColors[random.nextInt(allColors.length)];

    // 2. Deterministically select target positions
    final allIndices = List<int>.generate(totalTiles, (i) => i);
    _shuffle(allIndices, random);
    final targetIndices = allIndices.take(targetCount).toSet();

    // 3. Populate board items
    final items = <FocusHunterItem>[];
    for (int i = 0; i < totalTiles; i++) {
      if (targetIndices.contains(i)) {
        items.add(FocusHunterItem(
          id: i,
          symbol: targetSymbol,
          color: targetColor,
          isTarget: true,
        ));
      } else {
        // Generate distractor that never completely matches target
        final distractor = _generateDistractor(
          random: random,
          targetSymbol: targetSymbol,
          targetColor: targetColor,
          difficultyLevel: config.difficulty.level,
          id: i,
        );
        items.add(distractor);
      }
    }

    final maxErrors =
        FocusHunterConfig.maxErrorsForDifficulty(config.difficulty);

    return FocusHunterChallenge(
      roundIndex: roundIndex,
      seed: config.seed,
      targetSymbol: targetSymbol,
      targetColor: targetColor,
      items: List.unmodifiable(items),
      targetCount: targetCount,
      gridRows: rows,
      gridColumns: columns,
      maxErrorsAllowed: maxErrors,
    );
  }

  /// Generates a distractor item with difficulty-scaled feature overlap.
  FocusHunterItem _generateDistractor({
    required Random random,
    required FocusSymbolType targetSymbol,
    required FocusColorType targetColor,
    required int difficultyLevel,
    required int id,
  }) {
    const allSymbols = FocusSymbolType.values;
    const allColors = FocusColorType.values;

    final otherSymbols = allSymbols.where((s) => s != targetSymbol).toList();
    final otherColors = allColors.where((c) => c != targetColor).toList();

    FocusSymbolType symbol;
    FocusColorType color;

    if (difficultyLevel <= 2) {
      // Beginner: High feature divergence (different shape & different color)
      symbol = otherSymbols[random.nextInt(otherSymbols.length)];
      color = otherColors[random.nextInt(otherColors.length)];
    } else if (difficultyLevel <= 4) {
      // Intermediate: 50% chance to share color, 50% chance to share shape
      if (random.nextBool()) {
        symbol = targetSymbol;
        color = otherColors[random.nextInt(otherColors.length)];
      } else {
        symbol = otherSymbols[random.nextInt(otherSymbols.length)];
        color = targetColor;
      }
    } else {
      // Advanced / Expert / Master: Conjunction search with challenging visual distractors
      final pickType = random.nextInt(3);
      if (pickType == 0) {
        // Same symbol, distinct color
        symbol = targetSymbol;
        color = otherColors[random.nextInt(otherColors.length)];
      } else if (pickType == 1) {
        // Same color, distinct symbol
        symbol = otherSymbols[random.nextInt(otherSymbols.length)];
        color = targetColor;
      } else {
        // Distinct symbol & color
        symbol = otherSymbols[random.nextInt(otherSymbols.length)];
        color = otherColors[random.nextInt(otherColors.length)];
      }
    }

    // Safety guard: guarantee distractor is NEVER identical to target
    if (symbol == targetSymbol && color == targetColor) {
      symbol = otherSymbols.first;
    }

    return FocusHunterItem(
      id: id,
      symbol: symbol,
      color: color,
      isTarget: false,
    );
  }

  /// In-place Fisher-Yates shuffle using provided [Random] instance.
  void _shuffle<T>(List<T> list, Random random) {
    for (int i = list.length - 1; i > 0; i--) {
      final n = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[n];
      list[n] = temp;
    }
  }
}
