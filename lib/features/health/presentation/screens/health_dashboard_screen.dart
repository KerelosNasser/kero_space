import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/features/exercises/presentation/widgets/exercises_tab.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/features/health/presentation/widgets/radial_progress_painter.dart';
import 'package:kero_space/shared/widgets/inline_error_widget.dart';
import 'package:kero_space/shared/widgets/shimmer/health_skeleton.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNutritionTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: context.appColors.bgBase,
      appBar: AppBar(
        title: const Text('Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/health/config'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nutrition'),
            Tab(text: 'Exercises'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_NutritionDashboardTab(), ExercisesTab()],
      ),
      floatingActionButton: isNutritionTab
          ? FloatingActionButton(
              onPressed: () => context.push('/health/search'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _NutritionDashboardTab extends StatelessWidget {
  const _NutritionDashboardTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HealthBloc, HealthState>(
      builder: (context, state) {
        if (state.status == HealthStatus.initial ||
            state.status == HealthStatus.loading) {
          return const HealthSkeleton();
        }
        if (state.status == HealthStatus.failure) {
          return InlineErrorWidget(
            message: state.errorMessage ?? 'An error occurred',
            onRetry: () => context.read<HealthBloc>().add(LoadDashboard()),
          );
        }

        final dailyCalories = state.dailyCalories.isNaN
            ? 0.0
            : state.dailyCalories;
        final targetBmr = state.bmrTarget > 0
            ? (state.bmrTarget.isNaN ? 2000.0 : state.bmrTarget)
            : 2000.0;
        final caloriesRatio = dailyCalories / targetBmr;
        final dailyProtein = state.dailyProtein.isNaN
            ? 0.0
            : state.dailyProtein;
        final dailyCarbs = state.dailyCarbs.isNaN ? 0.0 : state.dailyCarbs;
        final dailyFat = state.dailyFat.isNaN ? 0.0 : state.dailyFat;
        final proteinTarget = (targetBmr * 0.30) / 4;
        final carbsTarget = (targetBmr * 0.40) / 4;
        final fatTarget = (targetBmr * 0.30) / 9;

        final colors = context.appColors;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.borderSubtle,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutrition Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
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
                                  context: context,
                                  label: 'Protein',
                                  current: dailyProtein,
                                  target: proteinTarget,
                                  color: colors.accentDanger,
                                ),
                                _buildMacroProgressBar(
                                  context: context,
                                  label: 'Carbs',
                                  current: dailyCarbs,
                                  target: carbsTarget,
                                  color: colors.accentPrimary,
                                ),
                                _buildMacroProgressBar(
                                  context: context,
                                  label: 'Fats',
                                  current: dailyFat,
                                  target: fatTarget,
                                  color: colors.accentWarning,
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: DeepNutritionSegmentedCard(state: state),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSquareCard(
                      context,
                      Icons.directions_walk,
                      '${state.steps.toInt()}',
                      'Steps',
                      colors.accentPrimary,
                    ),
                    _buildSquareCard(
                      context,
                      Icons.favorite,
                      '${state.heartRate.toInt()}',
                      'HR (bpm)',
                      colors.accentDanger,
                    ),
                    _buildSquareCard(
                      context,
                      Icons.bedtime,
                      (state.sleepMinutes / 60).toStringAsFixed(1),
                      'Sleep (h)',
                      colors.accentWarning,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Meals",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (state.todayMeals.isNotEmpty)
                      Text(
                        '${state.todayMeals.length} logged',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (state.todayMeals.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lunch_dining_outlined,
                          size: 56,
                          color: colors.domainHealth.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No meals logged yet today',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Search foods or scan ingredients to track your daily macros.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final meal = state.todayMeals[index];
                    final mealProtein = meal.protein.isNaN ? 0.0 : meal.protein;
                    final mealCarbs = meal.carbs.isNaN ? 0.0 : meal.carbs;
                    final mealFat = meal.fat.isNaN ? 0.0 : meal.fat;
                    final mealCalories = meal.calories.isNaN
                        ? 0.0
                        : meal.calories;
                    final mealGrams = meal.grams.isNaN ? 0.0 : meal.grams;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.domainHealth.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getMealIcon(meal.mealType),
                                color: colors.domainHealth,
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
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'P: ${mealProtein.toStringAsFixed(0)}g  C: ${mealCarbs.toStringAsFixed(0)}g  F: ${mealFat.toStringAsFixed(0)}g',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${DateFormat.jm().format(meal.timestamp)} - ${meal.mealType.name.toUpperCase()} - ${mealGrams.toInt()}g',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.textSecondary.withValues(alpha: 0.7),
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'kcal',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: state.todayMeals.length),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildSquareCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    final colors = context.appColors;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colors.textSecondary,
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
    required BuildContext context,
    required String label,
    required double current,
    required double target,
    required Color color,
  }) {
    final colors = context.appColors;
    final ratio = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${current.toStringAsFixed(0)}g / ${target.toStringAsFixed(0)}g ($percentage%)',
                style: TextStyle(
                  color: colors.textSecondary,
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
              backgroundColor: colors.borderSubtle.withValues(alpha: 0.3),
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
  const DeepNutritionSegmentedCard({super.key, required this.state});

  final HealthState state;

  @override
  State<DeepNutritionSegmentedCard> createState() =>
      _DeepNutritionSegmentedCardState();
}

class _DeepNutritionSegmentedCardState
    extends State<DeepNutritionSegmentedCard> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final targetBmr = widget.state.bmrTarget > 0
        ? (widget.state.bmrTarget.isNaN ? 2000.0 : widget.state.bmrTarget)
        : 2000.0;
    final dailyProtein = widget.state.dailyProtein.isNaN
        ? 0.0
        : widget.state.dailyProtein;
    final dailyCarbs = widget.state.dailyCarbs.isNaN
        ? 0.0
        : widget.state.dailyCarbs;
    final dailyFat = widget.state.dailyFat.isNaN ? 0.0 : widget.state.dailyFat;
    final dailyFiber = widget.state.dailyFiber.isNaN
        ? 0.0
        : widget.state.dailyFiber;
    final dailySugar = widget.state.dailySugar.isNaN
        ? 0.0
        : widget.state.dailySugar;
    final dailyFastCarbs = widget.state.dailyFastCarbs.isNaN
        ? 0.0
        : widget.state.dailyFastCarbs;
    final dailySlowCarbs = widget.state.dailySlowCarbs.isNaN
        ? 0.0
        : widget.state.dailySlowCarbs;
    final dailyFatSaturated = widget.state.dailyFatSaturated.isNaN
        ? 0.0
        : widget.state.dailyFatSaturated;
    final dailyFatUnsaturated = widget.state.dailyFatUnsaturated.isNaN
        ? 0.0
        : widget.state.dailyFatUnsaturated;
    final dailyCholesterol = widget.state.dailyCholesterol.isNaN
        ? 0.0
        : widget.state.dailyCholesterol;
    final dailySodium = widget.state.dailySodium.isNaN
        ? 0.0
        : widget.state.dailySodium;
    final proteinTarget = (targetBmr * 0.30) / 4;
    final carbsTarget = (targetBmr * 0.40) / 4;
    final fatTarget = (targetBmr * 0.30) / 9;

    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deep Nutrition Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Protein', colors.accentDanger),
                _buildTabButton(1, 'Carbs', colors.accentPrimary),
                _buildTabButton(2, 'Fats', colors.accentWarning),
                _buildTabButton(3, 'Micros', colors.domainHealth),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildTabContent(
              context,
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
    final colors = context.appColors;
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
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
    final colors = context.appColors;

    if (_selectedTab == 0) {
      return Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabHeaderProgressBar(
            context: context,
            label: 'Protein',
            current: dailyProtein,
            target: proteinTarget,
            color: colors.accentDanger,
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
                context: context,
                label: 'Consumed',
                value: '${dailyProtein.toStringAsFixed(1)}g',
                color: colors.accentDanger,
                icon: Icons.fitness_center,
                subtitle: 'Daily Total Intake',
              ),
              _buildDetailGridCard(
                context: context,
                label: 'Daily Target',
                value: '${proteinTarget.toStringAsFixed(1)}g',
                color: colors.textSecondary,
                icon: Icons.flag,
                subtitle: '30% of energy goal',
              ),
            ],
          ),
        ],
      );
    }

    if (_selectedTab == 1) {
      return Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabHeaderProgressBar(
            context: context,
            label: 'Carbs',
            current: dailyCarbs,
            target: carbsTarget,
            color: colors.accentPrimary,
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
                context: context,
                label: 'Fast Carbs',
                value: '${dailyFastCarbs.toStringAsFixed(1)}g',
                color: colors.accentDanger,
                icon: Icons.bolt,
                subtitle: 'Quick absorbing sugars',
              ),
              _buildDetailGridCard(
                context: context,
                label: 'Slow Carbs',
                value: '${dailySlowCarbs.toStringAsFixed(1)}g',
                color: colors.accentPrimary,
                icon: Icons.grain,
                subtitle: 'Complex starches / grains',
              ),
              _buildDetailGridCard(
                context: context,
                label: 'Fiber',
                value: '${dailyFiber.toStringAsFixed(1)}g',
                color: colors.accentSuccess,
                icon: Icons.spa,
                subtitle: 'Target: 30g / day',
              ),
              _buildDetailGridCard(
                context: context,
                label: 'Sugars',
                value: '${dailySugar.toStringAsFixed(1)}g',
                color: colors.accentWarning,
                icon: Icons.icecream,
                subtitle: 'Limit: <36g / day',
              ),
            ],
          ),
        ],
      );
    }

    if (_selectedTab == 2) {
      return Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabHeaderProgressBar(
            context: context,
            label: 'Fats',
            current: dailyFat,
            target: dailyFatTarget,
            color: colors.accentWarning,
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
                context: context,
                label: 'Saturated Fat',
                value: '${dailyFatSaturated.toStringAsFixed(1)}g',
                color: colors.accentDanger,
                icon: Icons.opacity,
                subtitle: 'Limit: <20g / day',
              ),
              _buildDetailGridCard(
                context: context,
                label: 'Unsaturated Fat',
                value: '${dailyFatUnsaturated.toStringAsFixed(1)}g',
                color: colors.accentPrimary,
                icon: Icons.water_drop,
                subtitle: 'Healthy oils / lipids',
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Micro-nutrients & cardiovascular markers',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
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
              context: context,
              label: 'Cholesterol',
              value: '${dailyCholesterol.toStringAsFixed(0)} mg',
              color: colors.accentWarning,
              icon: Icons.donut_large,
              subtitle: 'Limit: 300 mg / day',
            ),
            _buildDetailGridCard(
              context: context,
              label: 'Sodium',
              value: '${dailySodium.toStringAsFixed(0)} mg',
              color: colors.accentPrimary,
              icon: Icons.science,
              subtitle: 'Limit: 2300 mg / day',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabHeaderProgressBar({
    required BuildContext context,
    required String label,
    required double current,
    required double target,
    required Color color,
  }) {
    final colors = context.appColors;
    final ratio = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total $label Intake',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${current.toStringAsFixed(1)}g / ${target.toStringAsFixed(0)}g ($percentage%)',
              style: TextStyle(
                color: colors.textPrimary,
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
            backgroundColor: colors.borderSubtle.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailGridCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required String subtitle,
  }) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
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
                  style: TextStyle(
                    color: colors.textSecondary,
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
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textSecondary.withValues(alpha: 0.7),
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
