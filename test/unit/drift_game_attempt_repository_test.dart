import 'package:brainforge/core/database/app_database.dart';
import 'package:brainforge/features/games/shared/data/drift_game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftGameAttemptRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftGameAttemptRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  GameAttempt createTestAttempt({
    String id = 'attempt_1',
    String gameId = 'memory_grid',
    int difficultyLevel = 2,
    GameStatus status = GameStatus.completed,
    int finalScore = 1500,
    double accuracy = 0.95,
    int correctCount = 4,
    int incorrectCount = 0,
    int missedCount = 0,
    List<int> responseTimesMs = const [320, 410, 290, 350],
    DateTime? startedAt,
    DateTime? completedAt,
    int? seed = 12345,
  }) {
    final now = DateTime.now();
    return GameAttempt(
      id: id,
      gameId: gameId,
      difficultyLevel: difficultyLevel,
      status: status,
      finalScore: finalScore,
      accuracy: accuracy,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      missedCount: missedCount,
      responseTimesMs: responseTimesMs,
      startedAt: startedAt ?? now.subtract(const Duration(seconds: 10)),
      completedAt: completedAt ?? now,
      seed: seed,
    );
  }

  group('DriftGameAttemptRepository Unit Tests', () {
    test('initial state has empty dataset and returns null for personal best',
        () async {
      final attempts = await repository.getAttempts(gameId: 'memory_grid');
      final allAttempts = await repository.getAllAttempts();
      final pb = await repository.getPersonalBest('memory_grid');

      expect(attempts, isEmpty);
      expect(allAttempts, isEmpty);
      expect(pb, isNull);
    });

    test('saveAttempt and getAttempts preserve full domain data fidelity',
        () async {
      final startTime = DateTime.utc(2026, 10, 19, 10, 0, 0);
      final finishTime = DateTime.utc(2026, 10, 19, 10, 0, 15);
      final attempt = createTestAttempt(
        id: 'mg_001',
        gameId: 'memory_grid',
        difficultyLevel: 3,
        status: GameStatus.completed,
        finalScore: 2450,
        accuracy: 1.0,
        correctCount: 5,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: [250, 310, 280, 400, 220],
        startedAt: startTime,
        completedAt: finishTime,
        seed: 9999,
      );

      await repository.saveAttempt(attempt);

      final retrieved = await repository.getAttempts(gameId: 'memory_grid');
      expect(retrieved.length, equals(1));

      final stored = retrieved.first;
      expect(stored.id, equals('mg_001'));
      expect(stored.gameId, equals('memory_grid'));
      expect(stored.difficultyLevel, equals(3));
      expect(stored.status, equals(GameStatus.completed));
      expect(stored.finalScore, equals(2450));
      expect(stored.accuracy, equals(1.0));
      expect(stored.correctCount, equals(5));
      expect(stored.incorrectCount, equals(0));
      expect(stored.missedCount, equals(0));
      expect(stored.responseTimesMs, equals([250, 310, 280, 400, 220]));
      expect(stored.medianResponseTimeMs, equals(280));
      expect(stored.seed, equals(9999));
    });

    test('preserves failed and abandoned terminal states', () async {
      final failedAttempt = createTestAttempt(
        id: 'fail_1',
        status: GameStatus.failed,
        finalScore: 0,
        accuracy: 0.5,
        correctCount: 2,
        incorrectCount: 1,
      );
      final abandonedAttempt = createTestAttempt(
        id: 'abandon_1',
        status: GameStatus.abandoned,
        finalScore: 0,
      );

      await repository.saveAttempt(failedAttempt);
      await repository.saveAttempt(abandonedAttempt);

      final attempts = await repository.getAttempts(gameId: 'memory_grid');
      expect(attempts.length, equals(2));

      final statuses = attempts.map((a) => a.status).toSet();
      expect(
        statuses,
        containsAll([GameStatus.failed, GameStatus.abandoned]),
      );
    });

    test('validates inputs and throws ArgumentError on invalid parameters',
        () async {
      final emptyId = createTestAttempt(id: '');
      expect(() => repository.saveAttempt(emptyId), throwsArgumentError);

      final emptyGameId = createTestAttempt(gameId: '   ');
      expect(() => repository.saveAttempt(emptyGameId), throwsArgumentError);

      final invalidDifficulty = createTestAttempt(difficultyLevel: 0);
      expect(
          () => repository.saveAttempt(invalidDifficulty), throwsArgumentError);
    });

    test('idempotency: saving attempt with same ID updates without duplicating',
        () async {
      final attempt1 = createTestAttempt(
        id: 'duplicate_test_id',
        finalScore: 1000,
      );
      final attempt2 = createTestAttempt(
        id: 'duplicate_test_id',
        finalScore: 1200,
      );

      await repository.saveAttempt(attempt1);
      await repository.saveAttempt(attempt2);

      final attempts = await repository.getAttempts(gameId: 'memory_grid');
      expect(attempts.length, equals(1));
      expect(attempts.first.finalScore, equals(1200));
    });

    test(
        'deterministic ordering: ordered by completedAt descending and id descending',
        () async {
      final base = DateTime.utc(2026, 10, 19, 12, 0, 0);

      final older = createTestAttempt(
        id: 'id_old',
        completedAt: base.subtract(const Duration(minutes: 5)),
      );
      final newer = createTestAttempt(
        id: 'id_new',
        completedAt: base,
      );
      final sameTimeA = createTestAttempt(
        id: 'id_a',
        completedAt: base,
      );
      final sameTimeZ = createTestAttempt(
        id: 'id_z',
        completedAt: base,
      );

      await repository.saveAttempt(older);
      await repository.saveAttempt(newer);
      await repository.saveAttempt(sameTimeA);
      await repository.saveAttempt(sameTimeZ);

      final results = await repository.getAttempts(gameId: 'memory_grid');
      expect(results.length, equals(4));

      // At base timestamp: id_z, id_new, id_a (descending by id), then older
      expect(results.last.id, equals('id_old'));
      expect(results.first.id, equals('id_z'));
    });

    test('filters accurately by gameId', () async {
      final gridAttempt =
          createTestAttempt(id: 'grid_1', gameId: 'memory_grid');
      final colorEchoAttempt =
          createTestAttempt(id: 'echo_1', gameId: 'color_echo');

      await repository.saveAttempt(gridAttempt);
      await repository.saveAttempt(colorEchoAttempt);

      final gridResults = await repository.getAttempts(gameId: 'memory_grid');
      final echoResults = await repository.getAttempts(gameId: 'color_echo');
      final allResults = await repository.getAllAttempts();

      expect(gridResults.length, equals(1));
      expect(gridResults.first.id, equals('grid_1'));

      expect(echoResults.length, equals(1));
      expect(echoResults.first.id, equals('echo_1'));

      expect(allResults.length, equals(2));
    });

    test('getPersonalBest returns highest score for game and null if none',
        () async {
      expect(await repository.getPersonalBest('memory_grid'), isNull);

      await repository
          .saveAttempt(createTestAttempt(id: 'score_800', finalScore: 800));
      await repository
          .saveAttempt(createTestAttempt(id: 'score_2100', finalScore: 2100));
      await repository
          .saveAttempt(createTestAttempt(id: 'score_1500', finalScore: 1500));

      final pb = await repository.getPersonalBest('memory_grid');
      expect(pb, isNotNull);
      expect(pb!.id, equals('score_2100'));
      expect(pb.finalScore, equals(2100));
    });

    test('getRecentAttempts limits output to requested count', () async {
      for (int i = 1; i <= 10; i++) {
        await repository.saveAttempt(
          createTestAttempt(
            id: 'attempt_$i',
            completedAt: DateTime.utc(2026, 10, 19, 10, i),
          ),
        );
      }

      final recent3 =
          await repository.getRecentAttempts(gameId: 'memory_grid', count: 3);
      expect(recent3.length, equals(3));
      expect(recent3[0].id, equals('attempt_10'));
      expect(recent3[1].id, equals('attempt_9'));
      expect(recent3[2].id, equals('attempt_8'));
    });

    test('clearAll wipes all attempts cleanly', () async {
      await repository.saveAttempt(createTestAttempt(id: 'a1'));
      await repository
          .saveAttempt(createTestAttempt(id: 'a2', gameId: 'color_echo'));

      expect((await repository.getAllAttempts()).length, equals(2));

      await repository.clearAll();

      expect(await repository.getAllAttempts(), isEmpty);
      expect(await repository.getPersonalBest('memory_grid'), isNull);
    });

    test('watchAllAttempts emits updated lists on database insertions',
        () async {
      final stream = repository.watchAllAttempts();

      expect(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
          hasLength(2),
        ]),
      );

      await Future<void>.delayed(Duration.zero);
      await repository.saveAttempt(createTestAttempt(id: 's1'));
      await repository.saveAttempt(createTestAttempt(id: 's2'));
    });

    test('schema version is 2 and table metadata is valid', () {
      expect(db.schemaVersion, equals(2));
      expect(db.gameAttempts.actualTableName, equals('game_attempts'));
      expect(db.gameAttempts.$columns.length, equals(13));
    });
  });
}
