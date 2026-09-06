import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_event.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_state.dart';
import 'package:kero_space/shared/widgets/shimmer/telemetry_skeleton.dart';
import 'package:kero_space/shared/widgets/inline_error_widget.dart';

class TelemetryScreen extends StatelessWidget {
  const TelemetryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text('Telemetry', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: colors.bgBase,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.block, color: colors.accentDanger),
            tooltip: 'Configure App Blockers',
            onPressed: () => context.push('/telemetry/blacklist'),
          ),
        ],
      ),
      body: BlocBuilder<TelemetryBloc, TelemetryState>(
        builder: (context, state) {
          if (state.status == TelemetryStatus.loading) {
            return const TelemetrySkeleton();
          }
          if (state.status == TelemetryStatus.failure) {
            return InlineErrorWidget(
              message: state.errorMessage ?? 'An error occurred',
              onRetry: () => context.read<TelemetryBloc>().add(LoadTelemetryDashboard()),
            );
          }

          final hours = state.todayScreenTimeMs / (1000 * 60 * 60);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border(left: BorderSide(color: colors.domainTelemetry, width: 4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TODAY\'S SCREEN TIME', style: TextStyle(color: colors.textSecondary, fontSize: 13, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text('${hours.toStringAsFixed(1)} hours', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: SliverToBoxAdapter(
                  child: Text('WEEKLY TREND', style: TextStyle(color: colors.textSecondary, fontSize: 13, letterSpacing: 1.2)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: _buildChart(context, state.weeklyScreenTime),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: SliverToBoxAdapter(
                  child: Text('TOP APPS', style: TextStyle(color: colors.textSecondary, fontSize: 13, letterSpacing: 1.2)),
                ),
              ),
              if (state.todayTopApps.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No application usage recorded today.', style: TextStyle(color: colors.textSecondary)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final app = state.todayTopApps[index];
                      final appHours = app.foregroundMs / (1000 * 60 * 60);
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: colors.domainTelemetry.withValues(alpha: 0.15), child: Icon(Icons.apps, color: colors.domainTelemetry)),
                        title: Text(app.packageName.split('.').last, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text(app.packageName, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                        trailing: Text('${appHours.toStringAsFixed(1)}h', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
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

  Widget _buildChart(BuildContext context, List<(DateTime, int)> weeklyData) {
    final colors = context.appColors;

    if (weeklyData.isEmpty) {
      return Center(child: Text('No data yet', style: TextStyle(color: colors.textSecondary)));
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
                  return Text(days[value.toInt()], style: TextStyle(color: colors.textSecondary, fontSize: 12));
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
                color: colors.domainTelemetry,
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
