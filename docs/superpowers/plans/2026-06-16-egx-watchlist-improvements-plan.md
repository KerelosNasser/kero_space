# EGX Watchlist Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance EGX stock watchlist cards to display bullish/bearish indicators, daily and monthly trends, color-coded price targets, and mini-sparklines using Isar snapshots.

**Architecture:** Modify Isar model `EGXPriceSnapshot` to hold change amounts, update `EGXScraperService` to scrape changes, and implement SMA and trend calculations in `FinanceBloc`. Update `FinanceWorker` for Cairo close summaries, and render cards as grids with custom spark charts and sentiments.

**Tech Stack:** Flutter, Isar, fl_chart, flutter_local_notifications.

---

### Task 1: Update EGXPriceSnapshot Model
Add `changeAmount` field to the snapshot collection.

**Files:**
- Modify: `lib/features/finance/data/models/finance_collections.dart`
- Test: `test/features/finance/finance_test.dart`

- [ ] **Step 1: Write the failing test**
Update `test/features/finance/finance_test.dart` to assert the presence of `changeAmount` in `EGXPriceSnapshot`:

```dart
    test('EGXPriceSnapshot includes changeAmount', () {
      final snapshot = EGXPriceSnapshot()
        ..ticker = 'COMI'
        ..currentPrice = 135.50
        ..changePercentage = 1.2
        ..changeAmount = 1.50
        ..timestamp = DateTime.now();
      expect(snapshot.changeAmount, 1.50);
    });
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter analyze`
Expected: Compilation failure because `changeAmount` is not defined on `EGXPriceSnapshot`.

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/data/models/finance_collections.dart`:

```dart
@collection
class EGXPriceSnapshot {
  Id id = Isar.autoIncrement;

  @Index()
  late String ticker;
  
  late double currentPrice;
  late double changePercentage;
  late double changeAmount; // Daily change value
  late DateTime timestamp;
}
```

Now regenerate schemas:
Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/models/finance_collections.dart lib/features/finance/data/models/finance_collections.g.dart test/features/finance/finance_test.dart
git commit -m "feat(finance): add changeAmount to EGXPriceSnapshot"
```

---

### Task 2: Scraper Upgrades
Upgrade `EGXScraperService` to fetch price, change, and percentage.

**Files:**
- Modify: `lib/features/finance/data/repositories/egx_scraper_service.dart`
- Test: `test/features/finance/egx_scraper_test.dart`

- [ ] **Step 1: Write the failing test**
Create `test/features/finance/egx_scraper_test.dart` asserting result type changes.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';

