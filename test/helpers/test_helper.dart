import 'package:brainforge/core/database/app_database.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/features/games/shared/data/drift_game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test helper to setup clean dependency injection and mock SharedPreferences.
Future<void> initTestDependencies({
  Map<String, Object> initialValues = const {},
  AppDatabase? database,
  GameAttemptRepository? attemptRepository,
}) async {
  await resetDependencies();
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  final db = database ?? AppDatabase(NativeDatabase.memory());
  await setupDependencies(
    preferences: prefs,
    database: db,
    attemptRepository: attemptRepository ?? DriftGameAttemptRepository(db),
  );
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
