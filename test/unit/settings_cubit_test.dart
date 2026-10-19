import 'package:brainforge/core/constants/app_keys.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:brainforge/features/settings/logic/settings_cubit.dart';
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

  group('SettingsCubit Unit Tests', () {
    test('initial state defaults to dark theme and enabled feedback', () {
      final cubit = getIt<SettingsCubit>();
      expect(cubit.state.themeMode, equals(ThemeMode.dark));
      expect(cubit.state.soundEnabled, isTrue);
      expect(cubit.state.hapticEnabled, isTrue);
    });

    test('initial state correctly reads existing preferences', () async {
      await initTestDependencies(
        initialValues: {
          AppKeys.prefThemeMode: 'light',
          AppKeys.prefSoundEnabled: false,
          AppKeys.prefHapticEnabled: false,
        },
      );
      final cubit = getIt<SettingsCubit>();
      expect(cubit.state.themeMode, equals(ThemeMode.light));
      expect(cubit.state.soundEnabled, isFalse);
      expect(cubit.state.hapticEnabled, isFalse);
    });

    test('setThemeMode updates state and persists to SharedPreferences',
        () async {
      final cubit = getIt<SettingsCubit>();
      await cubit.setThemeMode(ThemeMode.light);
      expect(cubit.state.themeMode, equals(ThemeMode.light));

      final prefs = getIt<SharedPreferences>();
      expect(prefs.getString(AppKeys.prefThemeMode), equals('light'));

      await cubit.setThemeMode(ThemeMode.system);
      expect(cubit.state.themeMode, equals(ThemeMode.system));
      expect(prefs.getString(AppKeys.prefThemeMode), equals('system'));
    });

    test('toggleSound and setSoundEnabled update state and persist', () async {
      final cubit = getIt<SettingsCubit>();
      final prefs = getIt<SharedPreferences>();

      await cubit.toggleSound();
      expect(cubit.state.soundEnabled, isFalse);
      expect(prefs.getBool(AppKeys.prefSoundEnabled), isFalse);

      await cubit.setSoundEnabled(true);
      expect(cubit.state.soundEnabled, isTrue);
      expect(prefs.getBool(AppKeys.prefSoundEnabled), isTrue);
    });

    test('toggleHaptic and setHapticEnabled update state and persist',
        () async {
      final cubit = getIt<SettingsCubit>();
      final prefs = getIt<SharedPreferences>();

      await cubit.toggleHaptic();
      expect(cubit.state.hapticEnabled, isFalse);
      expect(prefs.getBool(AppKeys.prefHapticEnabled), isFalse);

      await cubit.setHapticEnabled(true);
      expect(cubit.state.hapticEnabled, isTrue);
      expect(prefs.getBool(AppKeys.prefHapticEnabled), isTrue);
    });
  });
}
