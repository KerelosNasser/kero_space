import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:kero_space/features/finance/presentation/widgets/overview_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/transactions_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/subscriptions_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/portfolio_tab.dart';
import 'package:kero_space/shared/widgets/shimmer/finance_skeleton.dart';
import 'package:kero_space/shared/widgets/inline_error_widget.dart';

class FinanceHomeScreen extends StatefulWidget {
  const FinanceHomeScreen({super.key});

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends State<FinanceHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(LoadFinanceData());
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await NotificationsListener.hasPermission;
    if (hasPermission != true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification access needed to auto-log transactions.'),
          action: SnackBarAction(
            label: 'GRANT',
            onPressed: () => NotificationsListener.openPermissionSettings(),
          ),
          duration: const Duration(days: 1), // Keeps it visible
        ),
      );
    } else {
      final isRunning = await NotificationsListener.isRunning;
      if (isRunning != true) {
        await NotificationsListener.startService(foreground: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kero Money Hub'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Txns'),
              Tab(icon: Icon(Icons.autorenew), text: 'Subs'),
              Tab(icon: Icon(Icons.show_chart), text: 'Stocks'),
            ],
          ),
        ),
        body: BlocBuilder<FinanceBloc, FinanceState>(
          builder: (context, state) {
            if (state is FinanceLoading) {
              return const FinanceSkeleton();
            } else if (state is FinanceLoaded) {
              return TabBarView(
                children: [
                  OverviewTab(state: state),
                  TransactionsTab(state: state),
                  SubscriptionsTab(state: state),
                  PortfolioTab(state: state),
                ],
              );
            } else if (state is FinanceError) {
              return InlineErrorWidget(
                message: state.message,
                onRetry: () => context.read<FinanceBloc>().add(LoadFinanceData()),
              );
            }
            return const Center(child: Text('Initialize Finance'));
          },
        ),
      ),
    );
  }
}
