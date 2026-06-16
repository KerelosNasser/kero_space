import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import '../../../../core/app_theme.dart';

class TransactionsTab extends StatelessWidget {
  final FinanceLoaded state;

  const TransactionsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Budgets Progress Section (if budgets exist)
        if (state.budgets.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
            child: Text('Category Budgets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.budgets.length,
              itemBuilder: (context, index) {
                final budget = state.budgets[index];
                double spent = 0;
                for (var tx in state.transactions) {
                  if (tx.type == 'EXPENSE' && tx.category == budget.category) {
                    spent += tx.amount;
                  }
                }
                final double percentage = budget.monthlyLimit > 0 
                    ? (spent / budget.monthlyLimit).clamp(0.0, 1.0) 
                    : 0.0;

                return Container(
                  width: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(budget.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppTheme.bgElevated,
                        color: percentage >= 1.0 ? AppTheme.accentRose : AppTheme.accentCyan,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${spent.toStringAsFixed(0)} / ${budget.monthlyLimit.toStringAsFixed(0)} EGP',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],

        const Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        Expanded(
          child: state.transactions.isEmpty
              ? const Center(
                  child: Text(
                    'No transactions recorded yet.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: state.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = state.transactions[index];
                    final isIncome = tx.type == 'INCOME';
                    
                    return Card(
                      color: AppTheme.bgElevated,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? AppTheme.accentMint : AppTheme.accentRose,
                        ),
                        title: Row(
                          children: [
                            Text(tx.vendor ?? 'Unknown Vendor', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            if (tx.isAutoParsed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tx.sourceName ?? 'Auto',
                                  style: const TextStyle(fontSize: 9, color: AppTheme.accentCyan, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text('${tx.category} • ${tx.date.toString().substring(0, 10)}'),
                        trailing: Text(
                          '${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} EGP',
                          style: TextStyle(
                            color: isIncome ? AppTheme.accentMint : AppTheme.accentRose,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddTransactionDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Log Transaction'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSetBudgetDialog(context),
                  icon: const Icon(Icons.pie_chart),
                  label: const Text('Set Budget'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    String vendor = '';
    double amount = 0;
    String type = 'EXPENSE';
    String category = 'Dining';
    String? selectedSource;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (innerContext, setState) {
            return AlertDialog(
              title: const Text('Log Transaction'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: type,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'INCOME', child: Text('Income')),
                      DropdownMenuItem(value: 'EXPENSE', child: Text('Expense')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => type = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Amount (EGP)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) => amount = double.tryParse(val) ?? 0,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Vendor / Description'),
                    onChanged: (val) => vendor = val,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: category,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Dining', child: Text('Dining')),
                      DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                      DropdownMenuItem(value: 'Groceries', child: Text('Groceries')),
                      DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                      DropdownMenuItem(value: 'Bills & Telecom', child: Text('Bills & Telecom')),
                      DropdownMenuItem(value: 'Investment', child: Text('Investment')),
                      DropdownMenuItem(value: 'Uncategorized', child: Text('Uncategorized')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String?>(
                    value: selectedSource,
                    isExpanded: true,
                    hint: const Text('Select Money Source'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No Source / Pocket Cash')),
                      ...state.moneySources.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))),
                    ],
                    onChanged: (val) {
                      setState(() => selectedSource = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (amount > 0 && vendor.trim().isNotEmpty) {
                      context.read<FinanceBloc>().add(AddTransactionEvent(
                        amount: amount,
                        type: type,
                        category: category,
                        vendor: vendor.trim(),
                        sourceName: selectedSource,
                      ));
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Log'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showSetBudgetDialog(BuildContext context) {
    String category = 'Dining';
    double limit = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (innerContext, setState) {
            return AlertDialog(
              title: const Text('Configure Budget'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: category,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Dining', child: Text('Dining')),
                      DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                      DropdownMenuItem(value: 'Groceries', child: Text('Groceries')),
                      DropdownMenuItem(value: 'Bills & Telecom', child: Text('Bills & Telecom')),
                      DropdownMenuItem(value: 'Uncategorized', child: Text('Uncategorized')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Monthly Limit (EGP)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) => limit = double.tryParse(val) ?? 0,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (limit > 0) {
                      context.read<FinanceBloc>().add(SetBudgetEvent(category, limit));
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save'),
                )
              ],
            );
          },
        );
      },
    );
  }
}
