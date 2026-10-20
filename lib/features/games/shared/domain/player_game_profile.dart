import 'package:equatable/equatable.dart';
import 'adaptation_action.dart';
import 'game_difficulty.dart';

/// Immutable domain model representing a player's current adaptive profile for a game.
class PlayerGameProfile extends Equatable {
  /// Unique identifier of the game (e.g. 'memory_grid').
  final String gameId;

  /// The player's current effective difficulty level.
  final GameDifficulty currentDifficulty;

  /// The most recent adaptation action applied.
  final AdaptationAction lastAction;

  /// Explainable rationale for the most recent adaptation.
  final String? lastReason;

  /// Timestamp when the profile was last updated.
  final DateTime updatedAt;

  const PlayerGameProfile({
    required this.gameId,
    required this.currentDifficulty,
    this.lastAction = AdaptationAction.insufficientData,
    this.lastReason,
    required this.updatedAt,
  });

  /// Factory creating a default baseline profile for a new game.
  factory PlayerGameProfile.initial(String gameId) {
    return PlayerGameProfile(
      gameId: gameId,
      currentDifficulty: GameDifficulty.baseline,
      lastAction: AdaptationAction.insufficientData,
      lastReason: 'Initial baseline difficulty.',
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy with specified fields updated.
  PlayerGameProfile copyWith({
    GameDifficulty? currentDifficulty,
    AdaptationAction? lastAction,
    String? lastReason,
    DateTime? updatedAt,
  }) {
    return PlayerGameProfile(
      gameId: gameId,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      lastAction: lastAction ?? this.lastAction,
      lastReason: lastReason ?? this.lastReason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        gameId,
        currentDifficulty,
        lastAction,
        lastReason,
        updatedAt,
      ];
}
