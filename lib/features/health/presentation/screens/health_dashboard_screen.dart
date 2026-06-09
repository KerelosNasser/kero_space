import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:go_router/go_router.dart';

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
            return Center(child: Text("Error: ${state.errorMessage}", style: const TextStyle(color: Colors.red)));
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
      elevation: 0,
      color: AppTheme.darkTheme.cardColor,
      child: SwitchListTile(
        title: const Text('Coptic Fasting Mode'),
        subtitle: const Text('Adjusts macros to plant-based ratios and alerts on animal products'),
        value: state.isFastingMode,
        activeThumbColor: Colors.purpleAccent,
        onChanged: (val) {
          context.read<HealthBloc>().add(ToggleFastingMode(val));
        },
      ),
    );
  }

  Widget _buildNutritionSummary(BuildContext context, HealthState state) {
    double caloriesRatio = state.bmrTarget > 0 ? state.dailyCalories / state.bmrTarget : 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today\'s Nutrition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: caloriesRatio,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        color: caloriesRatio > 1.0 ? Colors.red : Colors.greenAccent,
                      ),
                      Center(
                        child: Text(
                          '${state.dailyCalories.toInt()}\n/ ${state.bmrTarget.toInt()} kcal',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Protein: ${state.dailyProtein.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.blueAccent)),
                    const SizedBox(height: 8),
                    Text('Carbs: ${state.dailyCarbs.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.orangeAccent)),
                    const SizedBox(height: 8),
                    Text('Fat: ${state.dailyFat.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.redAccent)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBiometrics(BuildContext context, HealthState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Biometrics (Health Connect)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        Icon(icon, size: 32, color: Colors.tealAccent),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
