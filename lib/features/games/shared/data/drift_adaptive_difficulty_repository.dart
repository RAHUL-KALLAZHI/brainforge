import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../domain/adaptation_action.dart';
import '../domain/game_difficulty.dart';
import '../domain/player_game_profile.dart';
import 'adaptive_difficulty_repository.dart';

/// Exception thrown when a persistence operation fails in [DriftAdaptiveDifficultyRepository].
class AdaptiveDifficultyRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const AdaptiveDifficultyRepositoryException(this.message, [this.cause]);

  @override
  String toString() =>
      'AdaptiveDifficultyRepositoryException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Drift/SQLite-backed persistent implementation of [AdaptiveDifficultyRepository].
///
/// Ensures adaptive difficulty level adjustments survive application restarts.
class DriftAdaptiveDifficultyRepository
    implements AdaptiveDifficultyRepository {
  final AppDatabase _db;

  DriftAdaptiveDifficultyRepository(this._db);

  @override
  Future<PlayerGameProfile?> getProfile(String gameId) async {
    _validateGameId(gameId);

    try {
      final query = _db.select(_db.playerGameProfiles)
        ..where((tbl) => tbl.gameId.equals(gameId))
        ..limit(1);

      final row = await query.getSingleOrNull();
      return row != null ? _mapEntryToDomain(row) : null;
    } catch (e) {
      throw AdaptiveDifficultyRepositoryException(
        'Failed to fetch profile for game $gameId: $e',
        e,
      );
    }
  }

  @override
  Future<GameDifficulty> getDifficulty(String gameId) async {
    _validateGameId(gameId);

    try {
      final profile = await getProfile(gameId);
      return profile?.currentDifficulty ?? GameDifficulty.baseline;
    } catch (e) {
      if (e is AdaptiveDifficultyRepositoryException) rethrow;
      throw AdaptiveDifficultyRepositoryException(
        'Failed to get difficulty for game $gameId: $e',
        e,
      );
    }
  }

  @override
  Future<void> saveProfile(PlayerGameProfile profile) async {
    _validateGameId(profile.gameId);

    try {
      final companion = _mapDomainToCompanion(profile);
      await _db.into(_db.playerGameProfiles).insert(
            companion,
            mode: InsertMode.insertOrReplace,
          );
    } catch (e) {
      throw AdaptiveDifficultyRepositoryException(
        'Failed to save profile for game ${profile.gameId}: $e',
        e,
      );
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _db.delete(_db.playerGameProfiles).go();
    } catch (e) {
      throw AdaptiveDifficultyRepositoryException(
        'Failed to clear player game profiles: $e',
        e,
      );
    }
  }

  // --- Helpers & Mappers ---

  void _validateGameId(String gameId) {
    if (gameId.trim().isEmpty) {
      throw ArgumentError.value(gameId, 'gameId', 'Game ID must not be empty');
    }
  }

  PlayerGameProfilesCompanion _mapDomainToCompanion(PlayerGameProfile domain) {
    return PlayerGameProfilesCompanion(
      gameId: Value(domain.gameId),
      currentDifficulty: Value(domain.currentDifficulty.level),
      lastAction: Value(domain.lastAction.name),
      lastReason: Value(domain.lastReason),
      updatedAt: Value(domain.updatedAt.toUtc()),
    );
  }

  PlayerGameProfile _mapEntryToDomain(PlayerGameProfileEntry entry) {
    final action = AdaptationAction.values.firstWhere(
      (a) => a.name == entry.lastAction,
      orElse: () => AdaptationAction.insufficientData,
    );

    return PlayerGameProfile(
      gameId: entry.gameId,
      currentDifficulty: GameDifficulty.clamped(entry.currentDifficulty),
      lastAction: action,
      lastReason: entry.lastReason,
      updatedAt: entry.updatedAt.toLocal(),
    );
  }
}
