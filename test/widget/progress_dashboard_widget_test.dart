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

    await cubit.clearHistory();
    await tester.pumpAndSettle();

    expect(find.text('Analytics Awaiting Data'), findsOneWidget);
    expect(find.text('-- %'), findsOneWidget);
  });
}
