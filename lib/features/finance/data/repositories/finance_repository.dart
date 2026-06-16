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
      // If inserting a new subscription, check if one with the same name already exists
      if (subscription.id == Isar.autoIncrement) {
        final existing = await _isar.subscriptions.where().nameEqualTo(subscription.name).findFirst();
        if (existing != null) {
          subscription.id = existing.id;
        }
      }
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
}
