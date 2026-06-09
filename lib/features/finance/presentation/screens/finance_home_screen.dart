import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:kero_space/features/finance/presentation/widgets/transactions_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/budgets_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/portfolio_tab.dart';

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
                TransactionsTab(state: state),
                BudgetsTab(state: state),
                PortfolioTab(state: state),
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

}
