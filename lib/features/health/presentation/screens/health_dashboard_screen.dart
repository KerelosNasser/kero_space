import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:kero_space/shared/widgets/shimmer/health_skeleton.dart';
import 'package:kero_space/shared/widgets/inline_error_widget.dart';
import 'package:kero_space/features/health/presentation/widgets/deep_nutrition_cards.dart';

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
            return const HealthSkeleton();
          }
          if (state.status == HealthStatus.failure) {
            return InlineErrorWidget(
              message: state.errorMessage ?? 'An error occurred',
              onRetry: () => context.read<HealthBloc>().add(LoadDashboard()),
            );
          }

          double caloriesRatio = state.bmrTarget > 0 ? state.dailyCalories / state.bmrTarget : 0;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const SizedBox(height: 24),
              // The Top Big Circle
              Center(
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: caloriesRatio,
                        strokeWidth: 15,
                        backgroundColor: AppTheme.bgElevated,
                        color: caloriesRatio > 1.0 ? AppTheme.accentRose : AppTheme.accentMint,
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${state.dailyCalories.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 36, color: AppTheme.textPrimary)),
                            Text('/ ${state.bmrTarget.toInt()} kcal', style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // The Middle 3 Squares
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSquareCard(Icons.directions_walk, '${state.steps.toInt()}', 'Steps', AppTheme.accentCyan),
                  _buildSquareCard(Icons.favorite, '${state.heartRate.toInt()}', 'HR (bpm)', AppTheme.accentRose),
                  _buildSquareCard(Icons.bedtime, (state.sleepMinutes / 60).toStringAsFixed(1), 'Sleep (h)', AppTheme.accentGold),
                ],
              ),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Text("Today's Meals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ),
              const SizedBox(height: 16),
              // The Bottom List
              if (state.todayMeals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: Text("No meals logged yet today.", style: TextStyle(color: AppTheme.textSecondary))),
                )
              else
                ...state.todayMeals.map((meal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.bgElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.fastfood, color: AppTheme.accentViolet),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(meal.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                const SizedBox(height: 4),
                                Text('${DateFormat.jm().format(meal.timestamp)} • ${meal.mealType.name.toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          Text('${meal.calories.toInt()} kcal', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ],
                      ),
                    )),
              const SizedBox(height: 32),
              // Deep Nutrition Cards
              const DeepNutritionCards(),
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

  Widget _buildSquareCard(IconData icon, String value, String label, Color iconColor) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
