import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paper_tracker/config/theme_preset.dart';

class ThemeState {
  final ThemePreset preset;
  final ThemeMode mode;
  final int? customAccentValue;

  const ThemeState({
    required this.preset,
    required this.mode,
    this.customAccentValue,
  });

  static const initial = ThemeState(
    preset: ThemePreset.indigo,
    mode: ThemeMode.system,
    customAccentValue: null,
  );
}

class ThemeCubit extends Cubit<ThemeState> {
  static const String _modePrefKey = 'app_theme_preference';
  static const String _presetPrefKey = 'app_theme_preset';
  static const String _accentPrefKey = 'app_theme_accent';

  ThemeCubit() : super(ThemeState.initial);

  Future<void> load() => _loadTheme();

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_modePrefKey);
    final savedPreset = prefs.getString(_presetPrefKey);
    final savedAccent = prefs.getInt(_accentPrefKey);

    ThemeMode mode;
    switch (savedTheme) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }

    ThemePreset preset;
    switch (savedPreset) {
      case 'emerald':
        preset = ThemePreset.emerald;
        break;
      case 'sunset':
        preset = ThemePreset.sunset;
        break;
      case 'ocean':
        preset = ThemePreset.ocean;
        break;
      case 'rose':
        preset = ThemePreset.rose;
        break;
      default:
        preset = ThemePreset.indigo;
    }

    emit(ThemeState(
      preset: preset,
      mode: mode,
      customAccentValue: savedAccent,
    ));
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_modePrefKey, value);
    emit(ThemeState(
      preset: state.preset,
      mode: mode,
      customAccentValue: state.customAccentValue,
    ));
  }

  Future<void> updateThemePreset(ThemePreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_presetPrefKey, preset.name);
    emit(ThemeState(
      preset: preset,
      mode: state.mode,
      customAccentValue: state.customAccentValue,
    ));
  }

  Future<void> updateAccentColor(Color? color) async {
    final prefs = await SharedPreferences.getInstance();
    if (color != null) {
      await prefs.setInt(_accentPrefKey, color.toARGB32());
    } else {
      await prefs.remove(_accentPrefKey);
    }
    emit(ThemeState(
      preset: state.preset,
      mode: state.mode,
      customAccentValue: color?.toARGB32(),
    ));
  }
}
