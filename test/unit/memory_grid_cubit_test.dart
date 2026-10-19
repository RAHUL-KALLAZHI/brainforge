import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/memory_grid/logic/memory_grid_cubit.dart';
import 'package:brainforge/features/games/memory_grid/logic/memory_grid_engine.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';

void main() {
  group('MemoryGridCubit Unit Tests', () {
    late ControllableTestTicker testTicker;
    late GameTimer testTimer;
    late InMemoryGameAttemptRepository repo;
    late MemoryGridCubit cubit;

    setUp(() {
      testTicker = ControllableTestTicker();
      testTimer = GameTimer(ticker: testTicker);
      repo = InMemoryGameAttemptRepository();

      cubit = MemoryGridCubit(
        engine: const MemoryGridEngine(),
        attemptRepository: repo,
        timer: testTimer,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 1234,
        fastPreviewForTesting: true,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is configured with Level 1 defaults and idle status',
        () {
      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.difficulty.level, 1);
      expect(cubit.state.config.gridRows, 3);
      expect(cubit.state.config.gridColumns, 3);
      expect(cubit.state.challenge.sequence.length, 3);
      expect(cubit.state.currentStepIndex, 0);
      expect(cubit.state.playerSelections, isEmpty);
      expect(cubit.state.isInputAllowed, isFalse);
    });

    test('startGame triggers countdown and advances correctly', () {
      cubit.startGame(countdownSeconds: 3);
      expect(cubit.state.sessionState.status, GameStatus.countdown);
      expect(cubit.state.sessionState.countdownSecondsRemaining, 3);

      testTicker.step();
      expect(cubit.state.sessionState.countdownSecondsRemaining, 2);
      testTicker.step();
      expect(cubit.state.sessionState.countdownSecondsRemaining, 1);
      testTicker.step();
      // Countdown completed, enters playing (with fastPreviewForTesting completing preview)
      expect(cubit.state.sessionState.status, GameStatus.playing);
    });

    test('input is strictly rejected during non-input phases', () {
      // 1. Initial phase
      cubit.onTileTapped(0);
      expect(cubit.state.currentStepIndex, 0);
      expect(cubit.state.playerSelections, isEmpty);

      // 2. Countdown phase
      cubit.startGame(countdownSeconds: 2);
      cubit.onTileTapped(0);
      expect(cubit.state.currentStepIndex, 0);

      // 3. Paused phase
      testTicker.advanceToCompletion();
      cubit.pause();
      cubit.onTileTapped(0);
      expect(cubit.state.currentStepIndex, 0);
    });

    test(
        'full correct sequence reproduction completes session and saves attempt exactly once',
        () async {
      cubit.completePreviewForTesting();
      expect(cubit.state.isInputAllowed, isTrue);

      final sequence = cubit.state.challenge.sequence;
      expect(sequence.length, 3);

      // Tap first tile correctly
      cubit.onTileTapped(sequence[0]);
      expect(cubit.state.currentStepIndex, 1);
      expect(cubit.state.playerSelections, [sequence[0]]);
      expect(cubit.state.lastInputCorrect, isTrue);
      expect(cubit.state.sessionState.status, GameStatus.playing);

      // Tap second tile correctly
      cubit.onTileTapped(sequence[1]);
      expect(cubit.state.currentStepIndex, 2);
      expect(cubit.state.playerSelections, [sequence[0], sequence[1]]);

      // Tap final tile correctly
      cubit.onTileTapped(sequence[2]);
      expect(cubit.state.currentStepIndex, 3);
      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.result, isNotNull);
      expect(cubit.state.result!.score.scaledScore, greaterThan(0));
      expect(cubit.state.result!.score.accuracy, 1.0);

      // Check attempt was saved to repository exactly once
      final attempts = await repo.getAttempts(gameId: 'memory_grid');
      expect(attempts.length, 1);
      expect(attempts.first.finalScore, cubit.state.result!.score.scaledScore);
      expect(attempts.first.accuracy, 1.0);

      // Redundant taps after completion are rejected
      cubit.onTileTapped(sequence[0]);
      expect(cubit.state.playerSelections.length, 3);
      final attemptsAfter = await repo.getAttempts(gameId: 'memory_grid');
      expect(attemptsAfter.length, 1);
    });

    test('incorrect tile selection fails session and saves failed attempt',
        () async {
      cubit.completePreviewForTesting();
      final sequence = cubit.state.challenge.sequence;

      // Identify an incorrect tile
      final wrongTile = (sequence[0] + 1) % cubit.state.totalTiles;

      cubit.onTileTapped(wrongTile);

      expect(cubit.state.lastInputCorrect, isFalse);
      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.isInputAllowed, isFalse);

      final attempts = await repo.getAttempts(gameId: 'memory_grid');
      expect(attempts.length, 1);
      expect(attempts.first.status, GameStatus.failed);
      expect(attempts.first.incorrectCount, 1);
    });

    test('response timeout fails session and rejects subsequent late input',
        () async {
      cubit.completePreviewForTesting();
      expect(cubit.state.sessionState.status, GameStatus.playing);

      // Advance response window timer to completion
      testTicker.advanceToCompletion();

      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.isInputAllowed, isFalse);

      // Late input should be rejected
      cubit.onTileTapped(cubit.state.challenge.sequence[0]);
      expect(cubit.state.playerSelections, isEmpty);

      final attempts = await repo.getAttempts(gameId: 'memory_grid');
      expect(attempts.length, 1);
      expect(attempts.first.status, GameStatus.failed);
    });

    test('pause and resume toggle input availability', () {
      cubit.completePreviewForTesting();
      expect(cubit.state.isInputAllowed, isTrue);

      cubit.pause();
      expect(cubit.state.sessionState.status, GameStatus.paused);
      expect(cubit.state.isInputAllowed, isFalse);

      cubit.resume();
      expect(cubit.state.sessionState.status, GameStatus.playing);
      expect(cubit.state.isInputAllowed, isTrue);
    });

    test(
        'abandonGame terminates session with 0 score and saves abandoned attempt',
        () async {
      cubit.completePreviewForTesting();
      cubit.abandonGame();

      expect(cubit.state.sessionState.status, GameStatus.abandoned);
      expect(cubit.state.isInputAllowed, isFalse);
      expect(cubit.state.result!.score.scaledScore, 0);

      final attempts = await repo.getAttempts(gameId: 'memory_grid');
      expect(attempts.length, 1);
      expect(attempts.first.status, GameStatus.abandoned);
      expect(attempts.first.finalScore, 0);
    });

    test('restart resets state with fresh challenge and allows replaying', () {
      cubit.completePreviewForTesting();
      cubit.onTileTapped(cubit.state.challenge.sequence[0]);
      expect(cubit.state.playerSelections.length, 1);

      // Restart with Level 2 (4 tiles)
      cubit.restart(difficulty: const GameDifficulty(2), seed: 5555);

      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.difficulty.level, 2);
      expect(cubit.state.challenge.sequence.length, 4);
      expect(cubit.state.playerSelections, isEmpty);
      expect(cubit.state.currentStepIndex, 0);
      expect(cubit.state.result, isNull);
    });
  });
}
