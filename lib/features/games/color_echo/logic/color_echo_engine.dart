import '../../shared/domain/game_config.dart';
import '../../shared/logic/challenge_generator.dart';
import '../../shared/logic/game_engine.dart';
import '../domain/color_echo_config.dart';

/// Concrete game engine implementing the Color Echo challenge and validation rules.
class ColorEchoEngine extends GameEngine<SequenceChallenge, int> {
  @override
  final String gameId;

  @override
  final String gameTitle;

  @override
  final ChallengeGenerator<SequenceChallenge> challengeGenerator;

  const ColorEchoEngine({
    this.gameId = ColorEchoConfig.gameId,
    this.gameTitle = ColorEchoConfig.gameTitle,
    this.challengeGenerator =
        const SeededSequenceGenerator(allowDuplicates: true),
  });

  @override
  bool evaluateInput({
    required SequenceChallenge challenge,
    required int input,
    required int stepIndex,
  }) {
    if (stepIndex < 0 || stepIndex >= challenge.sequence.length) {
      return false;
    }
    return challenge.sequence[stepIndex] == input;
  }

  /// Generates a validated Color Echo challenge.
  SequenceChallenge generateEchoChallenge({
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
