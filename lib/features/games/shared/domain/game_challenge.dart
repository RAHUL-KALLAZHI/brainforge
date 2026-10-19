import 'package:equatable/equatable.dart';

/// Base contract for generated challenges across all mini-games.
abstract class GameChallenge extends Equatable {
  final int roundIndex;
  final int? seed;

  const GameChallenge({
    required this.roundIndex,
    this.seed,
  });

  @override
  List<Object?> get props => [roundIndex, seed];
}
