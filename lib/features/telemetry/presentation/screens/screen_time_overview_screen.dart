import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_state.dart';

class ScreenTimeOverviewScreen extends StatelessWidget {
  const ScreenTimeOverviewScreen({super.key});

  String _fmt(int ms) {
    final h = ms ~/ 3600000; final m = (ms % 3600000) ~/ 60000;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      if (state.status == TelemetryStatus.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Hero metric
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Today's Screen Time",
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text(_fmt(state.todayScreenTimeMs),
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(color: AppTheme.accentCyan)),
            ]),
          ),
          const SizedBox(height: 24),
          Text('7-Day Trend', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          SizedBox(height: 180, child: _WeeklyChart(data: state.weeklyScreenTime)),
          const SizedBox(height: 24),
          Text('App Breakdown Today', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          SizedBox(height: 260, child: _AppPieChart(apps: state.todayTopApps)),
        ]),
      );
    });
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<(DateTime, int)> data;
  const _WeeklyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data yet', style: TextStyle(color: AppTheme.textSecondary)));
    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.$2 / 60000.0)).toList();
    return LineChart(LineChartData(
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, color: AppTheme.accentCyan, barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: AppTheme.accentCyan.withValues(alpha: 0.1)),
      )],
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22)),
      ),
    ));
  }
}

class _AppPieChart extends StatelessWidget {
  final List apps;
  const _AppPieChart({required this.apps});
  static const _colors = [
    AppTheme.accentCyan, AppTheme.accentMint, AppTheme.accentGold, AppTheme.accentViolet,
    AppTheme.accentRose,
  ];

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) return const Center(child: Text('No usage data yet', style: TextStyle(color: AppTheme.textSecondary)));
    final sections = apps.asMap().entries.map((e) => PieChartSectionData(
      value: (e.value.foregroundMs as int).toDouble(),
      color: _colors[e.key % _colors.length],
      radius: 80, showTitle: false,
    )).toList();
    return PieChart(PieChartData(sections: sections, centerSpaceRadius: 50, sectionsSpace: 2));
  }
}
