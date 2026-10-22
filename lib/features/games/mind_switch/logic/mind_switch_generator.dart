import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/logic/challenge_generator.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_challenge.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_config.dart';

/// Seeded, deterministic challenge generator for Mind Switch.
class MindSwitchGenerator extends ChallengeGenerator<MindSwitchChallenge> {
  const MindSwitchGenerator();

  @override
  MindSwitchChallenge generate({
    required int roundIndex,
    required GameConfig config,
  }) {
    config.validate();

    final random = createRandom(roundIndex: roundIndex, config: config);
    final totalTrials = config.sequenceLength ??
        MindSwitchConfig.totalTrialsForDifficulty(config.difficulty);
    final switchInterval =
        MindSwitchConfig.switchIntervalForDifficulty(config.difficulty);
    final congruencyRate =
        MindSwitchConfig.congruencyRateForDifficulty(config.difficulty);
    final maxMistakesAllowed =
        MindSwitchConfig.maxMistakesForDifficulty(config.difficulty);

    // Initial rule selection (deterministic per seed & round)
    MindSwitchRule currentRule =
        random.nextBool() ? MindSwitchRule.color : MindSwitchRule.word;

    final trials = <MindSwitchTrial>[];
    int runLength = 0;

    for (var i = 0; i < totalTrials; i++) {
      bool isSwitch = false;

      if (i > 0) {
        runLength++;
        if (runLength >= switchInterval) {
          currentRule = currentRule.opposite;
          isSwitch = true;
          runLength = 0;
        }
      }

      // Determine congruency for this trial
      final isCongruent = random.nextDouble() < congruencyRate;

      // Select semantic word color
      final wordColor =
          MindSwitchColor.values[random.nextInt(MindSwitchColor.values.length)];

      // Select physical ink color
      final MindSwitchColor inkColor;
      if (isCongruent) {
        inkColor = wordColor;
      } else {
        final otherColors =
            MindSwitchColor.values.where((c) => c != wordColor).toList();
        inkColor = otherColors[random.nextInt(otherColors.length)];
      }

      trials.add(MindSwitchTrial(
        index: i,
        rule: currentRule,
        wordColor: wordColor,
        inkColor: inkColor,
        isRuleSwitch: isSwitch,
      ));
    }

    return MindSwitchChallenge(
      roundIndex: roundIndex,
      seed: config.seed,
      trials: List.unmodifiable(trials),
      maxMistakesAllowed: maxMistakesAllowed,
    );
  }
}
