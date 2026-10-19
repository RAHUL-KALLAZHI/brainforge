import '../../shared/domain/game_config.dart';
import '../../shared/logic/challenge_generator.dart';
import '../../shared/logic/game_engine.dart';
import '../domain/memory_grid_config.dart';

/// Concrete game engine implementing the Memory Grid challenge rules.
class MemoryGridEngine extends GameEngine<SequenceChallenge, int> {
  @override
  final String gameId;

  @override
  final String gameTitle;

  @override
  final ChallengeGenerator<SequenceChallenge> challengeGenerator;

  const MemoryGridEngine({
    this.gameId = MemoryGridConfig.gameId,
    this.gameTitle = 'Memory Grid',
    this.challengeGenerator =
        const SeededSequenceGenerator(allowDuplicates: false),
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

  /// Generates a validated Memory Grid challenge.
  SequenceChallenge generateGridChallenge({
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
