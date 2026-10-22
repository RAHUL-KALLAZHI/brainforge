import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_challenge.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_config.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_cubit.dart';

void main() {
  group('MindSwitchCubit Unit Tests', () {
    late InMemoryGameAttemptRepository attemptRepo;
    late ControllableTestTicker testTicker;
    late GameTimer testTimer;

    setUp(() {
      attemptRepo = InMemoryGameAttemptRepository();
      testTicker = ControllableTestTicker();
      testTimer = GameTimer(ticker: testTicker);
    });

    MindSwitchCubit createCubit({
      GameDifficulty initialDifficulty = const GameDifficulty(1),
      int? initialSeed = 42,
      bool fastPreview = true,
    }) {
      return MindSwitchCubit(
        attemptRepository: attemptRepo,
        timer: testTimer,
        trialTicker: testTicker,
        initialDifficulty: initialDifficulty,
        seed: initialSeed,
        fastPreviewForTesting: fastPreview,
      );
    }

    test('Initial state is correctly initialized in initial status', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(2));

      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.difficulty.level, 2);
      expect(cubit.state.totalTrials, 12);
      expect(cubit.state.currentTrialIndex, 0);
      expect(cubit.state.mistakeCount, 0);
      expect(cubit.state.correctCount, 0);
      expect(cubit.state.isInputAllowed, isFalse);
      expect(cubit.state.isTerminal, isFalse);

      cubit.close();
    });

    test('startGame initiates countdown', () {
      final cubit = createCubit();

      cubit.startGame(countdownSeconds: 3);
      expect(cubit.state.sessionState.status, GameStatus.countdown);
      expect(cubit.state.isCountingDown, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);

      cubit.close();
    });

    test('Input is rejected when not in active playing status', () {
      final cubit = createCubit();

      cubit.onColorSelected(MindSwitchColor.red);
      expect(cubit.state.currentTrialIndex, 0);
      expect(cubit.state.correctCount, 0);
      expect(cubit.state.mistakeCount, 0);

      cubit.close();
    });

    test('startPlayingImmediately transitions directly to playing state', () {
      final cubit = createCubit();

      cubit.startPlayingImmediately();
      expect(cubit.state.sessionState.status, GameStatus.playing);
      expect(cubit.state.isInputAllowed, isTrue);
      expect(cubit.state.currentTrial, isNotNull);

      cubit.close();
    });

    test('Correct selection increments correctCount and advances trial', () {
      final cubit = createCubit(initialSeed: 12345);
      cubit.startPlayingImmediately();

      final firstTrial = cubit.state.currentTrial!;
      final correctColor = firstTrial.targetColor;

      cubit.onColorSelected(correctColor);

      expect(cubit.state.correctCount, 1);
      expect(cubit.state.mistakeCount, 0);
      expect(cubit.state.currentTrialIndex, 1);
      expect(cubit.state.lastInputCorrect, isTrue);
      expect(cubit.state.lastSelectedColor, equals(correctColor));

      cubit.close();
    });

    test('Incorrect selection increments mistakeCount and tolerates mistakes',
        () {
      // Level 1 allows 3 mistakes
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 12345,
      );
      cubit.startPlayingImmediately();

      final firstTrial = cubit.state.currentTrial!;
      // Pick a color that is not the target color
      final wrongColor =
          MindSwitchColor.values.firstWhere((c) => c != firstTrial.targetColor);

      cubit.onColorSelected(wrongColor);

      expect(cubit.state.mistakeCount, 1);
      expect(cubit.state.correctCount, 0);
      expect(cubit.state.lastInputCorrect, isFalse);
      expect(cubit.state.currentTrialIndex, 1);
      expect(cubit.state.sessionState.status, GameStatus.playing);

      cubit.close();
    });

    test('Exceeding max mistakes fails the game session', () {
      // Level 1 allows 3 mistakes; 4th mistake fails
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 999,
      );
      cubit.startPlayingImmediately();

      for (var i = 0; i < 4; i++) {
        final trial = cubit.state.currentTrial!;
        final wrongColor =
            MindSwitchColor.values.firstWhere((c) => c != trial.targetColor);
        cubit.onColorSelected(wrongColor);
      }

      expect(cubit.state.mistakeCount, 4);
      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.isTerminal, isTrue);

      cubit.close();
    });

    test('Completing all trials completes session and saves attempt', () async {
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 888,
      );
      cubit.startPlayingImmediately();

      final totalTrials = cubit.state.totalTrials;
      for (var i = 0; i < totalTrials; i++) {
        final trial = cubit.state.currentTrial!;
        cubit.onColorSelected(trial.targetColor);
      }

      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.correctCount, totalTrials);
      expect(cubit.state.mistakeCount, 0);
      expect(cubit.state.result?.score.scaledScore, greaterThan(0));

      // Verify attempt persistence
      final attempts =
          await attemptRepo.getAttempts(gameId: MindSwitchConfig.gameId);
      expect(attempts.length, 1);
      expect(attempts.first.status, GameStatus.completed);
      expect(attempts.first.correctCount, totalTrials);

      cubit.close();
    });

    test('Pause and resume toggle state correctly', () {
      final cubit = createCubit();
      cubit.startPlayingImmediately();

      cubit.pause();
      expect(cubit.state.sessionState.status, GameStatus.paused);
      expect(cubit.state.isInputAllowed, isFalse);

      cubit.resume();
      expect(cubit.state.sessionState.status, GameStatus.playing);
      expect(cubit.state.isInputAllowed, isTrue);

      cubit.close();
    });

    test('Exit dialog and abandon session records abandoned attempt', () async {
      final cubit = createCubit();
      cubit.startPlayingImmediately();

      cubit.requestExit();
      expect(cubit.state.isExitDialogOpen, isTrue);

      cubit.confirmExit();
      expect(cubit.state.isExitDialogOpen, isFalse);
      expect(cubit.state.sessionState.status, GameStatus.abandoned);

      final attempts =
          await attemptRepo.getAttempts(gameId: MindSwitchConfig.gameId);
      expect(attempts.length, 1);
      expect(attempts.first.status, GameStatus.abandoned);

      cubit.close();
    });
  });
}
