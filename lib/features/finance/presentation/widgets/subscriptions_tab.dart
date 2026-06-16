import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import '../../../../core/app_theme.dart';

class SubscriptionsTab extends StatelessWidget {
  final FinanceLoaded state;

  const SubscriptionsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final double totalBurn = state.subscriptions.fold(0, (sum, item) => sum + item.amount);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentRose.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Burn Rate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${totalBurn.toStringAsFixed(2)} EGP/mo', style: const TextStyle(fontSize: 18, color: AppTheme.accentRose, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: state.subscriptions.isEmpty
              ? const Center(
                  child: Text('No subscriptions tracked yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                )
              : ListView.builder(
                  itemCount: state.subscriptions.length,
                  itemBuilder: (context, index) {
                    final sub = state.subscriptions[index];
                    final days = sub.nextRenewalDate.difference(DateTime.now()).inDays;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: AppTheme.bgElevated,
                      child: ListTile(
                        title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          days > 0 ? 'Renews in $days days (${sub.billingCycle.toLowerCase()})' : 'Renewing today',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${sub.amount.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppTheme.accentRose),
                              onPressed: () => context.read<FinanceBloc>().add(DeleteSubscriptionEvent(sub.id)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddSubscriptionDialog(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Subscription', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRose,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        )
      ],
    );
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    String name = '';
    double amount = 0;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Subscription Name (e.g. Spotify)'),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Amount (EGP)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => amount = double.tryParse(val) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (name.trim().isNotEmpty && amount > 0) {
                  context.read<FinanceBloc>().add(AddSubscriptionEvent(
                    name: name.trim(),
                    amount: amount,
                    billingCycle: 'MONTHLY',
                    nextRenewalDate: DateTime.now().add(const Duration(days: 30)),
                    isAutoRenew: true,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }
}
