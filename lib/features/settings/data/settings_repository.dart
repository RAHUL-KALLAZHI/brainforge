import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_keys.dart';

/// Repository interface for user preferences and persistent settings.
abstract class SettingsRepository {
  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  bool getSoundEnabled();
  Future<void> setSoundEnabled(bool enabled);

  bool getHapticEnabled();
  Future<void> setHapticEnabled(bool enabled);
}

/// SharedPreferences-backed implementation of [SettingsRepository].
class SharedPrefsSettingsRepository implements SettingsRepository {
  final SharedPreferences _prefs;

  SharedPrefsSettingsRepository(this._prefs);

  @override
  ThemeMode getThemeMode() {
    final value = _prefs.getString(AppKeys.prefThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        // Default to dark theme as required by product specs
        return ThemeMode.dark;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(AppKeys.prefThemeMode, value);
  }

  @override
  bool getSoundEnabled() {
    return _prefs.getBool(AppKeys.prefSoundEnabled) ?? true;
  }

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(AppKeys.prefSoundEnabled, enabled);
  }

  @override
  bool getHapticEnabled() {
    return _prefs.getBool(AppKeys.prefHapticEnabled) ?? true;
  }

  @override
  Future<void> setHapticEnabled(bool enabled) async {
    await _prefs.setBool(AppKeys.prefHapticEnabled, enabled);
  }
}
