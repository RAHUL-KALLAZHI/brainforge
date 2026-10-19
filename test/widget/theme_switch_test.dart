import 'package:brainforge/app/app.dart';
import 'package:brainforge/app/router.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_keys.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helper.dart';

void main() {
  setUp(() async {
    await initTestDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('Theme Switching & Persistence Widget Tests', () {
    testWidgets(
        'Tapping Light Mode in Settings updates app theme immediately and persists',
        (WidgetTester tester) async {
      final testRouter = createRouter(initialLocation: AppKeys.settingsPath);
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      // Verify currently dark
      var theme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(theme.brightness, equals(Brightness.dark));

      // Tap 'Light Mode'
      await tester.tap(find.text('Light Mode'));
      await tester.pumpAndSettle();

      // Verify switched to light theme immediately
      theme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.lightBackground));

      // Verify preference was persisted to SharedPreferences
      final prefs = getIt<SharedPreferences>();
      expect(prefs.getString(AppKeys.prefThemeMode), equals('light'));

      // Tap 'Dark Mode' to switch back
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      theme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(theme.brightness, equals(Brightness.dark));
      expect(prefs.getString(AppKeys.prefThemeMode), equals('dark'));
    });

    testWidgets('App restores persisted light theme preference on launch',
        (WidgetTester tester) async {
      // Pre-seed SharedPreferences with 'light' mode
      await initTestDependencies(
        initialValues: {
          AppKeys.prefThemeMode: 'light',
        },
      );

      final testRouter = createRouter();
      await tester.pumpWidget(BrainForgeApp(router: testRouter));
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.lightBackground));
    });
  });
}
