import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/productivity/presentation/screens/productivity_screen.dart';
import '../features/productivity/presentation/screens/note_editor_screen.dart';
import '../features/productivity/data/models/productivity_collections.dart';

import '../features/health/presentation/screens/health_dashboard_screen.dart';
import '../features/health/presentation/screens/calorie_config_screen.dart';
import '../features/health/presentation/screens/ingredient_search_screen.dart';
import '../features/health/presentation/screens/meal_log_screen.dart';
import '../features/health/data/models/health_collections.dart';
import '../features/health/presentation/bloc/health_bloc.dart';
import '../features/finance/presentation/screens/finance_home_screen.dart';
import '../features/finance/presentation/bloc/finance_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../features/telemetry/presentation/bloc/telemetry_bloc.dart' as kero_space_telemetry_bloc;
import '../features/telemetry/presentation/bloc/telemetry_event.dart' as kero_space_telemetry_event;
import '../features/telemetry/presentation/pages/telemetry_screen.dart' as kero_space_telemetry_screen;

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Placeholder for $title')),
    );
  }
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaceholderScreen(title: 'Home / Dashboard'),
    ),
    GoRoute(
      path: '/productivity',
      builder: (context, state) => const ProductivityScreen(),
    ),
    GoRoute(
      path: '/note_editor',
      builder: (context, state) {
        final extraMap = state.extra as Map<String, dynamic>?;
        final note = extraMap?['note'] as Note?;
        final bloc = extraMap?['bloc'];
        return NoteEditorScreen(existingNote: note, bloc: bloc);
      },
    ),
    GoRoute(
      path: '/health',
      builder: (context, state) => BlocProvider.value(
        value: GetIt.I<HealthBloc>()..add(LoadDashboard()),
        child: const HealthDashboardScreen(),
      ),
      routes: [
        GoRoute(
          path: 'config',
          builder: (context, state) => BlocProvider.value(
            value: GetIt.I<HealthBloc>(),
            child: const CalorieConfigScreen(),
          ),
        ),
        GoRoute(
          path: 'search',
          builder: (context, state) => BlocProvider.value(
            value: GetIt.I<HealthBloc>(),
            child: const IngredientSearchScreen(),
          ),
        ),
        GoRoute(
          path: 'log',
          builder: (context, state) {
            final ingredient = state.extra as Ingredient;
            return BlocProvider.value(
              value: GetIt.I<HealthBloc>(),
              child: MealLogScreen(ingredient: ingredient),
            );
          },
        ),
      ]
    ),
    GoRoute(
      path: '/finance',
      builder: (context, state) => BlocProvider.value(
        value: GetIt.I<FinanceBloc>()..add(LoadFinanceData()),
        child: const FinanceHomeScreen(),
      ),
    ),
    GoRoute(
      path: '/church',
      builder: (context, state) => const PlaceholderScreen(title: 'Church'),
    ),
    GoRoute(
      path: '/telemetry',
      builder: (context, state) => BlocProvider.value(
        value: GetIt.I<kero_space_telemetry_bloc.TelemetryBloc>()..add(kero_space_telemetry_event.LoadTelemetryDashboard()),
        child: const kero_space_telemetry_screen.TelemetryScreen(),
      ),
    ),
  ],
);
