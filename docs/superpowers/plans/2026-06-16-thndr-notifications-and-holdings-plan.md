# Thndr Notifications & holdings Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate Thndr stock execution notification parsing to automatically track portfolio quantities, average costs, log transaction expenses, and display holding metrics on the Stocks UI.

**Architecture:** Implement Isar `EGXHolding` database queries in `FinanceRepository`, add regex-based parsing for buy/sell execution push notifications in `NotificationParserService`, update `FinanceBloc` to cache and load holdings, and implement a dedicated holdings card in `PortfolioTab`.

**Tech Stack:** Flutter, Isar, flutter_notification_listener.

---

### Task 1: Add EGXHolding Queries to FinanceRepository
Add helper functions to retrieve, save, and delete `EGXHolding` records.

**Files:**
- Modify: `lib/features/finance/data/repositories/finance_repository.dart`
- Test: `test/features/finance/finance_repository_test.dart`

- [ ] **Step 1: Write the failing test**
Update `test/features/finance/finance_repository_test.dart`:
```dart
  test('Saves, retrieves and deletes EGX holdings', () async {
    final holding = EGXHolding()
      ..ticker = 'COMI'
      ..quantity = 10
      ..averageCost = 135.50
      ..purchaseDate = DateTime.now();

    await repository.saveHolding(holding);
    final fetched = await repository.getHoldingForTicker('COMI');
    expect(fetched, isNotNull);
    expect(fetched!.quantity, 10);

    await repository.deleteHolding(fetched.id);
    final deleted = await repository.getHoldingForTicker('COMI');
    expect(deleted, isNull);
  });
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter analyze`
Expected: Failure due to missing methods `saveHolding`, `getHoldingForTicker`, and `deleteHolding` on `FinanceRepository`.

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/data/repositories/finance_repository.dart`:
```dart
  Future<void> saveHolding(EGXHolding holding) async {
    await _isar.writeTxn(() async {
      await _isar.eGXHoldings.put(holding);
    });
  }

  Future<EGXHolding?> getHoldingForTicker(String ticker) async {
    return await _isar.eGXHoldings.where().tickerEqualTo(ticker).findFirst();
  }

  Future<List<EGXHolding>> getAllHoldings() async {
    return await _isar.eGXHoldings.where().findAll();
  }

  Future<void> deleteHolding(int id) async {
    await _isar.writeTxn(() async {
      await _isar.eGXHoldings.delete(id);
    });
  }
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/repositories/finance_repository.dart test/features/finance/finance_repository_test.dart
git commit -m "feat(finance): add EGXHolding storage queries to FinanceRepository"
```

---

### Task 2: Regex Parsing for Thndr Buys and Sells
Update `NotificationParserService` to catch com.thndr notifications, log buy/sell transaction expenses, update watchlist, and adjust `EGXHolding` average costs.

**Files:**
- Modify: `lib/features/finance/data/repositories/notification_parser_service.dart`
- Test: `test/features/finance/notification_parser_test.dart`

- [ ] **Step 1: Write the failing test**
Update `test/features/finance/notification_parser_test.dart`:
```dart
    test('Parses Thndr buy notification', () {
      final text = "Order executed: Bought 10 shares of COMI at 135.50 EGP on Thndr";
      final tx = parser.parseText(text);
      expect(tx, isNotNull);
      expect(tx!.amount, 1355.0);
      expect(tx.vendor, 'Thndr Buy: 10 COMI @ 135.5');
      expect(tx.type, 'EXPENSE');
      expect(tx.sourceName, 'Thndr');
    });

    test('Parses Thndr sell notification', () {
      final text = "Order executed: Sold 5 shares of HRHO at 22.10 EGP on Thndr";
      final tx = parser.parseText(text);
      expect(tx, isNotNull);
      expect(tx!.amount, 110.5);
      expect(tx.vendor, 'Thndr Sell: 5 HRHO @ 22.1');
      expect(tx.type, 'INCOME');
      expect(tx.sourceName, 'Thndr');
    });
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter analyze` or run tests
Expected: Failure (Thndr buy and sell notifications return null).

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/data/repositories/notification_parser_service.dart` to support Thndr parsing in `parseText(String content)`:
```dart
    // 6. Thndr Buy
    final thndrBuyMatch = RegExp(
      r'(?:bought|buy\s+order\s+executed:?)\s+(\d+)\s*(?:shares\s+of\s+)?([A-Z0-9]+)\s+(?:at|@)\s*([\d,\.]+)\s*(?:EGP|LE)?',
      caseSensitive: false
    ).firstMatch(content);
    if (thndrBuyMatch != null) {
      final int qty = int.parse(thndrBuyMatch.group(1)!);
      final String ticker = thndrBuyMatch.group(2)!.toUpperCase();
      final double price = double.parse(thndrBuyMatch.group(3)!.replaceAll(',', ''));
      return Transaction()
        ..amount = qty * price
        ..vendor = 'Thndr Buy: $qty $ticker @ $price'
        ..type = 'EXPENSE'
        ..category = 'Investment'
        ..sourceName = 'Thndr'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 7. Thndr Sell
    final thndrSellMatch = RegExp(
      r'(?:sold|sell\s+order\s+executed:?)\s+(\d+)\s*(?:shares\s+of\s+)?([A-Z0-9]+)\s+(?:at|@)\s*([\d,\.]+)\s*(?:EGP|LE)?',
      caseSensitive: false
    ).firstMatch(content);
    if (thndrSellMatch != null) {
      final int qty = int.parse(thndrSellMatch.group(1)!);
      final String ticker = thndrSellMatch.group(2)!.toUpperCase();
      final double price = double.parse(thndrSellMatch.group(3)!.replaceAll(',', ''));
      return Transaction()
        ..amount = qty * price
        ..vendor = 'Thndr Sell: $qty $ticker @ $price'
        ..type = 'INCOME'
        ..category = 'Investment'
        ..sourceName = 'Thndr'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }
```
Now, update `_handleNotification(NotificationEvent event)` in `lib/features/finance/data/repositories/notification_parser_service.dart` to handle target database updates for `EGXHolding` and `EGXWatchlist`:
```dart
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
        final String sourceName = parsedTx.sourceName ?? 'Thndr';
        var source = _isarInstance!.moneySources.where().nameEqualTo(sourceName).findFirstSync();
        if (source == null && sourceName == 'Thndr') {
          source = MoneySource()..name = 'Thndr'..balance = 0.0;
        }
        if (source != null) {
          if (parsedTx.type == 'INCOME') {
            source.balance += parsedTx.amount;
          } else {
            source.balance -= parsedTx.amount;
          }
          _isarInstance!.moneySources.putSync(source);
        }

        // Thndr-specific holdings and watchlist updates
        if (sourceName == 'Thndr') {
          final isBuy = parsedTx.type == 'EXPENSE';
          final description = parsedTx.vendor ?? '';
          final match = RegExp(r'Thndr (?:Buy|Sell):\s+(\d+)\s+([A-Z0-9]+)\s+@\s+([\d\.]+)').firstMatch(description);
          if (match != null) {
            final int qty = int.parse(match.group(1)!);
            final String ticker = match.group(2)!.toUpperCase();
            final double price = double.parse(match.group(3)!);

            // Ensure stock is in watchlist
            final watchExists = _isarInstance!.eGXWatchlists.where().tickerEqualTo(ticker).findFirstSync();
            if (watchExists == null) {
              _isarInstance!.eGXWatchlists.putSync(EGXWatchlist()..ticker = ticker..companyName = '$ticker Ticker');
            }

            // Update holdings
            var holding = _isarInstance!.eGXHoldings.where().tickerEqualTo(ticker).findFirstSync();
            if (isBuy) {
              if (holding == null) {
                holding = EGXHolding()
                  ..ticker = ticker
                  ..quantity = qty.toDouble()
                  ..averageCost = price
                  ..purchaseDate = DateTime.now();
              } else {
                final double currentQty = holding.quantity;
                final double currentAvg = holding.averageCost;
                final double newQty = currentQty + qty;
                holding.quantity = newQty;
                holding.averageCost = ((currentQty * currentAvg) + (qty * price)) / newQty;
                holding.purchaseDate = DateTime.now();
              }
              _isarInstance!.eGXHoldings.putSync(holding);
            } else {
              if (holding != null) {
                final double currentQty = holding.quantity;
                if (currentQty <= qty) {
                  _isarInstance!.eGXHoldings.deleteSync(holding.id);
                } else {
                  holding.quantity = currentQty - qty;
                  _isarInstance!.eGXHoldings.putSync(holding);
                }
              }
            }
          }
        }
      });
    }
  }
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/data/repositories/notification_parser_service.dart test/features/finance/notification_parser_test.dart
git commit -m "feat(finance): parse Thndr notifications and execute automatic holdings calculations"
```

