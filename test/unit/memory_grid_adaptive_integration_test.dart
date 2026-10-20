import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:brainforge/core/database/app_database.dart';
import 'package:brainforge/features/games/memory_grid/logic/memory_grid_cubit.dart';
import 'package:brainforge/features/games/memory_grid/logic/memory_grid_engine.dart';
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

/// A failing attempt repository for testing failure handling.
class FailingAttemptRepository extends InMemoryGameAttemptRepository {
  @override
  Future<void> saveAttempt(GameAttempt attempt) async {
    throw Exception('Simulated disk I/O error');
  }
}

void main() {
  group('Memory Grid Adaptive Difficulty Integration Tests', () {
    late ControllableTestTicker testTicker;
    late GameTimer testTimer;
    late InMemoryGameAttemptRepository attemptRepo;
    late InMemoryAdaptiveDifficultyRepository diffRepo;
    late AdaptiveDifficultyPolicy policy;
    late AdaptiveDifficultyService adaptiveService;

    setUp(() {
      testTicker = ControllableTestTicker();
      testTimer = GameTimer(ticker: testTicker);
      attemptRepo = InMemoryGameAttemptRepository();
      diffRepo = InMemoryAdaptiveDifficultyRepository();
      policy = const AdaptiveDifficultyPolicy();
      adaptiveService = AdaptiveDifficultyService(
        attemptRepository: attemptRepo,
        difficultyRepository: diffRepo,
        policy: policy,
      );
    });

    MemoryGridCubit createCubit({
      GameDifficulty? initialDifficulty,
      GameAttemptRepository? customAttemptRepo,
    }) {
      return MemoryGridCubit(
        engine: const MemoryGridEngine(),
        attemptRepository: customAttemptRepo ?? attemptRepo,
        adaptiveService: adaptiveService,
        timer: testTimer,
        initialDifficulty: initialDifficulty,
        initialSeed: 1234,
        fastPreviewForTesting: true,
      );
    }

    test(
        'loads persisted effective difficulty when no initialDifficulty provided',
        () async {
      // Seed the profile to Level 4 in database
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(4),
        updatedAt: DateTime.now(),
      ));

      final cubit = createCubit();
      // Allow async _loadAdaptiveDifficulty to resolve
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.difficulty.level, 4);
      cubit.close();
    });

    test(
        '3 consecutive high-accuracy games trigger promotion to Level 2 and update profile',
        () async {
      // Start with clean state (baseline Level 1)
      final cubit1 = createCubit();
      await Future<void>.delayed(Duration.zero);
      expect(cubit1.state.difficulty.level, 1);

      // Play 1st perfect game
      cubit1.completePreviewForTesting();
      for (final tile in cubit1.state.challenge.sequence) {
        cubit1.onTileTapped(tile);
      }
      await pumpEventQueue();
      expect(cubit1.state.sessionState.status, GameStatus.completed);
      // Min 3 required, so action is insufficientData
      expect(cubit1.state.adaptationDecision?.action,
          AdaptationAction.insufficientData);
      cubit1.close();

      // Play 2nd perfect game
      final cubit2 = createCubit();
      await Future<void>.delayed(Duration.zero);
      expect(cubit2.state.difficulty.level, 1);
      cubit2.completePreviewForTesting();
      for (final tile in cubit2.state.challenge.sequence) {
        cubit2.onTileTapped(tile);
      }
      await pumpEventQueue();
      expect(cubit2.state.sessionState.status, GameStatus.completed);
      expect(cubit2.state.adaptationDecision?.action,
          AdaptationAction.insufficientData);
      cubit2.close();

      // Play 3rd perfect game
      final cubit3 = createCubit();
      await Future<void>.delayed(Duration.zero);
      expect(cubit3.state.difficulty.level, 1);
      cubit3.completePreviewForTesting();
      for (final tile in cubit3.state.challenge.sequence) {
        cubit3.onTileTapped(tile);
      }
      await pumpEventQueue();
      expect(cubit3.state.sessionState.status, GameStatus.completed);
      // Now 3 attempts with 100% accuracy -> Promotion!
      expect(cubit3.state.adaptationDecision?.action, AdaptationAction.promote);
      expect(cubit3.state.adaptationDecision?.targetDifficulty.level, 2);
      expect(cubit3.state.adaptationDecision?.hasDifficultyChanged, isTrue);

      // Verify persisted profile in repository was updated to Level 2
      final savedDiff = await diffRepo.getDifficulty('memory_grid');
      expect(savedDiff.level, 2);

      // In result screen, playedDifficulty is 1 and recommended is 2
      expect(cubit3.state.playedDifficulty.level, 1);
      expect(cubit3.state.recommendedDifficulty.level, 2);
      expect(cubit3.state.canProceedToNextLevel, isTrue);

      // Proceed to Next Level starts Level 2
      cubit3.proceedToRecommendedLevel();
      expect(cubit3.state.difficulty.level, 2);
      cubit3.close();

      // Next session automatically starts at Level 2
      final cubit4 = createCubit();
      await Future<void>.delayed(Duration.zero);
      expect(cubit4.state.difficulty.level, 2);
      cubit4.close();
    });

    test('consecutive failures trigger demotion after meeting minimum history',
        () async {
      // Start at Level 3
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(3),
        updatedAt: DateTime.now(),
      ));

      // Attempt 1: Success
      final cubit1 = createCubit();
      await Future<void>.delayed(Duration.zero);
      expect(cubit1.state.difficulty.level, 3);
      cubit1.completePreviewForTesting();
      for (final tile in cubit1.state.challenge.sequence) {
        cubit1.onTileTapped(tile);
      }
      await pumpEventQueue();
      expect(cubit1.state.sessionState.status, GameStatus.completed);
      cubit1.close();

      // Attempt 2: Fail (1st failure)
      final cubit2 = createCubit();
      await Future<void>.delayed(Duration.zero);
      cubit2.completePreviewForTesting();
      final wrongTile2 =
          (cubit2.state.challenge.sequence[0] + 1) % cubit2.state.totalTiles;
      cubit2.onTileTapped(wrongTile2);
      await pumpEventQueue();
      expect(cubit2.state.sessionState.status, GameStatus.failed);
      cubit2.close();

      // Attempt 3: Fail again (2nd consecutive failure, total 3 eligible attempts)
      final cubit3 = createCubit();
      await Future<void>.delayed(Duration.zero);
      cubit3.completePreviewForTesting();
      final wrongTile3 =
          (cubit3.state.challenge.sequence[0] + 1) % cubit3.state.totalTiles;
      cubit3.onTileTapped(wrongTile3);
      await pumpEventQueue();
      expect(cubit3.state.sessionState.status, GameStatus.failed);
      expect(cubit3.state.adaptationDecision?.action, AdaptationAction.demote);
      expect(cubit3.state.adaptationDecision?.targetDifficulty.level, 2);

      // Persisted profile is now Level 2
      final savedDiff = await diffRepo.getDifficulty('memory_grid');
      expect(savedDiff.level, 2);
      cubit3.close();
    });

    test('repository save failure bypasses adaptive evaluation safely',
        () async {
      final failingRepo = FailingAttemptRepository();
      final cubit = createCubit(customAttemptRepo: failingRepo);
      await Future<void>.delayed(Duration.zero);

      cubit.completePreviewForTesting();
      for (final tile in cubit.state.challenge.sequence) {
        cubit.onTileTapped(tile);
      }
      await pumpEventQueue();
      expect(cubit.state.sessionState.status, GameStatus.completed);

      // Adaptation decision should remain null because the attempt could not be verified/persisted
      expect(cubit.state.adaptationDecision, isNull);

      // Repository still holds baseline Level 1
      final profile = await diffRepo.getProfile('memory_grid');
      expect(profile, isNull);
      cubit.close();
    });

    test(
        'attempt is evaluated only once even with redundant taps after completion',
        () async {
      final cubit = createCubit();
      await Future<void>.delayed(Duration.zero);

      cubit.completePreviewForTesting();
      for (final tile in cubit.state.challenge.sequence) {
        cubit.onTileTapped(tile);
      }
      await pumpEventQueue();
      expect(cubit.state.sessionState.status, GameStatus.completed);
      final initialDecision = cubit.state.adaptationDecision;

      // Redundant tap
      cubit.onTileTapped(0);
      await pumpEventQueue();
      expect(cubit.state.adaptationDecision, equals(initialDecision));

      // Attempt count in repository is exactly 1
      final attempts = await attemptRepo.getAttempts(gameId: 'memory_grid');
      expect(attempts.length, 1);
      cubit.close();
    });

    test(
        'pre-existing historical failures outside the qualifying window do not block promotion after 3 consecutive wins',
        () async {
      // Seed 2 old failed attempts (e.g. from prior testing)
      final baseTime = DateTime.now().subtract(const Duration(hours: 1));
      await attemptRepo.saveAttempt(GameAttempt(
        id: 'old_fail_1',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.failed,
        finalScore: 0,
        accuracy: 0.0,
        correctCount: 0,
        incorrectCount: 1,
        missedCount: 1,
        responseTimesMs: const [400],
        startedAt: baseTime.subtract(const Duration(minutes: 5)),
        completedAt: baseTime.subtract(const Duration(minutes: 4)),
      ));
      await attemptRepo.saveAttempt(GameAttempt(
        id: 'old_fail_2',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.failed,
        finalScore: 200,
        accuracy: 0.5,
        correctCount: 1,
        incorrectCount: 1,
        missedCount: 0,
        responseTimesMs: const [400, 500],
        startedAt: baseTime.subtract(const Duration(minutes: 3)),
        completedAt: baseTime.subtract(const Duration(minutes: 2)),
      ));

      // Play 3 consecutive perfect games now
      for (int i = 1; i <= 3; i++) {
        final cubit = createCubit();
        await Future<void>.delayed(Duration.zero);
        cubit.completePreviewForTesting();
        for (final tile in cubit.state.challenge.sequence) {
          cubit.onTileTapped(tile);
        }
        await pumpEventQueue();

        if (i < 3) {
          // Games 1 & 2 do not promote
          expect(cubit.state.adaptationDecision?.action,
              isNot(AdaptationAction.promote));
        } else {
          // Game 3 triggers promotion despite older historical failures!
          expect(
              cubit.state.adaptationDecision?.action, AdaptationAction.promote);
          expect(cubit.state.adaptationDecision?.targetDifficulty.level, 2);
        }
        cubit.close();
      }

      // Verify persisted profile is updated to Level 2
      final savedDiff = await diffRepo.getDifficulty('memory_grid');
      expect(savedDiff.level, 2);
    });

    test(
        'end-to-end SQLite promotion flow with Drift repositories preserves Level 2 across restart',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final driftAttemptRepo = DriftGameAttemptRepository(db);
      final driftDiffRepo = DriftAdaptiveDifficultyRepository(db);
      final driftService = AdaptiveDifficultyService(
        attemptRepository: driftAttemptRepo,
        difficultyRepository: driftDiffRepo,
        policy: const AdaptiveDifficultyPolicy(),
      );

      // Play 3 games with Drift SQLite
      for (int i = 1; i <= 3; i++) {
        final cubit = MemoryGridCubit(
          attemptRepository: driftAttemptRepo,
          adaptiveService: driftService,
          timer: testTimer,
          fastPreviewForTesting: true,
          initialSeed: 200 + i,
        );
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.difficulty.level, 1);

        cubit.completePreviewForTesting();
        for (final tile in cubit.state.challenge.sequence) {
          cubit.onTileTapped(tile);
        }
        await pumpEventQueue();

        if (i < 3) {
          expect(cubit.state.adaptationDecision?.action,
              AdaptationAction.insufficientData);
        } else {
          expect(
              cubit.state.adaptationDecision?.action, AdaptationAction.promote);
          expect(cubit.state.adaptationDecision?.targetDifficulty.level, 2);
        }
        cubit.close();
      }

      // Reopening app with new cubit (no initialDifficulty) reads Level 2 from SQLite
      final restartedCubit = MemoryGridCubit(
        attemptRepository: driftAttemptRepo,
        adaptiveService: driftService,
        timer: testTimer,
        fastPreviewForTesting: true,
      );
      await pumpEventQueue();
      expect(restartedCubit.state.difficulty.level, 2);
      restartedCubit.close();
      await db.close();
    });

    group('Phase 5 Regression: Play Again and Return to Game Lifecycle', () {
      late InMemoryGameAttemptRepository attemptRepo;
      late InMemoryAdaptiveDifficultyRepository diffRepo;
      late AdaptiveDifficultyService adaptiveService;
      late ControllableTestTicker testTicker;
      late GameTimer testTimer;

      GameAttempt createAttempt({
        required String id,
        required int difficultyLevel,
        required GameStatus status,
        required double accuracy,
        required DateTime completedAt,
      }) {
        return GameAttempt(
          id: id,
          gameId: 'memory_grid',
          difficultyLevel: difficultyLevel,
          status: status,
          finalScore: (accuracy * 1000).round(),
          accuracy: accuracy,
          correctCount: accuracy == 1.0 ? 3 : 0,
          incorrectCount: accuracy == 1.0 ? 0 : 1,
          missedCount: 0,
          responseTimesMs: const [400],
          startedAt: completedAt.subtract(const Duration(seconds: 2)),
          completedAt: completedAt,
        );
      }

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

      test(
          'promotion from Level 1 to Level 2 updates active cubit state immediately while preserving result',
          () async {
        final cubit = MemoryGridCubit(
          attemptRepository: attemptRepo,
          adaptiveService: adaptiveService,
          timer: testTimer,
          fastPreviewForTesting: true,
          initialDifficulty: const GameDifficulty(1),
          initialSeed: 100,
        );

        // Record 2 prior qualifying attempts at Level 1
        for (int i = 0; i < 2; i++) {
          await attemptRepo.saveAttempt(createAttempt(
            id: 'prior_$i',
            difficultyLevel: 1,
            status: GameStatus.completed,
            accuracy: 1.0,
            completedAt: DateTime.now().subtract(Duration(minutes: 5 - i)),
          ));
        }

        // Complete 3rd game in active cubit
        cubit.completePreviewForTesting();
        for (final tile in cubit.state.challenge.sequence) {
          cubit.onTileTapped(tile);
        }
        await pumpEventQueue();

        // 1. Result screen retains Level 1 as played difficulty, recommends Level 2
        expect(cubit.state.playedDifficulty.level, 1);
        expect(cubit.state.difficulty.level, 1);
        expect(cubit.state.recommendedDifficulty.level, 2);
        expect(cubit.state.canProceedToNextLevel, isTrue);
        expect(
            cubit.state.adaptationDecision?.action, AdaptationAction.promote);
        expect(cubit.state.adaptationDecision?.targetDifficulty.level, 2);

        // Result and score details preserved until action chosen
        expect(cubit.state.sessionState.result, isNotNull);
        expect(cubit.state.sessionState.result!.score.scaledScore, 1000);
        expect(cubit.state.sessionState.result!.score.accuracy, 1.0);
        expect(cubit.state.challenge.sequence.length,
            3); // previous challenge preserved on result view

        // 2. Play Again repeats the completed Level 1 session
        final attemptsBeforePlayAgain =
            (await attemptRepo.getAttempts(gameId: 'memory_grid')).length;
        cubit.playAgainAtCompletedDifficulty();

        // State immediately transitions to countdown at Level 1 (not Level 2)
        expect(cubit.state.sessionState.status, GameStatus.countdown);
        expect(cubit.state.difficulty.level, 1);
        expect(cubit.state.challenge.sequence.length, 3); // Level 1 has 3 tiles
        expect(cubit.state.adaptationDecision, isNull); // banner cleared
        expect(cubit.state.playerSelections, isEmpty);
        expect(cubit.state.currentStepIndex, 0);

        // 3. Play Again does not create duplicate attempt in repository
        final attemptsAfterPlayAgain =
            (await attemptRepo.getAttempts(gameId: 'memory_grid')).length;
        expect(attemptsAfterPlayAgain, attemptsBeforePlayAgain);

        // 4. Preserves the persisted adaptive profile at Level 2
        final savedProfile = await diffRepo.getProfile('memory_grid');
        expect(savedProfile?.currentDifficulty.level, 2);

        cubit.close();
      });

      test(
          'proceedToRecommendedLevel starts promoted level and does not double-increment profile',
          () async {
        final cubit = MemoryGridCubit(
          attemptRepository: attemptRepo,
          adaptiveService: adaptiveService,
          timer: testTimer,
          fastPreviewForTesting: true,
          initialDifficulty: const GameDifficulty(1),
          initialSeed: 150,
        );

        // 2 prior wins at Level 1
        for (int i = 0; i < 2; i++) {
          await attemptRepo.saveAttempt(createAttempt(
            id: 'p_qual_$i',
            difficultyLevel: 1,
            status: GameStatus.completed,
            accuracy: 1.0,
            completedAt: DateTime.now().subtract(Duration(minutes: 5 - i)),
          ));
        }

        // Win 3 -> Promoted to Level 2
        cubit.completePreviewForTesting();
        for (final tile in cubit.state.challenge.sequence) {
          cubit.onTileTapped(tile);
        }
        await pumpEventQueue();

        expect(cubit.state.canProceedToNextLevel, isTrue);
        expect(cubit.state.playedDifficulty.level, 1);
        expect(cubit.state.recommendedDifficulty.level, 2);

        final attemptsBefore =
            (await attemptRepo.getAttempts(gameId: 'memory_grid')).length;

        // Proceed to Level 2
        cubit.proceedToRecommendedLevel();

        // Session immediately starts at Level 2
        expect(cubit.state.sessionState.status, GameStatus.countdown);
        expect(cubit.state.difficulty.level, 2);
        expect(cubit.state.challenge.sequence.length, 4); // Level 2 has 4 tiles
        expect(cubit.state.adaptationDecision, isNull);

        // No duplicate attempt
        final attemptsAfter =
            (await attemptRepo.getAttempts(gameId: 'memory_grid')).length;
        expect(attemptsAfter, attemptsBefore);

        // Persisted profile is still Level 2 (not incremented again)
        final profile = await diffRepo.getProfile('memory_grid');
        expect(profile?.currentDifficulty.level, 2);

        cubit.close();
      });

      test(
          'second promotion is applied when proceeding to recommended level and winning 3 more games',
          () async {
        final cubit = MemoryGridCubit(
          attemptRepository: attemptRepo,
          adaptiveService: adaptiveService,
          timer: testTimer,
          fastPreviewForTesting: true,
          initialDifficulty: const GameDifficulty(1),
          initialSeed: 200,
        );

        // 2 prior wins at Level 1
        for (int i = 0; i < 2; i++) {
          await attemptRepo.saveAttempt(createAttempt(
            id: 'l1_$i',
            difficultyLevel: 1,
            status: GameStatus.completed,
            accuracy: 1.0,
            completedAt: DateTime.now().subtract(Duration(minutes: 10 - i)),
          ));
        }

        // Win 3 at Level 1 -> Promoted to Level 2
        cubit.completePreviewForTesting();
        for (final tile in cubit.state.challenge.sequence) {
          cubit.onTileTapped(tile);
        }
        await pumpEventQueue();
        expect(cubit.state.canProceedToNextLevel, isTrue);

        // Proceed to Level 2
        cubit.proceedToRecommendedLevel();
        expect(cubit.state.difficulty.level, 2);
        expect(cubit.state.challenge.sequence.length, 4);

        // Complete 1st game at Level 2 with 100% accuracy -> DOES NOT PROMOTE (requires 3 at Level 2!)
        cubit.completePreviewForTesting();
        for (final tile in cubit.state.challenge.sequence) {
          cubit.onTileTapped(tile);
        }
        await pumpEventQueue();
        expect(cubit.state.adaptationDecision?.action,
            AdaptationAction.insufficientData);
        expect(cubit.state.playedDifficulty.level, 2);
        expect(cubit.state.recommendedDifficulty.level, 2);
        expect(cubit.state.qualifyingWinsCount, 1);
        expect(cubit.state.canProceedToNextLevel, isFalse);

        // Continue at Level 2 for game 2
        cubit.playAgainAtCompletedDifficulty();
        expect(cubit.state.difficulty.level, 2);

        // Complete 2nd game at Level 2 with 100% accuracy -> DOES NOT PROMOTE
        cubit.completePreviewForTesting();
        for (final tile in cubit.state.challenge.sequence) {
          cubit.onTileTapped(tile);
        }
        await pumpEventQueue();
        expect(cubit.state.adaptationDecision?.action,
            AdaptationAction.insufficientData);
        expect(cubit.state.playedDifficulty.level, 2);
        expect(cubit.state.recommendedDifficulty.level, 2);
        expect(cubit.state.qualifyingWinsCount, 2);
        expect(cubit.state.canProceedToNextLevel, isFalse);

        // Continue at Level 2 for game 3
        cubit.playAgainAtCompletedDifficulty();
        expect(cubit.state.difficulty.level, 2);

        // Complete 3rd game at Level 2 with 100% accuracy -> NOW PROMOTES TO LEVEL 3!
        cubit.completePreviewForTesting();
        for (final tile in cubit.state.challenge.sequence) {
          cubit.onTileTapped(tile);
        }
        await pumpEventQueue();
        expect(
            cubit.state.adaptationDecision?.action, AdaptationAction.promote);
        expect(cubit.state.adaptationDecision?.targetDifficulty.level, 3);
        expect(cubit.state.playedDifficulty.level, 2);
        expect(cubit.state.recommendedDifficulty.level, 3);
        expect(cubit.state.qualifyingWinsCount, 3);
        expect(cubit.state.canProceedToNextLevel, isTrue);

        // Proceed to Level 3
        cubit.proceedToRecommendedLevel();
        expect(cubit.state.difficulty.level, 3);
        expect(cubit.state.challenge.sequence.length,
            5); // Level 3 sequence length is 5
        expect(cubit.state.sessionState.status, GameStatus.countdown);

        cubit.close();
      });

      test(
          'demotion preserves played difficulty on Play Again and updates ready view recommended level',
          () async {
        // Start profile at Level 2
        await diffRepo.saveProfile(PlayerGameProfile(
          gameId: 'memory_grid',
          currentDifficulty: const GameDifficulty(2),
          updatedAt: DateTime.now(),
        ));

        // 2 prior attempts at Level 2 to satisfy minimum 3 attempts history
        await attemptRepo.saveAttempt(createAttempt(
          id: 'l2_att_1',
          difficultyLevel: 2,
          status: GameStatus.completed,
          accuracy: 0.8,
          completedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ));
        await attemptRepo.saveAttempt(createAttempt(
          id: 'l2_fail_1',
          difficultyLevel: 2,
          status: GameStatus.failed,
          accuracy: 0.0,
          completedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ));

        final cubit = MemoryGridCubit(
          attemptRepository: attemptRepo,
          adaptiveService: adaptiveService,
          timer: testTimer,
          fastPreviewForTesting: true,
          initialDifficulty: const GameDifficulty(2),
          initialSeed: 300,
        );

        // Fail second consecutive game in active session at Level 2
        cubit.completePreviewForTesting();
        final wrongTile =
            (cubit.state.challenge.sequence.first + 1) % cubit.state.totalTiles;
        cubit.onTileTapped(wrongTile);
        await pumpEventQueue();

        // Demotion: played is Level 2, recommended is Level 1, canProceed is false
        expect(cubit.state.adaptationDecision?.action, AdaptationAction.demote);
        expect(cubit.state.adaptationDecision?.targetDifficulty.level, 1);
        expect(cubit.state.playedDifficulty.level, 2);
        expect(cubit.state.recommendedDifficulty.level, 1);
        expect(cubit.state.canProceedToNextLevel, isFalse);

        // Play Again starts Level 2 (replays the difficulty just played)
        cubit.playAgainAtCompletedDifficulty();
        expect(cubit.state.difficulty.level, 2);
        expect(cubit.state.challenge.sequence.length, 4); // Level 2 has 4 tiles
        expect(cubit.state.sessionState.status, GameStatus.countdown);

        cubit.close();
      });

      test(
          'no-promotion scenario repeats played difficulty and ignores proceedToRecommendedLevel',
          () async {
        final cubit = MemoryGridCubit(
          attemptRepository: attemptRepo,
          adaptiveService: adaptiveService,
          timer: testTimer,
          fastPreviewForTesting: true,
          initialDifficulty: const GameDifficulty(1),
          initialSeed: 350,
        );

        // Single win with insufficient history for promotion
        cubit.completePreviewForTesting();
        for (final tile in cubit.state.challenge.sequence) {
          cubit.onTileTapped(tile);
        }
        await pumpEventQueue();

        expect(cubit.state.playedDifficulty.level, 1);
        expect(cubit.state.recommendedDifficulty.level, 1);
        expect(cubit.state.canProceedToNextLevel, isFalse);

        // Attempting to proceed is ignored
        cubit.proceedToRecommendedLevel();
        expect(cubit.state.sessionState.status, GameStatus.completed);

        // Play Again repeats Level 1
        cubit.playAgainAtCompletedDifficulty();
        expect(cubit.state.sessionState.status, GameStatus.countdown);
        expect(cubit.state.difficulty.level, 1);

        cubit.close();
      });

      test(
          'returnToReadyView resets session state to initial and displays latest difficulty',
          () async {
        final cubit = MemoryGridCubit(
          attemptRepository: attemptRepo,
          adaptiveService: adaptiveService,
          timer: testTimer,
          fastPreviewForTesting: true,
          initialDifficulty: const GameDifficulty(1),
          initialSeed: 400,
        );

        // Win 3 games to promote
        for (int i = 0; i < 2; i++) {
          await attemptRepo.saveAttempt(createAttempt(
            id: 'qual_$i',
            difficultyLevel: 1,
            status: GameStatus.completed,
            accuracy: 1.0,
            completedAt: DateTime.now().subtract(Duration(minutes: 5 - i)),
          ));
        }

        cubit.completePreviewForTesting();
        for (final tile in cubit.state.challenge.sequence) {
          cubit.onTileTapped(tile);
        }
        await pumpEventQueue();
        expect(cubit.state.canProceedToNextLevel, isTrue);
        expect(cubit.state.recommendedDifficulty.level, 2);

        // Tapping Return to Game returns to ready view with Level 2
        cubit.returnToReadyView();
        expect(cubit.state.sessionState.status, GameStatus.initial);
        expect(cubit.state.difficulty.level, 2);
        expect(cubit.state.adaptationDecision, isNull);
        expect(cubit.state.playerSelections, isEmpty);

        cubit.close();
      });

      test('overlapping button taps while not terminal are ignored', () async {
        final cubit = MemoryGridCubit(
          attemptRepository: attemptRepo,
          adaptiveService: adaptiveService,
          timer: testTimer,
          fastPreviewForTesting: true,
          initialDifficulty: const GameDifficulty(1),
          initialSeed: 500,
        );

        // While in initial status (not terminal), playAgain and proceed are ignored
        expect(cubit.state.sessionState.status, GameStatus.initial);
        cubit.playAgainAtCompletedDifficulty();
        expect(cubit.state.sessionState.status, GameStatus.initial);

        cubit.proceedToRecommendedLevel();
        expect(cubit.state.sessionState.status, GameStatus.initial);

        cubit.close();
      });
    });
  });
}
