import 'package:brainforge/features/games/shared/domain/game_challenge.dart';

/// Challenge model for Reverse Recall representing an ordered sequence
/// and its expected reverse reproduction.
class ReverseRecallChallenge extends GameChallenge {
  /// The presented sequence in forward order.
  final List<int> sequence;

  /// The expected response sequence in reverse order.
  final List<int> expectedReverse;

  /// The pool of selectable digits (e.g. 1 to 9).
  final List<int> pool;

  const ReverseRecallChallenge({
    required super.roundIndex,
    super.seed,
    required this.sequence,
    required this.expectedReverse,
    required this.pool,
  });

  /// Total count of items in the sequence to remember and reverse.
  int get length => sequence.length;

  @override
  List<Object?> get props =>
      [roundIndex, seed, sequence, expectedReverse, pool];
}
