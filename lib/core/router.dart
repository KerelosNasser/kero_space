import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/app_shell.dart';

import '../features/productivity/presentation/screens/productivity_screen.dart';
import '../features/productivity/presentation/bloc/productivity_bloc.dart';
import '../features/productivity/presentation/screens/note_editor_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart' as kero_space_settings;
import '../features/productivity/data/models/productivity_collections.dart';

import '../features/health/presentation/screens/health_dashboard_screen.dart';
import '../features/health/presentation/screens/calorie_config_screen.dart';
import '../features/health/presentation/screens/ingredient_search_screen.dart';
import '../features/health/presentation/screens/meal_log_screen.dart';
import '../features/health/presentation/screens/food_scanner_screen.dart';
import '../features/health/data/models/health_collections.dart';
import '../features/health/presentation/bloc/health_bloc.dart';
import '../features/finance/presentation/screens/finance_home_screen.dart';
import '../features/finance/presentation/bloc/finance_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../features/telemetry/presentation/bloc/telemetry_bloc.dart' as kero_space_telemetry_bloc;
import '../features/telemetry/presentation/bloc/telemetry_event.dart' as kero_space_telemetry_event;
import '../features/telemetry/presentation/pages/telemetry_screen.dart' as kero_space_telemetry_screen;
import '../features/telemetry/presentation/screens/blacklist_management_screen.dart' as kero_space_blacklist_screen;
import '../features/church/presentation/screens/church_screen.dart';
import '../features/church/presentation/screens/confession_log_screen.dart';
import '../features/church/presentation/bloc/church_bloc.dart';
import '../features/church/presentation/bloc/confession_bloc.dart';
import '../features/church/presentation/bloc/coptic_bloc.dart';
import '../features/church/data/repositories/encrypted_confessions_repo.dart';
import '../features/home/presentation/screens/home_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final isOnboarding = state.matchedLocation == '/onboarding';

    if (!hasSeenOnboarding && !isOnboarding) {
      return '/onboarding';
    } else if (hasSeenOnboarding && isOnboarding) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    // --- Detail Routes (Full Screen) ---
    GoRoute(
      path: '/note_editor',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extraMap = state.extra as Map<String, dynamic>?;
        final note = extraMap?['note'] as Note?;
        final bloc = extraMap?['bloc'];
        return NoteEditorScreen(existingNote: note, bloc: bloc);
      },
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const kero_space_settings.SettingsScreen(),
    ),
    GoRoute(
      path: '/telemetry/blacklist',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BlocProvider.value(
        value: GetIt.I<kero_space_telemetry_bloc.TelemetryBloc>()..add(const kero_space_telemetry_event.LoadBlacklist()),
        child: const kero_space_blacklist_screen.BlacklistManagementScreen(),
      ),
    ),
    GoRoute(
      path: '/health/config',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BlocProvider.value(
        value: GetIt.I<HealthBloc>(),
        child: const CalorieConfigScreen(),
      ),
    ),
    GoRoute(
      path: '/health/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BlocProvider.value(
        value: GetIt.I<HealthBloc>(),
        child: const IngredientSearchScreen(),
      ),
    ),
    GoRoute(
      path: '/health/log',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final ingredient = state.extra as Ingredient;
        return BlocProvider.value(
          value: GetIt.I<HealthBloc>(),
          child: MealLogScreen(ingredient: ingredient),
        );
      },
    ),
    GoRoute(
      path: '/health/scan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FoodScannerScreen(),
    ),
    GoRoute(
      path: '/church/confessions_log',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: GetIt.I<ChurchBloc>()),
          BlocProvider.value(value: GetIt.I<ConfessionBloc>()),
        ],
        child: ConfessionLogScreen(repo: GetIt.I<EncryptedIsarConfessionsRepo>()),
      ),
    ),

    // --- Stateful Shell Routes ---
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: GetIt.I<ProductivityBloc>()),
                  BlocProvider.value(value: GetIt.I<HealthBloc>()),
                  BlocProvider.value(value: GetIt.I<FinanceBloc>()),
                  BlocProvider.value(value: GetIt.I<ChurchBloc>()),
                  BlocProvider.value(value: GetIt.I<kero_space_telemetry_bloc.TelemetryBloc>()),
                ],
                child: const HomeScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/productivity',
              builder: (context, state) => const ProductivityScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/health',
              builder: (context, state) => BlocProvider.value(
                value: GetIt.I<HealthBloc>()..add(LoadDashboard()),
                child: const HealthDashboardScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/finance',
              builder: (context, state) => BlocProvider.value(
                value: GetIt.I<FinanceBloc>()..add(LoadFinanceData()),
                child: const FinanceHomeScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/church',
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: GetIt.I<ChurchBloc>()..add(LoadChurchData())),
                  BlocProvider.value(value: GetIt.I<ConfessionBloc>()),
                  BlocProvider.value(value: GetIt.I<CopticBloc>()),
                ],
                child: const ChurchScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/telemetry',
              builder: (context, state) => BlocProvider.value(
                value: GetIt.I<kero_space_telemetry_bloc.TelemetryBloc>()..add(kero_space_telemetry_event.LoadTelemetryDashboard()),
                child: const kero_space_telemetry_screen.TelemetryScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
