import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import '../../../../core/app_theme.dart';

class SubscriptionsTab extends StatelessWidget {
  final FinanceLoaded state;

  const SubscriptionsTab({super.key, required this.state});

  void _confirmDeleteSubscription(BuildContext context, Subscription sub) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgSurface,
        title: Text(
          'Delete Subscription?',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to stop tracking "${sub.name}" (${sub.amount.toStringAsFixed(2)} EGP/mo)?',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentError,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<FinanceBloc>().add(DeleteSubscriptionEvent(sub.id));
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final double totalBurn = state.subscriptions.fold(0, (sum, item) => sum + item.amount);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Burn Rate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '${totalBurn.toStringAsFixed(2)} EGP/mo',
                style: TextStyle(
                  fontSize: 18,
                  color: colors.accentError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.subscriptions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.autorenew, size: 48, color: colors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No subscriptions tracked yet.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: state.subscriptions.length,
                  itemBuilder: (context, index) {
                    final sub = state.subscriptions[index];
                    final days = sub.nextRenewalDate.difference(DateTime.now()).inDays;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: colors.bgElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: colors.borderSubtle),
                      ),
                      child: ListTile(
                        title: Text(
                          sub.name,
                          style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                        subtitle: Text(
                          days > 0
                              ? 'Renews in $days days (${sub.billingCycle.toLowerCase()})'
                              : 'Renewing today',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${sub.amount.toStringAsFixed(2)} EGP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: colors.accentError),
                              onPressed: () => _confirmDeleteSubscription(context, sub),
                              tooltip: 'Delete Subscription',
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
              label: const Text('Add Subscription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.domainFinance,
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
    final colors = context.appColors;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.bgSurface,
          title: Text(
            'Add Subscription',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
          ),
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
