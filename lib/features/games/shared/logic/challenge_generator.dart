import 'dart:math';
import '../domain/game_challenge.dart';
import '../domain/game_config.dart';

/// Abstract contract for seeded, deterministic challenge generators.
abstract class ChallengeGenerator<C extends GameChallenge> {
  const ChallengeGenerator();

  /// Generates a deterministic challenge for the specified [roundIndex] and [config].
  C generate({
    required int roundIndex,
    required GameConfig config,
  });

  /// Creates a seeded [Random] instance using either [GameConfig.seed] or a salt.
  Random createRandom({required int roundIndex, required GameConfig config}) {
    if (config.seed != null) {
      // Deterministic PRNG using base seed combined with roundIndex
      return Random(config.seed! ^ (roundIndex * 31));
    }
    return Random();
  }
}

/// Generic sequence challenge representing an ordered list of items (e.g. tile indices or color IDs).
class SequenceChallenge extends GameChallenge {
  final List<int> sequence;
  final int totalPoolSize;

  const SequenceChallenge({
    required super.roundIndex,
    super.seed,
    required this.sequence,
    required this.totalPoolSize,
  });

  @override
  List<Object?> get props => [roundIndex, seed, sequence, totalPoolSize];
}

/// Concrete challenge generator producing unique or repeatable integer sequences from a pool.
class SeededSequenceGenerator extends ChallengeGenerator<SequenceChallenge> {
  final bool allowDuplicates;

  const SeededSequenceGenerator({this.allowDuplicates = false});

  @override
  SequenceChallenge generate({
    required int roundIndex,
    required GameConfig config,
  }) {
    config.validate();

    final random = createRandom(roundIndex: roundIndex, config: config);
    final length = config.sequenceLength ?? (3 + config.difficulty.level);
    final poolSize = (config.gridRows != null && config.gridColumns != null)
        ? (config.gridRows! * config.gridColumns!)
        : (4 + config.difficulty.level * 2);

    final sequence = <int>[];

    if (allowDuplicates) {
      for (var i = 0; i < length; i++) {
        sequence.add(random.nextInt(poolSize));
      }
    } else {
      // Unique tiles (e.g. Memory Grid where each tile lights up once in a sequence)
      final pool = List<int>.generate(poolSize, (i) => i);
      pool.shuffle(random);
      sequence.addAll(pool.take(length));
    }

    return SequenceChallenge(
      roundIndex: roundIndex,
      seed: config.seed,
      sequence: List.unmodifiable(sequence),
      totalPoolSize: poolSize,
    );
  }
}
