import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/app/app.dart';
import 'package:brainforge/app/router.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/features/games/color_echo/logic/color_echo_cubit.dart';
import 'package:brainforge/features/games/color_echo/presentation/color_echo_screen.dart';
import 'package:brainforge/features/games/color_echo/presentation/widgets/color_echo_board.dart';
import 'package:brainforge/features/games/color_echo/presentation/widgets/color_echo_pad.dart';
import 'package:brainforge/features/games/color_echo/presentation/widgets/color_echo_ready_view.dart';
import 'package:brainforge/features/games/color_echo/presentation/widgets/color_echo_result_view.dart';
import 'package:brainforge/features/games/shared/data/adaptive_difficulty_repository.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_policy.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';
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

  group('ColorEcho Widget Tests', () {
    testWidgets(
        'Launching Color Echo from Games Catalog navigates to Color Echo screen',
        (WidgetTester tester) async {
      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // 1. Navigate to Games tab
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();

      // 2. Scroll to Color Echo card and tap it
      await tester.scrollUntilVisible(find.text('Color Echo'), 200);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(find.text('Color Echo'), findsOneWidget);
      await tester.tap(find.text('Color Echo'));
      await tester.pumpAndSettle();

      // 3. Tap 'Play Color Echo' button in bottom sheet
      expect(find.text('Play Color Echo'), findsOneWidget);
      await tester.tap(find.text('Play Color Echo'));
      await tester.pumpAndSettle();

      // 4. Verify we arrived on Color Echo screen
      expect(find.byType(ColorEchoScreen), findsOneWidget);
      expect(find.text('Color Echo'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets(
        'Ready view displays instructions, pads preview, and difficulty level',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ColorEchoScreen(
            fastPreviewForTesting: true,
            initialDifficulty: GameDifficulty(1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ColorEchoReadyView), findsOneWidget);
      expect(find.text('Color Echo'), findsOneWidget);
      expect(find.text('Level 1 · Beginner'), findsWidgets);
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Audio-Visual Memory'), findsOneWidget);
    });

    testWidgets(
        'Renders 4 color pads, gates input during preview, and handles sequence completion',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = ColorEchoCubit(
        attemptRepository: repo,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ColorEchoScreen(
            cubit: cubit,
          ),
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

      // 2. Step through countdown (3 seconds) deterministically
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();

      // Complete preview to transition to interactive input phase
      cubit.completePreviewForTesting();
      await tester.pump();

      // Verify board is active and input allowed
      expect(find.byType(ColorEchoBoard), findsOneWidget);
      expect(find.byType(ColorEchoPad), findsNWidgets(4));
      expect(cubit.state.isInputAllowed, isTrue);

      // Tap pads matching sequence
      final seq = cubit.state.challenge.sequence;
      for (final padIndex in seq) {
        await tester.tap(find.byKey(Key('color_echo_pad_$padIndex')));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Verify results view shown with success state
      expect(find.byType(ColorEchoResultView), findsOneWidget);
      expect(find.text('Sequence Echoed!'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Continue · Level 1'), findsOneWidget);

      // Verify attempt recorded in repository
      final attempts = await repo.getAttempts(gameId: 'color_echo');
      expect(attempts.length, 1);
      expect(attempts.first.accuracy, 1.0);
      expect(attempts.first.status, GameStatus.completed);

      // Tap Continue · Level 1
      await tester.ensureVisible(find.text('Continue · Level 1'));
      await tester.tap(find.text('Continue · Level 1'));
      await tester.pump();

      // Immediately begins a new session (countdown)
      expect(cubit.state.sessionState.status, GameStatus.countdown);
    });

    testWidgets('Incorrect pad tap triggers failure results screen',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = ColorEchoCubit(
        attemptRepository: repo,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 42,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ColorEchoScreen(
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start game and complete preview
      cubit.startPlayingImmediately();
      await tester.pump();
      cubit.completePreviewForTesting();
      await tester.pump();
      expect(cubit.state.sessionState.status, GameStatus.playing);

      // Determine wrong pad
      final correctFirst = cubit.state.challenge.sequence.first;
      final wrongPad = (correctFirst + 1) % 4;

      await tester.tap(find.byKey(Key('color_echo_pad_$wrongPad')));
      await tester.pumpAndSettle();

      // Verify failure result view
      expect(find.byType(ColorEchoResultView), findsOneWidget);
      expect(find.text('Sequence Missed'), findsOneWidget);
      expect(find.text('Play Again · Level 1'), findsOneWidget);

      // Verify attempt recorded in repository
      final attempts = await repo.getAttempts(gameId: 'color_echo');
      expect(attempts.length, 1);
      expect(attempts.first.status, GameStatus.failed);

      // Tap Play Again · Level 1
      await tester.ensureVisible(find.text('Play Again · Level 1'));
      await tester.tap(find.text('Play Again · Level 1'));
      await tester.pump();
      expect(cubit.state.sessionState.status, GameStatus.countdown);
    });

    testWidgets(
        'Adaptive difficulty promotion displays Proceed to Level 2 and Replay Level 1',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final diffRepo = InMemoryAdaptiveDifficultyRepository();
      final adaptiveService = AdaptiveDifficultyService(
        attemptRepository: repo,
        difficultyRepository: diffRepo,
        policy: const AdaptiveDifficultyPolicy(),
      );
      final testTicker = ControllableTestTicker();
      final cubit = ColorEchoCubit(
        attemptRepository: repo,
        adaptiveService: adaptiveService,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ColorEchoScreen(
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Win Game 1
      cubit.startPlayingImmediately();
      await tester.pump();
      cubit.completePreviewForTesting();
      await tester.pump();
      for (final pad in cubit.state.challenge.sequence) {
        cubit.onPadTapped(pad);
      }
      await tester.pumpAndSettle();

      // Win Game 2
      cubit.playAgainAtCompletedDifficulty();
      await tester.pump();
      cubit.completePreviewForTesting();
      await tester.pump();
      for (final pad in cubit.state.challenge.sequence) {
        cubit.onPadTapped(pad);
      }
      await tester.pumpAndSettle();

      // Win Game 3 -> Should trigger promotion
      cubit.playAgainAtCompletedDifficulty();
      await tester.pump();
      cubit.completePreviewForTesting();
      await tester.pump();
      for (final pad in cubit.state.challenge.sequence) {
        cubit.onPadTapped(pad);
      }
      await tester.pumpAndSettle();

      // Verify promotion UI
      expect(find.byType(ColorEchoResultView), findsOneWidget);
      expect(find.byKey(const Key('color_echo_adaptation_banner')),
          findsOneWidget);
      expect(find.text('Proceed to Level 2'), findsOneWidget);
      expect(find.text('Replay Level 1'), findsOneWidget);

      // Tap Proceed to Level 2
      await tester.ensureVisible(find.text('Proceed to Level 2'));
      await tester.tap(find.text('Proceed to Level 2'));
      await tester.pump();

      expect(cubit.state.difficulty.level, 2);
      expect(cubit.state.sessionState.status, GameStatus.countdown);
    });

    testWidgets(
        'Return to Game from result screen navigates back to ready view',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = ColorEchoCubit(
        attemptRepository: repo,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ColorEchoScreen(
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fail game to get to result view
      cubit.startPlayingImmediately();
      await tester.pump();
      cubit.completePreviewForTesting();
      await tester.pump();
      final wrongPad = (cubit.state.challenge.sequence.first + 1) % 4;
      cubit.onPadTapped(wrongPad);
      await tester.pumpAndSettle();

      expect(find.byType(ColorEchoResultView), findsOneWidget);

      // Tap Return to Game
      await tester.ensureVisible(find.text('Return to Game'));
      await tester.tap(find.text('Return to Game'));
      await tester.pumpAndSettle();

      // Should be back on Ready view
      expect(find.byType(ColorEchoReadyView), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets('Exit confirmation dialog during active gameplay',
        (WidgetTester tester) async {
      final repo = InMemoryGameAttemptRepository();
      final testTicker = ControllableTestTicker();
      final cubit = ColorEchoCubit(
        attemptRepository: repo,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: ColorEchoScreen(
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start playing
      cubit.startPlayingImmediately();
      await tester.pump();
      cubit.completePreviewForTesting();
      await tester.pump();

      // Tap header exit/back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Verify exit confirmation dialog
      expect(find.text('Exit Color Echo?'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(find.text('Exit Color Echo?'), findsNothing);
      expect(find.byType(ColorEchoBoard), findsOneWidget);
      expect(cubit.state.sessionState.status, GameStatus.playing);
    });

    testWidgets('Light and dark themes render without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const ColorEchoScreen(
              fastPreviewForTesting: true,
              initialDifficulty: GameDifficulty(1),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Memory Grid remains functional without regression',
        (WidgetTester tester) async {
      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();

      expect(find.text('Memory Grid'), findsOneWidget);
      await tester.tap(find.text('Memory Grid'));
      await tester.pumpAndSettle();

      expect(find.text('Play Memory Grid'), findsOneWidget);
    });
  });
}
