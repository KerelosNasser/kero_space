// ignore_for_file: prefer_initializing_formals
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';
import 'package:kero_space/features/finance/data/services/finance_notification_service.dart';
import 'package:kero_space/features/finance/data/services/stock_analysis_service.dart';
import 'package:kero_space/features/finance/data/services/finance_ai_service.dart';

part 'finance_event.dart';
part 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository _financeRepository;
  final EGXScraperService _egxScraperService;
  final FinanceNotificationService _notificationService;
  final FinanceAIService _financeAiService;

  FinanceBloc({
    required FinanceRepository financeRepository,
    required EGXScraperService egxScraperService,
    required FinanceNotificationService notificationService,
    FinanceAIService? financeAiService,
  })  : _financeRepository = financeRepository,
        _egxScraperService = egxScraperService,
        _notificationService = notificationService,
        _financeAiService = financeAiService ?? FinanceAIService(),
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

      // Query database caches to emit immediately and prevent loading flicker
      Map<String, double> prices = {};
      Map<String, double> dailyChanges = {};
      Map<String, double> monthlyChanges = {};
      Map<String, String> sentiments = {};
      Map<String, List<double>> histories = {};

      for (final stock in watchlist) {
        final history = await _financeRepository.getSnapshotsForTicker(stock.ticker, limit: 30);
        if (history.isNotEmpty) {
          final last = history.first;
          final priceHistory = history.map((s) => s.currentPrice).toList().reversed.toList();
          
          prices[stock.ticker] = last.currentPrice;
          dailyChanges[stock.ticker] = last.changePercentage;
          histories[stock.ticker] = priceHistory;

          final analysis = await StockAnalysisService.analyze(
            priceHistory: priceHistory,
            currentPrice: last.currentPrice,
            changeAmount: last.changeAmount,
            changePercentage: last.changePercentage,
          );

          monthlyChanges[stock.ticker] = analysis.monthlyDiff;
          sentiments[stock.ticker] = analysis.sentiment;
        }
      }

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
        aiAdvice: existingAdvice,
      ));

      if (watchlist.isNotEmpty) {
        add(const RefreshStockPrices(force: false));
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
      
      Map<String, double> prices = {};
      Map<String, double> dailyChanges = {};
      Map<String, double> monthlyChanges = {};
      Map<String, String> sentiments = {};
      Map<String, List<double>> histories = {};

      for (final stock in currentState.watchlist) {
        // Retrieve local snapshots to check cache freshness
        final history = await _financeRepository.getSnapshotsForTicker(stock.ticker, limit: 30);
        
        bool needScrape = true;
        if (!event.force && history.isNotEmpty) {
          final lastSnapshot = history.first;
          if (_isCacheValid(lastSnapshot.timestamp)) {
            needScrape = false;
            
            // Populate maps from cache
            final priceHistory = history.map((s) => s.currentPrice).toList().reversed.toList();
            histories[stock.ticker] = priceHistory;
            prices[stock.ticker] = lastSnapshot.currentPrice;
            dailyChanges[stock.ticker] = lastSnapshot.changePercentage;
            
            final analysis = await StockAnalysisService.analyze(
              priceHistory: priceHistory,
              currentPrice: lastSnapshot.currentPrice,
              changeAmount: lastSnapshot.changeAmount,
              changePercentage: lastSnapshot.changePercentage,
            );
            monthlyChanges[stock.ticker] = analysis.monthlyDiff;
            sentiments[stock.ticker] = analysis.sentiment;
          }
        }

        if (needScrape) {
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

            // Re-fetch history to include new snapshot
            final updatedHistory = await _financeRepository.getSnapshotsForTicker(stock.ticker, limit: 30);
            final priceHistory = updatedHistory.map((s) => s.currentPrice).toList().reversed.toList();
            histories[stock.ticker] = priceHistory;

            prices[stock.ticker] = result.price;
            dailyChanges[stock.ticker] = result.changePercentage;

            final analysis = await StockAnalysisService.analyze(
              priceHistory: priceHistory,
              currentPrice: result.price,
              changeAmount: result.changeAmount,
              changePercentage: result.changePercentage,
            );
            monthlyChanges[stock.ticker] = analysis.monthlyDiff;
            sentiments[stock.ticker] = analysis.sentiment;
          } else {
            // If scrape failed but we have history, preserve it
            if (history.isNotEmpty) {
              final lastSnapshot = history.first;
              final priceHistory = history.map((s) => s.currentPrice).toList().reversed.toList();
              histories[stock.ticker] = priceHistory;
              prices[stock.ticker] = lastSnapshot.currentPrice;
              dailyChanges[stock.ticker] = lastSnapshot.changePercentage;
              
              final analysis = await StockAnalysisService.analyze(
                priceHistory: priceHistory,
                currentPrice: lastSnapshot.currentPrice,
                changeAmount: lastSnapshot.changeAmount,
                changePercentage: lastSnapshot.changePercentage,
              );
              monthlyChanges[stock.ticker] = analysis.monthlyDiff;
              sentiments[stock.ticker] = analysis.sentiment;
            }
          }
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
      final parsed = await _financeAiService.quickLogTransaction(event.text);
      final double amount = (parsed['amount'] as num).toDouble();
      final String type = parsed['type'] as String;
      final String category = parsed['category'] as String;
      final String? vendor = parsed['vendor'] as String?;
      final String? srcName = parsed['sourceName'] as String?;

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
      final String txSummary = currentState.transactions.take(10).map((t) => '${t.type}: ${t.amount} EGP for ${t.vendor ?? t.category}').join(', ');
      final String subSummary = currentState.subscriptions.map((s) => '${s.name} ${s.amount} EGP').join(', ');

      final advice = await _financeAiService.refreshAdvice(
        transactionSummary: txSummary,
        subscriptionSummary: subSummary,
      );
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
        aiAdvice: advice,
      ));
    } catch (e) {
      debugPrint('AI Advice generation failed: $e');
    }
  }

  bool _isCacheValid(DateTime lastScrapeTime) {
    final now = DateTime.now();
    
    // Convert to Cairo Time (UTC+3)
    final nowCairo = now.toUtc().add(const Duration(hours: 3));
    final lastCairo = lastScrapeTime.toUtc().add(const Duration(hours: 3));
    
    // Check if same day
    if (lastCairo.year == nowCairo.year && 
        lastCairo.month == nowCairo.month && 
        lastCairo.day == nowCairo.day) {
      
      // If we scraped after 2:30 PM (14:30) Cairo time close, cache is fully valid
      if (lastCairo.hour > 14 || (lastCairo.hour == 14 && lastCairo.minute >= 30)) {
        return true;
      }
      
      // If market is still open/running, avoid spamming: allow 15-minute cache
      if (nowCairo.difference(lastCairo).inMinutes < 15) {
        return true;
      }
    }
    
    // If weekend (Friday or Saturday) in Cairo, check if last scrape was after Thursday 2:30 PM close
    if (nowCairo.weekday == DateTime.friday || nowCairo.weekday == DateTime.saturday) {
      final daysToSubtract = nowCairo.weekday == DateTime.friday ? 1 : 2;
      final lastThursdayClose = DateTime(nowCairo.year, nowCairo.month, nowCairo.day)
          .subtract(Duration(days: daysToSubtract))
          .add(const Duration(hours: 14, minutes: 30));
      
      if (lastCairo.isAfter(lastThursdayClose)) {
        return true;
      }
    }
    
    return false;
  }
}
