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
import 'package:brainforge/features/games/shared/data/adaptive_difficulty_repository.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/domain/player_game_profile.dart';
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
      expect(find.text('Continue · Level 1'), findsOneWidget);

      // Verify attempt recorded in repository
      final attempts = await repo.getAttempts(gameId: 'memory_grid');
      expect(attempts.length, 1);
      expect(attempts.first.accuracy, 1.0);

      // Tap Continue · Level 1
      await tester.tap(find.text('Continue · Level 1'));
      await tester.pump();

      // Immediately begins a new session (countdown)
      expect(cubit.state.sessionState.status, GameStatus.countdown);
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
      expect(find.text('Play Again · Level 1'), findsOneWidget);

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

    testWidgets(
        'Result view displays Proceed to Level 2 and Replay Level 1 upon promotion, and Replay repeats Level 1',
        (WidgetTester tester) async {
      final attemptRepo = InMemoryGameAttemptRepository();
      final diffRepo = InMemoryAdaptiveDifficultyRepository();
      final adaptiveService = AdaptiveDifficultyService(
        attemptRepository: attemptRepo,
        difficultyRepository: diffRepo,
        policy: const AdaptiveDifficultyPolicy(),
      );

      // Pre-seed 2 perfect attempts so the next win triggers promotion
      final now = DateTime.now();
      await attemptRepo.saveAttempt(GameAttempt(
        id: 'seed_1',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 1000,
        accuracy: 1.0,
        correctCount: 3,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [400, 500, 600],
        startedAt: now.subtract(const Duration(minutes: 6)),
        completedAt: now.subtract(const Duration(minutes: 5)),
      ));
      await attemptRepo.saveAttempt(GameAttempt(
        id: 'seed_2',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 1000,
        accuracy: 1.0,
        correctCount: 3,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [400, 500, 600],
        startedAt: now.subtract(const Duration(minutes: 5)),
        completedAt: now.subtract(const Duration(minutes: 4)),
      ));

      final testTicker = ControllableTestTicker();
      final cubit = MemoryGridCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
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

      // Complete sequence
      final seq = cubit.state.challenge.sequence;
      for (final tileIndex in seq) {
        await tester.tap(find.byKey(ValueKey('tile_$tileIndex')));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Verify promotion banner and explanation are rendered
      expect(
          find.textContaining('Difficulty Increased: Level 2'), findsOneWidget);
      expect(
        find.textContaining(
            'Your performance qualifies you for Level 2. Ready for a longer sequence?'),
        findsOneWidget,
      );

      // Verify button hierarchy: Proceed to Level 2 (primary), Replay Level 1 (secondary), Return to Game
      expect(find.byKey(const Key('memory_grid_proceed_next_level_button')),
          findsOneWidget);
      expect(find.text('Proceed to Level 2'), findsOneWidget);
      expect(find.byKey(const Key('memory_grid_play_again_button')),
          findsOneWidget);
      expect(find.text('Replay Level 1'), findsOneWidget);
      expect(find.byKey(const Key('memory_grid_return_game_button')),
          findsOneWidget);

      // Tap Replay Level 1
      await tester.ensureVisible(
          find.byKey(const Key('memory_grid_play_again_button')));
      await tester.tap(find.byKey(const Key('memory_grid_play_again_button')));
      await tester.pump();

      // Verify the active session starts immediately at Level 1 (repeats played difficulty)
      expect(cubit.state.difficulty.level, 1);
      expect(cubit.state.sessionState.status, GameStatus.countdown);
      expect(find.textContaining('Level 1'), findsWidgets);
      cubit.close();
    });

    testWidgets(
        'Tapping Proceed to Level 2 starts promoted Level 2 immediately',
        (WidgetTester tester) async {
      final attemptRepo = InMemoryGameAttemptRepository();
      final diffRepo = InMemoryAdaptiveDifficultyRepository();
      final adaptiveService = AdaptiveDifficultyService(
        attemptRepository: attemptRepo,
        difficultyRepository: diffRepo,
        policy: const AdaptiveDifficultyPolicy(),
      );

      // Pre-seed 2 perfect attempts so the next win triggers promotion
      final now = DateTime.now();
      await attemptRepo.saveAttempt(GameAttempt(
        id: 'seed_p1',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 1000,
        accuracy: 1.0,
        correctCount: 3,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [400],
        startedAt: now.subtract(const Duration(minutes: 6)),
        completedAt: now.subtract(const Duration(minutes: 5)),
      ));
      await attemptRepo.saveAttempt(GameAttempt(
        id: 'seed_p2',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 1000,
        accuracy: 1.0,
        correctCount: 3,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [400],
        startedAt: now.subtract(const Duration(minutes: 5)),
        completedAt: now.subtract(const Duration(minutes: 4)),
      ));

      final testTicker = ControllableTestTicker();
      final cubit = MemoryGridCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 77,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MemoryGridScreen(cubit: cubit),
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

      // Complete sequence
      for (final tileIndex in cubit.state.challenge.sequence) {
        await tester.tap(find.byKey(ValueKey('tile_$tileIndex')));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Tap Proceed to Level 2
      await tester.ensureVisible(
          find.byKey(const Key('memory_grid_proceed_next_level_button')));
      await tester
          .tap(find.byKey(const Key('memory_grid_proceed_next_level_button')));
      await tester.pump();

      // Verify the active session starts immediately at Level 2!
      expect(cubit.state.difficulty.level, 2);
      expect(cubit.state.sessionState.status, GameStatus.countdown);
      expect(find.textContaining('Level 2'), findsWidgets);
      cubit.close();
    });

    testWidgets(
        'Completing games 1 & 2 leaves player at Level 1 without false promotion banner, game 3 renders promotion banner and Proceed button',
        (tester) async {
      final attemptRepo = InMemoryGameAttemptRepository();
      final diffRepo = InMemoryAdaptiveDifficultyRepository();
      final adaptiveService = AdaptiveDifficultyService(
        attemptRepository: attemptRepo,
        difficultyRepository: diffRepo,
        policy: const AdaptiveDifficultyPolicy(),
      );

      final testTicker = ControllableTestTicker();

      Future<void> playOneGame(MemoryGridCubit cubit) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: MemoryGridScreen(cubit: cubit),
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

        final seq = cubit.state.challenge.sequence;
        for (final tileIndex in seq) {
          await tester.tap(find.byKey(ValueKey('tile_$tileIndex')));
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }

      // Game 1
      final cubit1 = MemoryGridCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 101,
        timer: GameTimer(ticker: testTicker),
      );
      await playOneGame(cubit1);

      // Verify no promotion banner on game 1
      expect(find.textContaining('Difficulty Increased'), findsNothing);
      expect(find.byKey(const Key('memory_grid_proceed_next_level_button')),
          findsNothing);
      expect(find.text('Continue · Level 1'), findsOneWidget);
      expect(find.text('Return to Game'), findsOneWidget);
      cubit1.close();

      // Game 2
      final cubit2 = MemoryGridCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 102,
        timer: GameTimer(ticker: testTicker),
      );
      await playOneGame(cubit2);

      // Verify no promotion banner on game 2
      expect(find.textContaining('Difficulty Increased'), findsNothing);
      expect(find.byKey(const Key('memory_grid_proceed_next_level_button')),
          findsNothing);
      expect(find.text('Continue · Level 1'), findsOneWidget);
      cubit2.close();

      // Game 3 (Third qualifying victory)
      final cubit3 = MemoryGridCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 103,
        timer: GameTimer(ticker: testTicker),
      );
      await playOneGame(cubit3);

      // Verify promotion banner is rendered on 3rd qualifying victory
      expect(
          find.textContaining('Difficulty Increased: Level 2'), findsOneWidget);
      expect(find.byKey(const Key('memory_grid_proceed_next_level_button')),
          findsOneWidget);
      expect(find.text('Proceed to Level 2'), findsOneWidget);
      expect(find.text('Replay Level 1'), findsOneWidget);

      // Tap Proceed to Level 2 and confirm it launches Level 2
      await tester.ensureVisible(
          find.byKey(const Key('memory_grid_proceed_next_level_button')));
      await tester
          .tap(find.byKey(const Key('memory_grid_proceed_next_level_button')));
      await tester.pump();
      expect(cubit3.state.difficulty.level, 2);
      expect(cubit3.state.sessionState.status, GameStatus.countdown);
      expect(find.textContaining('Level 2'), findsWidgets);
      cubit3.close();
    });

    testWidgets(
        'Return to Game exits result screen and returns to Memory Grid ready view displaying latest promoted difficulty',
        (tester) async {
      final attemptRepo = InMemoryGameAttemptRepository();
      final diffRepo = InMemoryAdaptiveDifficultyRepository();
      final adaptiveService = AdaptiveDifficultyService(
        attemptRepository: attemptRepo,
        difficultyRepository: diffRepo,
        policy: const AdaptiveDifficultyPolicy(),
      );
      final testTicker = ControllableTestTicker();

      final cubit = MemoryGridCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(1),
        initialSeed: 999,
        timer: GameTimer(ticker: testTicker),
      );

      // Seed 2 prior qualifying attempts at Level 1
      for (int i = 0; i < 2; i++) {
        await attemptRepo.saveAttempt(GameAttempt(
          id: 'prior_ret_$i',
          gameId: 'memory_grid',
          difficultyLevel: 1,
          status: GameStatus.completed,
          finalScore: 1000,
          accuracy: 1.0,
          correctCount: 3,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [300],
          startedAt: DateTime.now().subtract(Duration(minutes: 5 - i)),
          completedAt: DateTime.now().subtract(Duration(minutes: 5 - i)),
        ));
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MemoryGridScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Start game
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();

      // Complete sequence
      for (final tile in cubit.state.challenge.sequence) {
        await tester.tap(find.byKey(ValueKey('tile_$tile')));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Result screen with promotion banner
      expect(find.textContaining('Difficulty Increased'), findsOneWidget);
      expect(find.text('Return to Game'), findsOneWidget);

      // Tap Return to Game
      await tester.ensureVisible(find.text('Return to Game'));
      await tester.tap(find.text('Return to Game'));
      await tester.pumpAndSettle();

      // Verify we returned to Memory Grid ready view, showing Level 2 and Start Game
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);
      expect(find.text('Working Memory'), findsOneWidget);
      expect(cubit.state.difficulty.level, 2);
      expect(cubit.state.sessionState.status, GameStatus.initial);

      // Tap Start Game from ready view begins session at Level 2
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      expect(cubit.state.sessionState.status, GameStatus.countdown);
      expect(cubit.state.difficulty.level, 2);
      expect(find.textContaining('Level 2'), findsWidgets);

      cubit.close();
    });

    testWidgets(
        'Demotion displays Play Again for completed difficulty and Return to Game for lower recommended level, with no Proceed button',
        (tester) async {
      final attemptRepo = InMemoryGameAttemptRepository();
      final diffRepo = InMemoryAdaptiveDifficultyRepository();
      final adaptiveService = AdaptiveDifficultyService(
        attemptRepository: attemptRepo,
        difficultyRepository: diffRepo,
        policy: const AdaptiveDifficultyPolicy(),
      );
      final testTicker = ControllableTestTicker();

      // Start profile at Level 2
      await diffRepo.saveProfile(PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(2),
        updatedAt: DateTime.now(),
      ));

      // 2 prior attempts at Level 2
      await attemptRepo.saveAttempt(GameAttempt(
        id: 'dem_prev_1',
        gameId: 'memory_grid',
        difficultyLevel: 2,
        status: GameStatus.completed,
        finalScore: 800,
        accuracy: 0.8,
        correctCount: 3,
        incorrectCount: 1,
        missedCount: 0,
        responseTimesMs: const [400],
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        completedAt: DateTime.now().subtract(const Duration(minutes: 4)),
      ));
      await attemptRepo.saveAttempt(GameAttempt(
        id: 'dem_prev_2',
        gameId: 'memory_grid',
        difficultyLevel: 2,
        status: GameStatus.failed,
        finalScore: 0,
        accuracy: 0.0,
        correctCount: 0,
        incorrectCount: 1,
        missedCount: 3,
        responseTimesMs: const [400],
        startedAt: DateTime.now().subtract(const Duration(minutes: 3)),
        completedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ));

      final cubit = MemoryGridCubit(
        attemptRepository: attemptRepo,
        adaptiveService: adaptiveService,
        fastPreviewForTesting: true,
        initialDifficulty: const GameDifficulty(2),
        initialSeed: 555,
        timer: GameTimer(ticker: testTicker),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MemoryGridScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Start game at Level 2
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();
      testTicker.step();
      await tester.pump();

      // Tap wrong tile to fail and trigger demotion
      final wrongTile =
          (cubit.state.challenge.sequence.first + 1) % cubit.state.totalTiles;
      await tester.tap(find.byKey(ValueKey('tile_$wrongTile')));
      await tester.pumpAndSettle();

      // Verify demotion banner is shown
      expect(
          find.textContaining('Difficulty Adjusted: Level 1'), findsOneWidget);

      // Verify Proceed to Next Level button is NOT displayed
      expect(find.byKey(const Key('memory_grid_proceed_next_level_button')),
          findsNothing);

      // Verify Play Again and Return to Game buttons are displayed
      expect(find.byKey(const Key('memory_grid_play_again_button')),
          findsOneWidget);
      expect(find.text('Play Again · Level 2'), findsOneWidget);
      expect(find.byKey(const Key('memory_grid_return_game_button')),
          findsOneWidget);

      // Tap Play Again and verify it restarts Level 2 (replays the played level)
      await tester.ensureVisible(
          find.byKey(const Key('memory_grid_play_again_button')));
      await tester.tap(find.byKey(const Key('memory_grid_play_again_button')));
      await tester.pump();
      expect(cubit.state.difficulty.level, 2);
      expect(cubit.state.sessionState.status, GameStatus.countdown);

      cubit.close();
    });
  });
}
