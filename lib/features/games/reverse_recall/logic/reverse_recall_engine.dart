import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/logic/challenge_generator.dart';
import 'package:brainforge/features/games/shared/logic/game_engine.dart';
import 'package:brainforge/features/games/reverse_recall/domain/reverse_recall_challenge.dart';
import 'package:brainforge/features/games/reverse_recall/domain/reverse_recall_config.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_generator.dart';

/// Pure-Dart game engine for Reverse Recall evaluating user input against the expected reverse sequence.
class ReverseRecallEngine extends GameEngine<ReverseRecallChallenge, int> {
  @override
  final String gameId;

  @override
  final String gameTitle;

  @override
  final ChallengeGenerator<ReverseRecallChallenge> challengeGenerator;

  const ReverseRecallEngine({
    this.gameId = ReverseRecallConfig.gameId,
    this.gameTitle = ReverseRecallConfig.gameTitle,
    this.challengeGenerator = const ReverseRecallGenerator(),
  });

  @override
  bool evaluateInput({
    required ReverseRecallChallenge challenge,
    required int input,
    required int stepIndex,
  }) {
    if (stepIndex < 0 || stepIndex >= challenge.expectedReverse.length) {
      return false;
    }
    return challenge.expectedReverse[stepIndex] == input;
  }

  /// Generates a validated Reverse Recall challenge.
  ReverseRecallChallenge generateReverseChallenge({
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
