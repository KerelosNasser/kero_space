import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:kero_space/features/finance/presentation/widgets/transactions_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/budgets_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/portfolio_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/correlation_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/career_tab.dart';
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
      // Start the listener service if it isn't running
      final isRunning = await NotificationsListener.isRunning;
      if (isRunning != true) {
        await NotificationsListener.startService(foreground: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance Module'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Txns'),
              Tab(icon: Icon(Icons.pie_chart), text: 'Budgets'),
              Tab(icon: Icon(Icons.trending_up), text: 'Portfolio'),
              Tab(icon: Icon(Icons.insights), text: 'Correlation'),
              Tab(icon: Icon(Icons.work), text: 'Career'),
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
                  TransactionsTab(state: state),
                  BudgetsTab(state: state),
                  PortfolioTab(state: state),
                  CorrelationTab(state: state),
                  CareerTab(state: state),
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
