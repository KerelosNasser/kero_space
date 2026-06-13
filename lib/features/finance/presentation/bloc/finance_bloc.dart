import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';

import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';
import 'package:kero_space/features/health/data/repositories/nutrition_repository.dart';

part 'finance_event.dart';
part 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository _financeRepository;
  final EGXScraperService _egxScraperService;
  final NutritionRepository _nutritionRepository;

  // ignore: prefer_initializing_formals
  FinanceBloc({
    required FinanceRepository financeRepository,
    required EGXScraperService egxScraperService,
    required NutritionRepository nutritionRepository,
  })  : _financeRepository = financeRepository, // ignore: prefer_initializing_formals
        _egxScraperService = egxScraperService, // ignore: prefer_initializing_formals
        _nutritionRepository = nutritionRepository, // ignore: prefer_initializing_formals
        super(FinanceInitial()) {

    on<LoadFinanceData>(_onLoadFinanceData);
    on<RefreshStockPrices>(_onRefreshStockPrices);
    on<AddTransactionEvent>(_onAddTransaction);
    on<SetBudgetEvent>(_onSetBudget);
    on<AddToWatchlistEvent>(_onAddToWatchlist);
    on<RemoveFromWatchlistEvent>(_onRemoveFromWatchlist);
    on<AddCareerTaskEvent>(_onAddCareerTask);
    on<UpdateCareerTaskStatusEvent>(_onUpdateCareerTaskStatus);
    on<DeleteCareerTaskEvent>(_onDeleteCareerTask);
  }

  Future<void> _onLoadFinanceData(
      LoadFinanceData event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    try {
      final transactions = await _financeRepository.getAllTransactions();
      final budgets = await _financeRepository.getAllBudgets();
      final watchlist = await _financeRepository.getWatchlist();
      final careerTasks = await _financeRepository.getAllCareerTasks();
      
      double income = 0;
      double expense = 0;
      // Also calculate daily net to build the cumulative wealth timeline
      Map<String, double> dailyWealthDelta = {};
      
      for (var tx in transactions) {
        if (tx.type == 'INCOME') income += tx.amount;
        if (tx.type == 'EXPENSE') expense += tx.amount;
        
        final dateKey = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
        final delta = tx.type == 'INCOME' ? tx.amount : -tx.amount;
        dailyWealthDelta[dateKey] = (dailyWealthDelta[dateKey] ?? 0) + delta;
      }

      // Fetch recent meals for correlation (last 7 days)
      final DateTime now = DateTime.now();
      List<CorrelationDataPoint> timeline = [];
      
      // Calculate true baseline wealth before the 7-day window
      double rollingWealth = 0; 
      final DateTime sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      
      for (var tx in transactions) {
        if (tx.date.isBefore(sevenDaysAgo)) {
           rollingWealth += tx.type == 'INCOME' ? tx.amount : -tx.amount;
        }
      }

      // Fetch dynamic UserProfile for BMR calculation
      final userProfile = await _nutritionRepository.getUserProfile();
      final double baselineBMR = userProfile?.bmrTarget ?? 2000.0;

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        rollingWealth += dailyWealthDelta[dateKey] ?? 0;
        
        final meals = await _nutritionRepository.getDailyMeals(date);
        double totalCalories = meals.fold(0.0, (sum, meal) => sum + meal.calories);
        double surplus = totalCalories - baselineBMR; 

        timeline.add(CorrelationDataPoint(
          date: date,
          cumulativeWealth: rollingWealth,
          dailyCaloricSurplus: surplus,
        ));
      }

      emit(FinanceLoaded(
        transactions: transactions,
        budgets: budgets,
        watchlist: watchlist,
        tickerPrices: const {},
        totalIncome: income,
        totalExpense: expense,
        careerTasks: careerTasks,
        correlationTimeline: timeline,
      ));

      // Trigger stock price fetch if we have a watchlist
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
      Map<String, double> newPrices = Map.from(currentState.tickerPrices);
      
      for (var stock in currentState.watchlist) {
        final price = await _egxScraperService.fetchPrice(stock.ticker);
        if (price != null) {
          newPrices[stock.ticker] = price;
        }
      }

      emit(FinanceLoaded(
        transactions: currentState.transactions,
        budgets: currentState.budgets,
        watchlist: currentState.watchlist,
        tickerPrices: newPrices,
        totalIncome: currentState.totalIncome,
        totalExpense: currentState.totalExpense,
        careerTasks: currentState.careerTasks,
        correlationTimeline: currentState.correlationTimeline,
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

  Future<void> _onAddCareerTask(
      AddCareerTaskEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.addCareerTask(event.task);
    add(LoadFinanceData());
  }

  Future<void> _onUpdateCareerTaskStatus(
      UpdateCareerTaskStatusEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.updateCareerTaskStatus(event.taskId, event.newStatus);
    add(LoadFinanceData());
  }

  Future<void> _onDeleteCareerTask(
      DeleteCareerTaskEvent event, Emitter<FinanceState> emit) async {
    await _financeRepository.deleteCareerTask(event.taskId);
    add(LoadFinanceData());
  }
}
