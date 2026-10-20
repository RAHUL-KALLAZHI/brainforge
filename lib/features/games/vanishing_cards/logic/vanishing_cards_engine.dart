import '../../shared/domain/game_config.dart';
import '../../shared/logic/challenge_generator.dart';
import '../../shared/logic/game_engine.dart';
import '../domain/vanishing_cards_config.dart';
import 'vanishing_cards_generator.dart';

/// Concrete game engine implementing the Vanishing Cards challenge and evaluation rules.
class VanishingCardsEngine extends GameEngine<VanishingCardsChallenge, int> {
  @override
  final String gameId;

  @override
  final String gameTitle;

  @override
  final ChallengeGenerator<VanishingCardsChallenge> challengeGenerator;

  const VanishingCardsEngine({
    this.gameId = VanishingCardsConfig.gameId,
    this.gameTitle = VanishingCardsConfig.gameTitle,
    this.challengeGenerator = const SeededVanishingCardsGenerator(),
  });

  @override
  bool evaluateInput({
    required VanishingCardsChallenge challenge,
    required int input,
    required int stepIndex,
  }) {
    if (input < 0 || input >= challenge.cards.length) {
      return false;
    }
    if (stepIndex < 0 || stepIndex >= challenge.targetCards.length) {
      return false;
    }

    final currentTarget = challenge.targetCards[stepIndex];
    return challenge.cards[input].positionIndex == currentTarget.positionIndex;
  }

  /// Generates a validated Vanishing Cards challenge.
  VanishingCardsChallenge generateCardsChallenge({
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
