import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthDashboardScreen extends StatelessWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/health/config'),
          ),
        ],
      ),
      body: BlocBuilder<HealthBloc, HealthState>(
        builder: (context, state) {
          if (state.status == HealthStatus.initial || state.status == HealthStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == HealthStatus.failure) {
            return Center(child: Text("Error: ${state.errorMessage}", style: const TextStyle(color: AppTheme.accentRose)));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildFastingToggle(context, state),
              const SizedBox(height: 16),
              _buildNutritionSummary(context, state),
              const SizedBox(height: 16),
              _buildBiometrics(context, state),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/health/search'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFastingToggle(BuildContext context, HealthState state) {
    return Card(
      child: SwitchListTile(
        title: const Text('Coptic Fasting Mode', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        subtitle: const Text('Adjusts macros to plant-based ratios', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        value: state.isFastingMode,
        activeTrackColor: AppTheme.accentViolet,
        activeColor: AppTheme.accentPrimary,
        inactiveTrackColor: AppTheme.bgElevated,
        inactiveThumbColor: AppTheme.textSecondary,
        onChanged: (val) {
          context.read<HealthBloc>().add(ToggleFastingMode(val));
        },
      ),
    );
  }

  Widget _buildNutritionSummary(BuildContext context, HealthState state) {
    double caloriesRatio = state.bmrTarget > 0 ? state.dailyCalories / state.bmrTarget : 0;
    
    // Macro Pie Chart Data
    final totalMacros = state.dailyProtein + state.dailyCarbs + state.dailyFat;
    final proRatio = totalMacros > 0 ? (state.dailyProtein / totalMacros) * 100 : 33.0;
    final carbRatio = totalMacros > 0 ? (state.dailyCarbs / totalMacros) * 100 : 33.0;
    final fatRatio = totalMacros > 0 ? (state.dailyFat / totalMacros) * 100 : 34.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today\'s Nutrition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: caloriesRatio,
                        strokeWidth: 10,
                        backgroundColor: AppTheme.bgElevated,
                        color: caloriesRatio > 1.0 ? AppTheme.accentRose : AppTheme.accentMint,
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${state.dailyCalories.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textPrimary)),
                            Text('/ ${state.bmrTarget.toInt()} kcal', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  width: 100,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 20,
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.accentCyan,
                          value: proRatio,
                          title: '',
                          radius: 20,
                        ),
                        PieChartSectionData(
                          color: AppTheme.accentGold,
                          value: carbRatio,
                          title: '',
                          radius: 20,
                        ),
                        PieChartSectionData(
                          color: AppTheme.accentRose,
                          value: fatRatio,
                          title: '',
                          radius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMacroLegend('Protein', '${state.dailyProtein.toStringAsFixed(0)}g', AppTheme.accentCyan),
                    const SizedBox(height: 8),
                    _buildMacroLegend('Carbs', '${state.dailyCarbs.toStringAsFixed(0)}g', AppTheme.accentGold),
                    const SizedBox(height: 8),
                    _buildMacroLegend('Fat', '${state.dailyFat.toStringAsFixed(0)}g', AppTheme.accentRose),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMacroLegend(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildBiometrics(BuildContext context, HealthState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Biometrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBioIcon(Icons.directions_walk, '${state.steps.toInt()}', 'Steps'),
                _buildBioIcon(Icons.favorite, '${state.heartRate.toInt()}', 'HR (bpm)'),
                _buildBioIcon(Icons.bedtime, (state.sleepMinutes / 60).toStringAsFixed(1), 'Sleep (hrs)'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBioIcon(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.accentMint),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}
