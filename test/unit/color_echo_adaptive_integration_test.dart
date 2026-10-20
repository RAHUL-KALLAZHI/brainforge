import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:brainforge/core/database/app_database.dart';
import 'package:brainforge/features/games/color_echo/logic/color_echo_cubit.dart';
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
  group('Color Echo Adaptive Difficulty Integration Tests', () {
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

    test('Color Echo profile is completely isolated from Memory Grid profile',
        () async {
      // Memory Grid is at Level 4
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(4),
        updatedAt: DateTime.now(),
      ));

      // Color Echo has no profile -> defaults to Level 1
      final ceDifficulty =
          await adaptiveService.getEffectiveDifficulty('color_echo');
      expect(ceDifficulty.level, 1);

      // Save Color Echo profile at Level 2
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'color_echo',
        currentDifficulty: const GameDifficulty(2),
        updatedAt: DateTime.now(),
      ));

      // Verify Memory Grid is still Level 4
      final mgDifficulty =
          await adaptiveService.getEffectiveDifficulty('memory_grid');
      expect(mgDifficulty.level, 4);

      // Verify Color Echo is Level 2
      final ceLoaded =
          await adaptiveService.getEffectiveDifficulty('color_echo');
      expect(ceLoaded.level, 2);
    });

    test('Color Echo attempts do not count towards Memory Grid evaluations',
        () async {
      final now = DateTime.now();

      // Seed 3 perfect Color Echo attempts
      for (var i = 0; i < 3; i++) {
        await attemptRepo.saveAttempt(createAttempt(
          id: 'ce_$i',
          gameId: 'color_echo',
          difficultyLevel: 1,
          status: GameStatus.completed,
          accuracy: 1.0,
          completedAt: now.subtract(Duration(minutes: 5 - i)),
        ));
      }

      // Evaluate Memory Grid at Level 1 (has 0 attempts) -> insufficientData
      final mgDecision = await adaptiveService.evaluateAndPersist(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(1),
      );
      expect(mgDecision.action, AdaptationAction.insufficientData);
      expect(mgDecision.targetDifficulty.level, 1);

      // Evaluate Color Echo at Level 1 (has 3 perfect attempts) -> promote to Level 2!
      final ceDecision = await adaptiveService.evaluateAndPersist(
        gameId: 'color_echo',
        currentDifficulty: const GameDifficulty(1),
      );
      expect(ceDecision.action, AdaptationAction.promote);
      expect(ceDecision.targetDifficulty.level, 2);
    });

    test(
        'Color Echo progression: Games 1 and 2 do not promote, Game 3 promotes to Level 2',
        () async {
      final cubit = ColorEchoCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        timer: testTimer,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 100,
      );

      // --- Game 1 ---
      cubit.completePreviewForTesting();
      for (final pad in cubit.state.challenge.sequence) {
        cubit.onPadTapped(pad);
      }
      await pumpEventQueue();

      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.adaptationDecision?.action,
          AdaptationAction.insufficientData);
      expect(cubit.state.qualifyingWinsCount, 1);
      expect(cubit.state.canProceedToNextLevel, isFalse);
      expect(cubit.state.playedDifficulty.level, 1);
      expect(cubit.state.recommendedDifficulty.level, 1);

      // --- Game 2 ---
      cubit.playAgainAtCompletedDifficulty();
      cubit.completePreviewForTesting();
      for (final pad in cubit.state.challenge.sequence) {
        cubit.onPadTapped(pad);
      }
      await pumpEventQueue();

      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.adaptationDecision?.action,
          AdaptationAction.insufficientData);
      expect(cubit.state.qualifyingWinsCount, 2);
      expect(cubit.state.canProceedToNextLevel, isFalse);

      // --- Game 3 ---
      cubit.playAgainAtCompletedDifficulty();
      cubit.completePreviewForTesting();
      for (final pad in cubit.state.challenge.sequence) {
        cubit.onPadTapped(pad);
      }
      await pumpEventQueue();

      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.adaptationDecision?.action, AdaptationAction.promote);
      expect(cubit.state.qualifyingWinsCount, 3);
      expect(cubit.state.canProceedToNextLevel, isTrue);
      expect(cubit.state.playedDifficulty.level, 1);
      expect(cubit.state.recommendedDifficulty.level, 2);

      // Proceed to Level 2
      cubit.proceedToRecommendedLevel();
      expect(cubit.state.difficulty.level, 2);
      expect(cubit.state.targetSequenceLength, 4); // Level 2 has 4 pads

      // Single win at Level 2 DOES NOT promote to Level 3!
      cubit.completePreviewForTesting();
      for (final pad in cubit.state.challenge.sequence) {
        cubit.onPadTapped(pad);
      }
      await pumpEventQueue();

      expect(cubit.state.adaptationDecision?.action,
          AdaptationAction.insufficientData);
      expect(cubit.state.qualifyingWinsCount, 1);
      expect(cubit.state.canProceedToNextLevel, isFalse);
      expect(cubit.state.playedDifficulty.level, 2);
      expect(cubit.state.recommendedDifficulty.level, 2);

      cubit.close();
    });

    test('Two consecutive failures at Level 2 triggers demotion to Level 1',
        () async {
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'color_echo',
        currentDifficulty: const GameDifficulty(2),
        updatedAt: DateTime.now(),
      ));

      // Seed 1 prior completed attempt and 1 prior failed attempt at Level 2
      final now = DateTime.now();
      await attemptRepo.saveAttempt(createAttempt(
        id: 'ce_prev_1',
        gameId: 'color_echo',
        difficultyLevel: 2,
        status: GameStatus.completed,
        accuracy: 1.0,
        completedAt: now.subtract(const Duration(minutes: 5)),
      ));
      await attemptRepo.saveAttempt(createAttempt(
        id: 'ce_fail_1',
        gameId: 'color_echo',
        difficultyLevel: 2,
        status: GameStatus.failed,
        accuracy: 0.0,
        completedAt: now.subtract(const Duration(minutes: 2)),
      ));

      final cubit = ColorEchoCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        timer: testTimer,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(2),
      );

      // Fail current session at Level 2 (2nd consecutive failure)
      cubit.completePreviewForTesting();
      final wrongPad = (cubit.state.challenge.sequence.first + 1) % 4;
      cubit.onPadTapped(wrongPad);
      await pumpEventQueue();

      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.adaptationDecision?.action, AdaptationAction.demote);
      expect(cubit.state.playedDifficulty.level, 2);
      expect(cubit.state.recommendedDifficulty.level, 1);
      expect(cubit.state.canProceedToNextLevel, isFalse);

      cubit.close();
    });

    test(
        'End-to-end SQLite integration with real Drift database for Color Echo',
        () async {
      final inMemoryExecutor = NativeDatabase.memory();
      final db = AppDatabase(inMemoryExecutor);
      final driftAttemptRepo = DriftGameAttemptRepository(db);
      final driftDiffRepo = DriftAdaptiveDifficultyRepository(db);
      final driftService = AdaptiveDifficultyService(
        attemptRepository: driftAttemptRepo,
        difficultyRepository: driftDiffRepo,
        policy: const AdaptiveDifficultyPolicy(),
      );

      final cubit = ColorEchoCubit(
        attemptRepository: driftAttemptRepo,
        adaptiveService: driftService,
        timer: testTimer,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
      );

      // Win 3 games to promote
      for (var i = 0; i < 3; i++) {
        cubit.completePreviewForTesting();
        for (final pad in cubit.state.challenge.sequence) {
          cubit.onPadTapped(pad);
        }
        await pumpEventQueue();
        if (i < 2) {
          cubit.playAgainAtCompletedDifficulty();
        }
      }

      // Check Drift SQLite persistence
      expect(cubit.state.canProceedToNextLevel, isTrue);
      expect(cubit.state.recommendedDifficulty.level, 2);

      final profile = await driftDiffRepo.getProfile('color_echo');
      expect(profile, isNotNull);
      expect(profile!.currentDifficulty.level, 2);
      expect(profile.lastAction, AdaptationAction.promote);

      final attempts = await driftAttemptRepo.getAttempts(gameId: 'color_echo');
      expect(attempts.length, 3);
      for (final a in attempts) {
        expect(a.gameId, 'color_echo');
        expect(a.difficultyLevel, 1);
        expect(a.accuracy, 1.0);
      }

      cubit.close();
      await db.close();
    });
  });
}
