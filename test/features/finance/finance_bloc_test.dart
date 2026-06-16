import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';

void main() {
  test('FinanceEvent contains custom events', () {
    expect(AddMoneySourceEvent, isNotNull);
    expect(AIQuickLogEvent, isNotNull);
  });

  test('FinanceLoaded contains sentiment mappings', () {
    final state = FinanceLoaded(
      transactions: const [],
      budgets: const [],
      watchlist: const [],
      tickerPrices: const {},
      totalIncome: 0,
      totalExpense: 0,
      moneySources: const [],
      subscriptions: const [],
      tickerDailyChanges: const {},
      tickerMonthlyChanges: const {},
      tickerSentiments: const {},
      tickerHistories: const {},
    );
    expect(state.tickerSentiments, isNotNull);
  });
}
