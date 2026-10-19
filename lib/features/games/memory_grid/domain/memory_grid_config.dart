import '../../shared/domain/game_config.dart';
import '../../shared/domain/game_difficulty.dart';

/// Helper generating validated [GameConfig] presets for Memory Grid levels.
abstract final class MemoryGridConfig {
  static const String gameId = 'memory_grid';

  /// Builds a [GameConfig] tailored to the specified [difficulty] level (1 to 10).
  static GameConfig forDifficulty(
    GameDifficulty difficulty, {
    int? seed,
    Duration presentationDuration = const Duration(milliseconds: 750),
    Duration responseTimeLimit = const Duration(seconds: 15),
  }) {
    final int rows;
    final int columns;
    final int sequenceLength;

    switch (difficulty.level) {
      case 1:
        rows = 3;
        columns = 3;
        sequenceLength = 3;
        break;
      case 2:
        rows = 3;
        columns = 3;
        sequenceLength = 4;
        break;
      case 3:
        rows = 3;
        columns = 3;
        sequenceLength = 5;
        break;
      case 4:
        rows = 4;
        columns = 4;
        sequenceLength = 5;
        break;
      case 5:
        rows = 4;
        columns = 4;
        sequenceLength = 6;
        break;
      case 6:
        rows = 4;
        columns = 4;
        sequenceLength = 7;
        break;
      case 7:
        rows = 5;
        columns = 5;
        sequenceLength = 7;
        break;
      case 8:
        rows = 5;
        columns = 5;
        sequenceLength = 8;
        break;
      case 9:
        rows = 5;
        columns = 5;
        sequenceLength = 9;
        break;
      case 10:
      default:
        rows = 5;
        columns = 5;
        sequenceLength = 10;
        break;
    }

    final config = GameConfig(
      gameId: gameId,
      difficulty: difficulty,
      gridRows: rows,
      gridColumns: columns,
      sequenceLength: sequenceLength,
      presentationDuration: presentationDuration,
      responseTimeLimit: responseTimeLimit,
      targetRounds: 1,
      allowDuplicates: false,
      seed: seed,
    );

    config.validate();
    return config;
  }
}
