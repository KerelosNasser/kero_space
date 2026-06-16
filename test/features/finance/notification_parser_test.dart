import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/repositories/notification_parser_service.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:isar/isar.dart';
import 'dart:io';

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

  group('Thndr Notification Parser Integration Tests', () {
    late Isar isar;
    late NotificationParserService parser;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('isar_test_thndr');
      isar = await Isar.open(
        [
          TransactionSchema,
          BudgetSchema,
          MoneySourceSchema,
          SubscriptionSchema,
          EGXHoldingSchema,
          EGXPriceSnapshotSchema,
          EGXWatchlistSchema,
          CareerTaskSchema
        ],
        directory: tempDir.path,
        name: 'test_db_thndr_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      parser = NotificationParserService();
      await parser.initialize(isar);
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
    });

    test('Parses and processes English Thndr buy order successfully', () async {
      // Setup Thndr Wallet money source
      final wallet = MoneySource()..name = 'Thndr Wallet'..balance = 10000.0;
      await isar.writeTxn(() => isar.moneySources.put(wallet));

      final event = NotificationEvent(
        packageName: 'co.thndr',
        title: 'Thndr',
        text: 'Your order to buy 10 shares of COMI at EGP 135.50 has been executed.',
      );

      parser.handleNotificationForTesting(event);

      // Verify transaction added
      final txs = await isar.transactions.where().findAll();
      expect(txs.length, 1);
      expect(txs.first.amount, 1355.0);
      expect(txs.first.type, 'EXPENSE');
      expect(txs.first.vendor, 'Thndr');
      expect(txs.first.category, 'Investment');

      // Verify holding updated/created
      final holdings = await isar.eGXHoldings.where().findAll();
      expect(holdings.length, 1);
      expect(holdings.first.ticker, 'COMI');
      expect(holdings.first.quantity, 10.0);
      expect(holdings.first.averageCost, 135.50);

      // Verify Thndr Wallet balance deducted
      final updatedWallet = await isar.moneySources.where().nameEqualTo('Thndr Wallet').findFirst();
      expect(updatedWallet!.balance, 10000.0 - 1355.0);
    });

    test('Parses and processes Arabic Thndr buy order successfully', () async {
      final event = NotificationEvent(
        packageName: 'co.thndr',
        title: 'ثندر',
        text: 'تم تنفيذ أمر شراء 20 سهم في FWRY بسعر 5.25 جنيه',
      );

      parser.handleNotificationForTesting(event);

      // Verify holding created
      final holdings = await isar.eGXHoldings.where().findAll();
      expect(holdings.length, 1);
      expect(holdings.first.ticker, 'FWRY');
      expect(holdings.first.quantity, 20.0);
      expect(holdings.first.averageCost, 5.25);
    });

    test('Parses and processes English Thndr sell order successfully (partial exit)', () async {
      // Pre-populate holding
      final initialHolding = EGXHolding()
        ..ticker = 'COMI'
        ..quantity = 15.0
        ..averageCost = 100.0
        ..purchaseDate = DateTime.now();
      await isar.writeTxn(() => isar.eGXHoldings.put(initialHolding));

      final event = NotificationEvent(
        packageName: 'co.thndr',
        title: 'Thndr',
        text: 'Your order to sell 5 shares of COMI at EGP 150.00 has been executed.',
      );

      parser.handleNotificationForTesting(event);

      // Verify transaction added
      final txs = await isar.transactions.where().findAll();
      expect(txs.length, 1);
      expect(txs.first.amount, 750.0);
      expect(txs.first.type, 'INCOME');

      // Verify holding updated (average cost stays the same, quantity reduced)
      final holding = await isar.eGXHoldings.where().tickerEqualTo('COMI').findFirst();
      expect(holding, isNotNull);
      expect(holding!.quantity, 10.0);
      expect(holding.averageCost, 100.0);
    });

    test('Parses and processes Arabic Thndr sell order successfully (full exit)', () async {
      // Pre-populate holding
      final initialHolding = EGXHolding()
        ..ticker = 'COMI'
        ..quantity = 10.0
        ..averageCost = 100.0
        ..purchaseDate = DateTime.now();
      await isar.writeTxn(() => isar.eGXHoldings.put(initialHolding));

      final event = NotificationEvent(
        packageName: 'co.thndr',
        title: 'ثندر',
        text: 'تم تنفيذ أمر بيع 10 سهم في COMI بسعر 160 جنيه',
      );

      parser.handleNotificationForTesting(event);

      // Verify holding deleted since quantity is now 0
      final holding = await isar.eGXHoldings.where().tickerEqualTo('COMI').findFirst();
      expect(holding, isNull);
    });
  });
}
