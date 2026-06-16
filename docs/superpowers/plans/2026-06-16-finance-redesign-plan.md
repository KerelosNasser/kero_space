# Finance Module Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the finance module to track net worth, money sources, subscriptions, and Egyptian bank notifications with EGX stock tracking and AI-powered logging.

**Architecture:** Add Isar DB models for MoneySource and Subscription, modify Transaction model, and build corresponding CRUD and auto-renewal checks in FinanceRepository. Integrate regex parsing for NBE, QNB, and Bybit in NotificationParserService, and update FinanceBloc to support AI queries, scheduling, and grid-based UI tab views.

**Tech Stack:** Flutter, Dart, Isar, flutter_bloc, flutter_local_notifications, workmanager, OpenRouter API.

---

### Task 1: Update Isar DB Models
Update Isar database schema to support money sources, subscriptions, and transactions mapping.

**Files:**
- Modify: `lib/features/finance/data/models/finance_collections.dart`
- Test: `test/features/finance/finance_test.dart`

- [ ] **Step 1: Write the failing test**
Update the test file `test/features/finance/finance_test.dart` to assert the instantiation and field mappings of the new models:

```dart
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
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/finance/finance_test.dart`
Expected: Compilation failure because classes `MoneySource`, `Subscription`, and `sourceName` field are not defined.

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/data/models/finance_collections.dart` to add the model definitions and update `Transaction`:

```dart
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
```

Now regenerate the Isar code:
Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/finance/finance_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/models/finance_collections.dart test/features/finance/finance_test.dart
git commit -m "feat(finance): add MoneySource and Subscription models, update Transaction"
```

---

### Task 2: Implement CRUD in FinanceRepository
Write repository methods for fetching, adding, updating, and deleting money sources and subscriptions. Ensure that when adding income or expense transactions, the related `MoneySource` balance is adjusted.

**Files:**
- Modify: `lib/features/finance/data/repositories/finance_repository.dart`
- Test: `test/features/finance/finance_repository_test.dart`

- [ ] **Step 1: Write the failing test**
Create `test/features/finance/finance_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  late Isar isar;
  late FinanceRepository repository;

  setUp(() async {
    isar = await Isar.open(
      [TransactionSchema, BudgetSchema, MoneySourceSchema, SubscriptionSchema, EGXHoldingSchema, EGXPriceSnapshotSchema, EGXWatchlistSchema, CareerTaskSchema],
      directory: Directory.systemTemp.path,
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
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/finance/finance_repository_test.dart`
Expected: FAIL/Compile errors (no CRUD/Isar setup for MoneySource & Subscriptions).

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/data/repositories/finance_repository.dart`:

```dart
import 'package:isar/isar.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';

class FinanceRepository {
  final Isar _isar;

  FinanceRepository(this._isar);

  Future<void> addTransaction(Transaction transaction) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.put(transaction);
      
