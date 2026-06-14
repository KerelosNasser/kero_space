import 'package:isar/isar.dart';
import '../models/telemetry_collections.dart';

class ScreenEventRepository {
  final Isar _isar;
  ScreenEventRepository(this._isar);

  Future<List<ScreenEvent>> getUnlockEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    return _isar.screenEvents
        .filter()
        .eventTypeEqualTo('UNLOCK')
        .timestampBetween(from, to)
        .sortByTimestamp()
        .findAll();
  }

  Future<List<ScreenEvent>> getAllEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    return _isar.screenEvents
        .filter()
        .timestampBetween(from, to)
        .sortByTimestamp()
        .findAll();
  }

  Future<int> getTotalScreenTimeMs({
    required DateTime from,
    required DateTime to,
  }) async {
    final events = await getAllEvents(from: from, to: to);
    int totalMs = 0;
    DateTime? lastWake;
    for (final e in events) {
      if (e.eventType == 'WAKE') {
        lastWake = e.timestamp;
      } else if (e.eventType == 'SLEEP' && lastWake != null) {
        totalMs += e.timestamp.difference(lastWake).inMilliseconds;
        lastWake = null;
      }
    }
    return totalMs;
  }

  /// Returns 7×24 matrix: matrix[dayIndex][hour] = unlock count.
  Future<List<List<int>>> getUnlockHeatmap({required DateTime weekStart}) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final unlocks = await getUnlockEvents(from: weekStart, to: weekEnd);
    final matrix = List.generate(7, (_) => List.filled(24, 0));
    for (final e in unlocks) {
      final dayIndex = e.timestamp.difference(weekStart).inDays.clamp(0, 6);
      final hour = e.timestamp.hour;
      matrix[dayIndex][hour]++;
    }
    return matrix;
  }

  Stream<void> watchChanges() => _isar.screenEvents.watchLazy();

  Future<void> pruneOldData({int daysToKeep = 30}) async {
    final threshold = DateTime.now().subtract(Duration(days: daysToKeep));
    await _isar.writeTxn(() async {
      await _isar.screenEvents.filter().timestampLessThan(threshold).deleteAll();
    });
  }
}
