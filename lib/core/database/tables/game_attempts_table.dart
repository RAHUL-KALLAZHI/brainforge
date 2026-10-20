import 'package:drift/drift.dart';

/// Drift table definition for game attempts.
///
/// Stores terminal and historical attempt data for all BrainForge mini-games.
@DataClassName('GameAttemptEntry')
@TableIndex(name: 'idx_game_attempts_game_completed', columns: {#gameId, #completedAt})
@TableIndex(name: 'idx_game_attempts_game_score', columns: {#gameId, #finalScore})
@TableIndex(name: 'idx_game_attempts_completed', columns: {#completedAt})
class GameAttempts extends Table {
  /// Unique attempt identifier (e.g., 'mg_1730000000000_42').
  TextColumn get id => text()();

  /// Identifier of the game (e.g., 'memory_grid').
  TextColumn get gameId => text().withLength(min: 1, max: 64)();

  /// Difficulty level (1 to 5).
  IntColumn get difficultyLevel => integer()();

  /// Completion status (e.g., 'completed', 'failed', 'abandoned', 'timeout').
  TextColumn get status => text().withLength(min: 1, max: 32)();

  /// Final computed score.
  IntColumn get finalScore => integer()();

  /// Accuracy ratio (0.0 to 1.0).
  RealColumn get accuracy => real()();

  /// Count of correct inputs.
  IntColumn get correctCount => integer()();

  /// Count of incorrect inputs.
  IntColumn get incorrectCount => integer()();

  /// Count of missed targets / inputs.
  IntColumn get missedCount => integer()();

  /// JSON-encoded array of response latency measurements in milliseconds.
  TextColumn get responseTimesMs => text()();

  /// Timestamp when the game session started (stored in UTC).
  DateTimeColumn get startedAt => dateTime()();

  /// Timestamp when the game session completed or terminated (stored in UTC).
  DateTimeColumn get completedAt => dateTime()();

  /// Deterministic generation seed, if specified.
  IntColumn get seed => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
