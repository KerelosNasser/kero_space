import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';

void main() {
  group('Finance Models', () {
    test('MoneySource maps fields correctly', () {
      final source = MoneySource()
        ..name = 'Freelance'
        ..balance = 1500.00;
      expect(source.name, 'Freelance');
      expect(source.balance, 1500.00);
    });

    test('Subscription maps fields correctly', () {
      final sub = Subscription()
        ..name = 'Netflix'
        ..amount = 250.00
        ..billingCycle = 'MONTHLY'
        ..nextRenewalDate = DateTime(2026, 6, 20)
        ..isAutoRenew = true;
      expect(sub.name, 'Netflix');
      expect(sub.amount, 250.00);
      expect(sub.billingCycle, 'MONTHLY');
      expect(sub.isAutoRenew, true);
    });

    test('Transaction includes sourceName', () {
      final tx = Transaction()
        ..amount = 100.0
        ..type = 'INCOME'
        ..category = 'Freelance'
        ..sourceName = 'Upwork'
        ..date = DateTime.now();
      expect(tx.sourceName, 'Upwork');
    });

    test('EGXPriceSnapshot includes changeAmount', () {
      final snapshot = EGXPriceSnapshot()
        ..ticker = 'COMI'
        ..currentPrice = 135.50
        ..changePercentage = 1.2
        ..changeAmount = 1.50
        ..timestamp = DateTime.now();
      expect(snapshot.changeAmount, 1.50);
    });
  });
}
