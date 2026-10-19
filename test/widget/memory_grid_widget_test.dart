import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/app/app.dart';
import 'package:brainforge/app/router.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/features/games/memory_grid/logic/memory_grid_cubit.dart';
import 'package:brainforge/features/games/memory_grid/presentation/memory_grid_screen.dart';
import 'package:brainforge/features/games/memory_grid/presentation/widgets/memory_grid_board.dart';
import 'package:brainforge/features/games/memory_grid/presentation/widgets/memory_grid_tile.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
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

  group('MemoryGrid Widget Tests', () {
    testWidgets(
        'Launching Memory Grid from Games Catalog navigates to game screen',
        (WidgetTester tester) async {
      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // 1. Navigate to Games tab
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();

      // 2. Tap Memory Grid card to open bottom sheet
      await tester.tap(find.text('Memory Grid'));
      await tester.pumpAndSettle();

      // 3. Tap 'Play Memory Grid' button inside modal
      expect(find.text('Play Memory Grid'), findsOneWidget);
      await tester.tap(find.text('Play Memory Grid'));
      await tester.pumpAndSettle();

      // 4. Verify we arrived on Memory Grid screen
      expect(find.text('Memory Grid'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.byType(MemoryGridScreen), findsOneWidget);
    });

    testWidgets('Ready view allows difficulty level adjustment',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MemoryGridScreen(
            fastPreviewForTesting: true,
            initialDifficulty: GameDifficulty(1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Level 1'), findsOneWidget);

      // Tap increment difficulty button (+)
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Level 2'), findsOneWidget);

      // Tap decrement difficulty button (-)
      await tester.tap(find.byIcon(Icons.remove_circle_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Level 1'), findsOneWidget);
    });

    testWidgets(
        'Renders 3x3 grid tiles and handles correct sequence completion',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = MemoryGridCubit(
        attemptRepository: repo,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MemoryGridScreen(
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Start game
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();

      // 2. Step through countdown (3 seconds) deterministically
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();

      // 3. Verify grid is rendered with 9 tiles
      expect(find.byType(MemoryGridBoard), findsOneWidget);
      expect(find.byType(MemoryGridTile), findsNWidgets(9));

      // Tap tiles matching sequence
      final seq = cubit.state.challenge.sequence;
      for (final tileIndex in seq) {
        await tester.tap(find.byKey(ValueKey('tile_$tileIndex')));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // 4. Verify results screen is shown with success state
      expect(find.text('Sequence Mastered!'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);

      // Verify attempt recorded in repository
      final attempts = await repo.getAttempts(gameId: 'memory_grid');
      expect(attempts.length, 1);
      expect(attempts.first.accuracy, 1.0);

      // Tap Play Again
      await tester.tap(find.text('Play Again'));
      await tester.pumpAndSettle();

      // Returns to ready view
      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets('Incorrect tile tap triggers failure results screen',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = MemoryGridCubit(
        attemptRepository: repo,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MemoryGridScreen(
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();

      // Tap wrong tile (identify a tile not equal to sequence[0])
      final firstCorrect = cubit.state.challenge.sequence.first;
      final wrongTileIndex = (firstCorrect + 1) % cubit.state.totalTiles;
      await tester.tap(find.byKey(ValueKey('tile_$wrongTileIndex')));
      await tester.pumpAndSettle();

      expect(find.text('Sequence Missed'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);

      final attempts = await repo.getAttempts(gameId: 'memory_grid');
      expect(attempts.length, 1);
      expect(attempts.first.incorrectCount, 1);
    });

    testWidgets(
        'Exit confirmation dialog shows on back button tap during active play',
        (WidgetTester tester) async {
      final testTicker = ControllableTestTicker();
      final cubit = MemoryGridCubit(
        fastPreviewForTesting: true,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MemoryGridScreen(
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();

      // Tap header exit / back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Exit Memory Grid?'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);

      // Tap Resume to dismiss dialog
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.text('Exit Memory Grid?'), findsNothing);
      expect(find.byType(MemoryGridBoard), findsOneWidget);
    });

    testWidgets('Renders properly in both light and dark themes',
        (WidgetTester tester) async {
      // 1. Dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MemoryGridScreen(fastPreviewForTesting: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Memory Grid'), findsOneWidget);

      // 2. Light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MemoryGridScreen(fastPreviewForTesting: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Memory Grid'), findsOneWidget);
    });

    testWidgets('Responsive on narrow screen without RenderFlex overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MemoryGridScreen(fastPreviewForTesting: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Start Game'), findsOneWidget);
    });
  });
}
