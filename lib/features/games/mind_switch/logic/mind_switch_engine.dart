import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/logic/challenge_generator.dart';
import 'package:brainforge/features/games/shared/logic/game_engine.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_challenge.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_config.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_generator.dart';

/// Concrete game engine implementing the Mind Switch Stroop task-switching rules.
class MindSwitchEngine
    extends GameEngine<MindSwitchChallenge, MindSwitchColor> {
  @override
  final String gameId;

  @override
  final String gameTitle;

  @override
  final ChallengeGenerator<MindSwitchChallenge> challengeGenerator;

  const MindSwitchEngine({
    this.gameId = MindSwitchConfig.gameId,
    this.gameTitle = MindSwitchConfig.gameTitle,
    this.challengeGenerator = const MindSwitchGenerator(),
  });

  @override
  bool evaluateInput({
    required MindSwitchChallenge challenge,
    required MindSwitchColor input,
    required int stepIndex,
  }) {
    if (stepIndex < 0 || stepIndex >= challenge.trials.length) {
      return false;
    }
    return challenge.trials[stepIndex].targetColor == input;
  }

  /// Generates a validated Mind Switch challenge.
  MindSwitchChallenge generateMindSwitchChallenge({
    required GameConfig config,
    int roundIndex = 0,
  }) {
    config.validate();
    return challengeGenerator.generate(
      roundIndex: roundIndex,
      config: config,
    );
  }
}
