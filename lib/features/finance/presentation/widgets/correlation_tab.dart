import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';

class CorrelationTab extends StatelessWidget {
  final FinanceLoaded state;

  const CorrelationTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> earningsSpots = [];
    final List<FlSpot> caloricSpots = [];
    
    for (int i = 0; i < state.correlationTimeline.length; i++) {
      final point = state.correlationTimeline[i];
      earningsSpots.add(FlSpot(i.toDouble(), point.cumulativeWealth));
      caloricSpots.add(FlSpot(i.toDouble(), point.dailyCaloricSurplus));
    }

    if (earningsSpots.isEmpty) {
      earningsSpots.add(const FlSpot(0, 0));
    }
    if (caloricSpots.isEmpty) {
      caloricSpots.add(const FlSpot(0, 0));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Wealth vs Health Correlation',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Tracking Net Earnings vs Daily Caloric Intake'),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: const LineTouchData(enabled: true),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: earningsSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.1)),
                  ),
                  LineChartBarData(
                    spots: caloricSpots,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green, 'Net Earnings (EGP)'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.orange, 'Caloric Intake (kcal)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
