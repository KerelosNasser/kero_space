import 'package:isar/isar.dart';

import '../models/telemetry_collections.dart';

class ClickLogRepository {
  final Isar _isar;

  static const int pageSize = 50;

  ClickLogRepository(this._isar);

  Future<List<TelemetryEvent>> getClickLogs({
    DateTime? from,
    DateTime? to,
    int page = 0,
  }) async {
    final rangeFrom = from ?? DateTime.now().subtract(const Duration(days: 7));
    final rangeTo = to ?? DateTime.now();

    return _isar.telemetryEvents
        .filter()
        .nameEqualTo('click')
        .timestampBetween(rangeFrom, rangeTo)
        .sortByTimestampDesc()
        .offset(page * pageSize)
        .limit(pageSize)
        .findAll();
  }

  Future<List<TelemetryEvent>> getEventsByName({
    required String name,
    required DateTime from,
    required DateTime to,
  }) async {
    return _isar.telemetryEvents
        .filter()
        .nameEqualTo(name)
        .timestampBetween(from, to)
        .findAll();
  }

  Future<List<int>> getHourlyClickDensity(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final events = await _isar.telemetryEvents
        .filter()
        .nameEqualTo('click')
        .timestampBetween(start, end)
        .findAll();

    final density = List.filled(24, 0);
    for (final event in events) {
      density[event.timestamp.hour]++;
    }
    return density;
  }

  Future<void> pruneOldData({int daysToKeep = 30}) async {
    final threshold = DateTime.now().subtract(Duration(days: daysToKeep));
    await _isar.writeTxn(() async {
      await _isar.telemetryEvents
          .filter()
          .timestampLessThan(threshold)
          .deleteAll();
    });
  }
}
