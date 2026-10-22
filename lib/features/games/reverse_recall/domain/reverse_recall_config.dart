import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';

/// Central configuration helper defining presets and difficulty mappings for Reverse Recall.
abstract final class ReverseRecallConfig {
  static const String gameId = 'reverse_recall';
  static const String gameTitle = 'Reverse Recall';

  /// Standard digit pool used for Reverse Recall keypad (digits 1 to 9).
  static const List<int> standardPool = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  /// Target sequence length for a given [difficulty] (Levels 1 to 10).
  ///
  /// Scaling follows clinical working memory digit span progression:
  /// - Level 1: 3 digits
  /// - Level 2: 4 digits
  /// - Level 3: 5 digits
  /// - Level 4: 6 digits
  /// - Level 5: 7 digits
  /// - Level 6: 8 digits
  /// - Level 7: 9 digits
  /// - Level 8: 10 digits
  /// - Level 9: 11 digits
  /// - Level 10: 12 digits
  static int sequenceLengthForDifficulty(GameDifficulty difficulty) {
    return 2 + difficulty.level;
  }

  /// Active presentation duration per digit for a given [difficulty].
  static Duration presentationDurationForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
        return const Duration(milliseconds: 1000);
      case 2:
        return const Duration(milliseconds: 950);
      case 3:
        return const Duration(milliseconds: 900);
      case 4:
        return const Duration(milliseconds: 850);
      case 5:
        return const Duration(milliseconds: 800);
      case 6:
        return const Duration(milliseconds: 750);
      case 7:
        return const Duration(milliseconds: 700);
      case 8:
        return const Duration(milliseconds: 650);
      case 9:
        return const Duration(milliseconds: 600);
      case 10:
      default:
        return const Duration(milliseconds: 550);
    }
  }

  /// Blank gap duration between sequential digit flashes.
  static Duration gapDurationForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
        return const Duration(milliseconds: 300);
      case 2:
        return const Duration(milliseconds: 280);
      case 3:
        return const Duration(milliseconds: 260);
      case 4:
        return const Duration(milliseconds: 240);
      case 5:
        return const Duration(milliseconds: 220);
      case 6:
        return const Duration(milliseconds: 200);
      case 7:
        return const Duration(milliseconds: 180);
      case 8:
        return const Duration(milliseconds: 160);
      case 9:
        return const Duration(milliseconds: 140);
      case 10:
      default:
        return const Duration(milliseconds: 120);
    }
  }

  /// Builds a validated [GameConfig] tailored to the specified [difficulty] level.
  static GameConfig forDifficulty(
    GameDifficulty difficulty, {
    int? seed,
    Duration? responseTimeLimit,
  }) {
    final length = sequenceLengthForDifficulty(difficulty);
    final presentationDuration = presentationDurationForDifficulty(difficulty);

    final config = GameConfig(
      gameId: gameId,
      difficulty: difficulty,
      sequenceLength: length,
      presentationDuration: presentationDuration,
      responseTimeLimit: responseTimeLimit ?? const Duration(seconds: 20),
      targetRounds: 1,
      seed: seed,
      allowDuplicates: false,
    );

    config.validate();
    return config;
  }
}