void main() {
  test('EGXScraperService returns EGXScrapeResult', () async {
    final scraper = EGXScraperService();
    final result = await scraper.fetchPrice('COMI');
    if (result != null) {
      expect(result.price, isPositive);
      expect(result.changePercentage, isNotNull);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter analyze`
Expected: Compilation errors (no `EGXScrapeResult` class, `fetchPrice` returns `double?`).

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/data/repositories/egx_scraper_service.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';

class EGXScrapeResult {
  final double price;
  final double changeAmount;
  final double changePercentage;

  EGXScrapeResult({
    required this.price,
    required this.changeAmount,
    required this.changePercentage,
  });
}

class EGXScraperService {
  final Dio _dio;

  EGXScraperService({Dio? dio}) : _dio = dio ?? Dio();

  Future<EGXScrapeResult?> fetchPrice(String ticker) async {
    final url = 'https://english.mubasher.info/markets/EGX/stocks/${ticker.toUpperCase()}';
    
    try {
      final response = await _dio.get(url, options: Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
      ));
      
      if (response.statusCode == 200) {
        var document = parse(response.data);
        var priceElement = document.querySelector('.market-summary__last-price') ?? 
                           document.querySelector('.market-summary__price');
        var changeElement = document.querySelector('.market-summary__change');
        var pctElement = document.querySelector('.market-summary__change-percentage');
        
        if (priceElement != null) {
          String priceText = priceElement.text.replaceAll(RegExp(r'[^0-9.-]'), '');
          String changeText = changeElement?.text.replaceAll(RegExp(r'[^0-9.-]'), '') ?? '0.0';
          String pctText = pctElement?.text.replaceAll(RegExp(r'[^0-9.-]'), '') ?? '0.0';

          return EGXScrapeResult(
            price: double.tryParse(priceText) ?? 0.0,
            changeAmount: double.tryParse(changeText) ?? 0.0,
            changePercentage: double.tryParse(pctText) ?? 0.0,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching price for $ticker: $e');
    }
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/repositories/egx_scraper_service.dart test/features/finance/egx_scraper_test.dart
git commit -m "feat(finance): upgrade EGXScraperService to return complete EGXScrapeResult"
```

---

### Task 3: Save and Retrieve Snapshots in FinanceRepository
Write repository helpers to save and fetch snapshots.

**Files:**
- Modify: `lib/features/finance/data/repositories/finance_repository.dart`
- Test: `test/features/finance/finance_repository_test.dart`

- [ ] **Step 1: Write the failing test**
Update `test/features/finance/finance_repository_test.dart`:

```dart
  test('Saves and retrieves price snapshots', () async {
    final snapshot = EGXPriceSnapshot()
      ..ticker = 'COMI'
      ..currentPrice = 135.0
      ..changeAmount = 1.0
      ..changePercentage = 0.74
      ..timestamp = DateTime.now();

    await repository.savePriceSnapshot(snapshot);
    final history = await repository.getSnapshotsForTicker('COMI');
    expect(history.length, 1);
    expect(history.first.currentPrice, 135.0);
  });
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter analyze`
Expected: Failure (methods `savePriceSnapshot` and `getSnapshotsForTicker` not defined).

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/data/repositories/finance_repository.dart`:

```dart
  // EGXPriceSnapshot DB access
  Future<void> savePriceSnapshot(EGXPriceSnapshot snapshot) async {
    await _isar.writeTxn(() async {
      await _isar.eGXPriceSnapshots.put(snapshot);
    });
  }

  Future<List<EGXPriceSnapshot>> getSnapshotsForTicker(String ticker, {int limit = 10}) async {
    return await _isar.eGXPriceSnapshots
        .where()
        .tickerEqualTo(ticker)
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
  }
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/repositories/finance_repository.dart
git commit -m "feat(finance): add snapshot storage and query methods in FinanceRepository"
```

---

### Task 4: Sentiment calculations in FinanceBloc
Add moving averages, monthly trend estimations, and classifications inside BLoC.

**Files:**
- Modify: `lib/features/finance/presentation/bloc/finance_bloc.dart`
- Modify: `lib/features/finance/presentation/bloc/finance_state.dart`

- [ ] **Step 1: Write the failing test**
Update `test/features/finance/finance_bloc_test.dart` to assert new properties in `FinanceLoaded`:

```dart
    // Ensure watchlistSentiment is defined in State properties
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
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter analyze`
Expected: Compilation failure.

- [ ] **Step 3: Write minimal implementation**
First modify `lib/features/finance/presentation/bloc/finance_state.dart`:

```dart
class FinanceLoaded extends FinanceState {
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final List<EGXWatchlist> watchlist;
  final Map<String, double> tickerPrices;
  final Map<String, double> tickerDailyChanges;
  final Map<String, double> tickerMonthlyChanges;
  final Map<String, String> tickerSentiments;
  final Map<String, List<double>> tickerHistories;
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
    required this.tickerDailyChanges,
    required this.tickerMonthlyChanges,
    required this.tickerSentiments,
    required this.tickerHistories,
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
        tickerDailyChanges,
        tickerMonthlyChanges,
        tickerSentiments,
        tickerHistories,
        totalIncome,
        totalExpense,
        moneySources,
        subscriptions,
        aiAdvice,
      ];
}
```

Now update `lib/features/finance/presentation/bloc/finance_bloc.dart` to perform math and store snapshots:

```dart
// Under import block
// ignore_for_file: prefer_initializing_formals
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

part 'finance_event.dart';
part 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository _financeRepository;
  final EGXScraperService _egxScraperService;
  final FinanceNotificationService _notificationService;

  FinanceBloc({
    required FinanceRepository financeRepository,
    required EGXScraperService egxScraperService,
    required FinanceNotificationService notificationService,
  })  : _financeRepository = financeRepository,
        _egxScraperService = egxScraperService,
        _notificationService = notificationService,
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

      emit(FinanceLoaded(
        transactions: transactions,
        budgets: budgets,
        watchlist: watchlist,
        tickerPrices: const {},
        tickerDailyChanges: const {},
        tickerMonthlyChanges: const {},
        tickerSentiments: const {},
        tickerHistories: const {},
        totalIncome: income,
        totalExpense: expense,
        moneySources: sources,
        subscriptions: subscriptions,
      ));

      if (watchlist.isNotEmpty) {
        add(RefreshStockPrices());
      }
    } catch (e) {
      emit(FinanceError(e.toString()));
    }
  }

  Future<void> _onRefreshStockPrices(
      RefreshStockPrices event, Emitter<FinanceState> emit) async {
    if (state is FinanceLoaded) {
      final currentState = state as FinanceLoaded;
      
      Map<String, double> prices = {};
      Map<String, double> dailyChanges = {};
      Map<String, double> monthlyChanges = {};
      Map<String, String> sentiments = {};
      Map<String, List<double>> histories = {};

      for (final stock in currentState.watchlist) {
        final result = await _egxScraperService.fetchPrice(stock.ticker);
        if (result != null) {
          // Save snapshot to database
          final snapshot = EGXPriceSnapshot()
            ..ticker = stock.ticker
            ..currentPrice = result.price
            ..changeAmount = result.changeAmount
            ..changePercentage = result.changePercentage
            ..timestamp = DateTime.now();
          await _financeRepository.savePriceSnapshot(snapshot);

          // Get price history
          final history = await _financeRepository.getSnapshotsForTicker(stock.ticker, limit: 30);
          final priceHistory = history.map((s) => s.currentPrice).toList().reversed.toList();
          histories[stock.ticker] = priceHistory;

          // 7-day Simple Moving Average (SMA)
          double sma = result.price;
          if (priceHistory.length >= 3) {
            sma = priceHistory.take(7).reduce((a, b) => a + b) / priceHistory.take(7).length;
          }

          // 30-day/Monthly change estimation
          double monthlyDiff = 0.0;
          if (priceHistory.length >= 5) {
            final oldPrice = priceHistory.first;
            monthlyDiff = oldPrice > 0 ? ((result.price - oldPrice) / oldPrice) * 100 : 0.0;
          } else {
            monthlyDiff = result.changePercentage; // fallback
          }

          // Sentiment indicator
          String sentiment = 'Neutral';
          if (priceHistory.length >= 3) {
            if (result.changeAmount > 0 && result.price > sma) {
              sentiment = 'Strong Bullish';
            } else if (result.changeAmount > 0 && result.price <= sma) {
              sentiment = 'Weak Bullish';
            } else if (result.changeAmount < 0 && result.price < sma) {
              sentiment = 'Strong Bearish';
            } else if (result.changeAmount < 0 && result.price >= sma) {
              sentiment = 'Weak Bearish';
            }
          } else {
            sentiment = result.changeAmount >= 0 ? 'Bullish' : 'Bearish'; // simple trend fallback
          }

          prices[stock.ticker] = result.price;
          dailyChanges[stock.ticker] = result.changePercentage;
          monthlyChanges[stock.ticker] = monthlyDiff;
          sentiments[stock.ticker] = sentiment;
        }
      }

      emit(FinanceLoaded(
        transactions: currentState.transactions,
        budgets: currentState.budgets,
        watchlist: currentState.watchlist,
        tickerPrices: prices,
        tickerDailyChanges: dailyChanges,
        tickerMonthlyChanges: monthlyChanges,
        tickerSentiments: sentiments,
        tickerHistories: histories,
        totalIncome: currentState.totalIncome,
        totalExpense: currentState.totalExpense,
        moneySources: currentState.moneySources,
        subscriptions: currentState.subscriptions,
        aiAdvice: currentState.aiAdvice,
      ));
    }
  }

  // The rest of BLoC methods stay exactly as are
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
  Future<void> _onSetBudget(SetBudgetEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.setBudget(event.category, event.limit);
    add(LoadFinanceData());
  }
  Future<void> _onAddToWatchlist(AddToWatchlistEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.addToWatchlist(event.ticker, event.name);
    add(LoadFinanceData());
  }
  Future<void> _onRemoveFromWatchlist(RemoveFromWatchlistEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.removeFromWatchlist(event.ticker);
    add(LoadFinanceData());
  }
  Future<void> _onAddMoneySource(AddMoneySourceEvent event, Emitter<FinanceState> emit) async {
    final source = MoneySource()..name = event.name..balance = event.balance;
    await _financeRepository.addMoneySource(source);
    add(LoadFinanceData());
  }
  Future<void> _onDeleteMoneySource(DeleteMoneySourceEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.deleteMoneySource(event.id);
    add(LoadFinanceData());
  }
  Future<void> _onAddSubscription(AddSubscriptionEvent event, Emitter<FinanceState> emit) async {
    final sub = Subscription()..name = event.name..amount = event.amount..billingCycle = event.billingCycle..nextRenewalDate = event.nextRenewalDate..isAutoRenew = event.isAutoRenew;
    await _financeRepository.addSubscription(sub);
    add(LoadFinanceData());
  }
  Future<void> _onDeleteSubscription(DeleteSubscriptionEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.deleteSubscription(event.id);
    add(LoadFinanceData());
  }
  Future<void> _onAIQuickLog(AIQuickLogEvent event, Emitter<FinanceState> emit) async {
    if (state is! FinanceLoaded) return;
    try {
      final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
      final dio = Dio();
      final res = await dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $key', 'Content-Type': 'application/json'}),
        data: {
          'model': 'openai/gpt-oss-120b:free',
          'messages': [
            {'role': 'system', 'content': 'You are a strict transaction parser. Respond ONLY with JSON:\n{"amount": double, "type": "INCOME"|"EXPENSE", "category": "Dining"|"Transport"|"Groceries"|"Salary"|"Other", "vendor": "name or null", "sourceName": "matched bank or source name or null"}'},
            {'role': 'user', 'content': event.text}
          ]
        }
      );
      final clean = res.data['choices'][0]['message']['content'].toString().trim().replaceAll('```json', '').replaceAll('```', '');
      final parsed = jsonDecode(clean);
      add(AddTransactionEvent(amount: (parsed['amount'] as num).toDouble(), type: parsed['type'], category: parsed['category'], vendor: parsed['vendor'], sourceName: parsed['sourceName']));
    } catch (e) {
      debugPrint('AI Quick-Log failed: $e');
    }
  }
  Future<void> _onRefreshAIAdvice(RefreshAIAdviceEvent event, Emitter<FinanceState> emit) async {
    if (state is! FinanceLoaded) return;
    final currentState = state as FinanceLoaded;
    try {
      final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
      final dio = Dio();
      final String txSummary = currentState.transactions.take(10).map((t) => '${t.type}: ${t.amount} EGP for ${t.vendor ?? t.category}').join(', ');
      final String subSummary = currentState.subscriptions.map((s) => '${s.name} ${s.amount} EGP').join(', ');
      final res = await dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $key', 'Content-Type': 'application/json'}),
        data: {
          'model': 'openai/gpt-oss-120b:free',
          'messages': [
            {'role': 'system', 'content': 'You are a financial advisor. Write a single short paragraph (maximum 3 sentences) giving the user highly specific financial advice or highlights of their budget. Keep it concise, friendly, and practical.'},
            {'role': 'user', 'content': 'My recent transactions: $txSummary. My subscriptions: $subSummary.'}
          ]
        }
      );
      emit(FinanceLoaded(transactions: currentState.transactions, budgets: currentState.budgets, watchlist: currentState.watchlist, tickerPrices: currentState.tickerPrices, tickerDailyChanges: currentState.tickerDailyChanges, tickerMonthlyChanges: currentState.tickerMonthlyChanges, tickerSentiments: currentState.tickerSentiments, tickerHistories: currentState.tickerHistories, totalIncome: currentState.totalIncome, totalExpense: currentState.totalExpense, moneySources: currentState.moneySources, subscriptions: currentState.subscriptions, aiAdvice: res.data['choices'][0]['message']['content'].toString().trim()));
    } catch (e) {
      debugPrint('AI Advice generation failed: $e');
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/presentation/bloc/finance_bloc.dart lib/features/finance/presentation/bloc/finance_state.dart test/features/finance/finance_bloc_test.dart
git commit -m "feat(finance): add technical sentiment and MA calculations to BLoC"
```

---

### Task 5: Background Worker Updates & Cairo Close Summary Notification
Modify background worker to scrape full data fields and trigger close summaries.

**Files:**
- Modify: `lib/features/finance/data/services/finance_worker.dart`

- [ ] **Step 1: Write the failing test**
We will verify that worker executes without compile warnings.

- [ ] **Step 2: Run test to verify it fails**
No explicit failure needed, just check compile rules.

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/data/services/finance_worker.dart` to trigger push recap summaries:

```dart
// Under imports
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Inside Workmanager executeTask
      final isar = IsarService.instance;
      final repo = FinanceRepository(isar);
      final scraper = EGXScraperService();
      
      final watchlist = await repo.getWatchlist();
      final List<String> summaries = [];

      for (final stock in watchlist) {
        final result = await scraper.fetchPrice(stock.ticker);
        if (result != null) {
          final snapshot = EGXPriceSnapshot()
            ..ticker = stock.ticker
            ..currentPrice = result.price
            ..changeAmount = result.changeAmount
            ..changePercentage = result.changePercentage
            ..timestamp = DateTime.now();
          await repo.savePriceSnapshot(snapshot);

          final sign = result.changeAmount >= 0 ? '+' : '';
          summaries.add('${stock.ticker}: ${result.price} EGP ($sign${result.changePercentage.toStringAsFixed(1)}%)');
        }
      }

      if (summaries.isNotEmpty) {
        final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
        await notifications.show(
          id: 777,
          title: 'EGX Cairo Market Close Summary',
          body: summaries.join(', '),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'finance_market_channel',
              'Market Updates',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/services/finance_worker.dart
git commit -m "feat(finance): send EGX performance recap alerts at 2:30 PM Cairo time close"
```

---

### Task 6: Watchlist Grid UI Implementation
Redesign UI dashboard grid items to display bullish/bearish chips, trends, and Sparklines.

**Files:**
- Modify: `lib/features/finance/presentation/widgets/portfolio_tab.dart`
- Modify: `lib/features/finance/presentation/widgets/overview_tab.dart`

- [ ] **Step 1: Write the failing test**
Compile verification.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter analyze`

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/presentation/widgets/portfolio_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/app_theme.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';

class PortfolioTab extends StatelessWidget {
  final FinanceLoaded state;

  const PortfolioTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'EGX Watchlist & Technical Sentiment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<FinanceBloc>().add(RefreshStockPrices());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: state.watchlist.isEmpty
                ? const Center(
                    child: Text(
                      'Your watchlist is empty.\nAdd a ticker like COMI to track it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: state.watchlist.length,
                    itemBuilder: (context, index) {
                      final stock = state.watchlist[index];
                      final price = state.tickerPrices[stock.ticker];
                      final dailyPct = state.tickerDailyChanges[stock.ticker] ?? 0.0;
                      final monthlyPct = state.tickerMonthlyChanges[stock.ticker] ?? 0.0;
                      final sentiment = state.tickerSentiments[stock.ticker] ?? 'Neutral';
                      final priceHistory = state.tickerHistories[stock.ticker] ?? [];

                      final isUp = dailyPct >= 0;
                      final trendColor = isUp ? AppTheme.accentMint : AppTheme.accentRose;

                      // Make spark points
                      final List<FlSpot> spots = [];
                      for (int i = 0; i < priceHistory.length; i++) {
                        spots.add(FlSpot(i.toDouble(), priceHistory[i]));
                      }

                      return Card(
                        color: AppTheme.bgElevated,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      stock.ticker,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16, color: AppTheme.accentRose),
                                    onPressed: () {
                                      context.read<FinanceBloc>().add(RemoveFromWatchlistEvent(stock.ticker));
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                price != null ? '${price.toStringAsFixed(2)} EGP' : 'Scraping...',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: trendColor),
                              ),
                              Text(
                                '${isUp ? "+" : ""}${dailyPct.toStringAsFixed(2)}%',
                                style: TextStyle(fontSize: 12, color: trendColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              
                              // Monthly change indicator
                              Text(
                                'Monthly: ${monthlyPct >= 0 ? "+" : ""}${monthlyPct.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 6),

                              // Sentiment Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: sentiment.contains('Bullish') 
                                      ? AppTheme.accentMint.withValues(alpha: 0.15) 
                                      : sentiment.contains('Bearish')
                                          ? AppTheme.accentRose.withValues(alpha: 0.15)
                                          : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: sentiment.contains('Bullish') 
                                        ? AppTheme.accentMint 
                                        : sentiment.contains('Bearish')
                                            ? AppTheme.accentRose
                                            : Colors.grey,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  sentiment,
                                  style: TextStyle(
                                    fontSize: 9, 
                                    fontWeight: FontWeight.bold,
                                    color: sentiment.contains('Bullish') 
                                        ? AppTheme.accentMint 
                                        : sentiment.contains('Bearish')
                                            ? AppTheme.accentRose
                                            : Colors.grey,
                                  ),
                                ),
                              ),
                              const Spacer(),

                              // Mini Sparkline Graph
                              if (spots.length >= 2)
                                SizedBox(
                                  height: 40,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: const FlGridData(show: false),
                                      titlesData: const FlTitlesData(show: false),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: spots,
                                          isCurved: true,
                                          color: trendColor,
                                          barWidth: 2,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(show: false),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(
                                  height: 40,
                                  child: Center(
                                    child: Text('Gathering chart data...', style: TextStyle(fontSize: 8, color: AppTheme.textSecondary)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddWatchlistDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add to Watchlist'),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddWatchlistDialog(BuildContext context) {
    String ticker = '';
    String name = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Watchlist Symbol'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Ticker (e.g. COMI)'),
                onChanged: (val) => ticker = val,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Company Name'),
                onChanged: (val) => name = val,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (ticker.trim().isNotEmpty && name.trim().isNotEmpty) {
                  context.read<FinanceBloc>().add(AddToWatchlistEvent(ticker.trim().toUpperCase(), name.trim()));
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
```

Now update `lib/features/finance/presentation/widgets/overview_tab.dart` to use new state variables for its Stocks Grid:

```dart
// Modify the Top Stocks Grid builder inside OverviewTab build() method:
                  itemBuilder: (context, index) {
                    final stock = state.watchlist[index];
                    final price = state.tickerPrices[stock.ticker];
                    final dailyPct = state.tickerDailyChanges[stock.ticker] ?? 0.0;
                    final sentiment = state.tickerSentiments[stock.ticker] ?? 'Neutral';

                    final isUp = dailyPct >= 0;
                    final trendColor = isUp ? AppTheme.accentMint : AppTheme.accentRose;

                    return Card(
                      color: AppTheme.bgElevated,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(stock.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  sentiment.contains('Bullish') ? '▲' : sentiment.contains('Bearish') ? '▼' : '●',
                                  style: TextStyle(color: sentiment.contains('Bullish') ? AppTheme.accentMint : sentiment.contains('Bearish') ? AppTheme.accentRose : Colors.grey, fontSize: 10),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              price != null ? '${price.toStringAsFixed(2)} EGP' : 'Scraping...',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: trendColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/presentation/widgets/portfolio_tab.dart lib/features/finance/presentation/widgets/overview_tab.dart
git commit -m "feat(finance): implement gridview stock watchlist UI with sentiment tags and sparklines"
```
