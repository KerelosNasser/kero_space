import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'dart:io';

void main() {
  late Isar isar;
  late FinanceRepository repository;

  setUp(() async {
    // Open Isar in temp directory for testing
    final tempDir = await Directory.systemTemp.createTemp('isar_test');
    isar = await Isar.open(
      [TransactionSchema, BudgetSchema, MoneySourceSchema, SubscriptionSchema, EGXHoldingSchema, EGXPriceSnapshotSchema, EGXWatchlistSchema, CareerTaskSchema],
      directory: tempDir.path,
      name: 'test_db_${DateTime.now().millisecondsSinceEpoch}',
    );
    repository = FinanceRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('Adds transaction and updates money source balance', () async {
    final source = MoneySource()..name = 'Freelance'..balance = 1000.0;
    await isar.writeTxn(() => isar.moneySources.put(source));

    final tx = Transaction()
      ..amount = 500.0
      ..type = 'INCOME'
      ..category = 'Freelance'
      ..sourceName = 'Freelance'
      ..date = DateTime.now();

    await repository.addTransaction(tx);

    final updatedSource = await isar.moneySources.where().nameEqualTo('Freelance').findFirst();
    expect(updatedSource!.balance, 1500.0);
  });

  test('Adds expense transaction and decreases money source balance', () async {
    final source = MoneySource()..name = 'QNB'..balance = 2000.0;
    await isar.writeTxn(() => isar.moneySources.put(source));

    final tx = Transaction()
      ..amount = 300.0
      ..type = 'EXPENSE'
      ..category = 'Dining'
      ..sourceName = 'QNB'
      ..date = DateTime.now();

    await repository.addTransaction(tx);

    final updatedSource = await isar.moneySources.where().nameEqualTo('QNB').findFirst();
    expect(updatedSource!.balance, 1700.0);
  });
}
