part of 'finance_bloc.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final List<EGXWatchlist> watchlist;
  final Map<String, double> tickerPrices;
  final Map<String, double> tickerDailyChanges;
  final Map<String, double> tickerMonthlyChanges;
  final Map<String, String> tickerSentiments;
  final Map<String, List<double>> tickerHistories;
  final double totalIncome;
  final double totalExpense;
  final List<MoneySource> moneySources;
  final List<Subscription> subscriptions;
  final String? aiAdvice;

  const FinanceLoaded({
    required this.transactions,
    required this.budgets,
    required this.watchlist,
    required this.tickerPrices,
    required this.tickerDailyChanges,
    required this.tickerMonthlyChanges,
    required this.tickerSentiments,
    required this.tickerHistories,
    required this.totalIncome,
    required this.totalExpense,
    required this.moneySources,
    required this.subscriptions,
    this.aiAdvice,
  });

  @override
  List<Object?> get props => [
        transactions,
        budgets,
        watchlist,
        tickerPrices,
        tickerDailyChanges,
        tickerMonthlyChanges,
        tickerSentiments,
        tickerHistories,
        totalIncome,
        totalExpense,
        moneySources,
        subscriptions,
        aiAdvice,
      ];
}

class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}
