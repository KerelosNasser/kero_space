import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/core/theme/custom_theme_config.dart';
import 'package:kero_space/core/theme/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme & Tokens Tests', () {
    test('All 10 preset themes resolve both Dark and Light variants with valid tokens', () {
      final presets = AppThemeId.values.where((id) => id != AppThemeId.custom);

      for (final id in presets) {
        // Dark
        final darkTheme = AppTheme.getThemeData(id, isDark: true);
        expect(darkTheme.brightness, Brightness.dark);
        final darkColors = darkTheme.extension<AppThemeColors>();
        expect(darkColors, isNotNull, reason: '$id dark colors missing extension');
        expect(darkColors!.bgBase, isNotNull);
        expect(darkColors.accentPrimary, isNotNull);
        expect(darkColors.domainProductivity, isNotNull);
        expect(darkColors.domainTelemetry, isNotNull);

        // Light
        final lightTheme = AppTheme.getThemeData(id, isDark: false);
        expect(lightTheme.brightness, Brightness.light);
        final lightColors = lightTheme.extension<AppThemeColors>();
        expect(lightColors, isNotNull, reason: '$id light colors missing extension');
        expect(lightColors!.bgBase, isNotNull);
        expect(lightColors.accentPrimary, isNotNull);
      }
    });

    test('ThemeData memoization returns cached reference', () {
      final firstCall = AppTheme.getThemeData(AppThemeId.gruvbox, isDark: true);
      final secondCall = AppTheme.getThemeData(AppThemeId.gruvbox, isDark: true);
      expect(identical(firstCall, secondCall), isTrue);
    });

    test('CustomThemeConfig serializes and deserializes accurately', () {
      const config = CustomThemeConfig(
        bgPrimaryValue: 0xFF123456,
        bgSurfaceValue: 0xFF654321,
        accentPrimaryValue: 0xFFAABBCC,
        accentSecondaryValue: 0xFFDDEEFF,
        isDark: true,
      );

      final json = config.toJson();
      final restored = CustomThemeConfig.fromJson(json);

      expect(restored.bgPrimaryValue, config.bgPrimaryValue);
      expect(restored.bgSurfaceValue, config.bgSurfaceValue);
      expect(restored.accentPrimaryValue, config.accentPrimaryValue);
      expect(restored.accentSecondaryValue, config.accentSecondaryValue);
      expect(restored.isDark, config.isDark);
      expect(restored.bgPrimary, const Color(0xFF123456));
    });

    test('ThemeCubit initializes, switches theme, and changes theme mode', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = ThemeCubit();

      expect(cubit.state.selectedThemeId, AppThemeId.monochrome);
      expect(cubit.state.themeMode, ThemeMode.dark);

      await cubit.selectTheme(AppThemeId.amberCrt);
      expect(cubit.state.selectedThemeId, AppThemeId.amberCrt);

      await cubit.setThemeMode(ThemeMode.light);
      expect(cubit.state.themeMode, ThemeMode.light);

      const customCfg = CustomThemeConfig(
        bgPrimaryValue: 0xFF000000,
        bgSurfaceValue: 0xFF111111,
        accentPrimaryValue: 0xFFFF5722,
        accentSecondaryValue: 0xFF00E5FF,
        isDark: true,
      );

      await cubit.updateCustomTheme(customCfg);
      expect(cubit.state.selectedThemeId, AppThemeId.custom);
      expect(cubit.state.customConfig.bgPrimaryValue, 0xFF000000);
    });
  });
}
