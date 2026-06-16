import 'package:isar/isar.dart';

part 'finance_collections.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late double amount;
  
  @Index()
  late String type; // 'INCOME' or 'EXPENSE'
  
  @Index()
  late String category;
  
  late DateTime date;
  
  String? memo;
  String? vendor;
  String? sourceName; // To link to MoneySource
  
  bool isAutoParsed = false;
}

@collection
class Budget {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String category;
  
  late double monthlyLimit;
}

@collection
class MoneySource {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;
  
  late double balance;
}

@collection
class Subscription {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;
  
  late double amount;
  late String billingCycle; // 'MONTHLY', 'YEARLY'
  late DateTime nextRenewalDate;
  late bool isAutoRenew;
}

@collection
class EGXHolding {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String ticker;
  
  late double quantity;
  late double averageCost;
  late DateTime purchaseDate;
}

@collection
class EGXPriceSnapshot {
  Id id = Isar.autoIncrement;

  @Index()
  late String ticker;
  
  late double currentPrice;
  late double changePercentage;
  late double changeAmount;
  late DateTime timestamp;
}

@collection
class EGXWatchlist {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String ticker;
  
  late String companyName;
}

@collection
class CareerTask {
  Id id = Isar.autoIncrement;

  late String title;
  String? description;

  @Index()
  late String status; // 'TODO', 'IN_PROGRESS', 'DONE'

  @Index()
  late String category; // 'Banking', 'Tech Cert', 'Freelance'

  DateTime? dueDate;
  late DateTime createdAt;
}
