import 'package:flutter/material.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';

class BudgetsTab extends StatelessWidget {
  final FinanceLoaded state;

  const BudgetsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.budgets.isEmpty) {
      return const Center(
        child: Text(
          'No budgets configured.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

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
        
        final double percentage = budget.monthlyLimit > 0 
            ? (spent / budget.monthlyLimit).clamp(0.0, 1.0) 
            : 0.0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(budget.category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.grey[800],
                  color: percentage >= 1.0 ? Colors.red : Colors.blue,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${spent.toStringAsFixed(2)} EGP spent', style: const TextStyle(color: Colors.grey)),
                    Text('${budget.monthlyLimit.toStringAsFixed(2)} EGP limit', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
