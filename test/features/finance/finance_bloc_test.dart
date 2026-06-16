import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';

void main() {
  test('FinanceEvent contains custom events', () {
    expect(AddMoneySourceEvent, isNotNull);
    expect(AIQuickLogEvent, isNotNull);
  });
}
