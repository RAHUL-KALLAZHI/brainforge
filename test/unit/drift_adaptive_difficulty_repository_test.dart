import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/core/database/app_database.dart';
import 'package:brainforge/features/games/shared/data/drift_adaptive_difficulty_repository.dart';
import 'package:brainforge/features/games/shared/data/drift_game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_action.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/domain/player_game_profile.dart';

void main() {
  late AppDatabase db;
  late DriftAdaptiveDifficultyRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAdaptiveDifficultyRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftAdaptiveDifficultyRepository Unit Tests', () {
    test('returns baseline difficulty when no profile exists for game',
        () async {
      final difficulty = await repository.getDifficulty('memory_grid');
      final profile = await repository.getProfile('memory_grid');

      expect(difficulty, equals(GameDifficulty.baseline));
      expect(profile, isNull);
    });

    test('saves and retrieves player profile accurately', () async {
      final profile = PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(3),
        lastAction: AdaptationAction.promote,
        lastReason:
            "Difficulty increased — you're performing consistently well.",
        updatedAt: DateTime(2026, 10, 20, 10, 30),
      );

      await repository.saveProfile(profile);

      final retrieved = await repository.getProfile('memory_grid');
      expect(retrieved, isNotNull);
      expect(retrieved!.gameId, 'memory_grid');
      expect(retrieved.currentDifficulty, const GameDifficulty(3));
      expect(retrieved.lastAction, AdaptationAction.promote);
      expect(retrieved.lastReason, contains('Difficulty increased'));

      final currentDifficulty = await repository.getDifficulty('memory_grid');
      expect(currentDifficulty, const GameDifficulty(3));
    });

    test('updating profile for same gameId replaces existing record', () async {
      final initialProfile = PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(2),
        lastAction: AdaptationAction.maintain,
        lastReason: 'Initial',
        updatedAt: DateTime(2026, 10, 20, 10, 0),
      );
      await repository.saveProfile(initialProfile);

      final updatedProfile = PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(3),
        lastAction: AdaptationAction.promote,
        lastReason: 'Promoted after 5 attempts',
        updatedAt: DateTime(2026, 10, 20, 10, 15),
      );
      await repository.saveProfile(updatedProfile);

      final result = await repository.getProfile('memory_grid');
      expect(result!.currentDifficulty, const GameDifficulty(3));
      expect(result.lastAction, AdaptationAction.promote);
      expect(result.lastReason, 'Promoted after 5 attempts');
    });

    test('different games maintain isolated difficulty profiles', () async {
      await repository.saveProfile(PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(4),
        lastAction: AdaptationAction.promote,
        updatedAt: DateTime(2026, 10, 20, 10, 0),
      ));

      await repository.saveProfile(PlayerGameProfile(
        gameId: 'focus_hunter',
        currentDifficulty: const GameDifficulty(2),
        lastAction: AdaptationAction.demote,
        updatedAt: DateTime(2026, 10, 20, 10, 0),
      ));

      final mgDifficulty = await repository.getDifficulty('memory_grid');
      final fhDifficulty = await repository.getDifficulty('focus_hunter');

      expect(mgDifficulty, const GameDifficulty(4));
      expect(fhDifficulty, const GameDifficulty(2));
    });

    test('clearAll wipes all stored profiles cleanly', () async {
      await repository.saveProfile(PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(5),
        updatedAt: DateTime.now(),
      ));

      await repository.clearAll();

      final profile = await repository.getProfile('memory_grid');
      final difficulty = await repository.getDifficulty('memory_grid');

      expect(profile, isNull);
      expect(difficulty, equals(GameDifficulty.baseline));
    });

    test('empty or whitespace gameId throws ArgumentError', () async {
      expect(
        () => repository.getDifficulty('   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.getProfile(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        'schema migration from version 1 to 2 preserves existing game attempts',
        () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

      // 1. Manually create v1 schema with game_attempts table only
      final executor = NativeDatabase.memory();
      final v1Migrator = AppDatabase(executor);

      // Execute schema v1 creation (game_attempts only)
      await v1Migrator.customStatement('''
        CREATE TABLE IF NOT EXISTS game_attempts (
          id TEXT NOT NULL PRIMARY KEY,
          game_id TEXT NOT NULL,
          difficulty_level INTEGER NOT NULL,
          status TEXT NOT NULL,
          final_score INTEGER NOT NULL,
          accuracy REAL NOT NULL,
          correct_count INTEGER NOT NULL,
          incorrect_count INTEGER NOT NULL,
          missed_count INTEGER NOT NULL,
          response_times_ms TEXT NOT NULL,
          started_at INTEGER NOT NULL,
          completed_at INTEGER NOT NULL,
          seed INTEGER
        );
      ''');
      await v1Migrator.customStatement('PRAGMA user_version = 1;');

      // Insert an attempt in v1
      final attemptRepo = DriftGameAttemptRepository(v1Migrator);
      await attemptRepo.saveAttempt(GameAttempt(
        id: 'v1_attempt',
        gameId: 'memory_grid',
        difficultyLevel: 2,
        status: GameStatus.completed,
        finalScore: 950,
        accuracy: 1.0,
        correctCount: 4,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [400, 500],
        startedAt: DateTime.now().subtract(const Duration(seconds: 15)),
        completedAt: DateTime.now(),
      ));

      // 2. Open with migration strategy to v2
      final v2Db = AppDatabase(executor);
      final m = v2Db.createMigrator();
      await v2Db.migration.onUpgrade(m, 1, 2);

      // Verify existing game attempt from v1 is completely intact
      final v2AttemptRepo = DriftGameAttemptRepository(v2Db);
      final attempts = await v2AttemptRepo.getAttempts(gameId: 'memory_grid');
      expect(attempts, hasLength(1));
      expect(attempts.first.id, 'v1_attempt');
      expect(attempts.first.finalScore, 950);

      // Verify newly added player_game_profiles table is functional
      final v2DiffRepo = DriftAdaptiveDifficultyRepository(v2Db);
      await v2DiffRepo.saveProfile(PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(3),
        lastAction: AdaptationAction.promote,
        lastReason: 'Migration test',
        updatedAt: DateTime.now(),
      ));

      final profile = await v2DiffRepo.getProfile('memory_grid');
      expect(profile, isNotNull);
      expect(profile!.currentDifficulty, const GameDifficulty(3));

      await v2Db.close();
    });
  });
}