---

### Task 3: Propagate Holdings in FinanceState and FinanceBloc
Modify `FinanceLoaded` and `FinanceBloc` to retrieve and propagate holdings data from Isar.

**Files:**
- Modify: `lib/features/finance/presentation/bloc/finance_state.dart`
- Modify: `lib/features/finance/presentation/bloc/finance_bloc.dart`

- [ ] **Step 1: Write the failing test**
Update `test/features/finance/finance_bloc_test.dart`:
```dart
  test('FinanceLoaded contains holdings list', () {
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
      holdings: const [],
    );
    expect(state.holdings, isNotNull);
  });
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter analyze`
Expected: Compilation failure because `holdings` parameter is not defined in `FinanceLoaded`.

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/presentation/bloc/finance_state.dart`:
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
  final List<EGXHolding> holdings;
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
    required this.holdings,
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
        holdings,
        aiAdvice,
      ];
}
```
Now, update `lib/features/finance/presentation/bloc/finance_bloc.dart` to fetch holdings inside `_onLoadFinanceData`, and preserve them inside `_onRefreshStockPrices` and `_onRefreshAIAdvice`.
Modify `_onLoadFinanceData` around line 135:
```dart
      final holdings = await _financeRepository.getAllHoldings();

      emit(FinanceLoaded(
        transactions: transactions,
        budgets: budgets,
        watchlist: watchlist,
        tickerPrices: prices,
        tickerDailyChanges: dailyChanges,
        tickerMonthlyChanges: monthlyChanges,
        tickerSentiments: sentiments,
        tickerHistories: histories,
        totalIncome: income,
        totalExpense: expense,
        moneySources: sources,
        subscriptions: subscriptions,
        holdings: holdings,
        aiAdvice: existingAdvice,
      ));
```
Modify `_onRefreshStockPrices` emission around line 280:
```dart
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
        holdings: currentState.holdings,
        aiAdvice: currentState.aiAdvice,
      ));
```
Modify `_onRefreshAIAdvice` emission around line 500:
```dart
      emit(FinanceLoaded(
        transactions: currentState.transactions,
        budgets: currentState.budgets,
        watchlist: currentState.watchlist,
        tickerPrices: currentState.tickerPrices,
        tickerDailyChanges: currentState.tickerDailyChanges,
        tickerMonthlyChanges: currentState.tickerMonthlyChanges,
        tickerSentiments: currentState.tickerSentiments,
        tickerHistories: currentState.tickerHistories,
        totalIncome: currentState.totalIncome,
        totalExpense: currentState.totalExpense,
        moneySources: currentState.moneySources,
        subscriptions: currentState.subscriptions,
        holdings: currentState.holdings,
        aiAdvice: advice,
      ));
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/presentation/bloc/finance_bloc.dart lib/features/finance/presentation/bloc/finance_state.dart test/features/finance/finance_bloc_test.dart
git commit -m "feat(finance): load and propagate EGXHoldings data in FinanceBloc"
```

