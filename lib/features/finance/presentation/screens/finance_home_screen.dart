import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';

class FinanceHomeScreen extends StatefulWidget {
  const FinanceHomeScreen({super.key});

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends State<FinanceHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(LoadFinanceData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Module'),
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FinanceLoaded) {
            return IndexedStack(
              index: _currentIndex,
              children: [
                _buildTransactionsTab(state),
                _buildBudgetsTab(state),
                _buildPortfolioTab(state),
              ],
            );
          } else if (state is FinanceError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Initialize Finance'));
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Budgets'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Portfolio'),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(FinanceLoaded state) {
    return ListView.builder(
      itemCount: state.transactions.length,
      itemBuilder: (context, index) {
        final tx = state.transactions[index];
        final isIncome = tx.type == 'INCOME';
        return ListTile(
          leading: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
          title: Text(tx.vendor ?? 'Unknown Vendor'),
          subtitle: Text('${tx.category} • ${tx.date.toString().substring(0, 10)}'),
          trailing: Text(
            '${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} EGP',
            style: TextStyle(
              color: isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetsTab(FinanceLoaded state) {
    return ListView.builder(
      itemCount: state.budgets.length,
      itemBuilder: (context, index) {
        final budget = state.budgets[index];
        
        // Calculate spent amount
        double spent = 0;
        for (var tx in state.transactions) {
          if (tx.type == 'EXPENSE' && tx.category == budget.category) {
            spent += tx.amount;
          }
        }
        
        final double percentage = (spent / budget.monthlyLimit).clamp(0.0, 1.0);

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(budget.category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage,
                  color: percentage >= 1.0 ? Colors.red : Colors.blue,
                ),
                const SizedBox(height: 8),
                Text('${spent.toStringAsFixed(2)} EGP / ${budget.monthlyLimit.toStringAsFixed(2)} EGP'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioTab(FinanceLoaded state) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('EGX Watchlist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.watchlist.length,
            itemBuilder: (context, index) {
              final stock = state.watchlist[index];
              final price = state.tickerPrices[stock.ticker];
              
              return ListTile(
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
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        context.read<FinanceBloc>().add(RemoveFromWatchlistEvent(stock.ticker));
                      },
                    )
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              _showAddWatchlistDialog(context);
            },
            child: const Text('Add to Watchlist'),
          ),
        ),
        const SizedBox(height: 16),
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
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Company Name'),
                onChanged: (val) => name = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (ticker.isNotEmpty && name.isNotEmpty) {
                  context.read<FinanceBloc>().add(AddToWatchlistEvent(ticker.toUpperCase(), name));
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
