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

  const AddTransactionEvent({
    required this.amount,
    required this.type,
    required this.category,
    this.vendor,
  });

  @override
  List<Object?> get props => [amount, type, category, vendor];
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

class AddCareerTaskEvent extends FinanceEvent {
  final CareerTask task;

  const AddCareerTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateCareerTaskStatusEvent extends FinanceEvent {
  final int taskId;
  final String newStatus;

  const UpdateCareerTaskStatusEvent(this.taskId, this.newStatus);

  @override
  List<Object?> get props => [taskId, newStatus];
}

class DeleteCareerTaskEvent extends FinanceEvent {
  final int taskId;

  const DeleteCareerTaskEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}
