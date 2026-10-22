import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:brainforge/core/database/app_database.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_cubit.dart';
import 'package:brainforge/features/games/shared/data/adaptive_difficulty_repository.dart';
import 'package:brainforge/features/games/shared/data/drift_adaptive_difficulty_repository.dart';
import 'package:brainforge/features/games/shared/data/drift_game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_action.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/domain/player_game_profile.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_policy.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';

void main() {
  group('Reverse Recall Adaptive Difficulty Integration Tests', () {
    late InMemoryGameAttemptRepository attemptRepo;
    late InMemoryAdaptiveDifficultyRepository diffRepo;
    late AdaptiveDifficultyService adaptiveService;
    late ControllableTestTicker testTicker;
    late GameTimer testTimer;

    setUp(() {
      attemptRepo = InMemoryGameAttemptRepository();
      diffRepo = InMemoryAdaptiveDifficultyRepository();
      adaptiveService = AdaptiveDifficultyService(
        attemptRepository: attemptRepo,
        difficultyRepository: diffRepo,
        policy: const AdaptiveDifficultyPolicy(),
      );
      testTicker = ControllableTestTicker();
      testTimer = GameTimer(ticker: testTicker);
    });

    GameAttempt createAttempt({
      required String id,
      required String gameId,
      required int difficultyLevel,
      required GameStatus status,
      required double accuracy,
      required DateTime completedAt,
    }) {
      return GameAttempt(
        id: id,
        gameId: gameId,
        difficultyLevel: difficultyLevel,
        status: status,
        finalScore: (accuracy * 1000).round(),
        accuracy: accuracy,
        correctCount: (accuracy * 5).round(),
        incorrectCount: ((1.0 - accuracy) * 5).round(),
        missedCount: 0,
        responseTimesMs: const [400, 500],
        startedAt: completedAt.subtract(const Duration(seconds: 10)),
        completedAt: completedAt,
      );
    }

    test(
        '3 consecutive completed attempts at 100% promote difficulty to Level 2',
        () async {
      final now = DateTime.now();
      await attemptRepo.saveAttempt(createAttempt(
        id: 'rr_1',
        gameId: 'reverse_recall',
        difficultyLevel: 1,
        status: GameStatus.completed,
        accuracy: 1.0,
        completedAt: now.subtract(const Duration(minutes: 5)),
      ));
      await attemptRepo.saveAttempt(createAttempt(
        id: 'rr_2',
        gameId: 'reverse_recall',
        difficultyLevel: 1,
        status: GameStatus.completed,
        accuracy: 1.0,
        completedAt: now.subtract(const Duration(minutes: 3)),
      ));

      final cubit = ReverseRecallCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        timer: testTimer,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
      );
      cubit.startPlayingImmediately();

      // Complete the 3rd attempt
      for (final digit in cubit.state.challenge.expectedReverse) {
        cubit.onDigitEntered(digit);
      }

      await pumpEventQueue();

      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.adaptationDecision?.action, AdaptationAction.promote);
      expect(cubit.state.adaptationDecision?.targetDifficulty.level, 2);

      final profile = await diffRepo.getProfile('reverse_recall');
      expect(profile?.currentDifficulty.level, 2);

      cubit.close();
    });

    test('2 consecutive failures at Level 2 trigger demotion to Level 1',
        () async {
      final now = DateTime.now();
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'reverse_recall',
        currentDifficulty: const GameDifficulty(2),
        updatedAt: now.subtract(const Duration(minutes: 10)),
      ));

      await attemptRepo.saveAttempt(createAttempt(
        id: 'rr_f1',
        gameId: 'reverse_recall',
        difficultyLevel: 2,
        status: GameStatus.failed,
        accuracy: 0.0,
        completedAt: now.subtract(const Duration(minutes: 2)),
      ));

      final cubit = ReverseRecallCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        timer: testTimer,
        initialDifficulty: const GameDifficulty(2),
        initialSeed: 42,
      );
      cubit.startPlayingImmediately();

      // Trigger 2nd failure
      final expectedFirst = cubit.state.challenge.expectedReverse.first;
      final wrongDigit = expectedFirst == 9 ? 1 : expectedFirst + 1;
      cubit.onDigitEntered(wrongDigit);

      await pumpEventQueue();

      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.adaptationDecision?.action, AdaptationAction.demote);
      expect(cubit.state.adaptationDecision?.targetDifficulty.level, 1);

      final profile = await diffRepo.getProfile('reverse_recall');
      expect(profile?.currentDifficulty.level, 1);

      cubit.close();
    });

    test('Reverse Recall difficulty profile is isolated from all other 4 games',
        () async {
      final now = DateTime.now();

      // Seed other games with various profiles
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(6),
        updatedAt: now,
      ));
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'color_echo',
        currentDifficulty: const GameDifficulty(4),
        updatedAt: now,
      ));
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'focus_hunter',
        currentDifficulty: const GameDifficulty(5),
        updatedAt: now,
      ));
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'vanishing_cards',
        currentDifficulty: const GameDifficulty(3),
        updatedAt: now,
      ));

      // Reverse Recall has no profile yet -> baseline 1
      final rrInit =
          await adaptiveService.getEffectiveDifficulty('reverse_recall');
      expect(rrInit.level, 1);

      // Save Reverse Recall profile at Level 2
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'reverse_recall',
        currentDifficulty: const GameDifficulty(2),
        updatedAt: now,
      ));

      // Verify that other game profiles remain completely untouched
      final mgProfile = await diffRepo.getProfile('memory_grid');
      final ceProfile = await diffRepo.getProfile('color_echo');
      final fhProfile = await diffRepo.getProfile('focus_hunter');
      final vcProfile = await diffRepo.getProfile('vanishing_cards');
      final rrProfile = await diffRepo.getProfile('reverse_recall');

      expect(mgProfile?.currentDifficulty.level, 6);
      expect(ceProfile?.currentDifficulty.level, 4);
      expect(fhProfile?.currentDifficulty.level, 5);
      expect(vcProfile?.currentDifficulty.level, 3);
      expect(rrProfile?.currentDifficulty.level, 2);
    });

    test(
        'SQLite Drift persistence isolates Reverse Recall attempts and deserializes properly',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final driftAttemptRepo = DriftGameAttemptRepository(db);
      final driftDiffRepo = DriftAdaptiveDifficultyRepository(db);

      try {
        final now = DateTime.now();

        // Save mixed attempts
        await driftAttemptRepo.saveAttempt(createAttempt(
          id: 'mg_attempt',
          gameId: 'memory_grid',
          difficultyLevel: 2,
          status: GameStatus.completed,
          accuracy: 1.0,
          completedAt: now.subtract(const Duration(minutes: 10)),
        ));
        await driftAttemptRepo.saveAttempt(createAttempt(
          id: 'rr_attempt_1',
          gameId: 'reverse_recall',
          difficultyLevel: 3,
          status: GameStatus.completed,
          accuracy: 1.0,
          completedAt: now.subtract(const Duration(minutes: 5)),
        ));
        await driftAttemptRepo.saveAttempt(createAttempt(
          id: 'rr_attempt_2',
          gameId: 'reverse_recall',
          difficultyLevel: 3,
          status: GameStatus.failed,
          accuracy: 0.5,
          completedAt: now.subtract(const Duration(minutes: 1)),
        ));

        // Fetch specifically for Reverse Recall
        final rrAttempts =
            await driftAttemptRepo.getAttempts(gameId: 'reverse_recall');
        expect(rrAttempts.length, 2);
        expect(rrAttempts.every((a) => a.gameId == 'reverse_recall'), isTrue);
        expect(rrAttempts.map((a) => a.id),
            containsAll(['rr_attempt_1', 'rr_attempt_2']));

        // Fetch specifically for Memory Grid
        final mgAttempts =
            await driftAttemptRepo.getAttempts(gameId: 'memory_grid');
        expect(mgAttempts.length, 1);
        expect(mgAttempts.first.id, 'mg_attempt');

        // Test drift adaptive profile
        await driftDiffRepo.saveProfile(PlayerGameProfile(
          gameId: 'reverse_recall',
          currentDifficulty: const GameDifficulty(3),
          updatedAt: now,
        ));

        final loadedProfile = await driftDiffRepo.getProfile('reverse_recall');
        expect(loadedProfile?.gameId, 'reverse_recall');
        expect(loadedProfile?.currentDifficulty.level, 3);
      } finally {
        await db.close();
      }
    });
  });
}
