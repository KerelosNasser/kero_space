import 'package:workmanager/workmanager.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';
import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'package:kero_space/core/data/isar_service.dart';

class FinanceWorker {
  static const String taskName = 'egx_scraper_task';

  static void initializeWorkmanager() {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static void scheduleDailyRefresh() {
    Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 5),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == FinanceWorker.taskName) {
      final now = DateTime.now();
      // Skip weekends (Friday and Saturday)
      if (now.weekday == DateTime.friday || now.weekday == DateTime.saturday) {
        return true;
      }
      
      final isar = IsarService.instance;
      final repo = FinanceRepository(isar);
      final scraper = EGXScraperService();
      
      final watchlist = await repo.getWatchlist();
      for (final stock in watchlist) {
        final price = await scraper.fetchPrice(stock.ticker);
        if (price != null) {
          // Snapshots can be captured here if required in production
        }
      }
    }
    return true;
  });
}
