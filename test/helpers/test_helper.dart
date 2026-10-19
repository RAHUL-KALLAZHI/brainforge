import 'package:brainforge/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test helper to setup clean dependency injection and mock SharedPreferences.
Future<void> initTestDependencies({
  Map<String, Object> initialValues = const {},
}) async {
  await resetDependencies();
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  await setupDependencies(preferences: prefs);
}

/// Helper to pump a testable widget wrapped in MaterialApp.
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: child,
    ),
  );
}
