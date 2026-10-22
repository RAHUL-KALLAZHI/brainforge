import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/app/app.dart';
import 'package:brainforge/app/router.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_cubit.dart';
import 'package:brainforge/features/games/reverse_recall/presentation/reverse_recall_screen.dart';
import 'package:brainforge/features/games/reverse_recall/presentation/widgets/reverse_recall_board.dart';
import 'package:brainforge/features/games/reverse_recall/presentation/widgets/reverse_recall_ready_view.dart';
import 'package:brainforge/features/games/reverse_recall/presentation/widgets/reverse_recall_result_view.dart';
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

  group('ReverseRecall Widget Tests', () {
    testWidgets(
        'Launching Reverse Recall from Games Catalog navigates to Reverse Recall screen',
        (WidgetTester tester) async {
      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // 1. Navigate to Games tab
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();

      // 2. Scroll until Reverse Recall card is visible and tap it
      await tester.scrollUntilVisible(find.text('Reverse Recall'), 100);
      await tester.pumpAndSettle();
      expect(find.text('Reverse Recall'), findsOneWidget);
      await tester.tap(find.text('Reverse Recall'));
      await tester.pumpAndSettle();

      // 3. Tap 'Play Reverse Recall' button in bottom sheet modal
      expect(find.text('Play Reverse Recall'), findsOneWidget);
      await tester.tap(find.text('Play Reverse Recall'));
      await tester.pumpAndSettle();

      // 4. Verify arrived on Reverse Recall screen
      expect(find.byType(ReverseRecallScreen), findsOneWidget);
      expect(find.text('Reverse Recall'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets(
        'Ready view displays instructions, length info, and difficulty level',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ReverseRecallScreen(
            initialDifficulty: GameDifficulty(1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReverseRecallReadyView), findsOneWidget);
      expect(find.text('Reverse Recall'), findsOneWidget);
      expect(find.text('Level 1 · Beginner'), findsWidgets);
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Working Memory'), findsOneWidget);
    });

    testWidgets(
        'Starting game renders presentation view and transitions to recall board with successful completion',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = ReverseRecallCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
        fastPreviewForTesting: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReverseRecallScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tap Start Game
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();

      // 2. Advance through countdown (3, 2, 1)
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();

      // Fast preview should transition quickly to recall
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.byType(ReverseRecallBoard), findsOneWidget);

      final expectedReverse = cubit.state.challenge.expectedReverse;
      expect(expectedReverse.length, equals(3));

      // Tap digits in reverse order using the keypad keys
      for (final digit in expectedReverse) {
        final keyFinder = find.byKey(Key('reverse_recall_key_$digit'));
        expect(keyFinder, findsOneWidget);
        await tester.tap(keyFinder);
        await tester.pump(const Duration(milliseconds: 60));
      }

      await tester.pumpAndSettle();

      // Verify arrived on success result view
      expect(find.byType(ReverseRecallResultView), findsOneWidget);
      expect(find.text('Sequence Inverted!'), findsOneWidget);
      expect(find.text('Return to Game'), findsOneWidget);
    });

    testWidgets('Tapping incorrect digit triggers failure results screen',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = ReverseRecallCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
        fastPreviewForTesting: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReverseRecallScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Start playing directly
      cubit.startPlayingImmediately();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.byType(ReverseRecallBoard), findsOneWidget);

      final expectedFirst = cubit.state.challenge.expectedReverse.first;
      final wrongDigit = expectedFirst == 9 ? 1 : expectedFirst + 1;

      final wrongKeyFinder = find.byKey(Key('reverse_recall_key_$wrongDigit'));
      expect(wrongKeyFinder, findsOneWidget);
      await tester.tap(wrongKeyFinder);
      await tester.pumpAndSettle();

      // Verify arrived on failure result view
      expect(find.byType(ReverseRecallResultView), findsOneWidget);
      expect(find.text('Reverse Order Missed'), findsOneWidget);
    });

    testWidgets(
        'Exit button during active game triggers exit dialog and can be cancelled',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = ReverseRecallCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
        fastPreviewForTesting: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ReverseRecallScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      cubit.startPlayingImmediately();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Tap close button in header
      final exitBtn = find.byKey(const Key('reverse_recall_exit_button'));
      expect(exitBtn, findsOneWidget);
      await tester.tap(exitBtn);
      await tester.pumpAndSettle();

      // Verify exit confirmation dialog
      expect(find.text('Exit Reverse Recall?'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);

      // Cancel exit
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.text('Exit Reverse Recall?'), findsNothing);
      expect(find.byType(ReverseRecallBoard), findsOneWidget);
    });
  });
}
