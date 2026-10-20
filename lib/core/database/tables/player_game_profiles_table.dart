import 'package:drift/drift.dart';

/// Drift table definition for storing player game profiles and adaptive difficulty levels.
@DataClassName('PlayerGameProfileEntry')
class PlayerGameProfiles extends Table {
  /// Unique identifier of the game (e.g., 'memory_grid').
  TextColumn get gameId => text().withLength(min: 1, max: 64)();

  /// The player's current effective difficulty level (1 through 10).
  IntColumn get currentDifficulty => integer()();

  /// The most recent adaptation action applied (e.g. 'promote', 'demote', 'maintain').
  TextColumn get lastAction => text().withLength(min: 1, max: 32)();

  /// Human-readable explainable rationale for the adaptation.
  TextColumn get lastReason => text().nullable()();

  /// Timestamp when this difficulty level was updated (stored in UTC).
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {gameId};
}
