import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';

import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';

part 'finance_event.dart';
part 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository _financeRepository;
  final EGXScraperService _egxScraperService;

  FinanceBloc({
    required this._financeRepository,
    required this._egxScraperService,
  })  : super(FinanceInitial()) {

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
      
      for (var tx in transactions) {
        if (tx.type == 'INCOME') income += tx.amount;
        if (tx.type == 'EXPENSE') expense += tx.amount;
      }

      emit(FinanceLoaded(
        transactions: transactions,
        budgets: budgets,
        watchlist: watchlist,
        tickerPrices: const {},
        totalIncome: income,
        totalExpense: expense,
        careerTasks: careerTasks,
        correlationTimeline: const [],
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