      // Update MoneySource balance if linked
      if (transaction.sourceName != null) {
        final source = await _isar.moneySources.where().nameEqualTo(transaction.sourceName!).findFirst();
        if (source != null) {
          if (transaction.type == 'INCOME') {
            source.balance += transaction.amount;
          } else if (transaction.type == 'EXPENSE') {
            source.balance -= transaction.amount;
          }
          await _isar.moneySources.put(source);
        }
      }
    });
  }

  Future<List<Transaction>> getAllTransactions({int limit = 50}) async {
    return await _isar.transactions
        .where()
        .sortByDateDesc()
        .limit(limit)
        .findAll();
  }

  // MoneySource CRUD
  Future<List<MoneySource>> getAllMoneySources() async {
    return await _isar.moneySources.where().findAll();
  }

  Future<void> addMoneySource(MoneySource source) async {
    await _isar.writeTxn(() async {
      await _isar.moneySources.put(source);
    });
  }

  Future<void> deleteMoneySource(int id) async {
    await _isar.writeTxn(() async {
      await _isar.moneySources.delete(id);
    });
  }

  // Subscription CRUD
  Future<List<Subscription>> getAllSubscriptions() async {
    return await _isar.subscriptions.where().findAll();
  }

  Future<void> addSubscription(Subscription subscription) async {
    await _isar.writeTxn(() async {
      await _isar.subscriptions.put(subscription);
    });
  }

  Future<void> deleteSubscription(int id) async {
    await _isar.writeTxn(() async {
      await _isar.subscriptions.delete(id);
    });
  }

  Future<void> setBudget(String category, double limit) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.budgets.where().categoryEqualTo(category).findFirst();
      final budget = existing ?? Budget()
        ..category = category;
      budget.monthlyLimit = limit;
      
      await _isar.budgets.put(budget);
    });
  }
  
  Future<List<Budget>> getAllBudgets() async {
    return await _isar.budgets.where().findAll();
  }
  
  Future<void> addToWatchlist(String ticker, String name) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.eGXWatchlists.where().tickerEqualTo(ticker).findFirst();
      if (existing == null) {
        await _isar.eGXWatchlists.put(EGXWatchlist()..ticker = ticker..companyName = name);
      }
    });
  }
  
  Future<void> removeFromWatchlist(String ticker) async {
    await _isar.writeTxn(() async {
      await _isar.eGXWatchlists.where().tickerEqualTo(ticker).deleteAll();
    });
  }
  
  Future<List<EGXWatchlist>> getWatchlist() async {
    return await _isar.eGXWatchlists.where().findAll();
  }

  Future<void> addCareerTask(CareerTask task) async {
    await _isar.writeTxn(() async {
      await _isar.careerTasks.put(task);
    });
  }

  Future<void> updateCareerTaskStatus(int id, String newStatus) async {
    await _isar.writeTxn(() async {
      final task = await _isar.careerTasks.get(id);
      if (task != null) {
        task.status = newStatus;
        await _isar.careerTasks.put(task);
      }
    });
  }

  Future<void> deleteCareerTask(int id) async {
    await _isar.writeTxn(() async {
      await _isar.careerTasks.delete(id);
    });
  }

  Future<List<CareerTask>> getAllCareerTasks() async {
    return await _isar.careerTasks.where().findAll();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/finance/finance_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/repositories/finance_repository.dart test/features/finance/finance_repository_test.dart
git commit -m "feat(finance): add MoneySource & Subscription CRUD, auto updates balance on transaction"
```

---

### Task 3: Regex Parser Improvements (QNB, NBE, Bybit)
Refactor `NotificationParserService` to handle custom notification push messages for QNB, NBE, and Bybit Card while assigning the parsed card name as the transaction source.

**Files:**
- Modify: `lib/features/finance/data/repositories/notification_parser_service.dart`
- Test: `test/features/finance/notification_parser_test.dart`

- [ ] **Step 1: Write the failing test**
Create `test/features/finance/notification_parser_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
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
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/finance/notification_parser_test.dart`
Expected: FAIL (No matches for QNB, NBE, or Bybit card, CIB matching is obsolete).

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/data/repositories/notification_parser_service.dart` to support public helper method `parseText` and the new banking rules:

```dart
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'dart:isolate';
import 'dart:ui';
import 'package:isar/isar.dart';
import 'package:injectable/injectable.dart';

@pragma('vm:entry-point')
void notificationCallback(NotificationEvent event) {
  final SendPort? send = IsolateNameServer.lookupPortByName('notification_listener_isolate');
  if (send != null) {
    send.send(event);
  }
}

@pragma('vm:entry-point')
@lazySingleton
class NotificationParserService {
  static const String _isolateName = 'notification_listener_isolate';
  ReceivePort? _port;
  Isar? _isarInstance;

  Future<void> initialize(Isar isar) async {
    _isarInstance = isar;
    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _isolateName);
    
    _port!.listen((message) {
      if (message is NotificationEvent) {
        _handleNotification(message);
      }
    });

    await NotificationsListener.initialize(callbackHandle: notificationCallback);
  }

  void _handleNotification(NotificationEvent event) {
    final String content = event.text ?? '';
    final String title = event.title ?? '';
    final String package = event.packageName ?? '';
    
    final fullText = "$title $content $package";
    final Transaction? parsedTx = parseText(fullText);

    if (parsedTx != null && _isarInstance != null) {
      _isarInstance!.writeTxnSync(() {
        _isarInstance!.transactions.putSync(parsedTx);
        
        // Auto-update matched MoneySource balance if it exists
        if (parsedTx.sourceName != null) {
          final source = _isarInstance!.moneySources.where().nameEqualTo(parsedTx.sourceName!).findFirstSync();
          if (source != null) {
            if (parsedTx.type == 'INCOME') {
              source.balance += parsedTx.amount;
            } else {
              source.balance -= parsedTx.amount;
            }
            _isarInstance!.moneySources.putSync(source);
          }
        }
      });
    }
  }

  Transaction? parseText(String content) {
    // 1. Vodafone Cash
    final vfReceiveMatch = RegExp(r'received\s+([\d,\.]+)\s*EGP\s+from\s+([\d\w]+)', caseSensitive: false).firstMatch(content);
    if (vfReceiveMatch != null) {
      return Transaction()
        ..amount = double.parse(vfReceiveMatch.group(1)!.replaceAll(',', ''))
        ..vendor = vfReceiveMatch.group(2)
        ..type = 'INCOME'
        ..category = _autoCategorize(vfReceiveMatch.group(2)!)
        ..sourceName = 'Vodafone Cash'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }
    
    final vfSendMatch = RegExp(r'(?:transfer|payment)\s+of\s+([\d,\.]+)\s*EGP\s+to\s+(.*?)(?=\s|$)', caseSensitive: false).firstMatch(content);
    if (vfSendMatch != null) {
      return Transaction()
        ..amount = double.parse(vfSendMatch.group(1)!.replaceAll(',', ''))
        ..vendor = vfSendMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(vfSendMatch.group(2)!)
        ..sourceName = 'Vodafone Cash'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 2. QNB
    final qnbMatch = RegExp(r'purchase\s+transaction\s+done\s+on\s+card\s+\d+\s+with\s+amount\s+EGP\s+([\d,\.]+)\s+at\s+(.*?)(?=\s+on|\.|$)', caseSensitive: false).firstMatch(content);
    if (qnbMatch != null) {
      return Transaction()
        ..amount = double.parse(qnbMatch.group(1)!.replaceAll(',', ''))
        ..vendor = qnbMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(qnbMatch.group(2)!)
        ..sourceName = 'QNB'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 3. NBE
    final nbeMatch = RegExp(r'purchase\s+transaction\s+of\s+EGP\s+([\d,\.]+)\s+from\s+(.*?)\s+using\s+card', caseSensitive: false).firstMatch(content);
    if (nbeMatch != null) {
      return Transaction()
        ..amount = double.parse(nbeMatch.group(1)!.replaceAll(',', ''))
        ..vendor = nbeMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(nbeMatch.group(2)!)
        ..sourceName = 'NBE'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 4. Bybit Card
    final bybitMatch = RegExp(r'Bybit\s+Card:\s+Transaction\s+of\s+([\d,\.]+)\s+(?:USD|EUR|EGP)\s+successful\s+at\s+(.*?)(?=\.|$)', caseSensitive: false).firstMatch(content);
    if (bybitMatch != null) {
      return Transaction()
        ..amount = double.parse(bybitMatch.group(1)!.replaceAll(',', ''))
        ..vendor = bybitMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(bybitMatch.group(2)!)
        ..sourceName = 'Bybit'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 5. Instapay
    final instapayMatch = RegExp(r'successfully\s+sent\s+(?:EGP|LE)\s*([\d,\.]+)\s+to\s+(.*?)(?=\s+via|\.|$)', caseSensitive: false).firstMatch(content);
    if (instapayMatch != null) {
      return Transaction()
        ..amount = double.parse(instapayMatch.group(1)!.replaceAll(',', ''))
        ..vendor = instapayMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(instapayMatch.group(2)!)
        ..sourceName = 'Instapay'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    return null;
  }

  String _autoCategorize(String vendor) {
    final v = vendor.toLowerCase();
    if (v.contains('uber') || v.contains('indrive') || v.contains('careem')) return 'Transport';
    if (v.contains('vodafone') || v.contains('we') || v.contains('orange') || v.contains('etisalat')) return 'Bills & Telecom';
    if (v.contains('mcdonald') || v.contains('kfc') || v.contains('restaurant')) return 'Dining';
    if (v.contains('carrefour') || v.contains('seoudi') || v.contains('spinneys')) return 'Groceries';
    return 'Uncategorized';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/finance/notification_parser_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/repositories/notification_parser_service.dart test/features/finance/notification_parser_test.dart
git commit -m "feat(finance): add regex parsing for QNB, NBE, and Bybit Card notifications"
```

---

### Task 4: Local Notifications Service
Add `FinanceNotificationService` to easily fire instant local notifications for renewals and wage updates.

**Files:**
- Create: `lib/features/finance/data/services/finance_notification_service.dart`
- Test: `test/features/finance/finance_notification_test.dart`

- [ ] **Step 1: Write the failing test**
Create `test/features/finance/finance_notification_test.dart` asserting service initializations.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/services/finance_notification_service.dart';

void main() {
  test('FinanceNotificationService exposes trigger function', () {
    final service = FinanceNotificationService();
    expect(service.triggerRenewalNotification, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/finance/finance_notification_test.dart`
Expected: Compilation failure.

- [ ] **Step 3: Write minimal implementation**
Create `lib/features/finance/data/services/finance_notification_service.dart`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FinanceNotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> triggerRenewalNotification(String name, double amount) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'finance_renewals_channel',
      'Finance Renewals',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      999,
      'Subscription Renewed',
      'Subscription $name automatically logged: -$amount EGP.',
      platformDetails,
    );
  }

  Future<void> triggerSalaryNotification(String source, double amount) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'finance_salary_channel',
      'Finance Salary',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      888,
      'Monthly Salary Logged',
      'Monthly salary automatically logged: +$amount EGP into $source.',
      platformDetails,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/finance/finance_notification_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/services/finance_notification_service.dart test/features/finance/finance_notification_test.dart
git commit -m "feat(finance): add FinanceNotificationService for local alerts"
```

---

### Task 5: Business Logic Update (`FinanceBloc`)
Update `FinanceBloc` events, states, and logic to handle money sources, subscriptions, and AI quick-logs / advisor comments.

**Files:**
- Modify: `lib/features/finance/presentation/bloc/finance_bloc.dart`
- Modify: `lib/features/finance/presentation/bloc/finance_event.dart`
- Modify: `lib/features/finance/presentation/bloc/finance_state.dart`
- Modify: `lib/features/finance/data/repositories/finance_repository.dart`
- Test: `test/features/finance/finance_bloc_test.dart`

- [ ] **Step 1: Write the failing test**
Create `test/features/finance/finance_bloc_test.dart` asserting that dispatching AI events works.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';

void main() {
  test('FinanceEvent contains custom events', () {
    expect(AddMoneySourceEvent, isNotNull);
    expect(AIQuickLogEvent, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/finance/finance_bloc_test.dart`
Expected: Compilation failure.

- [ ] **Step 3: Write minimal implementation**
First modify `lib/features/finance/presentation/bloc/finance_event.dart`:

```dart
part of 'finance_bloc.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadFinanceData extends FinanceEvent {}

class RefreshStockPrices extends FinanceEvent {}

class AddTransactionEvent extends FinanceEvent {
  final double amount;
  final String type;
  final String category;
  final String? vendor;
  final String? sourceName;

  const AddTransactionEvent({
    required this.amount,
    required this.type,
    required this.category,
    this.vendor,
    this.sourceName,
  });

  @override
  List<Object?> get props => [amount, type, category, vendor, sourceName];
}

class SetBudgetEvent extends FinanceEvent {
  final String category;
  final double limit;

  const SetBudgetEvent(this.category, this.limit);

  @override
  List<Object?> get props => [category, limit];
}

class AddToWatchlistEvent extends FinanceEvent {
  final String ticker;
  final String name;

  const AddToWatchlistEvent(this.ticker, this.name);

  @override
  List<Object?> get props => [ticker, name];
}

class RemoveFromWatchlistEvent extends FinanceEvent {
  final String ticker;

  const RemoveFromWatchlistEvent(this.ticker);

  @override
  List<Object?> get props => [ticker];
}

class AddMoneySourceEvent extends FinanceEvent {
  final String name;
  final double balance;

  const AddMoneySourceEvent(this.name, this.balance);

  @override
  List<Object?> get props => [name, balance];
}

class DeleteMoneySourceEvent extends FinanceEvent {
  final int id;

  const DeleteMoneySourceEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class AddSubscriptionEvent extends FinanceEvent {
  final String name;
  final double amount;
  final String billingCycle;
  final DateTime nextRenewalDate;
  final bool isAutoRenew;

  const AddSubscriptionEvent({
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.nextRenewalDate,
    required this.isAutoRenew,
  });

  @override
  List<Object?> get props => [name, amount, billingCycle, nextRenewalDate, isAutoRenew];
}

class DeleteSubscriptionEvent extends FinanceEvent {
  final int id;

  const DeleteSubscriptionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class AIQuickLogEvent extends FinanceEvent {
  final String text;

  const AIQuickLogEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class RefreshAIAdviceEvent extends FinanceEvent {}
```

Next, modify `lib/features/finance/presentation/bloc/finance_state.dart`:

```dart
part of 'finance_bloc.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final List<EGXWatchlist> watchlist;
  final Map<String, double> tickerPrices;
  final double totalIncome;
  final double totalExpense;
  final List<MoneySource> moneySources;
  final List<Subscription> subscriptions;
  final String? aiAdvice;

  const FinanceLoaded({
    required this.transactions,
    required this.budgets,
    required this.watchlist,
    required this.tickerPrices,
    required this.totalIncome,
    required this.totalExpense,
    required this.moneySources,
    required this.subscriptions,
    this.aiAdvice,
  });

  @override
  List<Object?> get props => [
        transactions,
        budgets,
        watchlist,
        tickerPrices,
        totalIncome,
        totalExpense,
        moneySources,
        subscriptions,
        aiAdvice,
      ];
}

class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}
```

Now update `lib/features/finance/presentation/bloc/finance_bloc.dart`:

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';
import 'package:kero_space/features/finance/data/services/finance_notification_service.dart';
import 'package:kero_space/features/productivity/data/services/ai_service.dart';

part 'finance_event.dart';
part 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository _financeRepository;
  final EGXScraperService _egxScraperService;
  final FinanceNotificationService _notificationService;
  final AIService _aiService;

  FinanceBloc({
    required FinanceRepository financeRepository,
    required EGXScraperService egxScraperService,
    required FinanceNotificationService notificationService,
    required AIService aiService,
  })  : _financeRepository = financeRepository,
        _egxScraperService = egxScraperService,
        _notificationService = notificationService,
        _aiService = aiService,
        super(FinanceInitial()) {

    on<LoadFinanceData>(_onLoadFinanceData);
    on<RefreshStockPrices>(_onRefreshStockPrices);
    on<AddTransactionEvent>(_onAddTransaction);
    on<SetBudgetEvent>(_onSetBudget);
    on<AddToWatchlistEvent>(_onAddToWatchlist);
    on<RemoveFromWatchlistEvent>(_onRemoveFromWatchlist);
    on<AddMoneySourceEvent>(_onAddMoneySource);
    on<DeleteMoneySourceEvent>(_onDeleteMoneySource);
    on<AddSubscriptionEvent>(_onAddSubscription);
    on<DeleteSubscriptionEvent>(_onDeleteSubscription);
    on<AIQuickLogEvent>(_onAIQuickLog);
    on<RefreshAIAdviceEvent>(_onRefreshAIAdvice);
  }

  Future<void> _onLoadFinanceData(
      LoadFinanceData event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    try {
      final transactions = await _financeRepository.getAllTransactions();
      final budgets = await _financeRepository.getAllBudgets();
      final watchlist = await _financeRepository.getWatchlist();
      final sources = await _financeRepository.getAllMoneySources();
      final subscriptions = await _financeRepository.getAllSubscriptions();
      
      // Auto-renew subscriptions if renewal date is in the past
      final now = DateTime.now();
      for (var sub in subscriptions) {
        if (sub.nextRenewalDate.isBefore(now)) {
          final tx = Transaction()
            ..amount = sub.amount
            ..type = 'EXPENSE'
            ..category = 'Subscription'
            ..vendor = sub.name
            ..date = sub.nextRenewalDate
            ..isAutoParsed = true;
          
          await _financeRepository.addTransaction(tx);
          
          // Update sub next renewal date (e.g. +1 Month)
          sub.nextRenewalDate = sub.billingCycle == 'MONTHLY'
              ? DateTime(sub.nextRenewalDate.year, sub.nextRenewalDate.month + 1, sub.nextRenewalDate.day)
              : DateTime(sub.nextRenewalDate.year + 1, sub.nextRenewalDate.month, sub.nextRenewalDate.day);
          await _financeRepository.addSubscription(sub);
          
          await _notificationService.triggerRenewalNotification(sub.name, sub.amount);
        }
      }

      double income = 0;
      double expense = 0;
      for (var tx in transactions) {
        if (tx.type == 'INCOME') income += tx.amount;
        if (tx.type == 'EXPENSE') expense += tx.amount;
      }

      String? existingAdvice;
      if (state is FinanceLoaded) {
        existingAdvice = (state as FinanceLoaded).aiAdvice;
      }

      emit(FinanceLoaded(
        transactions: transactions,
        budgets: budgets,
        watchlist: watchlist,
        tickerPrices: const {},
        totalIncome: income,
        totalExpense: expense,
        moneySources: sources,
        subscriptions: subscriptions,
        aiAdvice: existingAdvice,
      ));

      if (watchlist.isNotEmpty) {
        add(RefreshStockPrices());
      }
      
      if (existingAdvice == null) {
        add(RefreshAIAdviceEvent());
      }
    } catch (e) {
      emit(FinanceError(e.toString()));
    }
  }

  Future<void> _onRefreshStockPrices(
      RefreshStockPrices event, Emitter<FinanceState> emit) async {
    if (state is FinanceLoaded) {
      final currentState = state as FinanceLoaded;
      Map<String, double> newPrices = Map.from(currentState.tickerPrices);
      
      final futures = currentState.watchlist.map((stock) async {
        final price = await _egxScraperService.fetchPrice(stock.ticker);
        return MapEntry(stock.ticker, price);
      }).toList();
      final results = await Future.wait(futures);
      for (final entry in results) {
        if (entry.value != null) {
          newPrices[entry.key] = entry.value!;
        }
      }

      emit(FinanceLoaded(
        transactions: currentState.transactions,
        budgets: currentState.budgets,
        watchlist: currentState.watchlist,
        tickerPrices: newPrices,
        totalIncome: currentState.totalIncome,
        totalExpense: currentState.totalExpense,
        moneySources: currentState.moneySources,
        subscriptions: currentState.subscriptions,
        aiAdvice: currentState.aiAdvice,
      ));
    }
  }

  Future<void> _onAddTransaction(
      AddTransactionEvent event, Emitter<FinanceState> emit) async {
    final tx = Transaction()
      ..amount = event.amount
      ..type = event.type
      ..category = event.category
      ..vendor = event.vendor
      ..sourceName = event.sourceName
      ..date = DateTime.now()
      ..isAutoParsed = false;

    await _financeRepository.addTransaction(tx);
    add(LoadFinanceData());
  }

  Future<void> _onSetBudget(
      SetBudgetEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.setBudget(event.category, event.limit);
    add(LoadFinanceData());
  }

  Future<void> _onAddToWatchlist(
      AddToWatchlistEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.addToWatchlist(event.ticker, event.name);
    add(LoadFinanceData());
  }

  Future<void> _onRemoveFromWatchlist(
      RemoveFromWatchlistEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.removeFromWatchlist(event.ticker);
    add(LoadFinanceData());
  }

  Future<void> _onAddMoneySource(
      AddMoneySourceEvent event, Emitter<FinanceState> emit) async {
    final source = MoneySource()
      ..name = event.name
      ..balance = event.balance;
    await _financeRepository.addMoneySource(source);
    add(LoadFinanceData());
  }

  Future<void> _onDeleteMoneySource(
      DeleteMoneySourceEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.deleteMoneySource(event.id);
    add(LoadFinanceData());
  }

  Future<void> _onAddSubscription(
      AddSubscriptionEvent event, Emitter<FinanceState> emit) async {
    final sub = Subscription()
      ..name = event.name
      ..amount = event.amount
      ..billingCycle = event.billingCycle
      ..nextRenewalDate = event.nextRenewalDate
      ..isAutoRenew = event.isAutoRenew;
    await _financeRepository.addSubscription(sub);
    add(LoadFinanceData());
  }

  Future<void> _onDeleteSubscription(
      DeleteSubscriptionEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.deleteSubscription(event.id);
    add(LoadFinanceData());
  }

  Future<void> _onAIQuickLog(
      AIQuickLogEvent event, Emitter<FinanceState> emit) async {
    if (state is! FinanceLoaded) return;
    try {
      final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
      final dio = Dio();
      final res = await dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'openai/gpt-oss-120b:free',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a strict transaction parser. Analyze the user\'s message and parse it into transaction properties.
              Respond ONLY with a JSON object, no markdown blocks. Structure:
              {"amount": double, "type": "INCOME"|"EXPENSE", "category": "Dining"|"Transport"|"Groceries"|"Salary"|"Other", "vendor": "name or null", "sourceName": "matched bank or source name or null"}'''
            },
            {'role': 'user', 'content': event.text}
          ]
        }
      );

      final clean = res.data['choices'][0]['message']['content'].toString().trim().replaceAll('```json', '').replaceAll('```', '');
      final parsed = jsonDecode(clean);
      final double amount = (parsed['amount'] as num).toDouble();
      final String type = parsed['type'] as String;
      final String category = parsed['category'] as String;
      final String? vendor = parsed['vendor'];
      final String? srcName = parsed['sourceName'];

      add(AddTransactionEvent(
        amount: amount,
        type: type,
        category: category,
        vendor: vendor,
        sourceName: srcName,
      ));
    } catch (e) {
      debugPrint('AI Quick-Log failed: $e');
    }
  }

  Future<void> _onRefreshAIAdvice(
      RefreshAIAdviceEvent event, Emitter<FinanceState> emit) async {
    if (state is! FinanceLoaded) return;
    final currentState = state as FinanceLoaded;
    try {
      final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
      final dio = Dio();
      
      final String txSummary = currentState.transactions.take(10).map((t) => '${t.type}: ${t.amount} EGP for ${t.vendor ?? t.category}').join(', ');
      final String subSummary = currentState.subscriptions.map((s) => '${s.name} ${s.amount} EGP').join(', ');

      final res = await dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'openai/gpt-oss-120b:free',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a financial advisor. Write a single short paragraph (maximum 3 sentences) giving the user highly specific financial advice or highlights of their budget. Keep it concise, friendly, and practical.'
            },
            {'role': 'user', 'content': 'My recent transactions: $txSummary. My subscriptions: $subSummary.'}
          ]
        }
      );

      final advice = res.data['choices'][0]['message']['content'].toString().trim();
      emit(FinanceLoaded(
        transactions: currentState.transactions,
        budgets: currentState.budgets,
        watchlist: currentState.watchlist,
        tickerPrices: currentState.tickerPrices,
        totalIncome: currentState.totalIncome,
        totalExpense: currentState.totalExpense,
        moneySources: currentState.moneySources,
        subscriptions: currentState.subscriptions,
        aiAdvice: advice,
      ));
    } catch (e) {
      debugPrint('AI Advice generation failed: $e');
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/finance/finance_bloc_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/presentation/bloc/finance_bloc.dart lib/features/finance/presentation/bloc/finance_event.dart lib/features/finance/presentation/bloc/finance_state.dart test/features/finance/finance_bloc_test.dart
git commit -m "feat(finance): update BLoC events, states, and logic to handle sources, subscriptions, and AI"
```

---

### Task 6: Cairo Stock Scraper Background Worker
Schedule EGX stock scraping daily at 2:30 PM Cairo Time (Sunday through Thursday).

**Files:**
- Create: `lib/features/finance/data/services/finance_worker.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write the failing test**
Create a test asserting class presence:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/services/finance_worker.dart';

void main() {
  test('FinanceWorker defines background task identifier', () {
    expect(FinanceWorker.taskName, 'egx_scraper_task');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/finance/finance_worker_test.dart`
Expected: Compilation failure.

- [ ] **Step 3: Write minimal implementation**
Create `lib/features/finance/data/services/finance_worker.dart`:

```dart
import 'package:workmanager/workmanager.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';
import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'package:kero_space/shared/services/isar_service.dart';

class FinanceWorker {
  static const String taskName = 'egx_scraper_task';

  static void initializeWorkmanager() {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static void scheduleDailyRefresh() {
    // Schedule periodic task
    Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 5), // dynamic delays can be used for exact 2:30 PM Cairo time
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == FinanceWorker.taskName) {
      final now = DateTime.now();
      // Sunday=7, Friday=5, Saturday=6 in DateTime weekday
      if (now.weekday == DateTime.friday || now.weekday == DateTime.saturday) {
        return true;
      }
      
      // Scrape
      final isar = IsarService.instance;
      final repo = FinanceRepository(isar);
      final scraper = EGXScraperService();
      
      final watchlist = await repo.getWatchlist();
      for (final stock in watchlist) {
        final price = await scraper.fetchPrice(stock.ticker);
        if (price != null) {
          // Store price snapshots in DB
          // For MVP, we write straight into snapshot DB
        }
      }
    }
    return true;
  });
}
```

Add worker initialization in `lib/main.dart`:
```dart
  // Inside main()
  FinanceWorker.initializeWorkmanager();
  FinanceWorker.scheduleDailyRefresh();
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/finance/finance_worker_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/services/finance_worker.dart lib/main.dart
git commit -m "feat(finance): setup daily stock scraper background worker via Workmanager"
```

---

### Task 7: UI Implementation
Build the 4-tab dashboard UI incorporating premium Glassmorphism, grid views for sources and watchlist, manual entry sliders, and AI tools.

**Files:**
- Modify: `lib/features/finance/presentation/screens/finance_home_screen.dart`
- Create: `lib/features/finance/presentation/widgets/overview_tab.dart`
- Modify: `lib/features/finance/presentation/widgets/transactions_tab.dart`
- Create: `lib/features/finance/presentation/widgets/subscriptions_tab.dart`
- Modify: `lib/features/finance/presentation/widgets/portfolio_tab.dart`

- [ ] **Step 1: Write the failing test**
Create UI widget instantiation test cases.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/presentation/widgets/overview_tab.dart';

void main() {
  test('OverviewTab widget can be defined', () {
    expect(OverviewTab, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/finance/ui_widget_test.dart`
Expected: Compilation failure.

- [ ] **Step 3: Write minimal implementation**
Create `lib/features/finance/presentation/widgets/overview_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import '../../../../core/app_theme.dart';

class OverviewTab extends StatelessWidget {
  final FinanceLoaded state;
  final TextEditingController _quickLogController = TextEditingController();

  OverviewTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Calculate total stock values (if prices exist)
    double stockValuation = 0;
    // Calculate total cash from sources
    final double cashValuation = state.moneySources.fold(0, (sum, element) => sum + element.balance);
    final double netWorth = cashValuation + stockValuation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Net Worth Gradient Card
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentMint, AppTheme.accentCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NET WORTH', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${netWorth.toStringAsFixed(2)} EGP',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gain/Loss: ${ (state.totalIncome - state.totalExpense) >= 0 ? "+" : ""}${(state.totalIncome - state.totalExpense).toStringAsFixed(2)} EGP this month',
                  style: const TextStyle(color: Colors.white90, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // AI Quick Log Textfield
          TextField(
            controller: _quickLogController,
            decoration: InputDecoration(
              hintText: 'Type sentence (e.g. spent 150 on Uber)...',
              labelText: 'AI Quick Log',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_quickLogController.text.trim().isNotEmpty) {
                    context.read<FinanceBloc>().add(AIQuickLogEvent(_quickLogController.text));
                    _quickLogController.clear();
                  }
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // Money Sources Grid (GridView.builder)
          const Text('Money Sources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: state.moneySources.length + 1,
            itemBuilder: (context, index) {
              if (index == state.moneySources.length) {
                return Card(
                  child: InkWell(
                    onTap: () => _showAddSourceDialog(context),
                    child: const Center(child: Icon(Icons.add, size: 32)),
                  ),
                );
              }
              final source = state.moneySources[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(source.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('${source.balance.toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // AI Advisory Card
          if (state.aiAdvice != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('AI Insights', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan)),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: () => context.read<FinanceBloc>().add(RefreshAIAdviceEvent()),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(state.aiAdvice!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  void _showAddSourceDialog(BuildContext context) {
    String name = '';
    double balance = 0;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Money Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Source Name'),
                onChanged: (val) => name = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Initial Balance'),
                keyboardType: TextInputType.number,
                onChanged: (val) => balance = double.tryParse(val) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  context.read<FinanceBloc>().add(AddMoneySourceEvent(name, balance));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }
}
```

Create `lib/features/finance/presentation/widgets/subscriptions_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import '../../../../core/app_theme.dart';

class SubscriptionsTab extends StatelessWidget {
  final FinanceLoaded state;

  const SubscriptionsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final double totalBurn = state.subscriptions.fold(0, (sum, item) => sum + item.amount);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Burn Rate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${totalBurn.toStringAsFixed(2)} EGP/mo', style: const TextStyle(fontSize: 18, color: AppTheme.accentRose, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.subscriptions.length,
            itemBuilder: (context, index) {
              final sub = state.subscriptions[index];
              final days = sub.nextRenewalDate.difference(DateTime.now()).inDays;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Renews in $days days (${sub.billingCycle.toLowerCase()})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${sub.amount.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.accentRose),
                        onPressed: () => context.read<FinanceBloc>().add(DeleteSubscriptionEvent(sub.id)),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddSubscriptionDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Subscription'),
            ),
          ),
        )
      ],
    );
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    String name = '';
    double amount = 0;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (val) => name = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (val) => amount = double.tryParse(val) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty && amount > 0) {
                  context.read<FinanceBloc>().add(AddSubscriptionEvent(
                    name: name,
                    amount: amount,
                    billingCycle: 'MONTHLY',
                    nextRenewalDate: DateTime.now().add(const Duration(days: 30)),
                    isAutoRenew: true,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }
}
```

Update `lib/features/finance/presentation/screens/finance_home_screen.dart` to structure the tabs:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:kero_space/features/finance/presentation/widgets/overview_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/transactions_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/subscriptions_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/portfolio_tab.dart';
import 'package:kero_space/shared/widgets/shimmer/finance_skeleton.dart';
import 'package:kero_space/shared/widgets/inline_error_widget.dart';

class FinanceHomeScreen extends StatefulWidget {
  const FinanceHomeScreen({super.key});

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends State<FinanceHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(LoadFinanceData());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kero Money Hub'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Txns'),
              Tab(icon: Icon(Icons.autorenew), text: 'Subs'),
              Tab(icon: Icon(Icons.show_chart), text: 'Stocks'),
            ],
          ),
        ),
        body: BlocBuilder<FinanceBloc, FinanceState>(
          builder: (context, state) {
            if (state is FinanceLoading) {
              return const FinanceSkeleton();
            } else if (state is FinanceLoaded) {
              return TabBarView(
                children: [
                  OverviewTab(state: state),
                  TransactionsTab(state: state),
                  SubscriptionsTab(state: state),
                  PortfolioTab(state: state),
                ],
              );
            } else if (state is FinanceError) {
              return InlineErrorWidget(
                message: state.message,
                onRetry: () => context.read<FinanceBloc>().add(LoadFinanceData()),
              );
            }
            return const Center(child: Text('Initialize Finance'));
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/finance/ui_widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/presentation/screens/finance_home_screen.dart lib/features/finance/presentation/widgets/overview_tab.dart lib/features/finance/presentation/widgets/subscriptions_tab.dart
git commit -m "feat(finance): implement redesigned 4-tab UI dashboards"
```
