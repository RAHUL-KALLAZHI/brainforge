import '../../shared/domain/game_config.dart';
import '../../shared/logic/challenge_generator.dart';
import '../../shared/logic/game_engine.dart';
import '../domain/focus_hunter_config.dart';
import 'focus_hunter_generator.dart';

/// Concrete game engine implementing the Focus Hunter challenge and evaluation rules.
class FocusHunterEngine extends GameEngine<FocusHunterChallenge, int> {
  @override
  final String gameId;

  @override
  final String gameTitle;

  @override
  final ChallengeGenerator<FocusHunterChallenge> challengeGenerator;

  const FocusHunterEngine({
    this.gameId = FocusHunterConfig.gameId,
    this.gameTitle = FocusHunterConfig.gameTitle,
    this.challengeGenerator = const SeededFocusHunterGenerator(),
  });

  @override
  bool evaluateInput({
    required FocusHunterChallenge challenge,
    required int input,
    required int stepIndex,
  }) {
    if (input < 0 || input >= challenge.items.length) {
      return false;
    }
    return challenge.items[input].isTarget;
  }

  /// Generates a validated Focus Hunter challenge.
  FocusHunterChallenge generateHunterChallenge({
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
