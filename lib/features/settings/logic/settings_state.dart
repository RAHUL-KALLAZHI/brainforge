import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Immutable state representing user settings.
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool soundEnabled;
  final bool hapticEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.soundEnabled = true,
    this.hapticEnabled = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? soundEnabled,
    bool? hapticEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }

  @override
  List<Object?> get props => [themeMode, soundEnabled, hapticEnabled];
}
