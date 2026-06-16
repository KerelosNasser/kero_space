import 'package:workmanager/workmanager.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';
import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'package:kero_space/core/data/isar_service.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FinanceWorker {
  static const String taskName = 'egx_scraper_task';

  static void initializeWorkmanager() {
    Workmanager().initialize(
      callbackDispatcher,
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
    }
    return true;
  });
}
