import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/focus_hunter/domain/focus_hunter_config.dart';
import 'package:brainforge/features/games/focus_hunter/logic/focus_hunter_cubit.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';

void main() {
  group('FocusHunterCubit Unit Tests', () {
    late InMemoryGameAttemptRepository attemptRepo;
    late ControllableTestTicker testTicker;
    late GameTimer testTimer;

    setUp(() {
      attemptRepo = InMemoryGameAttemptRepository();
      testTicker = ControllableTestTicker();
      testTimer = GameTimer(ticker: testTicker);
    });

    FocusHunterCubit createCubit({
      GameDifficulty initialDifficulty = const GameDifficulty(1),
      int? initialSeed = 42,
    }) {
      return FocusHunterCubit(
        attemptRepository: attemptRepo,
        timer: testTimer,
        initialDifficulty: initialDifficulty,
        initialSeed: initialSeed,
      );
    }

    test('Initial state is correctly initialized in initial status', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(2));

      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.difficulty.level, 2);
      expect(cubit.state.isInputAllowed, isFalse);
      expect(cubit.state.isTerminal, isFalse);
      expect(cubit.state.foundTargetIndices, isEmpty);
      expect(cubit.state.mistakeIndices, isEmpty);
      expect(cubit.state.challenge.targetIndices.length, 2);

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

    test('Input is rejected when not in input phase', () {
      final cubit = createCubit();

      // In initial state
      cubit.onItemTapped(0);
      expect(cubit.state.selectedIndices, isEmpty);
      expect(cubit.state.foundTargetIndices, isEmpty);

      cubit.close();
    });

    test('startPlayingImmediately transitions directly to input allowed', () {
      final cubit = createCubit();

      cubit.startPlayingImmediately();
      expect(cubit.state.sessionState.status, GameStatus.playing);
      expect(cubit.state.isInputAllowed, isTrue);

      cubit.close();
    });

    test('Tapping targets until all found completes session successfully',
        () async {
      final cubit = createCubit(
          initialDifficulty: const GameDifficulty(1), initialSeed: 10);
      cubit.startPlayingImmediately();

      final targetIndices = cubit.state.challenge.targetIndices.toList();
      expect(targetIndices.isNotEmpty, isTrue);

      for (final idx in targetIndices) {
        cubit.onItemTapped(idx);
      }

      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.foundTargetIndices.length, targetIndices.length);
      expect(cubit.state.isTerminal, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);

      // Verify persistence in repository
      final attempts =
          await attemptRepo.getAttempts(gameId: FocusHunterConfig.gameId);
      expect(attempts.length, equals(1));
      expect(attempts.first.gameId, FocusHunterConfig.gameId);
      expect(attempts.first.status, GameStatus.completed);
      expect(attempts.first.accuracy, equals(1.0));
      expect(attempts.first.correctCount, equals(targetIndices.length));
      expect(attempts.first.incorrectCount, equals(0));

      cubit.close();
    });

    test(
        'Tapping distractors until max errors exceeded fails session immediately',
        () async {
      final cubit = createCubit(
          initialDifficulty: const GameDifficulty(1), initialSeed: 10);
      cubit.startPlayingImmediately();

      final maxErrors = cubit.state.challenge.maxErrorsAllowed;
      final distractorIndices =
          Iterable<int>.generate(cubit.state.challenge.items.length)
              .where((i) => !cubit.state.challenge.targetIndices.contains(i))
              .take(maxErrors)
              .toList();

      for (final idx in distractorIndices) {
        cubit.onItemTapped(idx);
      }

      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.mistakeIndices.length, maxErrors);
      expect(cubit.state.isTerminal, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);

      // Verify persistence in repository
      final attempts =
          await attemptRepo.getAttempts(gameId: FocusHunterConfig.gameId);
      expect(attempts.length, equals(1));
      expect(attempts.first.gameId, FocusHunterConfig.gameId);
      expect(attempts.first.status, GameStatus.failed);

      cubit.close();
    });

    test('Duplicate tap on already selected tile is ignored', () {
      final cubit = createCubit(
          initialDifficulty: const GameDifficulty(2), initialSeed: 20);
      cubit.startPlayingImmediately();

      final targetIdx = cubit.state.challenge.targetIndices.first;
      cubit.onItemTapped(targetIdx);
      expect(cubit.state.foundTargetIndices, contains(targetIdx));

      // Tap again on the same tile
      cubit.onItemTapped(targetIdx);
      // Status should still be playing because targetCount is 2 for level 2
      expect(cubit.state.sessionState.status, GameStatus.playing);
      expect(cubit.state.foundTargetIndices.length, equals(1));

      cubit.close();
    });

    test('pause and resume correctly update status', () {
      final cubit = createCubit();
      cubit.startPlayingImmediately();
      expect(cubit.state.sessionState.status, GameStatus.playing);

      cubit.pause();
      expect(cubit.state.sessionState.status, GameStatus.paused);
      expect(cubit.state.isInputAllowed, isFalse);

      cubit.resume();
      expect(cubit.state.sessionState.status, GameStatus.playing);
      expect(cubit.state.isInputAllowed, isTrue);

      cubit.close();
    });

    test('abandonGame terminates session with abandoned status', () async {
      final cubit = createCubit();
      cubit.startPlayingImmediately();

      cubit.abandonGame();
      expect(cubit.state.sessionState.status, GameStatus.abandoned);
      expect(cubit.state.isTerminal, isTrue);

      final attempts =
          await attemptRepo.getAttempts(gameId: FocusHunterConfig.gameId);
      expect(attempts.length, equals(1));
      expect(attempts.first.status, GameStatus.abandoned);

      cubit.close();
    });

    test('playAgainAtCompletedDifficulty replays played level', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(3));
      cubit.startPlayingImmediately();

      for (final idx in cubit.state.challenge.targetIndices) {
        cubit.onItemTapped(idx);
      }
      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.difficulty.level, 3);

      cubit.playAgainAtCompletedDifficulty();
      expect(cubit.state.difficulty.level, 3);
      expect(cubit.state.sessionState.status, GameStatus.countdown);

      cubit.close();
    });

    test('returnToReadyView resets session to initial state', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(2));
      cubit.startPlayingImmediately();

      for (final idx in cubit.state.challenge.targetIndices) {
        cubit.onItemTapped(idx);
      }
      expect(cubit.state.sessionState.status, GameStatus.completed);

      cubit.returnToReadyView();
      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.foundTargetIndices, isEmpty);
      expect(cubit.state.mistakeIndices, isEmpty);

      cubit.close();
    });
  });
}
