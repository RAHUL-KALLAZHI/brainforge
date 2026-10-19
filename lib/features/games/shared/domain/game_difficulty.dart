import 'package:equatable/equatable.dart';

/// Value object representing validated difficulty tiers (levels 1 through 10).
class GameDifficulty extends Equatable implements Comparable<GameDifficulty> {
  static const int minLevel = 1;
  static const int maxLevel = 10;

  final int level;

  const GameDifficulty(this.level)
      : assert(
          level >= minLevel && level <= maxLevel,
          'Difficulty level must be between $minLevel and $maxLevel, was $level',
        );

  /// Factory constructor that clamps arbitrary integers into the valid range [1, 10].
  factory GameDifficulty.clamped(int value) {
    final clamped = value.clamp(minLevel, maxLevel);
    return GameDifficulty(clamped);
  }

  /// Default baseline difficulty level.
  static const GameDifficulty baseline = GameDifficulty(1);

  /// Progresses by [step] levels without exceeding [maxLevel].
  GameDifficulty increase([int step = 1]) {
    return GameDifficulty.clamped(level + step);
  }

  /// Regresses by [step] levels without dropping below [minLevel].
  GameDifficulty decrease([int step = 1]) {
    return GameDifficulty.clamped(level - step);
  }

  /// Human-readable difficulty tier descriptor.
  String get tierName {
    if (level <= 2) return 'Beginner';
    if (level <= 4) return 'Intermediate';
    if (level <= 6) return 'Advanced';
    if (level <= 8) return 'Expert';
    return 'Master';
  }

  @override
  int compareTo(GameDifficulty other) => level.compareTo(other.level);

  @override
  List<Object?> get props => [level];

  @override
  String toString() => 'Level $level ($tierName)';
}
