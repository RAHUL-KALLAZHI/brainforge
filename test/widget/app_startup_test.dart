import 'package:brainforge/app/app.dart';
import 'package:brainforge/app/router.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helper.dart';

void main() {
  setUp(() async {
    await initTestDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('Application Startup & Theme Rendering Widget Tests', () {
    testWidgets(
        'BrainForgeApp launches successfully and renders Home destination',
        (WidgetTester tester) async {
      final testRouter = createRouter();

      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // Check branding and primary workout action on Home
      expect(find.text('BrainForge'), findsWidgets);
      expect(find.text("Today's Workout"), findsOneWidget);
      expect(find.text('Start Workout'), findsOneWidget);

      // Verify bottom navigation bar destinations
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Games'), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets(
        'Default theme renders as Dark Mode with Deep Space Navy background',
        (WidgetTester tester) async {
      final testRouter = createRouter();

      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      // The default dark theme background is deep space navy
      final theme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.darkBackground));
      expect(scaffold, isNotNull);
    });

    testWidgets('Renders properly on narrow mobile screen without overflow',
        (WidgetTester tester) async {
      // Simulate small compact screen (iPhone SE / 320x568)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // Ensure no RenderFlex overflows occurred
      expect(tester.takeException(), isNull);
      expect(find.text('BrainForge'), findsWidgets);
      expect(find.text('Start Workout'), findsOneWidget);
    });
  });
}
