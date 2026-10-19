import 'package:brainforge/app/app.dart';
import 'package:brainforge/app/router.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helper.dart';

void main() {
  setUp(() async {
    await initTestDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('Navigation & Shell Widget Tests', () {
    testWidgets(
        'Tapping bottom navigation bar switches between all 5 destinations',
        (WidgetTester tester) async {
      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // 1. Initial tab: Home
      expect(find.text("Today's Workout"), findsOneWidget);

      // 2. Tap 'Games' tab
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();
      expect(find.text('Games Catalog'), findsOneWidget);
      expect(find.text('Memory Grid'), findsOneWidget);
      expect(find.text('Focus Hunter'), findsOneWidget);

      // 3. Tap 'Workout' tab
      await tester.tap(find.text('Workout'));
      await tester.pumpAndSettle();
      expect(find.text('Daily Cognitive Routine'), findsOneWidget);
      expect(find.text('SESSION BREAKDOWN'), findsOneWidget);

      // 4. Tap 'Progress' tab
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(find.text('Analytics Awaiting Data'), findsOneWidget);
      expect(find.text('Average Accuracy'), findsOneWidget);

      // 5. Tap 'Settings' tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Sound Effects'), findsOneWidget);
      expect(find.text('Haptic Feedback'), findsOneWidget);

      // 6. Return to 'Home' tab
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text("Today's Workout"), findsOneWidget);
    });

    testWidgets(
        'Tapping "Start Workout" button on Home navigates to Daily Workout tab',
        (WidgetTester tester) async {
      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // Tap 'Start Workout' on Home screen
      await tester.tap(find.text('Start Workout'));
      await tester.pumpAndSettle();

      // Verify we arrived at Daily Workout screen
      expect(find.text('Daily Cognitive Routine'), findsOneWidget);
      expect(find.text('SESSION BREAKDOWN'), findsOneWidget);
    });

    testWidgets(
        'Tapping game card in Games catalog opens detailed info bottom sheet',
        (WidgetTester tester) async {
      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // Navigate to Games tab
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();

      // Tap Memory Grid card
      await tester.tap(find.text('Memory Grid'));
      await tester.pumpAndSettle();

      // Verify bottom sheet modal opened
      expect(find.text('Overview & Mechanics'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Overview & Mechanics'), findsNothing);
    });

    testWidgets(
        'Unknown route displays NotFoundScreen fallback with return button',
        (WidgetTester tester) async {
      final testRouter =
          createRouter(initialLocation: '/unknown-invalid-route');
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // Verify Page Not Found is displayed
      expect(find.text('Page Not Found'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);

      // Tap Return to Home
      await tester.tap(find.text('Return to Home'));
      await tester.pumpAndSettle();

      // Verifies redirected to Home
      expect(find.text("Today's Workout"), findsOneWidget);
    });
  });
}
