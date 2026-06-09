import 'package:isar/isar.dart';

part 'finance_collections.g.dart';

@collection
class Invoice {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String clientName;
  late double amount;
  late String currency;
  late String status;
  late DateTime dueDate;
}

@collection
class Transaction {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String type; // 'DEBIT' or 'CREDIT'
  late String account;
  late double amount;
  late String currency;
  late DateTime date;
  late String memo;
}

@collection
class EGXHolding {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String ticker;
  late int quantity;
  late double averageCost;
  late DateTime purchaseDate;
}

@collection
class EGXPriceSnapshot {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String ticker;
  late double currentPrice;
  late DateTime timestamp;
}
