import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';

class DeepNutritionCards extends StatelessWidget {
  const DeepNutritionCards({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HealthBloc, HealthState>(
      builder: (context, state) {
        // Removed the dailyCalories == 0 check to always show the UI framework

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Deep Nutrition',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _buildCarbCard(state),
            const SizedBox(height: 12),
            _buildFatCard(state),
            const SizedBox(height: 12),
            _buildMicrosCard(state),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildCarbCard(HealthState state) {
    final double totalCarbs = state.dailyCarbs;

    final double fastCarbs = state.dailyFastCarbs;
    final double slowCarbs = state.dailySlowCarbs;
    final double fiber = state.dailyFiber;
    final double sugar = state.dailySugar;

    return _NutritionExpandableCard(
      title: 'Carbohydrates',
      totalValue: '${totalCarbs.toStringAsFixed(1)}g',
      icon: Icons.grain,
      iconColor: AppTheme.accentMint,
      children: [
        _buildHorizontalStackedBar([
          _BarSegment(fastCarbs, AppTheme.accentRose, 'Fast'),
          _BarSegment(slowCarbs, AppTheme.accentViolet, 'Slow'),
          _BarSegment(fiber, AppTheme.accentMint, 'Fiber'),
        ]),
        const SizedBox(height: 16),
        _buildDetailRow('Fast Carbs', '${fastCarbs.toStringAsFixed(1)}g', AppTheme.accentRose),
        _buildDetailRow('Slow Carbs', '${slowCarbs.toStringAsFixed(1)}g', AppTheme.accentViolet),
        _buildDetailRow('Fiber', '${fiber.toStringAsFixed(1)}g', AppTheme.accentMint),
        _buildDetailRow('Sugars', '${sugar.toStringAsFixed(1)}g', Colors.orange),
      ],
    );
  }

  Widget _buildFatCard(HealthState state) {
    final double totalFat = state.dailyFat;

    return _NutritionExpandableCard(
      title: 'Fats',
      totalValue: '${totalFat.toStringAsFixed(1)}g',
      icon: Icons.water_drop,
      iconColor: AppTheme.accentCyan,
      children: [
         _buildHorizontalStackedBar([
          _BarSegment(state.dailyFatSaturated, AppTheme.accentRose, 'Sat'),
          _BarSegment(state.dailyFatUnsaturated, AppTheme.accentCyan, 'Unsat'),
        ]),
        const SizedBox(height: 16),
        _buildDetailRow('Saturated', '${state.dailyFatSaturated.toStringAsFixed(1)}g', AppTheme.accentRose),
        _buildDetailRow('Unsaturated', '${state.dailyFatUnsaturated.toStringAsFixed(1)}g', AppTheme.accentCyan),
      ],
    );
  }

  Widget _buildMicrosCard(HealthState state) {
    return _NutritionExpandableCard(
      title: 'Micros & Indexes',
      totalValue: 'View',
      icon: Icons.science,
      iconColor: AppTheme.accentViolet,
      children: [
        _buildDetailRow('Cholesterol', '${state.dailyCholesterol.toStringAsFixed(1)}mg', Colors.yellow),
        _buildDetailRow('Sodium', '${state.dailySodium.toStringAsFixed(1)}mg', Colors.grey),
        // Glycemic Load could be approximated if we had logic, here we just show total index for reference or omit
      ],
    );
  }

  Widget _buildHorizontalStackedBar(List<_BarSegment> segments) {
    final double total = segments.fold(0, (sum, seg) => sum + seg.value);
    if (total <= 0 || total.isNaN) return const SizedBox.shrink();

    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: segments.map((seg) {
          if (seg.value.isNaN || seg.value <= 0) return const SizedBox.shrink();
          final int flex = (seg.value / total * 100).round();
          if (flex == 0) return const SizedBox.shrink();
          return Expanded(
            flex: flex,
            child: Container(color: seg.color),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BarSegment {
  final double value;
  final Color color;
  final String label;
  _BarSegment(this.value, this.color, this.label);
}

class _NutritionExpandableCard extends StatefulWidget {
  final String title;
  final String totalValue;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _NutritionExpandableCard({
    required this.title,
    required this.totalValue,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  State<_NutritionExpandableCard> createState() => _NutritionExpandableCardState();
}

class _NutritionExpandableCardState extends State<_NutritionExpandableCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppTheme.bgElevated,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (val) => setState(() => _isExpanded = val),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 20),
            ),
            title: Text(
              widget.title,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.totalValue,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
            children: widget.children,
          ),
        ),
      ),
    );
  }
}
