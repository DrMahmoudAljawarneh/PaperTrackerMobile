import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paper_tracker/blocs/theme/theme_cubit.dart';
import 'package:paper_tracker/config/theme_preset.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeCubit', () {
    test('initial state is ThemeState.initial', () {
      final cubit = ThemeCubit();
      expect(cubit.state.preset, ThemePreset.indigo);
      expect(cubit.state.mode, ThemeMode.system);
    });

    group('updateThemeMode', () {
      blocTest<ThemeCubit, ThemeState>(
        'emits ThemeState with ThemeMode.light',
        build: () => ThemeCubit(),
        act: (cubit) => cubit.updateThemeMode(ThemeMode.light),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.mode, 'mode', ThemeMode.light)
              .having((s) => s.preset, 'preset', ThemePreset.indigo),
        ],
      );

      blocTest<ThemeCubit, ThemeState>(
        'emits ThemeState with ThemeMode.dark',
        build: () => ThemeCubit(),
        act: (cubit) => cubit.updateThemeMode(ThemeMode.dark),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.mode, 'mode', ThemeMode.dark)
              .having((s) => s.preset, 'preset', ThemePreset.indigo),
        ],
      );

      blocTest<ThemeCubit, ThemeState>(
        'emits ThemeState with ThemeMode.system',
        build: () => ThemeCubit(),
        act: (cubit) => cubit.updateThemeMode(ThemeMode.system),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.mode, 'mode', ThemeMode.system)
              .having((s) => s.preset, 'preset', ThemePreset.indigo),
        ],
      );
    });

    group('updateThemePreset', () {
      blocTest<ThemeCubit, ThemeState>(
        'emits ThemeState with ThemePreset.emerald',
        build: () => ThemeCubit(),
        act: (cubit) => cubit.updateThemePreset(ThemePreset.emerald),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.preset, 'preset', ThemePreset.emerald)
              .having((s) => s.mode, 'mode', ThemeMode.system),
        ],
      );

      blocTest<ThemeCubit, ThemeState>(
        'emits ThemeState with ThemePreset.sunset',
        build: () => ThemeCubit(),
        act: (cubit) => cubit.updateThemePreset(ThemePreset.sunset),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.preset, 'preset', ThemePreset.sunset)
              .having((s) => s.mode, 'mode', ThemeMode.system),
        ],
      );

      blocTest<ThemeCubit, ThemeState>(
        'emits ThemeState with ThemePreset.ocean',
        build: () => ThemeCubit(),
        act: (cubit) => cubit.updateThemePreset(ThemePreset.ocean),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.preset, 'preset', ThemePreset.ocean)
              .having((s) => s.mode, 'mode', ThemeMode.system),
        ],
      );

      blocTest<ThemeCubit, ThemeState>(
        'emits ThemeState with ThemePreset.rose',
        build: () => ThemeCubit(),
        act: (cubit) => cubit.updateThemePreset(ThemePreset.rose),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.preset, 'preset', ThemePreset.rose)
              .having((s) => s.mode, 'mode', ThemeMode.system),
        ],
      );
    });

    test('mode is persisted to SharedPreferences', () async {
      final cubit = ThemeCubit();
      final prefs = await SharedPreferences.getInstance();

      await cubit.updateThemeMode(ThemeMode.light);
      expect(prefs.getString('app_theme_preference'), 'light');

      await cubit.updateThemeMode(ThemeMode.dark);
      expect(prefs.getString('app_theme_preference'), 'dark');

      await cubit.updateThemeMode(ThemeMode.system);
      expect(prefs.getString('app_theme_preference'), 'system');
    });

    test('preset is persisted to SharedPreferences', () async {
      final cubit = ThemeCubit();
      final prefs = await SharedPreferences.getInstance();

      await cubit.updateThemePreset(ThemePreset.emerald);
      expect(prefs.getString('app_theme_preset'), 'emerald');

      await cubit.updateThemePreset(ThemePreset.rose);
      expect(prefs.getString('app_theme_preset'), 'rose');
    });

    test('load restores persisted preset and mode', () async {
      SharedPreferences.setMockInitialValues({
        'app_theme_preference': 'dark',
        'app_theme_preset': 'ocean',
      });

      final cubit = ThemeCubit();
      expect(cubit.state.preset, ThemePreset.indigo);
      expect(cubit.state.mode, ThemeMode.system);

      await cubit.load();

      expect(cubit.state.preset, ThemePreset.ocean);
      expect(cubit.state.mode, ThemeMode.dark);
    });
  });
}
