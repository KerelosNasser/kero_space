import 'package:equatable/equatable.dart';
import 'recurrence.dart';

sealed class ParsedIntent extends Equatable {
  const ParsedIntent();

  @override
  List<Object?> get props => [];
}

class AddTodoIntent extends ParsedIntent {
  final String title;
  final Recurrence? recurrence;

  const AddTodoIntent({required this.title, this.recurrence});

  @override
  List<Object?> get props => [title, recurrence];
}

class AddNoteIntent extends ParsedIntent {
  final String body;

  const AddNoteIntent({required this.body});

  @override
  List<Object?> get props => [body];
}

class AddEventIntent extends ParsedIntent {
  final String title;
  final DateTime? dateTime;

  const AddEventIntent({required this.title, this.dateTime});

  @override
  List<Object?> get props => [title, dateTime];
}

class AddExpenseIntent extends ParsedIntent {
  final double amount;
  final String? vendor;

  const AddExpenseIntent({required this.amount, this.vendor});

  @override
  List<Object?> get props => [amount, vendor];
}

class AddIncomeIntent extends ParsedIntent {
  final double amount;
  final String? source;

  const AddIncomeIntent({required this.amount, this.source});

  @override
  List<Object?> get props => [amount, source];
}

class LogMealIntent extends ParsedIntent {
  final String food;
  final int? grams;

  const LogMealIntent({required this.food, this.grams});

  @override
  List<Object?> get props => [food, grams];
}

class MarkAttendanceIntent extends ParsedIntent {
  final DateTime date;

  const MarkAttendanceIntent({required this.date});

  @override
  List<Object?> get props => [date];
}

class BlockAppIntent extends ParsedIntent {
  final String appName;

  const BlockAppIntent({required this.appName});

  @override
  List<Object?> get props => [appName];
}

class NavigateIntent extends ParsedIntent {
  final String destination;

  const NavigateIntent({required this.destination});

  @override
  List<Object?> get props => [destination];
}

class UnknownIntent extends ParsedIntent {
  final String raw;

  const UnknownIntent({required this.raw});

  @override
  List<Object?> get props => [raw];
}
