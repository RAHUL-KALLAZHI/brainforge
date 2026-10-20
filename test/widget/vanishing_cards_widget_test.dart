import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/app/app.dart';
import 'package:brainforge/app/router.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';
import 'package:brainforge/features/games/vanishing_cards/logic/vanishing_cards_cubit.dart';
import 'package:brainforge/features/games/vanishing_cards/presentation/vanishing_cards_screen.dart';
import 'package:brainforge/features/games/vanishing_cards/presentation/widgets/vanishing_cards_board.dart';
import 'package:brainforge/features/games/vanishing_cards/presentation/widgets/vanishing_cards_ready_view.dart';
import 'package:brainforge/features/games/vanishing_cards/presentation/widgets/vanishing_cards_result_view.dart';
import 'package:brainforge/features/games/vanishing_cards/presentation/widgets/vanishing_cards_tile.dart';
import '../helpers/test_helper.dart';

void main() {
  setUp(() async {
    await initTestDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('VanishingCards Widget Tests', () {
    testWidgets(
        'Launching Vanishing Cards from Games Catalog navigates to Vanishing Cards screen',
        (WidgetTester tester) async {
      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // 1. Navigate to Games tab
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();

      // 2. Scroll until Vanishing Cards card is visible and tap it
      await tester.scrollUntilVisible(find.text('Vanishing Cards'), 100);
      await tester.pumpAndSettle();
      expect(find.text('Vanishing Cards'), findsOneWidget);
      await tester.tap(find.text('Vanishing Cards'));
      await tester.pumpAndSettle();

      // 3. Tap 'Play Vanishing Cards' button in bottom sheet modal
      expect(find.text('Play Vanishing Cards'), findsOneWidget);
      await tester.tap(find.text('Play Vanishing Cards'));
      await tester.pumpAndSettle();

      // 4. Verify arrived on Vanishing Cards screen
      expect(find.byType(VanishingCardsScreen), findsOneWidget);
      expect(find.text('Vanishing Cards'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets(
        'Ready view displays instructions, preview metrics, and difficulty level',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const VanishingCardsScreen(
            initialDifficulty: GameDifficulty(1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VanishingCardsReadyView), findsOneWidget);
      expect(find.text('Vanishing Cards'), findsOneWidget);
      expect(find.text('Level 1 · Beginner'), findsWidgets);
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Spatial Recall'), findsOneWidget);
    });

    testWidgets(
        'Starting game renders board, handles preview-to-recall transition, and completes session',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = VanishingCardsCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
        fastPreviewForTesting: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: VanishingCardsScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Start game
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();

      // Countdown active
      expect(cubit.state.sessionState.status, GameStatus.countdown);
      expect(cubit.state.isCountingDown, isTrue);
      expect(cubit.state.isInputAllowed, isFalse);

      // 2. Step through countdown (3 seconds)
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();

      // Fast preview finishes and transitions to recall phase
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Verify board is active in recall phase
      expect(find.byType(VanishingCardsBoard), findsOneWidget);
      expect(
          find.byType(VanishingCardsTile), findsNWidgets(9)); // 3x3 for Level 1
      expect(cubit.state.isInputAllowed, isTrue);
      expect(cubit.state.isPreviewing, isFalse);

      // Recall target cards in sequence
      final targetCards = cubit.state.challenge.targetCards;
      for (final target in targetCards) {
        await tester.tap(
          find.byKey(Key('vanishing_cards_tile_${target.positionIndex}')),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Verify results view shown with victory state
      expect(find.byType(VanishingCardsResultView), findsOneWidget);
      expect(find.text('Cards Recalled!'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Continue · Level 1'), findsOneWidget);

      // Verify attempt recorded in repository
      final attempts = await repo.getAttempts(gameId: 'vanishing_cards');
      expect(attempts.length, 1);
      expect(attempts.first.accuracy, 1.0);
      expect(attempts.first.status, GameStatus.completed);
    });

    testWidgets(
        'Tapping incorrect cards until max errors triggers failure results screen',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = VanishingCardsCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: VanishingCardsScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Start immediately
      cubit.startPlayingImmediately();
      await tester.pumpAndSettle();
      expect(cubit.state.sessionState.status, GameStatus.playing);

      // Tap wrong cards up to max errors (3 for level 1)
      final currentTargetPos =
          cubit.state.challenge.targetCards.first.positionIndex;
      final wrongPositions =
          Iterable<int>.generate(cubit.state.challenge.cards.length)
              .where((pos) => pos != currentTargetPos)
              .take(3)
              .toList();

      for (final pos in wrongPositions) {
        await tester.tap(find.byKey(Key('vanishing_cards_tile_$pos')));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Verify failure result view
      expect(find.byType(VanishingCardsResultView), findsOneWidget);
      expect(find.text('Memory Faded'), findsOneWidget);
      expect(find.text('Play Again · Level 1'), findsOneWidget);
    });

    testWidgets('Exit dialog pauses session and can abandon or resume',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = VanishingCardsCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: VanishingCardsScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      cubit.startPlayingImmediately();
      await tester.pumpAndSettle();

      // Tap exit button in header
      await tester.tap(find.byKey(const Key('vanishing_cards_exit_button')));
      await tester.pumpAndSettle();

      // Dialog is visible and session paused
      expect(find.text('Exit Vanishing Cards?'), findsOneWidget);
      expect(cubit.state.sessionState.status, GameStatus.paused);

      // Tap Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      // Dialog dismissed and resumed
      expect(find.text('Exit Vanishing Cards?'), findsNothing);
      expect(cubit.state.sessionState.status, GameStatus.playing);
    });
  });
}
