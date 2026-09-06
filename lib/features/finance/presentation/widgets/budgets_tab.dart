import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import '../../../../core/app_theme.dart';

class BudgetsTab extends StatelessWidget {
  final FinanceLoaded state;

  const BudgetsTab({super.key, required this.state});

  void _showSetBudgetDialog(BuildContext context, [Budget? existing]) {
    final categoryController = TextEditingController(text: existing?.category ?? '');
    final limitController = TextEditingController(
      text: existing != null ? existing.monthlyLimit.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ctx.appColors;
        return AlertDialog(
          backgroundColor: colors.bgSurface,
          title: Text(
            existing == null ? 'Set New Budget' : 'Edit Budget Limit',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existing == null)
                TextField(
                  controller: categoryController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Category (e.g. Dining, Transport, Groceries)',
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Category: ${existing.category}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: limitController,
                autofocus: existing != null,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly Limit (EGP)',
                ),
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
                final cat = existing?.category ?? categoryController.text.trim();
                final limit = double.tryParse(limitController.text.trim()) ?? 0.0;
                if (cat.isNotEmpty && limit > 0) {
                  context.read<FinanceBloc>().add(SetBudgetEvent(cat, limit));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (state.budgets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 64, color: colors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'No budgets configured yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Set spending limits per category to track monthly burn and avoid overspending.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showSetBudgetDialog(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Create First Budget', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.domainFinance,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
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
          final isExceeded = spent > budget.monthlyLimit;

          return Card(
            color: colors.bgElevated,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isExceeded ? colors.accentError : colors.borderSubtle,
                width: isExceeded ? 1.5 : 1.0,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showSetBudgetDialog(context, budget),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          budget.category,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 18, color: colors.textSecondary),
                          onPressed: () => _showSetBudgetDialog(context, budget),
                          tooltip: 'Edit Limit',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: colors.bgSurface,
                      color: isExceeded ? colors.accentError : colors.domainFinance,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${spent.toStringAsFixed(2)} EGP spent',
                          style: TextStyle(
                            color: isExceeded ? colors.accentError : colors.textSecondary,
                            fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          '${budget.monthlyLimit.toStringAsFixed(2)} EGP limit',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_budget_fab',
        onPressed: () => _showSetBudgetDialog(context),
        backgroundColor: colors.domainFinance,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