---

### Task 4: Premium Holdings UI in Stocks Tab
Implement a clean visual card summarizing overall holdings value/returns, and add holdings details onto active watchlist grid cards in `PortfolioTab`.

**Files:**
- Modify: `lib/features/finance/presentation/widgets/portfolio_tab.dart`

- [ ] **Step 1: Write the failing test**
Run: `flutter analyze`
Verify there are no current layout errors.

- [ ] **Step 2: Run test to verify it fails**
Check compilation status.

- [ ] **Step 3: Write minimal implementation**
Modify `lib/features/finance/presentation/widgets/portfolio_tab.dart` to add a header card for holdings value/profit summary, and display stock holdings count/averages under prices:
```dart
  @override
  Widget build(BuildContext context) {
    // 1. Calculate Holdings metrics
    double totalHoldingsValuation = 0.0;
    double totalHoldingsCost = 0.0;
    for (var h in state.holdings) {
      final price = state.tickerPrices[h.ticker] ?? h.averageCost;
      totalHoldingsValuation += h.quantity * price;
      totalHoldingsCost += h.quantity * h.averageCost;
    }
    final double profitLoss = totalHoldingsValuation - totalHoldingsCost;
    final double profitLossPct = totalHoldingsCost > 0 ? (profitLoss / totalHoldingsCost) * 100 : 0.0;
    final bool isProfitUp = profitLoss >= 0;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'EGX Portfolio & Watchlist',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Holdings Portfolio Valuation Card
        if (state.holdings.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentMint.withValues(alpha: 0.15), AppTheme.bgElevated],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentMint.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PORTFOLIO VALUATION', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 4),
                    Text(
                      '${totalHoldingsValuation.toStringAsFixed(2)} EGP',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TOTAL RETURNS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 4),
                    Text(
                      '${isProfitUp ? "+" : ""}${profitLoss.toStringAsFixed(2)} EGP (${profitLossPct.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isProfitUp ? AppTheme.accentMint : AppTheme.accentRose,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        Expanded(
          child: RefreshIndicator(
...
```
Now, update the `GridView.builder` `itemBuilder` in `lib/features/finance/presentation/widgets/portfolio_tab.dart` to display quantity and average cost if there's a holding entry for the ticker:
```dart
                    itemBuilder: (context, index) {
                      final stock = state.watchlist[index];
                      final price = state.tickerPrices[stock.ticker];
                      final dailyPct = state.tickerDailyChanges[stock.ticker] ?? 0.0;
                      final monthlyPct = state.tickerMonthlyChanges[stock.ticker] ?? 0.0;
                      final sentiment = state.tickerSentiments[stock.ticker] ?? 'Neutral';
                      final priceHistory = state.tickerHistories[stock.ticker] ?? [];

                      // Check if ticker is owned in holdings
                      final holdingMatches = state.holdings.where((h) => h.ticker == stock.ticker);
                      final EGXHolding? holding = holdingMatches.isNotEmpty ? holdingMatches.first : null;

                      final isUp = dailyPct >= 0;
                      final trendColor = isUp ? AppTheme.accentMint : AppTheme.accentRose;
```
And insert the holding summary layout directly under the price details in the card Column (around line 149):
```dart
                                // Price
                                Text(
                                  price != null ? price.toStringAsFixed(2) : 'Scraping...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: trendColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${isUp ? "▲" : "▼"} ${dailyPct.abs().toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: trendColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'EGP',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Holdings Details (If owned)
                                if (holding != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentMint.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.accentMint.withValues(alpha: 0.1)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Owned: ${holding.quantity.toStringAsFixed(0)} shares',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Avg Cost: ${holding.averageCost.toStringAsFixed(2)} EGP',
                                          style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/finance/presentation/widgets/portfolio_tab.dart
git commit -m "feat(finance): render overall portfolio returns and holdings count on Stocks tab"
```
