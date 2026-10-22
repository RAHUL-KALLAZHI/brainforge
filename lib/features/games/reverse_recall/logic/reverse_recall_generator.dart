import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/logic/challenge_generator.dart';
import 'package:brainforge/features/games/reverse_recall/domain/reverse_recall_challenge.dart';
import 'package:brainforge/features/games/reverse_recall/domain/reverse_recall_config.dart';

/// Seeded, deterministic challenge generator for Reverse Recall.
class ReverseRecallGenerator
    extends ChallengeGenerator<ReverseRecallChallenge> {
  final List<int> pool;

  const ReverseRecallGenerator({
    this.pool = ReverseRecallConfig.standardPool,
  });

  @override
  ReverseRecallChallenge generate({
    required int roundIndex,
    required GameConfig config,
  }) {
    config.validate();

    final random = createRandom(roundIndex: roundIndex, config: config);
    final targetLength = config.sequenceLength ??
        ReverseRecallConfig.sequenceLengthForDifficulty(config.difficulty);

    final sequence = <int>[];
    int? lastDigit;

    // Pick digits from pool ensuring no immediate consecutive duplicates
    for (var i = 0; i < targetLength; i++) {
      final available = pool.where((d) => d != lastDigit).toList();
      final selected = available[random.nextInt(available.length)];
      sequence.add(selected);
      lastDigit = selected;
    }

    final unmodifiableSequence = List<int>.unmodifiable(sequence);
    final expectedReverse = List<int>.unmodifiable(sequence.reversed.toList());

    return ReverseRecallChallenge(
      roundIndex: roundIndex,
      seed: config.seed,
      sequence: unmodifiableSequence,
      expectedReverse: expectedReverse,
      pool: List<int>.unmodifiable(pool),
    );
  }
}
