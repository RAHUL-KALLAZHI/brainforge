import 'package:brainforge/core/database/app_database.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/features/games/shared/data/drift_game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/progress/logic/progress_cubit.dart';
import 'package:brainforge/features/progress/presentation/progress_dashboard_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helper.dart';

void main() {
  late AppDatabase db;
  late DriftGameAttemptRepository repository;
  late ProgressCubit cubit;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftGameAttemptRepository(db);
    cubit = ProgressCubit(repository);
    await cubit.loadProgress();
    await initTestDependencies(
      database: db,
      attemptRepository: repository,
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Widget buildDashboard() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: ProgressDashboardScreen(cubit: cubit),
    );
  }

  testWidgets('renders empty state when no attempts exist in SQLite',
      (tester) async {
    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Analytics Awaiting Data'), findsOneWidget);
    expect(find.text('Browse Games'), findsOneWidget);
    expect(find.text('-- %'), findsOneWidget);
    expect(find.text('-- ms'), findsOneWidget);
    expect(find.text('0 Days'), findsOneWidget);
  });

  testWidgets(
      'renders live persisted metrics when attempts are saved in SQLite',
      (tester) async {
    final now = DateTime.now();
    await repository.saveAttempt(
      GameAttempt(
        id: 'mg_test_1',
        gameId: 'memory_grid',
        difficultyLevel: 2,
        status: GameStatus.completed,
        finalScore: 1950,
        accuracy: 1.0,
        correctCount: 4,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [280, 310, 290, 320],
        startedAt: now.subtract(const Duration(seconds: 15)),
        completedAt: now,
      ),
    );

    await cubit.loadProgress();

    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    expect(find.text('Gameplay Overview'), findsOneWidget);
    expect(find.text('1 total attempts recorded'), findsOneWidget);
    expect(find.text('Personal Best Score: 1950 pts'), findsOneWidget);
    expect(find.text('100.0%'), findsOneWidget);
    expect(find.text('300 ms'), findsOneWidget);
    expect(find.text('RECENT ATTEMPTS'), findsOneWidget);
    expect(find.text('Memory Grid'), findsWidgets);
    expect(find.text('Lvl 2'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('clearing repository resets dashboard to empty state',
      (tester) async {
    final now = DateTime.now();
    await repository.saveAttempt(
      GameAttempt(
        id: 'mg_test_2',
        gameId: 'memory_grid',
        difficultyLevel: 1,
        status: GameStatus.completed,
        finalScore: 1000,
        accuracy: 1.0,
        correctCount: 3,
        incorrectCount: 0,
        missedCount: 0,
        responseTimesMs: const [400],
        startedAt: now.subtract(const Duration(seconds: 10)),
        completedAt: now,
      ),
    );

    await cubit.loadProgress();

    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    expect(find.text('Gameplay Overview'), findsOneWidget);

    await tester.runAsync(() async {
      await cubit.clearHistory();
    });
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Analytics Awaiting Data'), findsOneWidget);
    expect(find.text('-- %'), findsOneWidget);
  });

  testWidgets(
      'displays correct game names for Memory Grid, Color Echo, and unknown game IDs in recent attempts',
      (tester) async {
    final now = DateTime.now();

    await tester.runAsync(() async {
      // 1. Color Echo attempt
      await repository.saveAttempt(
        GameAttempt(
          id: 'ce_attempt_1',
          gameId: 'color_echo',
          difficultyLevel: 1,
          status: GameStatus.completed,
          finalScore: 1600,
          accuracy: 1.0,
          correctCount: 5,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [300, 320],
          startedAt: now.subtract(const Duration(minutes: 5)),
          completedAt: now.subtract(const Duration(minutes: 4)),
        ),
      );

      // 2. Memory Grid attempt
      await repository.saveAttempt(
        GameAttempt(
          id: 'mg_attempt_1',
          gameId: 'memory_grid',
          difficultyLevel: 2,
          status: GameStatus.completed,
          finalScore: 2100,
          accuracy: 1.0,
          correctCount: 6,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [250, 260],
          startedAt: now.subtract(const Duration(minutes: 10)),
          completedAt: now.subtract(const Duration(minutes: 9)),
        ),
      );

      // 3. Unknown game attempt (fallback test)
      await repository.saveAttempt(
        GameAttempt(
          id: 'unknown_attempt_1',
          gameId: 'speed_math',
          difficultyLevel: 3,
          status: GameStatus.failed,
          finalScore: 400,
          accuracy: 0.6,
          correctCount: 3,
          incorrectCount: 2,
          missedCount: 0,
          responseTimesMs: const [500],
          startedAt: now.subtract(const Duration(minutes: 15)),
          completedAt: now.subtract(const Duration(minutes: 14)),
        ),
      );

      await cubit.loadProgress();
    });

    await tester.pumpWidget(buildDashboard());
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify recent attempts display correct game names
    expect(find.text('RECENT ATTEMPTS'), findsOneWidget);
    expect(find.text('Color Echo'), findsOneWidget);
    expect(find.text('Memory Grid'), findsWidgets);
    expect(find.text('Speed Math'), findsOneWidget);

    // Verify icons are present for the known games
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.byIcon(Icons.grid_4x4_rounded), findsWidgets);
    expect(find.byIcon(Icons.extension_rounded), findsOneWidget);

    // Verify stats aggregates are properly preserved
    expect(find.text('3 total attempts recorded'), findsOneWidget);
    expect(find.text('Personal Best Score: 2100 pts'), findsOneWidget);
  });

  testWidgets(
      'saving a new Memory Grid attempt after a Color Echo attempt dynamically updates UI with correct game names and keys',
      (tester) async {
    final now = DateTime.now();

    await tester.runAsync(() async {
      // Initial state: older Memory Grid (mg_0) and newer Color Echo (ce_1)
      await repository.saveAttempt(
        GameAttempt(
          id: 'mg_0',
          gameId: 'memory_grid',
          difficultyLevel: 1,
          status: GameStatus.completed,
          finalScore: 1000,
          accuracy: 1.0,
          correctCount: 3,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [300],
          startedAt: now.subtract(const Duration(minutes: 10)),
          completedAt: now.subtract(const Duration(minutes: 9)),
        ),
      );

      await repository.saveAttempt(
        GameAttempt(
          id: 'ce_1',
          gameId: 'color_echo',
          difficultyLevel: 1,
          status: GameStatus.completed,
          finalScore: 1500,
          accuracy: 1.0,
          correctCount: 4,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [250],
          startedAt: now.subtract(const Duration(minutes: 5)),
          completedAt: now.subtract(const Duration(minutes: 4)),
        ),
      );

      await cubit.loadProgress();
    });
    await tester.pumpWidget(buildDashboard());
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify initial rendering: top item is ce_1, bottom is mg_0
    expect(find.byKey(const ValueKey('recent_attempt_ce_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('recent_attempt_mg_0')), findsOneWidget);
    expect(find.text('Color Echo'), findsOneWidget);

    // Now, simulate completing another Memory Grid game (mg_new)
    final mgNew = GameAttempt(
      id: 'mg_new_latest',
      gameId: 'memory_grid',
      difficultyLevel: 3,
      status: GameStatus.completed,
      finalScore: 2800,
      accuracy: 1.0,
      correctCount: 7,
      incorrectCount: 0,
      missedCount: 0,
      responseTimesMs: const [200, 210],
      startedAt: now.subtract(const Duration(seconds: 30)),
      completedAt: now,
    );

    await tester.runAsync(() async {
      await repository.saveAttempt(mgNew);
      await Future.delayed(const Duration(milliseconds: 50));
    });
    // Cubit updates reactively via repository.onAttemptsChanged
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify mg_new_latest is now the newest top attempt
    expect(find.byKey(const ValueKey('recent_attempt_mg_new_latest')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('recent_attempt_ce_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('recent_attempt_mg_0')), findsOneWidget);

    // Verify all 3 attempts display their own distinct and correct game names
    expect(
        find.descendant(
          of: find.byKey(const ValueKey('recent_attempt_mg_new_latest')),
          matching: find.text('Memory Grid'),
        ),
        findsOneWidget);

    expect(
        find.descendant(
          of: find.byKey(const ValueKey('recent_attempt_ce_1')),
          matching: find.text('Color Echo'),
        ),
        findsOneWidget);

    expect(
        find.descendant(
          of: find.byKey(const ValueKey('recent_attempt_mg_0')),
          matching: find.text('Memory Grid'),
        ),
        findsOneWidget);

    // Verify score on new attempt
    expect(find.text('Personal Best Score: 2800 pts'), findsOneWidget);
    expect(find.text('3 total attempts recorded'), findsOneWidget);
  });

  testWidgets(
      'displays Focus Hunter alongside Memory Grid and Color Echo in recent attempts with proper name and icon',
      (tester) async {
    final now = DateTime.now();

    await tester.runAsync(() async {
      // 1. Focus Hunter attempt
      await repository.saveAttempt(
        GameAttempt(
          id: 'fh_attempt_1',
          gameId: 'focus_hunter',
          difficultyLevel: 2,
          status: GameStatus.completed,
          finalScore: 1800,
          accuracy: 1.0,
          correctCount: 2,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [320, 290],
          startedAt: now.subtract(const Duration(minutes: 5)),
          completedAt: now.subtract(const Duration(minutes: 4)),
        ),
      );

      // 2. Color Echo attempt
      await repository.saveAttempt(
        GameAttempt(
          id: 'ce_attempt_2',
          gameId: 'color_echo',
          difficultyLevel: 1,
          status: GameStatus.completed,
          finalScore: 1200,
          accuracy: 1.0,
          correctCount: 3,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [310],
          startedAt: now.subtract(const Duration(minutes: 10)),
          completedAt: now.subtract(const Duration(minutes: 9)),
        ),
      );

      // 3. Memory Grid attempt
      await repository.saveAttempt(
        GameAttempt(
          id: 'mg_attempt_3',
          gameId: 'memory_grid',
          difficultyLevel: 3,
          status: GameStatus.completed,
          finalScore: 2400,
          accuracy: 1.0,
          correctCount: 5,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [270],
          startedAt: now.subtract(const Duration(minutes: 15)),
          completedAt: now.subtract(const Duration(minutes: 14)),
        ),
      );

      await cubit.loadProgress();
    });

    await tester.pumpWidget(buildDashboard());
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify recent attempts display all 3 game names accurately
    expect(find.text('RECENT ATTEMPTS'), findsOneWidget);
    expect(find.text('Focus Hunter'), findsOneWidget);
    expect(find.text('Color Echo'), findsOneWidget);
    expect(find.text('Memory Grid'), findsWidgets);

    // Verify correct icons for all 3 games
    expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.byIcon(Icons.grid_4x4_rounded), findsWidgets);

    // Verify stats aggregates
    expect(find.text('3 total attempts recorded'), findsOneWidget);
    expect(find.text('Personal Best Score: 2400 pts'), findsOneWidget);
  });

  testWidgets(
      'displays correct game names and icons for all 4 games (Memory Grid, Color Echo, Focus Hunter, Vanishing Cards) in recent attempts',
      (tester) async {
    final now = DateTime.now();

    await tester.runAsync(() async {
      // 1. Vanishing Cards attempt (most recent)
      await repository.saveAttempt(
        GameAttempt(
          id: 'vc_attempt_1',
          gameId: 'vanishing_cards',
          difficultyLevel: 2,
          status: GameStatus.completed,
          finalScore: 1800,
          accuracy: 1.0,
          correctCount: 4,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [400],
          startedAt: now.subtract(const Duration(minutes: 5)),
          completedAt: now.subtract(const Duration(minutes: 4)),
        ),
      );

      // 2. Focus Hunter attempt
      await repository.saveAttempt(
        GameAttempt(
          id: 'fh_attempt_2',
          gameId: 'focus_hunter',
          difficultyLevel: 1,
          status: GameStatus.completed,
          finalScore: 1200,
          accuracy: 1.0,
          correctCount: 3,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [350],
          startedAt: now.subtract(const Duration(minutes: 10)),
          completedAt: now.subtract(const Duration(minutes: 9)),
        ),
      );

      // 3. Color Echo attempt
      await repository.saveAttempt(
        GameAttempt(
          id: 'ce_attempt_2',
          gameId: 'color_echo',
          difficultyLevel: 1,
          status: GameStatus.completed,
          finalScore: 1100,
          accuracy: 1.0,
          correctCount: 3,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [310],
          startedAt: now.subtract(const Duration(minutes: 15)),
          completedAt: now.subtract(const Duration(minutes: 14)),
        ),
      );

      // 4. Memory Grid attempt
      await repository.saveAttempt(
        GameAttempt(
          id: 'mg_attempt_4',
          gameId: 'memory_grid',
          difficultyLevel: 3,
          status: GameStatus.completed,
          finalScore: 2500,
          accuracy: 1.0,
          correctCount: 5,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [270],
          startedAt: now.subtract(const Duration(minutes: 20)),
          completedAt: now.subtract(const Duration(minutes: 19)),
        ),
      );

      await cubit.loadProgress();
    });

    await tester.pumpWidget(buildDashboard());
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify recent attempts display all 4 game names accurately
    expect(find.text('RECENT ATTEMPTS'), findsOneWidget);
    expect(find.text('Vanishing Cards'), findsOneWidget);
    expect(find.text('Focus Hunter'), findsOneWidget);
    expect(find.text('Color Echo'), findsOneWidget);
    expect(find.text('Memory Grid'), findsWidgets);

    // Verify correct icons for all 4 games
    expect(find.byIcon(Icons.style_rounded), findsOneWidget);
    expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.byIcon(Icons.grid_4x4_rounded), findsWidgets);

    // Verify stats aggregates
    expect(find.text('4 total attempts recorded'), findsOneWidget);
    expect(find.text('Personal Best Score: 2500 pts'), findsOneWidget);
  });

  testWidgets(
      'Recent attempts feed correctly displays all games interleaved with proper names, icons, and scores',
      (tester) async {
    final now = DateTime.now();

    await tester.runAsync(() async {
      // 1. Mind Switch
      await repository.saveAttempt(
        GameAttempt(
          id: 'ms_attempt_1',
          gameId: 'mind_switch',
          difficultyLevel: 2,
          status: GameStatus.completed,
          finalScore: 2400,
          accuracy: 1.0,
          correctCount: 10,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [250],
          startedAt: now.subtract(const Duration(minutes: 2)),
          completedAt: now.subtract(const Duration(minutes: 1)),
        ),
      );

      // 2. Reverse Recall
      await repository.saveAttempt(
        GameAttempt(
          id: 'rr_attempt_1',
          gameId: 'reverse_recall',
          difficultyLevel: 3,
          status: GameStatus.completed,
          finalScore: 2100,
          accuracy: 1.0,
          correctCount: 5,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [300],
          startedAt: now.subtract(const Duration(minutes: 5)),
          completedAt: now.subtract(const Duration(minutes: 4)),
        ),
      );

      // 3. Vanishing Cards
      await repository.saveAttempt(
        GameAttempt(
          id: 'vc_attempt_1',
          gameId: 'vanishing_cards',
          difficultyLevel: 2,
          status: GameStatus.completed,
          finalScore: 1800,
          accuracy: 1.0,
          correctCount: 4,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [400],
          startedAt: now.subtract(const Duration(minutes: 10)),
          completedAt: now.subtract(const Duration(minutes: 9)),
        ),
      );

      // 4. Focus Hunter
      await repository.saveAttempt(
        GameAttempt(
          id: 'fh_attempt_1',
          gameId: 'focus_hunter',
          difficultyLevel: 2,
          status: GameStatus.completed,
          finalScore: 1600,
          accuracy: 1.0,
          correctCount: 3,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [350],
          startedAt: now.subtract(const Duration(minutes: 15)),
          completedAt: now.subtract(const Duration(minutes: 14)),
        ),
      );

      // 5. Color Echo
      await repository.saveAttempt(
        GameAttempt(
          id: 'ce_attempt_1',
          gameId: 'color_echo',
          difficultyLevel: 1,
          status: GameStatus.completed,
          finalScore: 1200,
          accuracy: 1.0,
          correctCount: 3,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [320],
          startedAt: now.subtract(const Duration(minutes: 20)),
          completedAt: now.subtract(const Duration(minutes: 19)),
        ),
      );

      // 6. Memory Grid
      await repository.saveAttempt(
        GameAttempt(
          id: 'mg_attempt_1',
          gameId: 'memory_grid',
          difficultyLevel: 1,
          status: GameStatus.completed,
          finalScore: 1000,
          accuracy: 1.0,
          correctCount: 3,
          incorrectCount: 0,
          missedCount: 0,
          responseTimesMs: const [290],
          startedAt: now.subtract(const Duration(minutes: 25)),
          completedAt: now.subtract(const Duration(minutes: 24)),
        ),
      );

      await cubit.loadProgress();
    });

    await tester.pumpWidget(buildDashboard());
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('RECENT ATTEMPTS'), findsOneWidget);
    expect(find.text('Mind Switch'), findsOneWidget);
    expect(find.text('Reverse Recall'), findsOneWidget);
    expect(find.text('Vanishing Cards'), findsOneWidget);
    expect(find.text('Focus Hunter'), findsOneWidget);
    expect(find.text('Color Echo'), findsOneWidget);
    expect(find.text('Memory Grid'), findsWidgets);

    // Verify icons for all 6 games
    expect(find.byIcon(Icons.alt_route_rounded), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    expect(find.byIcon(Icons.style_rounded), findsOneWidget);
    expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.byIcon(Icons.grid_4x4_rounded), findsWidgets);

    expect(find.text('6 total attempts recorded'), findsOneWidget);
  });
}
