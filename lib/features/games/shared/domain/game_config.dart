import 'package:equatable/equatable.dart';
import 'game_difficulty.dart';

/// Exception thrown when game configuration parameters violate constraints.
class GameConfigException implements Exception {
  final String message;
  const GameConfigException(this.message);

  @override
  String toString() => 'GameConfigException: $message';
}

/// Immutable configuration model for parameterized game sessions.
class GameConfig extends Equatable {
  final String gameId;
  final GameDifficulty difficulty;
  final int? gridRows;
  final int? gridColumns;
  final int? sequenceLength;
  final Duration presentationDuration;
  final Duration? responseTimeLimit;
  final int distractorCount;
  final int targetRounds;
  final int? seed;
  final bool allowDuplicates;

  const GameConfig({
    required this.gameId,
    required this.difficulty,
    this.gridRows,
    this.gridColumns,
    this.sequenceLength,
    this.presentationDuration = const Duration(milliseconds: 1000),
    this.responseTimeLimit = const Duration(seconds: 15),
    this.distractorCount = 0,
    this.targetRounds = 1,
    this.seed,
    this.allowDuplicates = false,
  });

  /// Validates all parameters, throwing [GameConfigException] if any constraint is violated.
  void validate() {
    if (gameId.trim().isEmpty) {
      throw const GameConfigException('Game ID cannot be empty.');
    }

    if (difficulty.level < GameDifficulty.minLevel ||
        difficulty.level > GameDifficulty.maxLevel) {
      throw const GameConfigException(
        'Difficulty level must be between ${GameDifficulty.minLevel} and ${GameDifficulty.maxLevel}.',
      );
    }

    if (gridRows != null && gridRows! < 2) {
      throw GameConfigException('gridRows must be at least 2, was $gridRows.');
    }

    if (gridColumns != null && gridColumns! < 2) {
      throw GameConfigException(
        'gridColumns must be at least 2, was $gridColumns.',
      );
    }

    if (!allowDuplicates && gridRows != null && gridColumns != null) {
      final totalTiles = gridRows! * gridColumns!;
      if (sequenceLength != null && sequenceLength! > totalTiles) {
        throw GameConfigException(
          'sequenceLength ($sequenceLength) cannot exceed total tiles ($totalTiles).',
        );
      }
    }

    if (sequenceLength != null && sequenceLength! < 1) {
      throw GameConfigException(
        'sequenceLength must be at least 1, was $sequenceLength.',
      );
    }

    if (presentationDuration <= Duration.zero) {
      throw GameConfigException(
        'presentationDuration must be greater than zero, was $presentationDuration.',
      );
    }

    if (responseTimeLimit != null && responseTimeLimit! <= Duration.zero) {
      throw GameConfigException(
        'responseTimeLimit must be greater than zero, was $responseTimeLimit.',
      );
    }

    if (distractorCount < 0) {
      throw GameConfigException(
        'distractorCount cannot be negative, was $distractorCount.',
      );
    }

    if (targetRounds < 1) {
      throw GameConfigException(
        'targetRounds must be at least 1, was $targetRounds.',
      );
    }
  }

  GameConfig copyWith({
    String? gameId,
    GameDifficulty? difficulty,
    int? gridRows,
    int? gridColumns,
    int? sequenceLength,
    Duration? presentationDuration,
    Duration? responseTimeLimit,
    int? distractorCount,
    int? targetRounds,
    int? seed,
    bool? allowDuplicates,
  }) {
    return GameConfig(
      gameId: gameId ?? this.gameId,
      difficulty: difficulty ?? this.difficulty,
      gridRows: gridRows ?? this.gridRows,
      gridColumns: gridColumns ?? this.gridColumns,
      sequenceLength: sequenceLength ?? this.sequenceLength,
      presentationDuration: presentationDuration ?? this.presentationDuration,
      responseTimeLimit: responseTimeLimit ?? this.responseTimeLimit,
      distractorCount: distractorCount ?? this.distractorCount,
      targetRounds: targetRounds ?? this.targetRounds,
      seed: seed ?? this.seed,
      allowDuplicates: allowDuplicates ?? this.allowDuplicates,
    );
  }

  @override
  List<Object?> get props => [
        gameId,
        difficulty,
        gridRows,
        gridColumns,
        sequenceLength,
        presentationDuration,
        responseTimeLimit,
        distractorCount,
        targetRounds,
        seed,
        allowDuplicates,
      ];
}
