import 'dart:async';
import '../domain/game_attempt.dart';

/// Repository interface for storing and querying game attempt history.
///
/// Phase 2 provides this contract and an [InMemoryGameAttemptRepository] implementation.
/// Phase 4 will provide the persistent SQLite implementation via Drift.
abstract class GameAttemptRepository {
  /// Persists a completed or terminated game attempt.
  Future<void> saveAttempt(GameAttempt attempt);

  /// Retrieves attempts for a specified [gameId], ordered latest first.
  Future<List<GameAttempt>> getAttempts({
    required String gameId,
    int limit = 50,
  });

  /// Retrieves the highest scoring attempt for a given [gameId].
  Future<GameAttempt?> getPersonalBest(String gameId);

  /// Retrieves the [count] most recent attempts for adaptive engine analysis.
  Future<List<GameAttempt>> getRecentAttempts({
    required String gameId,
    int count = 5,
  });

  /// Retrieves all recorded attempts across all games, ordered latest first.
  Future<List<GameAttempt>> getAllAttempts({int limit = 100});

  /// Stream emitting a notification whenever attempts are saved, updated, or cleared.
  Stream<void> get onAttemptsChanged;

  /// Reactive stream of all attempts across all games, ordered latest first.
  Stream<List<GameAttempt>> watchAllAttempts({int limit = 100});

  /// Clears all recorded attempts (used for data wipes or testing).
  Future<void> clearAll();
}

/// In-memory implementation of [GameAttemptRepository] for offline engine testing.
class InMemoryGameAttemptRepository implements GameAttemptRepository {
  final List<GameAttempt> _attempts = [];
  final StreamController<List<GameAttempt>> _updateController =
      StreamController<List<GameAttempt>>.broadcast();
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  @override
  Stream<void> get onAttemptsChanged => _changesController.stream;

  @override
  Future<void> saveAttempt(GameAttempt attempt) async {
    _attempts.add(attempt);
    _updateController.add(List.unmodifiable(_attempts));
    _changesController.add(null);
  }

  @override
  Stream<List<GameAttempt>> watchAllAttempts({int limit = 100}) async* {
    final sorted = List<GameAttempt>.from(_attempts)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    yield sorted.take(limit).toList();
    await for (final list in _updateController.stream) {
      final s = List<GameAttempt>.from(list)
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      yield s.take(limit).toList();
    }
  }

  @override
  Future<List<GameAttempt>> getAttempts({
    required String gameId,
    int limit = 50,
  }) async {
    final filtered = _attempts.where((a) => a.gameId == gameId).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return filtered.take(limit).toList();
  }

  @override
  Future<GameAttempt?> getPersonalBest(String gameId) async {
    final filtered = _attempts.where((a) => a.gameId == gameId).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return filtered.first;
  }

  @override
  Future<List<GameAttempt>> getRecentAttempts({
    required String gameId,
    int count = 5,
  }) async {
    final filtered = _attempts.where((a) => a.gameId == gameId).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return filtered.take(count).toList();
  }

  @override
  Future<List<GameAttempt>> getAllAttempts({int limit = 100}) async {
    final sorted = List<GameAttempt>.from(_attempts)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<void> clearAll() async {
    _attempts.clear();
    _updateController.add(const []);
    _changesController.add(null);
  }
}
