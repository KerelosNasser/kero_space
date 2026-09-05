import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import 'custom_theme_config.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String _prefThemeId = 'kero_selected_theme_id';
  static const String _prefThemeMode = 'kero_selected_theme_mode';
  static const String _prefCustomConfig = 'kero_custom_theme_config';

  ThemeCubit() : super(ThemeState.initial()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Theme ID
      final themeIdName = prefs.getString(_prefThemeId);
      AppThemeId themeId = AppThemeId.monochrome;
      if (themeIdName != null) {
        themeId = AppThemeId.values.firstWhere(
          (e) => e.name == themeIdName,
          orElse: () => AppThemeId.monochrome,
        );
      }

      // Theme Mode
      final modeName = prefs.getString(_prefThemeMode);
      ThemeMode mode = ThemeMode.dark;
      if (modeName == 'light') {
        mode = ThemeMode.light;
      } else if (modeName == 'system') {
        mode = ThemeMode.system;
      }

      // Custom Config
      CustomThemeConfig customConfig = CustomThemeConfig.defaultDark;
      final customJsonStr = prefs.getString(_prefCustomConfig);
      if (customJsonStr != null) {
        try {
          final map = jsonDecode(customJsonStr) as Map<String, dynamic>;
          customConfig = CustomThemeConfig.fromJson(map);
        } catch (_) {}
      }

      emit(state.copyWith(
        selectedThemeId: themeId,
        themeMode: mode,
        customConfig: customConfig,
      ));
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  Future<void> selectTheme(AppThemeId id) async {
    if (state.selectedThemeId == id) return;
    emit(state.copyWith(selectedThemeId: id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefThemeId, id.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    emit(state.copyWith(themeMode: mode));
    final prefs = await SharedPreferences.getInstance();
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : (mode == ThemeMode.system ? 'system' : 'dark');
    await prefs.setString(_prefThemeMode, modeStr);
  }

  Future<void> toggleThemeMode() async {
    final next = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(next);
  }

  Future<void> updateCustomTheme(CustomThemeConfig config) async {
    emit(state.copyWith(
      selectedThemeId: AppThemeId.custom,
      customConfig: config,
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefThemeId, AppThemeId.custom.name);
    await prefs.setString(_prefCustomConfig, jsonEncode(config.toJson()));
  }
}
