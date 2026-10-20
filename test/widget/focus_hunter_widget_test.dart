import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/app/app.dart';
import 'package:brainforge/app/router.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/features/games/focus_hunter/logic/focus_hunter_cubit.dart';
import 'package:brainforge/features/games/focus_hunter/presentation/focus_hunter_screen.dart';
import 'package:brainforge/features/games/focus_hunter/presentation/widgets/focus_hunter_board.dart';
import 'package:brainforge/features/games/focus_hunter/presentation/widgets/focus_hunter_ready_view.dart';
import 'package:brainforge/features/games/focus_hunter/presentation/widgets/focus_hunter_result_view.dart';
import 'package:brainforge/features/games/focus_hunter/presentation/widgets/focus_hunter_tile.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';
import '../helpers/test_helper.dart';

void main() {
  setUp(() async {
    await initTestDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('FocusHunter Widget Tests', () {
    testWidgets(
        'Launching Focus Hunter from Games Catalog navigates to Focus Hunter screen',
        (WidgetTester tester) async {
      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // 1. Navigate to Games tab
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();

      // 2. Scroll until Focus Hunter card is visible and tap it
      await tester.scrollUntilVisible(find.text('Focus Hunter'), 100);
      await tester.pumpAndSettle();
      expect(find.text('Focus Hunter'), findsOneWidget);
      await tester.tap(find.text('Focus Hunter'));
      await tester.pumpAndSettle();

      // 3. Tap 'Play Focus Hunter' button in bottom sheet modal
      expect(find.text('Play Focus Hunter'), findsOneWidget);
      await tester.tap(find.text('Play Focus Hunter'));
      await tester.pumpAndSettle();

      // 4. Verify arrived on Focus Hunter screen
      expect(find.byType(FocusHunterScreen), findsOneWidget);
      expect(find.text('Focus Hunter'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets(
        'Ready view displays instructions, target preview, and difficulty level',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const FocusHunterScreen(
            initialDifficulty: GameDifficulty(1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FocusHunterReadyView), findsOneWidget);
      expect(find.text('Focus Hunter'), findsOneWidget);
      expect(find.text('Level 1 · Beginner'), findsWidgets);
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Selective Attention'), findsOneWidget);
    });

    testWidgets(
        'Starting game renders board, handles correct target taps, and completes session',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = FocusHunterCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FocusHunterScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Start game
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();

      // Input should be gated during countdown
      expect(cubit.state.sessionState.status, GameStatus.countdown);
      expect(cubit.state.isInputAllowed, isFalse);

      // 2. Step through countdown (3 seconds)
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();

      // Verify board is active and tiles rendered
      expect(find.byType(FocusHunterBoard), findsOneWidget);
      expect(find.byType(FocusHunterTile), findsNWidgets(9)); // 3x3 for Level 1
      expect(cubit.state.isInputAllowed, isTrue);

      // Tap the target index
      final targetIdx = cubit.state.challenge.targetIndices.first;
      await tester.tap(find.byKey(Key('focus_hunter_tile_$targetIdx')));
      await tester.pumpAndSettle();

      // Verify results view shown with victory state
      expect(find.byType(FocusHunterResultView), findsOneWidget);
      expect(find.text('Targets Spotted!'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Continue · Level 1'), findsOneWidget);

      // Verify attempt recorded in repository
      final attempts = await repo.getAttempts(gameId: 'focus_hunter');
      expect(attempts.length, 1);
      expect(attempts.first.accuracy, 1.0);
      expect(attempts.first.status, GameStatus.completed);
    });

    testWidgets(
        'Tapping distractors until max errors triggers failure results screen',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = FocusHunterCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FocusHunterScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Start immediately
      cubit.startPlayingImmediately();
      await tester.pumpAndSettle();
      expect(cubit.state.sessionState.status, GameStatus.playing);

      // Tap distractors up to max errors (3 for level 1)
      final distractors =
          Iterable<int>.generate(cubit.state.challenge.items.length)
              .where((i) => !cubit.state.challenge.targetIndices.contains(i))
              .take(3)
              .toList();

      for (final idx in distractors) {
        await tester.tap(find.byKey(Key('focus_hunter_tile_$idx')));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Verify failure result view
      expect(find.byType(FocusHunterResultView), findsOneWidget);
      expect(find.text('Focus Broken'), findsOneWidget);
      expect(find.text('Play Again · Level 1'), findsOneWidget);
    });

    testWidgets('Exit dialog pauses session and can abandon or resume',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = FocusHunterCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: FocusHunterScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      cubit.startPlayingImmediately();
      await tester.pumpAndSettle();

      // Tap exit button in header
      await tester.tap(find.byKey(const Key('focus_hunter_exit_button')));
      await tester.pumpAndSettle();

      // Dialog is visible and session paused
      expect(find.text('Exit Focus Hunter?'), findsOneWidget);
      expect(cubit.state.sessionState.status, GameStatus.paused);

      // Tap Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      // Dialog dismissed and resumed
      expect(find.text('Exit Focus Hunter?'), findsNothing);
      expect(cubit.state.sessionState.status, GameStatus.playing);
    });
  });
}
