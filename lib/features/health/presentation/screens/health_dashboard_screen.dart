import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:kero_space/shared/widgets/shimmer/health_skeleton.dart';
import 'package:kero_space/shared/widgets/inline_error_widget.dart';
import 'package:kero_space/features/health/presentation/widgets/radial_progress_painter.dart';

class HealthDashboardScreen extends StatelessWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
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

          // Sanitize NaN values from the BLoC state to prevent layout/display crashes
          final double dailyCalories = state.dailyCalories.isNaN ? 0.0 : state.dailyCalories;
          final double targetBmr = state.bmrTarget > 0 ? (state.bmrTarget.isNaN ? 2000.0 : state.bmrTarget) : 2000.0;
          final double caloriesRatio = dailyCalories / targetBmr;

          final double dailyProtein = state.dailyProtein.isNaN ? 0.0 : state.dailyProtein;
          final double dailyCarbs = state.dailyCarbs.isNaN ? 0.0 : state.dailyCarbs;
          final double dailyFat = state.dailyFat.isNaN ? 0.0 : state.dailyFat;

          final double proteinTarget = (targetBmr * 0.30) / 4;
          final double carbsTarget = (targetBmr * 0.40) / 4;
          final double fatTarget = (targetBmr * 0.30) / 9;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Nutrition Dashboard Hub (Overview)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nutrition Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            PremiumCalorieRing(
                              value: caloriesRatio,
                              current: dailyCalories.toInt(),
                              target: targetBmr.toInt(),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildMacroProgressBar(
                                    label: 'Protein',
                                    current: dailyProtein,
                                    target: proteinTarget,
                                    color: AppTheme.accentCyan,
                                  ),
                                  _buildMacroProgressBar(
                                    label: 'Carbs',
                                    current: dailyCarbs,
                                    target: carbsTarget,
                                    color: AppTheme.accentRose,
                                  ),
                                  _buildMacroProgressBar(
                                    label: 'Fats',
                                    current: dailyFat,
                                    target: fatTarget,
                                    color: AppTheme.accentGold,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Deep Nutrition Segmented Details Card
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: DeepNutritionSegmentedCard(state: state),
                ),
              ),

              // Biometrics Row (Steps, HR, Sleep)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSquareCard(
                        Icons.directions_walk,
                        '${state.steps.toInt()}',
                        'Steps',
                        AppTheme.accentCyan,
                      ),
                      _buildSquareCard(
                        Icons.favorite,
                        '${state.heartRate.toInt()}',
                        'HR (bpm)',
                        AppTheme.accentRose,
                      ),
                      _buildSquareCard(
                        Icons.bedtime,
                        (state.sleepMinutes / 60).toStringAsFixed(1),
                        'Sleep (h)',
                        AppTheme.accentGold,
                      ),
                    ],
                  ),
                ),
              ),

              // Meals Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Meals",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (state.todayMeals.isNotEmpty)
                        Text(
                          '${state.todayMeals.length} logged',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Meals List or Empty State
              if (state.todayMeals.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        "No meals logged yet today.",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final meal = state.todayMeals[index];
                        final mealProtein = meal.protein.isNaN ? 0.0 : meal.protein;
                        final mealCarbs = meal.carbs.isNaN ? 0.0 : meal.carbs;
                        final mealFat = meal.fat.isNaN ? 0.0 : meal.fat;
                        final mealCalories = meal.calories.isNaN ? 0.0 : meal.calories;
                        final mealGrams = meal.grams.isNaN ? 0.0 : meal.grams;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgElevated,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getMealIcon(meal.mealType),
                                    color: AppTheme.accentViolet,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        meal.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'P: ${mealProtein.toStringAsFixed(0)}g  C: ${mealCarbs.toStringAsFixed(0)}g  F: ${mealFat.toStringAsFixed(0)}g',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${DateFormat.jm().format(meal.timestamp)} • ${meal.mealType.name.toUpperCase()} • ${mealGrams.toInt()}g',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textDisabled,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${mealCalories.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Text(
                                      'kcal',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: state.todayMeals.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
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
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroProgressBar({
    required String label,
    required double current,
    required double target,
    required Color color,
  }) {
    final double ratio = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final int percentage = (ratio * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${current.toStringAsFixed(0)}g / ${target.toStringAsFixed(0)}g ($percentage%)',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppTheme.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.breakfast_dining;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.cookie;
    }
  }
}

class DeepNutritionSegmentedCard extends StatefulWidget {
  final HealthState state;

  const DeepNutritionSegmentedCard({super.key, required this.state});

  @override
  State<DeepNutritionSegmentedCard> createState() => _DeepNutritionSegmentedCardState();
}

class _DeepNutritionSegmentedCardState extends State<DeepNutritionSegmentedCard> {
  int _selectedTab = 0; // 0: Protein, 1: Carbs, 2: Fats, 3: Micros

  @override
  Widget build(BuildContext context) {
    final double targetBmr = widget.state.bmrTarget > 0 ? (widget.state.bmrTarget.isNaN ? 2000.0 : widget.state.bmrTarget) : 2000.0;

    final double dailyProtein = widget.state.dailyProtein.isNaN ? 0.0 : widget.state.dailyProtein;
    final double dailyCarbs = widget.state.dailyCarbs.isNaN ? 0.0 : widget.state.dailyCarbs;
    final double dailyFat = widget.state.dailyFat.isNaN ? 0.0 : widget.state.dailyFat;

    final double dailyFiber = widget.state.dailyFiber.isNaN ? 0.0 : widget.state.dailyFiber;
    final double dailySugar = widget.state.dailySugar.isNaN ? 0.0 : widget.state.dailySugar;
    final double dailyFastCarbs = widget.state.dailyFastCarbs.isNaN ? 0.0 : widget.state.dailyFastCarbs;
    final double dailySlowCarbs = widget.state.dailySlowCarbs.isNaN ? 0.0 : widget.state.dailySlowCarbs;
    final double dailyFatSaturated = widget.state.dailyFatSaturated.isNaN ? 0.0 : widget.state.dailyFatSaturated;
    final double dailyFatUnsaturated = widget.state.dailyFatUnsaturated.isNaN ? 0.0 : widget.state.dailyFatUnsaturated;
    final double dailyCholesterol = widget.state.dailyCholesterol.isNaN ? 0.0 : widget.state.dailyCholesterol;
    final double dailySodium = widget.state.dailySodium.isNaN ? 0.0 : widget.state.dailySodium;

    final double proteinTarget = (targetBmr * 0.30) / 4;
    final double carbsTarget = (targetBmr * 0.40) / 4;
    final double fatTarget = (targetBmr * 0.30) / 9;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deep Nutrition Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Tab bar containing 4 categories
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Protein', AppTheme.accentCyan),
                _buildTabButton(1, 'Carbs', AppTheme.accentMint),
                _buildTabButton(2, 'Fats', AppTheme.accentGold),
                _buildTabButton(3, 'Micros', AppTheme.accentViolet),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildTabContent(
              dailyProtein,
              proteinTarget,
              dailyCarbs,
              carbsTarget,
              dailyFat,
              fatTarget,
              dailyFiber,
              dailySugar,
              dailyFastCarbs,
              dailySlowCarbs,
              dailyFatSaturated,
              dailyFatUnsaturated,
              dailyCholesterol,
              dailySodium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, Color activeColor) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor.withValues(alpha: 0.25) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    double dailyProtein,
    double proteinTarget,
    double dailyCarbs,
    double carbsTarget,
    double dailyFat,
    double dailyFatTarget,
    double dailyFiber,
    double dailySugar,
    double dailyFastCarbs,
    double dailySlowCarbs,
    double dailyFatSaturated,
    double dailyFatUnsaturated,
    double dailyCholesterol,
    double dailySodium,
  ) {
    if (_selectedTab == 0) {
      return Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabHeaderProgressBar(
            label: 'Protein',
            current: dailyProtein,
            target: proteinTarget,
            color: AppTheme.accentCyan,
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDetailGridCard(
                label: 'Consumed',
                value: '${dailyProtein.toStringAsFixed(1)}g',
                color: AppTheme.accentCyan,
                icon: Icons.fitness_center,
                subtitle: 'Daily Total Intake',
              ),
              _buildDetailGridCard(
                label: 'Daily Target',
                value: '${proteinTarget.toStringAsFixed(1)}g',
                color: AppTheme.textSecondary,
                icon: Icons.flag,
                subtitle: '30% of energy goal',
              ),
            ],
          ),
        ],
      );
    } else if (_selectedTab == 1) {
      return Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabHeaderProgressBar(
            label: 'Carbs',
            current: dailyCarbs,
            target: carbsTarget,
            color: AppTheme.accentMint,
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDetailGridCard(
                label: 'Fast Carbs',
                value: '${dailyFastCarbs.toStringAsFixed(1)}g',
                color: AppTheme.accentRose,
                icon: Icons.bolt,
                subtitle: 'Quick absorbing sugars',
              ),
              _buildDetailGridCard(
                label: 'Slow Carbs',
                value: '${dailySlowCarbs.toStringAsFixed(1)}g',
                color: AppTheme.accentViolet,
                icon: Icons.grain,
                subtitle: 'Complex starches / grains',
              ),
              _buildDetailGridCard(
                label: 'Fiber',
                value: '${dailyFiber.toStringAsFixed(1)}g',
                color: AppTheme.accentMint,
                icon: Icons.spa,
                subtitle: 'Target: 30g / day',
              ),
              _buildDetailGridCard(
                label: 'Sugars',
                value: '${dailySugar.toStringAsFixed(1)}g',
                color: Colors.orange,
                icon: Icons.icecream,
                subtitle: 'Limit: <36g / day',
              ),
            ],
          ),
        ],
      );
    } else if (_selectedTab == 2) {
      return Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabHeaderProgressBar(
            label: 'Fats',
            current: dailyFat,
            target: dailyFatTarget,
            color: AppTheme.accentGold,
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDetailGridCard(
                label: 'Saturated Fat',
                value: '${dailyFatSaturated.toStringAsFixed(1)}g',
                color: AppTheme.accentRose,
                icon: Icons.opacity,
                subtitle: 'Limit: <20g / day',
              ),
              _buildDetailGridCard(
                label: 'Unsaturated Fat',
                value: '${dailyFatUnsaturated.toStringAsFixed(1)}g',
                color: AppTheme.accentCyan,
                icon: Icons.water_drop,
                subtitle: 'Healthy oils / lipids',
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        key: const ValueKey(3),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Micro-nutrients & Cardiovascular Markers',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDetailGridCard(
                label: 'Cholesterol',
                value: '${dailyCholesterol.toStringAsFixed(0)} mg',
                color: AppTheme.accentGold,
                icon: Icons.donut_large,
                subtitle: 'Limit: 300 mg / day',
              ),
              _buildDetailGridCard(
                label: 'Sodium',
                value: '${dailySodium.toStringAsFixed(0)} mg',
                color: Colors.blueGrey,
                icon: Icons.science,
                subtitle: 'Limit: 2300 mg / day',
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildTabHeaderProgressBar({
    required String label,
    required double current,
    required double target,
    required Color color,
  }) {
    final double ratio = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final int percentage = (ratio * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total $label Intake',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${current.toStringAsFixed(1)}g / ${target.toStringAsFixed(0)}g ($percentage%)',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppTheme.bgElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailGridCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textDisabled,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
