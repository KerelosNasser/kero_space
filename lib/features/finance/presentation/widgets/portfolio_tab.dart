import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          child: Text('EGX Watchlist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                : ListView.builder(
                    itemCount: state.watchlist.length,
                    itemBuilder: (context, index) {
                      final stock = state.watchlist[index];
                      final price = state.tickerPrices[stock.ticker];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(stock.ticker, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(stock.companyName),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                price != null ? '${price.toStringAsFixed(2)} EGP' : 'Loading...',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: AppTheme.accentRose),
                                onPressed: () {
                                  context.read<FinanceBloc>().add(RemoveFromWatchlistEvent(stock.ticker));
                                },
                              )
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
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
                decoration: const InputDecoration(labelText: 'Ticker (e.g. COMI)', hintText: 'COMI'),
                onChanged: (val) => ticker = val,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Company Name', hintText: 'Commercial International Bank'),
                onChanged: (val) => name = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
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
