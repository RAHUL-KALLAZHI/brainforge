import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../domain/game_attempt.dart';
import '../domain/game_status.dart';
import 'game_attempt_repository.dart';

/// Exception thrown when a persistence operation fails in [DriftGameAttemptRepository].
class GameAttemptRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const GameAttemptRepositoryException(this.message, [this.cause]);

  @override
  String toString() =>
      'GameAttemptRepositoryException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Drift/SQLite-backed persistent implementation of [GameAttemptRepository].
///
/// Ensures game attempt history, personal bests, and analytics survive app restarts.
class DriftGameAttemptRepository implements GameAttemptRepository {
  final AppDatabase _db;
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  DriftGameAttemptRepository(this._db);

  @override
  Stream<void> get onAttemptsChanged => _changesController.stream;

  @override
  Future<void> saveAttempt(GameAttempt attempt) async {
    _validateAttempt(attempt);

    try {
      final companion = _mapDomainToCompanion(attempt);
      await _db.into(_db.gameAttempts).insert(
            companion,
            mode: InsertMode.insertOrReplace,
          );
      _changesController.add(null);
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw GameAttemptRepositoryException(
        'Failed to save attempt ${attempt.id}: $e',
        e,
      );
    }
  }

  @override
  Future<List<GameAttempt>> getAttempts({
    required String gameId,
    int limit = 50,
  }) async {
    try {
      final query = _db.select(_db.gameAttempts)
        ..where((tbl) => tbl.gameId.equals(gameId))
        ..orderBy([
          (tbl) => OrderingTerm(
              expression: tbl.completedAt, mode: OrderingMode.desc),
          (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
        ])
        ..limit(limit);

      final rows = await query.get();
      return rows.map(_mapEntryToDomain).toList();
    } catch (e) {
      throw GameAttemptRepositoryException(
        'Failed to fetch attempts for game $gameId: $e',
        e,
      );
    }
  }

  @override
  Future<GameAttempt?> getPersonalBest(String gameId) async {
    try {
      final query = _db.select(_db.gameAttempts)
        ..where((tbl) => tbl.gameId.equals(gameId))
        ..orderBy([
          (tbl) =>
              OrderingTerm(expression: tbl.finalScore, mode: OrderingMode.desc),
          (tbl) => OrderingTerm(
              expression: tbl.completedAt, mode: OrderingMode.desc),
          (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
        ])
        ..limit(1);

      final row = await query.getSingleOrNull();
      return row != null ? _mapEntryToDomain(row) : null;
    } catch (e) {
      throw GameAttemptRepositoryException(
        'Failed to fetch personal best for game $gameId: $e',
        e,
      );
    }
  }

  @override
  Future<List<GameAttempt>> getRecentAttempts({
    required String gameId,
    int count = 5,
  }) async {
    return getAttempts(gameId: gameId, limit: count);
  }

  @override
  Future<List<GameAttempt>> getAllAttempts({int limit = 100}) async {
    try {
      final query = _db.select(_db.gameAttempts)
        ..orderBy([
          (tbl) => OrderingTerm(
              expression: tbl.completedAt, mode: OrderingMode.desc),
          (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
        ])
        ..limit(limit);

      final rows = await query.get();
      return rows.map(_mapEntryToDomain).toList();
    } catch (e) {
      throw GameAttemptRepositoryException(
        'Failed to fetch all attempts: $e',
        e,
      );
    }
  }

  /// Reactive stream of attempts for [gameId].
  Stream<List<GameAttempt>> watchAttempts({
    required String gameId,
    int limit = 50,
  }) {
    final query = _db.select(_db.gameAttempts)
      ..where((tbl) => tbl.gameId.equals(gameId))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.completedAt, mode: OrderingMode.desc),
        (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    return query.watch().map((rows) => rows.map(_mapEntryToDomain).toList());
  }

  /// Reactive stream of all attempts across all games.
  @override
  Stream<List<GameAttempt>> watchAllAttempts({int limit = 100}) {
    final query = _db.select(_db.gameAttempts)
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.completedAt, mode: OrderingMode.desc),
        (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    return query.watch().map((rows) => rows.map(_mapEntryToDomain).toList());
  }

  @override
  Future<void> clearAll() async {
    try {
      await _db.delete(_db.gameAttempts).go();
      _changesController.add(null);
    } catch (e) {
      throw GameAttemptRepositoryException(
          'Failed to clear attempt history: $e', e);
    }
  }

  // --- Helpers & Mappers ---

  void _validateAttempt(GameAttempt attempt) {
    if (attempt.id.trim().isEmpty) {
      throw ArgumentError.value(
          attempt.id, 'id', 'Attempt ID must not be empty');
    }
    if (attempt.gameId.trim().isEmpty) {
      throw ArgumentError.value(
        attempt.gameId,
        'gameId',
        'Game ID must not be empty',
      );
    }
    if (attempt.difficultyLevel < 1) {
      throw ArgumentError.value(
        attempt.difficultyLevel,
        'difficultyLevel',
        'Difficulty level must be >= 1',
      );
    }
  }

  GameAttemptsCompanion _mapDomainToCompanion(GameAttempt domain) {
    return GameAttemptsCompanion(
      id: Value(domain.id),
      gameId: Value(domain.gameId),
      difficultyLevel: Value(domain.difficultyLevel),
      status: Value(domain.status.name),
      finalScore: Value(domain.finalScore),
      accuracy: Value(domain.accuracy),
      correctCount: Value(domain.correctCount),
      incorrectCount: Value(domain.incorrectCount),
      missedCount: Value(domain.missedCount),
      responseTimesMs: Value(jsonEncode(domain.responseTimesMs)),
      startedAt: Value(domain.startedAt.toUtc()),
      completedAt: Value(domain.completedAt.toUtc()),
      seed: Value(domain.seed),
    );
  }

  GameAttempt _mapEntryToDomain(GameAttemptEntry entry) {
    List<int> responseTimes = const [];
    if (entry.responseTimesMs.isNotEmpty) {
      try {
        final decoded = jsonDecode(entry.responseTimesMs);
        if (decoded is List) {
          responseTimes = decoded.map((e) => (e as num).toInt()).toList();
        }
      } catch (_) {
        responseTimes = const [];
      }
    }

    final status = GameStatus.values.firstWhere(
      (s) => s.name == entry.status,
      orElse: () => GameStatus.completed,
    );

    return GameAttempt(
      id: entry.id,
      gameId: entry.gameId,
      difficultyLevel: entry.difficultyLevel,
      status: status,
      finalScore: entry.finalScore,
      accuracy: entry.accuracy,
      correctCount: entry.correctCount,
      incorrectCount: entry.incorrectCount,
      missedCount: entry.missedCount,
      responseTimesMs: List.unmodifiable(responseTimes),
      startedAt: entry.startedAt.toLocal(),
      completedAt: entry.completedAt.toLocal(),
      seed: entry.seed,
    );
  }
}
