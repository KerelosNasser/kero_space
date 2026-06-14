import 'package:flutter/material.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import '../../../../core/app_theme.dart';

class TransactionsTab extends StatelessWidget {
  final FinanceLoaded state;

  const TransactionsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.transactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions recorded yet.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.transactions.length,
      itemBuilder: (context, index) {
        final tx = state.transactions[index];
        final isIncome = tx.type == 'INCOME';
        
        return ListTile(
          leading: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? AppTheme.accentMint : AppTheme.accentRose,
          ),
          title: Text(tx.vendor ?? 'Unknown Vendor'),
          subtitle: Text('${tx.category} • ${tx.date.toString().substring(0, 10)}'),
          trailing: Text(
            '${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} EGP',
            style: TextStyle(
              color: isIncome ? AppTheme.accentMint : AppTheme.accentRose,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
