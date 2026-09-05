import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_mode.dart';
import 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  static const String _prefNavMode = 'kero_selected_nav_mode';

  NavigationCubit() : super(NavigationState.initial()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModeName = prefs.getString(_prefNavMode);
      if (savedModeName != null) {
        final mode = AppNavStyle.values.firstWhere(
          (m) => m.name == savedModeName,
          orElse: () => AppNavStyle.commandCapsule,
        );
        emit(state.copyWith(mode: mode));
      }
    } catch (e) {
      debugPrint('Error loading navigation mode from prefs: $e');
    }
  }

  Future<void> setNavigationMode(AppNavStyle mode) async {
    if (state.mode == mode) return;
    emit(state.copyWith(mode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNavMode, mode.name);
  }
}
