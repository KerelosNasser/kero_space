import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/services/finance_worker.dart';

void main() {
  test('FinanceWorker defines background task identifier', () {
    expect(FinanceWorker.taskName, 'egx_scraper_task');
  });
}
