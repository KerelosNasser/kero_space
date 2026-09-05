import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../app_theme.dart';
import 'custom_theme_config.dart';

class ThemeState extends Equatable {
  final AppThemeId selectedThemeId;
  final ThemeMode themeMode;
  final CustomThemeConfig customConfig;
  final ThemeData darkThemeData;
  final ThemeData lightThemeData;

  const ThemeState({
    required this.selectedThemeId,
    required this.themeMode,
    required this.customConfig,
    required this.darkThemeData,
    required this.lightThemeData,
  });

  factory ThemeState.initial({
    AppThemeId initialThemeId = AppThemeId.monochrome,
    ThemeMode initialMode = ThemeMode.dark,
    CustomThemeConfig? initialCustomConfig,
  }) {
    final custom = initialCustomConfig ?? CustomThemeConfig.defaultDark;
    return ThemeState(
      selectedThemeId: initialThemeId,
      themeMode: initialMode,
      customConfig: custom,
      darkThemeData: AppTheme.getThemeData(
        initialThemeId,
        isDark: true,
        customConfig: custom,
      ),
      lightThemeData: AppTheme.getThemeData(
        initialThemeId,
        isDark: false,
        customConfig: custom,
      ),
    );
  }

  ThemeState copyWith({
    AppThemeId? selectedThemeId,
    ThemeMode? themeMode,
    CustomThemeConfig? customConfig,
  }) {
    final newId = selectedThemeId ?? this.selectedThemeId;
    final newMode = themeMode ?? this.themeMode;
    final newCustom = customConfig ?? this.customConfig;

    return ThemeState(
      selectedThemeId: newId,
      themeMode: newMode,
      customConfig: newCustom,
      darkThemeData: AppTheme.getThemeData(newId, isDark: true, customConfig: newCustom),
      lightThemeData: AppTheme.getThemeData(newId, isDark: false, customConfig: newCustom),
    );
  }

  @override
  List<Object?> get props => [
        selectedThemeId,
        themeMode,
        customConfig.bgPrimaryValue,
        customConfig.bgSurfaceValue,
        customConfig.accentPrimaryValue,
        customConfig.accentSecondaryValue,
        customConfig.isDark,
      ];
}
