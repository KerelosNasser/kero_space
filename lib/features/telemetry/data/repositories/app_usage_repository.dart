import 'package:isar/isar.dart';
import '../models/telemetry_collections.dart';

class AppUsageRepository {
  final Isar _isar;
  AppUsageRepository(this._isar);

  Future<List<AppUsageRecord>> getTodayUsage() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _isar.appUsageRecords
        .filter()
        .dateBetween(startOfDay, now)
        .sortByForegroundMsDesc()
        .findAll();
  }

  Future<List<(DateTime, int)>> getWeeklyScreenTimeTotals() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final records = await _isar.appUsageRecords
        .filter()
        .dateBetween(weekAgo, now)
        .findAll();

    final Map<String, int> byDate = {};
    for (final r in records) {
      final key = '${r.date.year}-${r.date.month}-${r.date.day}';
      byDate[key] = (byDate[key] ?? 0) + r.foregroundMs;
    }

    return byDate.entries.map((e) {
      final parts = e.key.split('-');
      return (DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])), e.value);
    }).toList()..sort((a, b) => a.$1.compareTo(b.$1));
  }

  Stream<void> watchChanges() => _isar.appUsageRecords.watchLazy();
}
