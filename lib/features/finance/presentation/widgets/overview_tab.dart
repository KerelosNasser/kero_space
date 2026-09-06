import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import '../../../../core/app_theme.dart';

class OverviewTab extends StatelessWidget {
  final FinanceLoaded state;
  final TextEditingController _quickLogController = TextEditingController();

  OverviewTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Calculate total cash from sources
    final double cashValuation = state.moneySources.fold(
      0,
      (sum, element) => sum + element.balance,
    );

    final double netWorth = cashValuation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Net Worth Gradient Card
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.domainFinance, colors.accentSuccess],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NET WORTH',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${netWorth.toStringAsFixed(2)} EGP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Net Gain/Loss: ${(state.totalIncome - state.totalExpense) >= 0 ? "+" : ""}${(state.totalIncome - state.totalExpense).toStringAsFixed(2)} EGP this month',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AI Quick Log Textfield
          TextField(
            controller: _quickLogController,
            decoration: InputDecoration(
              hintText: 'Type: spent 150 EGP on Transport...',
              labelText: 'AI Quick Log (Lazy Logger)',
              suffixIcon: IconButton(
                icon: Icon(Icons.send, color: colors.domainFinance),
                onPressed: () {
                  if (_quickLogController.text.trim().isNotEmpty) {
                    context.read<FinanceBloc>().add(
                      AIQuickLogEvent(_quickLogController.text),
                    );
                    _quickLogController.clear();
                  }
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Money Sources Grid (GridView)
          Text(
            'Money Sources',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: state.moneySources.length + 1,
            itemBuilder: (context, index) {
              if (index == state.moneySources.length) {
                return Card(
                  color: colors.bgElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.borderSubtle),
                  ),
                  child: InkWell(
                    onTap: () => _showAddSourceDialog(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        size: 28,
                        color: colors.domainFinance,
                      ),
                    ),
                  ),
                );
              }
              final source = state.moneySources[index];
              return Card(
                color: colors.bgElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colors.borderSubtle),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        source.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${source.balance.toStringAsFixed(2)} EGP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Top Stocks Watchlist Grid
          Text(
            'Top Stocks Watchlist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          state.watchlist.isEmpty
              ? Card(
                  color: colors.bgElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.borderSubtle),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Your watchlist is empty. Add stocks in the Stocks tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.watchlist.length,
                  itemBuilder: (context, index) {
                    final stock = state.watchlist[index];
                    final price = state.tickerPrices[stock.ticker];
                    final dailyPct =
                        state.tickerDailyChanges[stock.ticker] ?? 0.0;
                    final sentiment =
                        state.tickerSentiments[stock.ticker] ?? 'Neutral';

                    final isUp = dailyPct >= 0;
                    final trendColor = isUp
                        ? colors.accentSuccess
                        : colors.accentError;

                    return Card(
                      color: colors.bgElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: colors.borderSubtle),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 10.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  stock.ticker,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  sentiment.contains('Bullish')
                                      ? '▲'
                                      : sentiment.contains('Bearish')
                                      ? '▼'
                                      : '●',
                                  style: TextStyle(
                                    color: sentiment.contains('Bullish')
                                        ? colors.accentSuccess
                                        : sentiment.contains('Bearish')
                                        ? colors.accentError
                                        : colors.textDisabled,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              price != null
                                  ? '${price.toStringAsFixed(2)} EGP'
                                  : 'Scraping...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: trendColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24),

          // AI Advisory Card
          if (state.aiAdvice != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                border: Border.all(
                  color: colors.domainFinance.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: colors.domainFinance,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Insights',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colors.domainFinance,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        onPressed: () => context.read<FinanceBloc>().add(
                          RefreshAIAdviceEvent(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.aiAdvice!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  void _showAddSourceDialog(BuildContext context) {
    String name = '';
    double balance = 0;
    final colors = context.appColors;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.bgSurface,
          title: Text(
            'Add Money Source',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Source Name (e.g. Freelancing)',
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Initial Balance (EGP)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (val) => balance = double.tryParse(val) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.domainFinance,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (name.trim().isNotEmpty) {
                  context.read<FinanceBloc>().add(
                    AddMoneySourceEvent(name.trim(), balance),
                  );
                  Navigator.pop(ctx);
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
