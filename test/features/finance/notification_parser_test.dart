import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/repositories/notification_parser_service.dart';

void main() {
  group('NotificationParserService Regex Tests', () {
    final parser = NotificationParserService();

    test('Parses QNB notification', () {
      final text = "Dear customer, purchase transaction done on card 1234 with amount EGP 450.00 at McDonalds Cairo";
      final tx = parser.parseText(text);
      expect(tx, isNotNull);
      expect(tx!.amount, 450.0);
      expect(tx.vendor, 'McDonalds Cairo');
      expect(tx.type, 'EXPENSE');
      expect(tx.sourceName, 'QNB');
    });

    test('Parses NBE notification', () {
      final text = "Purchase transaction of EGP 1,200.00 from Uber Egypt using card ending 5678 successful";
      final tx = parser.parseText(text);
      expect(tx, isNotNull);
      expect(tx!.amount, 1200.0);
      expect(tx.vendor, 'Uber Egypt');
      expect(tx.type, 'EXPENSE');
      expect(tx.sourceName, 'NBE');
    });

    test('Parses Bybit Card notification', () {
      final text = "Bybit Card: Transaction of 25.50 EUR successful at Steam Games";
      final tx = parser.parseText(text);
      expect(tx, isNotNull);
      expect(tx!.amount, 25.50);
      expect(tx.vendor, 'Steam Games');
      expect(tx.type, 'EXPENSE');
      expect(tx.sourceName, 'Bybit');
    });
  });
}
