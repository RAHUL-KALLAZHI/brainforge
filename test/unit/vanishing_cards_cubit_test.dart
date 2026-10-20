import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/data/adaptive_difficulty_repository.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_policy.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';
import 'package:brainforge/features/games/vanishing_cards/domain/vanishing_cards_config.dart';
import 'package:brainforge/features/games/vanishing_cards/logic/vanishing_cards_cubit.dart';

void main() {
  group('VanishingCardsCubit Unit Tests', () {
    late InMemoryGameAttemptRepository attemptRepo;
    late InMemoryAdaptiveDifficultyRepository diffRepo;
    late ControllableTestTicker testTicker;
    late GameTimer testTimer;

    setUp(() {
      attemptRepo = InMemoryGameAttemptRepository();
      diffRepo = InMemoryAdaptiveDifficultyRepository();
      testTicker = ControllableTestTicker();
      testTimer = GameTimer(ticker: testTicker);
    });

    VanishingCardsCubit createCubit({
      GameDifficulty initialDifficulty = const GameDifficulty(1),
      int? initialSeed = 42,
      AdaptiveDifficultyService? adaptiveService,
    }) {
      return VanishingCardsCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        timer: testTimer,
        initialDifficulty: initialDifficulty,
        initialSeed: initialSeed,
      );
    }

    test('Initial state is correctly initialized in initial status', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(2));

      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.difficulty.level, 2);
      expect(cubit.state.isPreviewing, isFalse);
      expect(cubit.state.isInputAllowed, isFalse);
      expect(cubit.state.isTerminal, isFalse);
      expect(cubit.state.foundCardPositions, isEmpty);
      expect(cubit.state.mistakePositions, isEmpty);
      expect(cubit.state.currentTargetStepIndex, 0);
      expect(cubit.state.cardsToRecallCount, 3);

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
      cubit.onCardTapped(0);
      expect(cubit.state.foundCardPositions, isEmpty);
      expect(cubit.state.mistakePositions, isEmpty);

      // In preview state
      cubit.startGame(countdownSeconds: 3);
      cubit.onCardTapped(0);
      expect(cubit.state.foundCardPositions, isEmpty);
      expect(cubit.state.mistakePositions, isEmpty);

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

    test('Recalling target cards in sequence completes session successfully',
        () async {
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 10,
      );
      cubit.startPlayingImmediately();

      final targetCards = cubit.state.challenge.targetCards;
      expect(targetCards.length, 2);

      for (var i = 0; i < targetCards.length; i++) {
        expect(cubit.state.currentTargetStepIndex, i);
        cubit.onCardTapped(targetCards[i].positionIndex);
      }

      expect(cubit.state.sessionState.status, GameStatus.completed);
      expect(cubit.state.foundCardPositions.length, targetCards.length);
      expect(cubit.state.isTerminal, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);

      // Verify persistence in repository
      final attempts =
          await attemptRepo.getAttempts(gameId: VanishingCardsConfig.gameId);
      expect(attempts.length, equals(1));
      expect(attempts.first.gameId, VanishingCardsConfig.gameId);
      expect(attempts.first.status, GameStatus.completed);
      expect(attempts.first.accuracy, equals(1.0));
      expect(attempts.first.correctCount, equals(targetCards.length));
      expect(attempts.first.incorrectCount, equals(0));

      cubit.close();
    });

    test('Tapping incorrect positions until error limit exceeded fails session',
        () async {
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 10,
      );
      cubit.startPlayingImmediately();

      final maxErrors = cubit.state.challenge.maxErrorsAllowed;
      final currentTargetPos =
          cubit.state.challenge.targetCards.first.positionIndex;
      final incorrectPositions =
          Iterable<int>.generate(cubit.state.challenge.cards.length)
              .where((pos) => pos != currentTargetPos)
              .take(maxErrors + 1)
              .toList();

      for (final pos in incorrectPositions) {
        cubit.onCardTapped(pos);
      }

      expect(cubit.state.sessionState.status, GameStatus.failed);
      expect(cubit.state.mistakePositions.length, maxErrors + 1);
      expect(cubit.state.isTerminal, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);

      // Verify persistence
      final attempts =
          await attemptRepo.getAttempts(gameId: VanishingCardsConfig.gameId);
      expect(attempts.length, equals(1));
      expect(attempts.first.gameId, VanishingCardsConfig.gameId);
      expect(attempts.first.status, GameStatus.failed);

      cubit.close();
    });

    test('Duplicate tap on already found or mistake card is ignored', () {
      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(2),
        initialSeed: 20,
      );
      cubit.startPlayingImmediately();

      final firstTarget = cubit.state.challenge.targetCards[0];
      cubit.onCardTapped(firstTarget.positionIndex);
      expect(
          cubit.state.foundCardPositions, contains(firstTarget.positionIndex));
      expect(cubit.state.currentTargetStepIndex, 1);

      // Tap again on the same position
      cubit.onCardTapped(firstTarget.positionIndex);
      expect(cubit.state.sessionState.status, GameStatus.playing);
      expect(cubit.state.foundCardPositions.length, equals(1));
      expect(cubit.state.currentTargetStepIndex, 1);

      cubit.close();
    });

    test('pause and resume correctly toggle active recall status', () {
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
          await attemptRepo.getAttempts(gameId: VanishingCardsConfig.gameId);
      expect(attempts.length, equals(1));
      expect(attempts.first.status, GameStatus.abandoned);

      cubit.close();
    });

    test('playAgainAtCompletedDifficulty restarts current level', () {
      final cubit = createCubit(initialDifficulty: const GameDifficulty(3));
      cubit.startPlayingImmediately();

      for (final target in cubit.state.challenge.targetCards) {
        cubit.onCardTapped(target.positionIndex);
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

      for (final target in cubit.state.challenge.targetCards) {
        cubit.onCardTapped(target.positionIndex);
      }
      expect(cubit.state.sessionState.status, GameStatus.completed);

      cubit.returnToReadyView();
      expect(cubit.state.sessionState.status, GameStatus.initial);
      expect(cubit.state.foundCardPositions, isEmpty);
      expect(cubit.state.mistakePositions, isEmpty);

      cubit.close();
    });

    test(
        'Adaptive difficulty promotes after qualifying threshold and isolates profile',
        () async {
      final adaptiveService = AdaptiveDifficultyService(
        attemptRepository: attemptRepo,
        difficultyRepository: diffRepo,
        policy: const AdaptiveDifficultyPolicy(),
      );

      final cubit = createCubit(
        initialDifficulty: const GameDifficulty(1),
        adaptiveService: adaptiveService,
      );

      // Play 3 successful games at Level 1
      for (var round = 0; round < 3; round++) {
        cubit.startPlayingImmediately();
        for (final target in cubit.state.challenge.targetCards) {
          cubit.onCardTapped(target.positionIndex);
        }
        expect(cubit.state.sessionState.status, GameStatus.completed);
        await pumpEventQueue();

        if (round < 2) {
          cubit.playAgainAtCompletedDifficulty();
        }
      }

      // Check adaptation decision qualifies for promotion to Level 2
      expect(cubit.state.canProceedToNextLevel, isTrue);
      expect(cubit.state.recommendedDifficulty.level, 2);

      // Proceed to next level
      cubit.proceedToRecommendedLevel();
      expect(cubit.state.difficulty.level, 2);

      // Verify that other games (Memory Grid, Focus Hunter, Color Echo) are unaffected
      final otherAttempts =
          await attemptRepo.getAttempts(gameId: 'memory_grid');
      expect(otherAttempts, isEmpty);

      cubit.close();
    });
  });
}
