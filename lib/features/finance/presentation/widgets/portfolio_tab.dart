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
              context.read<FinanceBloc>().add(const RefreshStockPrices(force: true));
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
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
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

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Ticker & Delete
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        stock.ticker,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        context.read<FinanceBloc>().add(RemoveFromWatchlistEvent(stock.ticker));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Price
                                Text(
                                  price != null ? price.toStringAsFixed(2) : 'Scraping...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: trendColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${isUp ? "▲" : "▼"} ${dailyPct.abs().toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: trendColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'EGP',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Trends Row: Monthly & Sentiment
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '30D: ${monthlyPct >= 0 ? "+" : ""}${monthlyPct.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: monthlyPct >= 0 ? AppTheme.accentMint : AppTheme.accentRose,
                                      ),
                                    ),
                                    
                                    // Sentiment Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: sentiment.contains('Bullish') 
                                            ? AppTheme.accentMint.withValues(alpha: 0.1) 
                                            : sentiment.contains('Bearish')
                                                ? AppTheme.accentRose.withValues(alpha: 0.1)
                                                : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: sentiment.contains('Bullish') 
                                              ? AppTheme.accentMint.withValues(alpha: 0.3) 
                                              : sentiment.contains('Bearish')
                                                  ? AppTheme.accentRose.withValues(alpha: 0.3)
                                                  : Colors.grey.withValues(alpha: 0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        sentiment,
                                        style: TextStyle(
                                          fontSize: 8, 
                                          fontWeight: FontWeight.bold,
                                          color: sentiment.contains('Bullish') 
                                              ? AppTheme.accentMint 
                                              : sentiment.contains('Bearish')
                                                  ? AppTheme.accentRose
                                                  : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),

                                // Mini Sparkline Graph
                                if (spots.length >= 2)
                                  SizedBox(
                                    height: 36,
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
                                            belowBarData: BarAreaData(
                                              show: true,
                                              gradient: LinearGradient(
                                                colors: [
                                                  trendColor.withValues(alpha: 0.15),
                                                  trendColor.withValues(alpha: 0.0)
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(
                                    height: 36,
                                    child: Center(
                                      child: Text(
                                        'Gathering chart data...', 
                                        style: TextStyle(fontSize: 8, color: AppTheme.textSecondary),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
