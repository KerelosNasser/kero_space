import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_state.dart';

class TelemetryScreen extends StatelessWidget {
  const TelemetryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry'),
      ),
      body: BlocBuilder<TelemetryBloc, TelemetryState>(
        builder: (context, state) {
          if (state.status == TelemetryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TelemetryStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }

          final hours = state.todayScreenTimeMs / (1000 * 60 * 60);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Hero(
                    tag: 'hero-telemetry',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: const Border(left: BorderSide(color: AppTheme.accentGold, width: 4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TODAY\'S SCREEN TIME', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            Text('${hours.toStringAsFixed(1)} hours', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: Text('WEEKLY TREND', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, letterSpacing: 1.2)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildChart(state.weeklyScreenTime),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: SliverToBoxAdapter(
                  child: Text('TOP APPS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, letterSpacing: 1.2)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final app = state.todayTopApps[index];
                    final appHours = app.foregroundMs / (1000 * 60 * 60);
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: AppTheme.bgElevated, child: Icon(Icons.apps, color: AppTheme.accentGold)),
                      title: Text(app.packageName.split('.').last, style: const TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text(app.packageName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: Text('${appHours.toStringAsFixed(1)}h', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    );
                  },
                  childCount: state.todayTopApps.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChart(List<(DateTime, int)> weeklyData) {
    if (weeklyData.isEmpty) {
      return const Center(child: Text('No data yet', style: TextStyle(color: AppTheme.textSecondary)));
    }
    
    // Fallback if data isn't full 7 days
    final data = List<(DateTime, int)>.from(weeklyData);
    while (data.length < 7) {
      data.add((DateTime.now(), 0));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 24, // max 24 hours
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                if (value.toInt() >= 0 && value.toInt() < 7) {
                  return Text(days[value.toInt()], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          final val = data[index].$2 / (1000 * 60 * 60); // Convert to hours
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: AppTheme.accentGold,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
