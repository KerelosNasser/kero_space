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
        tickerDailyChanges: const {},
        tickerMonthlyChanges: const {},
        tickerSentiments: const {},
        tickerHistories: const {},
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
              'content': 'You are a strict transaction parser. Analyze the user\'s message and parse it into transaction properties. Respond ONLY with a JSON object, no markdown blocks. Structure:\n{"amount": double, "type": "INCOME"|"EXPENSE", "category": "Dining"|"Transport"|"Groceries"|"Salary"|"Other", "vendor": "name or null", "sourceName": "matched bank or source name or null"}'
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
}
