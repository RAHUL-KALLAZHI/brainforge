import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_registry.dart';

/// Central configuration helper defining presets and difficulty mappings for Mind Switch.
abstract final class MindSwitchConfig {
  static const String gameId = GameRegistry.mindSwitch;
  static const String gameTitle = 'Mind Switch';

  /// Total trials in a session for a given [difficulty] (Levels 1 to 10).
  static int totalTrialsForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
        return 10;
      case 2:
        return 12;
      case 3:
        return 14;
      case 4:
        return 16;
      case 5:
        return 18;
      case 6:
        return 20;
      case 7:
        return 22;
      case 8:
        return 24;
      case 9:
      case 10:
      default:
        return 25;
    }
  }

  /// Per-trial response time limit for a given [difficulty].
  ///
  /// Scales from 5.0 seconds at Level 1 down to 1.5 seconds at Level 10.
  static Duration trialTimeLimitForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
        return const Duration(milliseconds: 5000);
      case 2:
        return const Duration(milliseconds: 4500);
      case 3:
        return const Duration(milliseconds: 4000);
      case 4:
        return const Duration(milliseconds: 3500);
      case 5:
        return const Duration(milliseconds: 3000);
      case 6:
        return const Duration(milliseconds: 2600);
      case 7:
        return const Duration(milliseconds: 2200);
      case 8:
        return const Duration(milliseconds: 1900);
      case 9:
        return const Duration(milliseconds: 1700);
      case 10:
      default:
        return const Duration(milliseconds: 1500);
    }
  }

  /// Average run length of trials before a rule switch occurs.
  ///
  /// At low levels, rules persist for 4-5 trials to allow habituation.
  /// At high levels, rules rapidly flip every 1-2 trials demanding continuous flexibility.
  static int switchIntervalForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
        return 5;
      case 2:
        return 4;
      case 3:
        return 4;
      case 4:
        return 3;
      case 5:
        return 3;
      case 6:
        return 2;
      case 7:
        return 2;
      case 8:
        return 2;
      case 9:
      case 10:
      default:
        return 1;
    }
  }

  /// Proportion of trials where the ink color matches the word text (congruent).
  ///
  /// At Level 1, 60% of trials are congruent. At Level 10, only 10% are congruent,
  /// maximizing Stroop interference.
  static double congruencyRateForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
        return 0.60;
      case 2:
        return 0.50;
      case 3:
        return 0.40;
      case 4:
        return 0.35;
      case 5:
        return 0.30;
      case 6:
        return 0.25;
      case 7:
        return 0.20;
      case 8:
        return 0.15;
      case 9:
        return 0.10;
      case 10:
      default:
        return 0.05;
    }
  }

  /// Maximum mistakes allowed before the game enters a failed state.
  static int maxMistakesForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
      case 2:
        return 3;
      case 3:
      case 4:
        return 2;
      case 5:
      case 6:
      case 7:
        return 1;
      case 8:
      case 9:
      case 10:
      default:
        return 0;
    }
  }

  /// Builds a validated [GameConfig] tailored to the specified [difficulty] level.
  static GameConfig forDifficulty(
    GameDifficulty difficulty, {
    int? seed,
    Duration? responseTimeLimit,
  }) {
    final totalTrials = totalTrialsForDifficulty(difficulty);
    final trialTimeLimit =
        responseTimeLimit ?? trialTimeLimitForDifficulty(difficulty);

    final config = GameConfig(
      gameId: gameId,
      difficulty: difficulty,
      sequenceLength: totalTrials,
      presentationDuration: const Duration(milliseconds: 500),
      responseTimeLimit: trialTimeLimit,
      targetRounds: 1,
      seed: seed,
      allowDuplicates: true,
    );

    config.validate();
    return config;
  }
}
