import 'package:isar/isar.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';

class FinanceRepository {
  final Isar _isar;

  FinanceRepository(this._isar);

  Future<void> addTransaction(Transaction transaction) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.put(transaction);
    });
  }

  Future<List<Transaction>> getAllTransactions({int limit = 50}) async {
    return await _isar.transactions
        .where()
        .sortByDateDesc()
        .limit(limit)
        .findAll();
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
  
  // Watchlist
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
}
