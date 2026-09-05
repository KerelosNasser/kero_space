import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/features/home/presentation/screens/home_screen.dart';
import 'package:kero_space/features/productivity/presentation/bloc/productivity_bloc.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:kero_space/features/church/presentation/bloc/church_bloc.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_event.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_state.dart';

class FakeProductivityBloc extends Bloc<ProductivityEvent, ProductivityState> implements ProductivityBloc {
  FakeProductivityBloc() : super(const ProductivityState.loaded(
    allTasks: [],
    dailyChecklist: [],
    allNotes: [],
  ));
}

class FakeHealthBloc extends Bloc<HealthEvent, HealthState> implements HealthBloc {
  FakeHealthBloc() : super(const HealthState(steps: 4200));
}

class FakeFinanceBloc extends Bloc<FinanceEvent, FinanceState> implements FinanceBloc {
  FakeFinanceBloc() : super(const FinanceLoaded(
    transactions: [],
    budgets: [],
    watchlist: [],
    tickerPrices: {},
    tickerDailyChanges: {},
    tickerMonthlyChanges: {},
    tickerSentiments: {},
    tickerHistories: {},
    totalIncome: 12500,
    totalExpense: 5000,
    moneySources: [],
    subscriptions: [],
  ));
}

class FakeChurchBloc extends Bloc<ChurchEvent, ChurchState> implements ChurchBloc {
  FakeChurchBloc() : super(const ChurchState(currentStreak: 5));
}

class FakeTelemetryBloc extends Bloc<TelemetryEvent, TelemetryState> implements TelemetryBloc {
  FakeTelemetryBloc() : super(const TelemetryState(todayScreenTimeMs: 7200000));
}

void main() {
  testWidgets('HomeScreen renders without exception in Dark Mode', (tester) async {
    final prodBloc = FakeProductivityBloc();
    final healthBloc = FakeHealthBloc();
    final financeBloc = FakeFinanceBloc();
    final churchBloc = FakeChurchBloc();
    final telemetryBloc = FakeTelemetryBloc();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProductivityBloc>.value(value: prodBloc),
          BlocProvider<HealthBloc>.value(value: healthBloc),
          BlocProvider<FinanceBloc>.value(value: financeBloc),
          BlocProvider<ChurchBloc>.value(value: churchBloc),
          BlocProvider<TelemetryBloc>.value(value: telemetryBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Trobio'), findsOneWidget);
    expect(find.text("TODAY'S FOCUS"), findsOneWidget);
    expect(find.text("4200 steps"), findsOneWidget);
    expect(find.text("2.0 h"), findsOneWidget);
    expect(find.text("EGP 12500"), findsOneWidget);
    expect(find.text("5d streak"), findsOneWidget);
  });

  testWidgets('HomeScreen renders without exception in Light Mode across themes', (tester) async {
    final prodBloc = FakeProductivityBloc();
    final healthBloc = FakeHealthBloc();
    final financeBloc = FakeFinanceBloc();
    final churchBloc = FakeChurchBloc();
    final telemetryBloc = FakeTelemetryBloc();

    for (final themeId in AppThemeId.values) {
      final lightTheme = AppTheme.getThemeData(themeId, isDark: false);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ProductivityBloc>.value(value: prodBloc),
            BlocProvider<HealthBloc>.value(value: healthBloc),
            BlocProvider<FinanceBloc>.value(value: financeBloc),
            BlocProvider<ChurchBloc>.value(value: churchBloc),
            BlocProvider<TelemetryBloc>.value(value: telemetryBloc),
          ],
          child: MaterialApp(
            theme: lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Trobio'), findsOneWidget);
    }
  });
}
