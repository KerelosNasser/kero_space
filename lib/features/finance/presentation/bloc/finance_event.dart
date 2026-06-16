part of 'finance_bloc.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadFinanceData extends FinanceEvent {}

class RefreshStockPrices extends FinanceEvent {}

class AddTransactionEvent extends FinanceEvent {
  final double amount;
  final String type;
  final String category;
  final String? vendor;
  final String? sourceName;

  const AddTransactionEvent({
    required this.amount,
    required this.type,
    required this.category,
    this.vendor,
    this.sourceName,
  });

  @override
  List<Object?> get props => [amount, type, category, vendor, sourceName];
}

class SetBudgetEvent extends FinanceEvent {
  final String category;
  final double limit;

  const SetBudgetEvent(this.category, this.limit);

  @override
  List<Object?> get props => [category, limit];
}

class AddToWatchlistEvent extends FinanceEvent {
  final String ticker;
  final String name;

  const AddToWatchlistEvent(this.ticker, this.name);

  @override
  List<Object?> get props => [ticker, name];
}

class RemoveFromWatchlistEvent extends FinanceEvent {
  final String ticker;

  const RemoveFromWatchlistEvent(this.ticker);

  @override
  List<Object?> get props => [ticker];
}

class AddMoneySourceEvent extends FinanceEvent {
  final String name;
  final double balance;

  const AddMoneySourceEvent(this.name, this.balance);

  @override
  List<Object?> get props => [name, balance];
}

class DeleteMoneySourceEvent extends FinanceEvent {
  final int id;

  const DeleteMoneySourceEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class AddSubscriptionEvent extends FinanceEvent {
  final String name;
  final double amount;
  final String billingCycle;
  final DateTime nextRenewalDate;
  final bool isAutoRenew;

  const AddSubscriptionEvent({
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.nextRenewalDate,
    required this.isAutoRenew,
  });

  @override
  List<Object?> get props => [name, amount, billingCycle, nextRenewalDate, isAutoRenew];
}

class DeleteSubscriptionEvent extends FinanceEvent {
  final int id;

  const DeleteSubscriptionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class AIQuickLogEvent extends FinanceEvent {
  final String text;

  const AIQuickLogEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class RefreshAIAdviceEvent extends FinanceEvent {}
