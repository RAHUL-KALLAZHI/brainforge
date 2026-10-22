import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/app/app.dart';
import 'package:brainforge/app/router.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_challenge.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_cubit.dart';
import 'package:brainforge/features/games/mind_switch/presentation/mind_switch_screen.dart';
import 'package:brainforge/features/games/mind_switch/presentation/widgets/mind_switch_board.dart';
import 'package:brainforge/features/games/mind_switch/presentation/widgets/mind_switch_header.dart';
import 'package:brainforge/features/games/mind_switch/presentation/widgets/mind_switch_ready_view.dart';
import 'package:brainforge/features/games/mind_switch/presentation/widgets/mind_switch_result_view.dart';
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

  group('MindSwitch Widget Tests', () {
    testWidgets(
        'Launching Mind Switch from Games Catalog navigates to Mind Switch screen',
        (WidgetTester tester) async {
      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // 1. Navigate to Games tab
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();

      // 2. Scroll until Mind Switch card is visible and tap it
      await tester.scrollUntilVisible(find.text('Mind Switch'), 100);
      await tester.pumpAndSettle();
      expect(find.text('Mind Switch'), findsOneWidget);
      await tester.tap(find.text('Mind Switch'));
      await tester.pumpAndSettle();

      // 3. Tap 'Play Mind Switch' button in bottom sheet modal
      expect(find.text('Play Mind Switch'), findsOneWidget);
      await tester.tap(find.text('Play Mind Switch'));
      await tester.pumpAndSettle();

      // 4. Verify arrived on Mind Switch screen
      expect(find.byType(MindSwitchScreen), findsOneWidget);
      expect(find.text('Mind Switch'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets(
        'Ready view displays instructions, multi-sensory options, and difficulty level',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MindSwitchScreen(
            initialDifficulty: const GameDifficulty(1),
            attemptRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MindSwitchReadyView), findsOneWidget);
      expect(find.text('Mind Switch'), findsOneWidget);
      expect(find.text('Cognitive Flexibility'), findsOneWidget);
      expect(find.text('How to Play'), findsOneWidget);
      expect(find.text('Multi-Sensory Options'), findsOneWidget);
      expect(find.text('Red'), findsWidgets);
      expect(find.text('Blue'), findsWidgets);
      expect(find.text('Green'), findsWidgets);
      expect(find.text('Yellow'), findsWidgets);
      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets(
        'Starting game renders countdown, header, board, and allows color selection to completion',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = MindSwitchCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        seed: 42,
        timer: GameTimer(ticker: testTicker),
        trialTicker: testTicker,
        fastPreviewForTesting: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MindSwitchScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tap Start Game
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();

      // 2. Advance countdown ticks
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Board and header are visible
      expect(find.byType(MindSwitchHeader), findsOneWidget);
      expect(find.byType(MindSwitchBoard), findsOneWidget);

      // Play through all trials by tapping the target color
      final totalTrials = cubit.state.totalTrials;
      for (var i = 0; i < totalTrials; i++) {
        final targetColor = cubit.state.currentTrial!.targetColor;
        final buttonKey = Key('mind_switch_color_button_${targetColor.name}');
        expect(find.byKey(buttonKey), findsOneWidget);
        await tester.tap(find.byKey(buttonKey));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();

      // 3. Verify arrival on success results screen
      expect(find.byType(MindSwitchResultView), findsOneWidget);
      expect(find.text('Cognitive Flexibility Mastered!'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Return to Games'), findsOneWidget);
    });

    testWidgets('Exceeding mistakes threshold displays failure results view',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = MindSwitchCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        seed: 42,
        timer: GameTimer(ticker: testTicker),
        trialTicker: testTicker,
        fastPreviewForTesting: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MindSwitchScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      cubit.startPlayingImmediately();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.byType(MindSwitchBoard), findsOneWidget);

      // Level 1 allows 3 mistakes; make 4 wrong selections
      for (var i = 0; i < 4; i++) {
        final targetColor = cubit.state.currentTrial!.targetColor;
        final wrongColor =
            MindSwitchColor.values.firstWhere((c) => c != targetColor);
        final buttonKey = Key('mind_switch_color_button_${wrongColor.name}');
        await tester.tap(find.byKey(buttonKey));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();

      expect(find.byType(MindSwitchResultView), findsOneWidget);
      expect(find.text('Cognitive Switch Missed'), findsOneWidget);
    });

    testWidgets('Exit button displays exit confirmation dialog',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = MindSwitchCubit(
        attemptRepository: repo,
        initialDifficulty: const GameDifficulty(1),
        seed: 42,
        timer: GameTimer(ticker: testTicker),
        trialTicker: testTicker,
        fastPreviewForTesting: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MindSwitchScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      cubit.startPlayingImmediately();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Tap exit button in header
      await tester.tap(find.byKey(const Key('mind_switch_exit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Exit Mind Switch?'), findsOneWidget);
      expect(
          find.byKey(const Key('dialog_cancel_exit_button')), findsOneWidget);
      expect(
          find.byKey(const Key('dialog_confirm_exit_button')), findsOneWidget);

      // Cancel exit
      await tester.tap(find.byKey(const Key('dialog_cancel_exit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Exit Mind Switch?'), findsNothing);
      expect(find.byType(MindSwitchBoard), findsOneWidget);
    });
  });
}
