import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/app_theme.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';

class PortfolioTab extends StatelessWidget {
  final FinanceLoaded state;

  const PortfolioTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'EGX Watchlist & Technical Sentiment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<FinanceBloc>().add(RefreshStockPrices());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: state.watchlist.isEmpty
                ? const Center(
                    child: Text(
                      'Your watchlist is empty.\nAdd a ticker like COMI to track it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: state.watchlist.length,
                    itemBuilder: (context, index) {
                      final stock = state.watchlist[index];
                      final price = state.tickerPrices[stock.ticker];
                      final dailyPct = state.tickerDailyChanges[stock.ticker] ?? 0.0;
                      final monthlyPct = state.tickerMonthlyChanges[stock.ticker] ?? 0.0;
                      final sentiment = state.tickerSentiments[stock.ticker] ?? 'Neutral';
                      final priceHistory = state.tickerHistories[stock.ticker] ?? [];

                      final isUp = dailyPct >= 0;
                      final trendColor = isUp ? AppTheme.accentMint : AppTheme.accentRose;

                      // Make spark points
                      final List<FlSpot> spots = [];
                      for (int i = 0; i < priceHistory.length; i++) {
                        spots.add(FlSpot(i.toDouble(), priceHistory[i]));
                      }

                      return Card(
                        color: AppTheme.bgElevated,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      stock.ticker,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16, color: AppTheme.accentRose),
                                    onPressed: () {
                                      context.read<FinanceBloc>().add(RemoveFromWatchlistEvent(stock.ticker));
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                price != null ? '${price.toStringAsFixed(2)} EGP' : 'Scraping...',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: trendColor),
                              ),
                              Text(
                                '${isUp ? "+" : ""}${dailyPct.toStringAsFixed(2)}%',
                                style: TextStyle(fontSize: 12, color: trendColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              
                              // Monthly change indicator
                              Text(
                                'Monthly: ${monthlyPct >= 0 ? "+" : ""}${monthlyPct.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 6),

                              // Sentiment Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: sentiment.contains('Bullish') 
                                      ? AppTheme.accentMint.withValues(alpha: 0.15) 
                                      : sentiment.contains('Bearish')
                                          ? AppTheme.accentRose.withValues(alpha: 0.15)
                                          : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: sentiment.contains('Bullish') 
                                        ? AppTheme.accentMint 
                                        : sentiment.contains('Bearish')
                                            ? AppTheme.accentRose
                                            : Colors.grey,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  sentiment,
                                  style: TextStyle(
                                    fontSize: 9, 
                                    fontWeight: FontWeight.bold,
                                    color: sentiment.contains('Bullish') 
                                        ? AppTheme.accentMint 
                                        : sentiment.contains('Bearish')
                                            ? AppTheme.accentRose
                                            : Colors.grey,
                                  ),
                                ),
                              ),
                              const Spacer(),

                              // Mini Sparkline Graph
                              if (spots.length >= 2)
                                SizedBox(
                                  height: 40,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: const FlGridData(show: false),
                                      titlesData: const FlTitlesData(show: false),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: spots,
                                          isCurved: true,
                                          color: trendColor,
                                          barWidth: 2,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(show: false),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(
                                  height: 40,
                                  child: Center(
                                    child: Text('Gathering chart data...', style: TextStyle(fontSize: 8, color: AppTheme.textSecondary)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddWatchlistDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add to Watchlist'),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddWatchlistDialog(BuildContext context) {
    String ticker = '';
    String name = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Watchlist Symbol'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Ticker (e.g. COMI)'),
                onChanged: (val) => ticker = val,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Company Name'),
                onChanged: (val) => name = val,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (ticker.trim().isNotEmpty && name.trim().isNotEmpty) {
                  context.read<FinanceBloc>().add(AddToWatchlistEvent(ticker.trim().toUpperCase(), name.trim()));
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
