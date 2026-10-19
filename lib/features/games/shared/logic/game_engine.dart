import '../domain/game_challenge.dart';
import '../domain/game_config.dart';
import 'challenge_generator.dart';
import 'game_state_machine.dart';
import 'game_timer.dart';

/// Contract that every cognitive game must implement.
///
/// Ensures decoupled logic where game mechanics, input evaluations, and
/// challenge generations can be tested in pure Dart without Flutter UI bindings.
abstract class GameEngine<C extends GameChallenge, I> {
  const GameEngine();

  /// Unique canonical identifier matching catalog routes (e.g. 'memory_grid').
  String get gameId;

  /// Display title.
  String get gameTitle;

  /// Underlying challenge generator.
  ChallengeGenerator<C> get challengeGenerator;

  /// Generates a deterministic challenge for a given round.
  C generateChallenge({
    required int roundIndex,
    required GameConfig config,
  }) {
    return challengeGenerator.generate(
      roundIndex: roundIndex,
      config: config,
    );
  }

  /// Evaluates player input against the challenge rules.
  bool evaluateInput({
    required C challenge,
    required I input,
    required int stepIndex,
  });

  /// Instantiates a new state machine session for this game.
  GameStateMachine createSession({
    required GameConfig config,
    GameTimer? timer,
  }) {
    config.validate();
    return GameStateMachine(
      config: config,
      timer: timer,
    );
  }
}

/// Reference sequence game engine used to validate the shared engine contracts.
class TestSequenceGameEngine extends GameEngine<SequenceChallenge, int> {
  @override
  final String gameId;

  @override
  final String gameTitle;

  @override
  final ChallengeGenerator<SequenceChallenge> challengeGenerator;

  const TestSequenceGameEngine({
    this.gameId = 'test_sequence',
    this.gameTitle = 'Test Sequence Game',
    this.challengeGenerator = const SeededSequenceGenerator(),
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
}
