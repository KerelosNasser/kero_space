part of 'finance_bloc.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object> get props => [];
}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final List<EGXWatchlist> watchlist;
  final Map<String, double> tickerPrices;
  final double totalIncome;
  final double totalExpense;
  final List<CareerTask> careerTasks;
  // We use dynamic here to avoid importing health models directly, or we can just import health models in finance_bloc.dart
  final List<dynamic> recentMeals;

  const FinanceLoaded({
    required this.transactions,
    required this.budgets,
    required this.watchlist,
    required this.tickerPrices,
    required this.totalIncome,
    required this.totalExpense,
    required this.careerTasks,
    required this.recentMeals,
  });

  @override
  List<Object> get props => [
        transactions,
        budgets,
        watchlist,
        tickerPrices,
        totalIncome,
        totalExpense,
        careerTasks,
        recentMeals,
      ];
}

class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object> get props => [message];
}
