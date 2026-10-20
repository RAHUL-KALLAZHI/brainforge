import '../domain/game_difficulty.dart';
import '../domain/player_game_profile.dart';

/// Repository interface for persisting and retrieving player game profiles and adaptive difficulty levels.
abstract class AdaptiveDifficultyRepository {
  /// Retrieves the persisted profile for [gameId], or null if not yet recorded.
  Future<PlayerGameProfile?> getProfile(String gameId);

  /// Retrieves the effective [GameDifficulty] for [gameId].
  ///
  /// Returns [GameDifficulty.baseline] (Level 1) if no profile has been saved yet.
  Future<GameDifficulty> getDifficulty(String gameId);

  /// Persists or updates the player's profile for a game.
  Future<void> saveProfile(PlayerGameProfile profile);

  /// Clears all stored game profiles (used for user data wipes or testing).
  Future<void> clearAll();
}

/// In-memory implementation of [AdaptiveDifficultyRepository] for fast, unit test execution.
class InMemoryAdaptiveDifficultyRepository
    implements AdaptiveDifficultyRepository {
  final Map<String, PlayerGameProfile> _profiles = {};

  @override
  Future<PlayerGameProfile?> getProfile(String gameId) async {
    return _profiles[gameId];
  }

  @override
  Future<GameDifficulty> getDifficulty(String gameId) async {
    return _profiles[gameId]?.currentDifficulty ?? GameDifficulty.baseline;
  }

  @override
  Future<void> saveProfile(PlayerGameProfile profile) async {
    _profiles[profile.gameId] = profile;
  }

  @override
  Future<void> clearAll() async {
    _profiles.clear();
  }
}
