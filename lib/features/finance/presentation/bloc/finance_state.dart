part of 'finance_bloc.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class CorrelationDataPoint extends Equatable {
  final DateTime date;
  final double cumulativeWealth;
  final double dailyCaloricSurplus;

  const CorrelationDataPoint({
    required this.date,
    required this.cumulativeWealth,
    required this.dailyCaloricSurplus,
  });

  @override
  List<Object?> get props => [date, cumulativeWealth, dailyCaloricSurplus];
}

class FinanceLoaded extends FinanceState {
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final List<EGXWatchlist> watchlist;
  final Map<String, double> tickerPrices;
  final double totalIncome;
  final double totalExpense;
  final List<CareerTask> careerTasks;
  final List<CorrelationDataPoint> correlationTimeline;

  const FinanceLoaded({
    required this.transactions,
    required this.budgets,
    required this.watchlist,
    required this.tickerPrices,
    required this.totalIncome,
    required this.totalExpense,
    required this.careerTasks,
    required this.correlationTimeline,
  });

  @override
  List<Object?> get props => [
        transactions,
        budgets,
        watchlist,
        tickerPrices,
        totalIncome,
        totalExpense,
        careerTasks,
        correlationTimeline,
      ];
}

class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}
