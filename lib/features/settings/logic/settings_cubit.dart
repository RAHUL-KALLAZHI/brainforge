import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/settings_repository.dart';
import 'settings_state.dart';

/// Cubit managing settings state and persistence.
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit(this._repository)
      : super(
          SettingsState(
            themeMode: _repository.getThemeMode(),
            soundEnabled: _repository.getSoundEnabled(),
            hapticEnabled: _repository.getHapticEnabled(),
          ),
        );

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _repository.setThemeMode(mode);
  }

  Future<void> toggleSound() async {
    final newValue = !state.soundEnabled;
    emit(state.copyWith(soundEnabled: newValue));
    await _repository.setSoundEnabled(newValue);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    emit(state.copyWith(soundEnabled: enabled));
    await _repository.setSoundEnabled(enabled);
  }

  Future<void> toggleHaptic() async {
    final newValue = !state.hapticEnabled;
    emit(state.copyWith(hapticEnabled: newValue));
    await _repository.setHapticEnabled(newValue);
  }

  Future<void> setHapticEnabled(bool enabled) async {
    emit(state.copyWith(hapticEnabled: enabled));
    await _repository.setHapticEnabled(enabled);
  }
}
