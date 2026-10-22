import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_config.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_cubit.dart';
import 'package:brainforge/features/games/shared/data/adaptive_difficulty_repository.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_action.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_policy.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';

void main() {
  group('Mind Switch Adaptive Difficulty Integration Tests', () {
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
        correctCount: (accuracy * 10).round(),
        incorrectCount: ((1.0 - accuracy) * 10).round(),
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
        id: 'ms_1',
        gameId: MindSwitchConfig.gameId,
        difficultyLevel: 1,
        status: GameStatus.completed,
        accuracy: 1.0,
        completedAt: now.subtract(const Duration(minutes: 5)),
      ));
      await attemptRepo.saveAttempt(createAttempt(
        id: 'ms_2',
        gameId: MindSwitchConfig.gameId,
        difficultyLevel: 1,
        status: GameStatus.completed,
        accuracy: 1.0,
        completedAt: now.subtract(const Duration(minutes: 3)),
      ));

      final cubit = MindSwitchCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        timer: testTimer,
        trialTicker: testTicker,
        initialDifficulty: const GameDifficulty(1),
        seed: 42,
        fastPreviewForTesting: true,
      );
      cubit.startPlayingImmediately();

      // Complete the 3rd attempt
      final totalTrials = cubit.state.totalTrials;
      for (var i = 0; i < totalTrials; i++) {
        final trial = cubit.state.currentTrial!;
        cubit.onColorSelected(trial.targetColor);
      }

      await pumpEventQueue();

      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.adaptationDecision, isNotNull);
      expect(cubit.state.adaptationDecision!.action,
          equals(AdaptationAction.promote));
      expect(cubit.state.adaptationDecision!.targetDifficulty.level, equals(2));
      expect(cubit.state.canProceedToNextLevel, isTrue);

      // Verify that proceeding to next level sets difficulty to level 2
      cubit.proceedToRecommendedLevel();
      expect(cubit.state.difficulty.level, equals(2));

      cubit.close();
    });

    test('Isolated profile persisted under canonical gameId mind_switch',
        () async {
      final now = DateTime.now();
      await attemptRepo.saveAttempt(createAttempt(
        id: 'ms_p1',
        gameId: MindSwitchConfig.gameId,
        difficultyLevel: 1,
        status: GameStatus.completed,
        accuracy: 1.0,
        completedAt: now,
      ));

      final decision = await adaptiveService.evaluateAndPersist(
        gameId: MindSwitchConfig.gameId,
        currentDifficulty: const GameDifficulty(1),
      );
      expect(decision, isNotNull);

      final diff =
          await adaptiveService.getEffectiveDifficulty(MindSwitchConfig.gameId);
      expect(diff.level, equals(1));
    });
  });
}
