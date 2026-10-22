import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';
import 'package:brainforge/features/games/reverse_recall/domain/reverse_recall_config.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_cubit.dart';

void main() {
  group('ReverseRecallCubit Unit Tests', () {
    late InMemoryGameAttemptRepository attemptRepo;
    late ControllableTestTicker testTicker;
    late GameTimer testTimer;

    setUp(() {
      attemptRepo = InMemoryGameAttemptRepository();
      testTicker = ControllableTestTicker();
      testTimer = GameTimer(ticker: testTicker);
    });

    ReverseRecallCubit createCubit({
      GameDifficulty initialDifficulty = const GameDifficulty(1),
      int? initialSeed = 42,
      AdaptiveDifficultyService? adaptiveService,
      bool fastPreview = false,
    }) {
      return ReverseRecallCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
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
      expect(cubit.state.targetSequenceLength, 4); // 2 + 2
      expect(cubit.state.isPreviewing, isFalse);
      expect(cubit.state.isInputAllowed, isFalse);
      expect(cubit.state.isTerminal, isFalse);
      expect(cubit.state.playerEntries, isEmpty);
      expect(cubit.state.currentStepIndex, 0);

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

    test('Input is rejected when not in recall phase', () {
      final cubit = createCubit();

      // In initial state
      cubit.onDigitEntered(5);
      expect(cubit.state.playerEntries, isEmpty);

      // In countdown state
      cubit.startGame(countdownSeconds: 3);
      cubit.onDigitEntered(5);
      expect(cubit.state.playerEntries, isEmpty);

      cubit.close();
    });

    test('startPlayingImmediately transitions directly to recall input allowed',
        () {
      final cubit = createCubit();

      cubit.startPlayingImmediately();
      expect(cubit.state.sessionState.status, GameStatus.playing);
      expect(cubit.state.isPreviewing, isFalse);
      expect(cubit.state.isInputAllowed, isTrue);

      cubit.close();
    });

    test(
        'Entering entire sequence in reverse completes game successfully with score and attempt saved',
        () async {
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 100,
      );
      cubit.startPlayingImmediately();

      final expectedReverse = cubit.state.challenge.expectedReverse;
      expect(expectedReverse.length, equals(3));

      for (var i = 0; i < expectedReverse.length; i++) {
        expect(cubit.state.currentStepIndex, equals(i));
        cubit.onDigitEntered(expectedReverse[i]);
      }

      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.isTerminal, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);
      expect(cubit.state.playerEntries, equals(expectedReverse));

      // Check persisted attempt
      final attempts =
          await attemptRepo.getAttempts(gameId: ReverseRecallConfig.gameId);
      expect(attempts.length, equals(1));
      expect(attempts.first.gameId, equals(ReverseRecallConfig.gameId));
      expect(attempts.first.status, equals(GameStatus.completed));
      expect(attempts.first.accuracy, equals(1.0));
      expect(attempts.first.correctCount, equals(3));
      expect(attempts.first.incorrectCount, equals(0));

      cubit.close();
    });

    test('Entering wrong digit immediately fails the game and saves attempt',
        () async {
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 100,
      );
      cubit.startPlayingImmediately();

      final expectedFirst = cubit.state.challenge.expectedReverse.first;
      final wrongDigit = expectedFirst == 9 ? 1 : expectedFirst + 1;

      cubit.onDigitEntered(wrongDigit);

      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.isTerminal, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);
      expect(cubit.state.lastInputCorrect, isFalse);

      final attempts =
          await attemptRepo.getAttempts(gameId: ReverseRecallConfig.gameId);
      expect(attempts.length, equals(1));
      expect(attempts.first.gameId, equals(ReverseRecallConfig.gameId));
      expect(attempts.first.status, equals(GameStatus.failed));
      expect(attempts.first.incorrectCount, equals(1));

      cubit.close();
    });

    test('Subsequent input taps after failure or completion are ignored',
        () async {
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 100,
      );
      cubit.startPlayingImmediately();

      final expectedFirst = cubit.state.challenge.expectedReverse.first;
      final wrongDigit = expectedFirst == 9 ? 1 : expectedFirst + 1;

      cubit.onDigitEntered(wrongDigit);
      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.playerEntries.length, equals(1));

      // Try tapping more digits
      cubit.onDigitEntered(expectedFirst);
      expect(cubit.state.playerEntries.length, equals(1));

      // Ensure no duplicate persistence
      final attempts =
          await attemptRepo.getAttempts(gameId: ReverseRecallConfig.gameId);
      expect(attempts.length, equals(1));

      cubit.close();
    });

    test('Response timer expiration triggers timeout failure and saves attempt',
        () async {
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 200,
      );
      cubit.startPlayingImmediately();

      expect(cubit.state.sessionState.status, GameStatus.playing);

      // Trigger response timer completion
      testTicker.advanceToCompletion();

      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.isTerminal, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);

      final attempts =
          await attemptRepo.getAttempts(gameId: ReverseRecallConfig.gameId);
      expect(attempts.length, equals(1));
      expect(attempts.first.status, equals(GameStatus.failed));

      cubit.close();
    });

    test('pause and resume toggle input availability', () {
      final cubit = createCubit();
      cubit.startPlayingImmediately();
      expect(cubit.state.isInputAllowed, isTrue);

      cubit.pause();
      expect(cubit.state.sessionState.status, GameStatus.paused);
      expect(cubit.state.isInputAllowed, isFalse);

      cubit.resume();
      expect(cubit.state.sessionState.status, GameStatus.playing);
      expect(cubit.state.isInputAllowed, isTrue);

      cubit.close();
    });

    test(
        'abandonGame transitions session to abandoned status without completion score',
        () {
      final cubit = createCubit();
      cubit.startPlayingImmediately();

      cubit.abandonGame();
      expect(cubit.state.sessionState.status, GameStatus.abandoned);
      expect(cubit.state.isTerminal, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);

      cubit.close();
    });

    test('playAgainAtCompletedDifficulty restarts at played level', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(3));
      cubit.startPlayingImmediately();
      cubit.abandonGame();

      expect(cubit.state.sessionState.status, GameStatus.abandoned);

      cubit.playAgainAtCompletedDifficulty();
      expect(cubit.state.sessionState.status, GameStatus.countdown);
      expect(cubit.state.difficulty.level, equals(3));

      cubit.close();
    });

    test('returnToReadyView resets state to initial status', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(2));
      cubit.startPlayingImmediately();
      cubit.abandonGame();

      expect(cubit.state.sessionState.status, GameStatus.abandoned);

      cubit.returnToReadyView();
      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.difficulty.level, equals(2));

      cubit.close();
    });
  });
}
