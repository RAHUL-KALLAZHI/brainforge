import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/color_echo/logic/color_echo_cubit.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';

void main() {
  group('ColorEchoCubit Unit Tests', () {
    late InMemoryGameAttemptRepository attemptRepo;
    late ControllableTestTicker testTicker;
    late GameTimer testTimer;

    setUp(() {
      attemptRepo = InMemoryGameAttemptRepository();
      testTicker = ControllableTestTicker();
      testTimer = GameTimer(ticker: testTicker);
    });

    ColorEchoCubit createCubit({
      GameDifficulty initialDifficulty = const GameDifficulty(1),
      int? initialSeed,
      bool fastPreview = true,
    }) {
      return ColorEchoCubit(
        attemptRepository: attemptRepo,
        timer: testTimer,
        initialDifficulty: initialDifficulty,
        initialSeed: initialSeed,
        fastPreviewForTesting: fastPreview,
      );
    }

    test('Initial state is correctly initialized in initial status', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(2));

      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.difficulty.level, 2);
      expect(cubit.state.isInputAllowed, isFalse);
      expect(cubit.state.isPreviewing, isFalse);
      expect(cubit.state.isTerminal, isFalse);
      expect(cubit.state.targetSequenceLength, 4);
      expect(cubit.state.currentStepIndex, 0);
      expect(cubit.state.playerSelections, isEmpty);

      cubit.close();
    });

    test('startGame initiates countdown before playback', () async {
      final cubit = createCubit();

      cubit.startGame(countdownSeconds: 3);
      expect(cubit.state.sessionState.status, GameStatus.countdown);
      expect(cubit.state.isCountingDown, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);

      cubit.close();
    });

    test('Input is rejected when not in input phase', () {
      final cubit = createCubit();

      expect(cubit.state.isInputAllowed, isFalse);
      cubit.onPadTapped(0);

      expect(cubit.state.currentStepIndex, 0);
      expect(cubit.state.playerSelections, isEmpty);

      cubit.close();
    });

    test('completePreviewForTesting transitions directly to input allowed', () {
      final cubit = createCubit();

      cubit.completePreviewForTesting();
      expect(cubit.state.sessionState.status, GameStatus.playing);
      expect(cubit.state.sessionState.phase, GamePhase.input);
      expect(cubit.state.isInputAllowed, isTrue);

      cubit.close();
    });

    test('Sequential correct pad taps complete session successfully', () async {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(1));
      cubit.completePreviewForTesting();

      final sequence = cubit.state.challenge.sequence;
      expect(sequence.length, 3);

      // Tap pad 1 of 3
      cubit.onPadTapped(sequence[0]);
      expect(cubit.state.currentStepIndex, 1);
      expect(cubit.state.playerSelections, [sequence[0]]);
      expect(cubit.state.lastInputCorrect, isTrue);
      expect(cubit.state.sessionState.status, GameStatus.playing);

      // Tap pad 2 of 3
      cubit.onPadTapped(sequence[1]);
      expect(cubit.state.currentStepIndex, 2);
      expect(cubit.state.playerSelections, [sequence[0], sequence[1]]);
      expect(cubit.state.sessionState.status, GameStatus.playing);

      // Tap pad 3 of 3 (final correct pad)
      cubit.onPadTapped(sequence[2]);
      expect(cubit.state.currentStepIndex, 3);
      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.isTerminal, isTrue);
      expect(cubit.state.result?.score.accuracy, 1.0);

      // Attempt was saved to repository with gameId 'color_echo'
      await pumpEventQueue();
      final attempts = await attemptRepo.getAttempts(gameId: 'color_echo');
      expect(attempts.length, 1);
      expect(attempts.first.gameId, 'color_echo');
      expect(attempts.first.accuracy, 1.0);
      expect(attempts.first.status, GameStatus.completed);

      cubit.close();
    });

    test('Incorrect pad tap fails session immediately', () async {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(1));
      cubit.completePreviewForTesting();

      final sequence = cubit.state.challenge.sequence;
      final wrongPad = (sequence.first + 1) % 4;

      cubit.onPadTapped(wrongPad);

      expect(cubit.state.lastInputCorrect, isFalse);
      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.isTerminal, isTrue);

      await pumpEventQueue();
      final attempts = await attemptRepo.getAttempts(gameId: 'color_echo');
      expect(attempts.length, 1);
      expect(attempts.first.gameId, 'color_echo');
      expect(attempts.first.status, GameStatus.failed);
      expect(attempts.first.incorrectCount, 1);

      cubit.close();
    });

    test('pause and resume correctly update status', () {
      final cubit = createCubit();
      cubit.completePreviewForTesting();

      expect(cubit.state.sessionState.status, GameStatus.playing);

      cubit.pause();
      expect(cubit.state.sessionState.status, GameStatus.paused);
      expect(cubit.state.isInputAllowed, isFalse);

      cubit.resume();
      expect(cubit.state.sessionState.status, GameStatus.playing);

      cubit.close();
    });

    test('abandonGame terminates session with 0 score', () async {
      final cubit = createCubit();
      cubit.completePreviewForTesting();

      cubit.abandonGame();
      expect(cubit.state.sessionState.status, GameStatus.abandoned);

      await pumpEventQueue();
      final attempts = await attemptRepo.getAttempts(gameId: 'color_echo');
      expect(attempts.length, 1);
      expect(attempts.first.status, GameStatus.abandoned);
      expect(attempts.first.finalScore, 0);

      cubit.close();
    });

    test('playAgainAtCompletedDifficulty replays played level', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(3));
      cubit.completePreviewForTesting();
      for (final pad in cubit.state.challenge.sequence) {
        cubit.onPadTapped(pad);
      }
      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.playedDifficulty.level, 3);

      cubit.playAgainAtCompletedDifficulty();

      expect(cubit.state.difficulty.level, 3);
      expect(cubit.state.sessionState.status, GameStatus.countdown);

      cubit.close();
    });

    test('returnToReadyView resets session to initial state', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(2));
      cubit.completePreviewForTesting();
      for (final pad in cubit.state.challenge.sequence) {
        cubit.onPadTapped(pad);
      }
      expect(cubit.state.isTerminal, isTrue);

      cubit.returnToReadyView();
      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.currentStepIndex, 0);
      expect(cubit.state.playerSelections, isEmpty);

      cubit.close();
    });

    test('Restart cancels running preview and prevents race conditions',
        () async {
      // Create cubit with real playback timing
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        fastPreview: false,
      );

      // Start playing
      cubit.startPlayingImmediately();
      expect(cubit.state.isPreviewing, isTrue);

      // Immediately restart
      cubit.restart(difficulty: const GameDifficulty(2));
      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.difficulty.level, 2);

      // Wait out what would have been the preview duration
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Status must still be initial, not mutated by old session callbacks
      expect(cubit.state.sessionState.status, GameStatus.initial);

      cubit.close();
    });
  });
}
