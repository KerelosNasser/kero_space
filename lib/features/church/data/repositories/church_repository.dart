import 'package:isar/isar.dart';
import '../models/mass_attendance.dart';
import '../models/ministry_task.dart';

class ChurchRepository {
  final Isar _isar;
  ChurchRepository(this._isar);

  Future<void> markAttendance(DateTime date, ServiceType type) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await _isar.writeTxn(() async {
      final existing = await _isar.massAttendances
          .filter()
          .dateEqualTo(normalized)
          .findFirst();
      if (existing != null) {
        if (!existing.services.contains(type)) {
          existing.services = [...existing.services, type];
          await _isar.massAttendances.put(existing);
        }
      } else {
        final record = MassAttendance()
          ..date = normalized
          ..services = [type];
        await _isar.massAttendances.put(record);
      }
    });
  }

  Future<List<MassAttendance>> getAttendances() {
    return _isar.massAttendances.where().sortByDate().findAll();
  }

  Future<List<MassAttendance>> getAttendancesByDateRange(
      DateTime start, DateTime end) {
    return _isar.massAttendances
        .filter()
        .dateBetween(start, end)
        .sortByDate()
        .findAll();
  }

  Future<int> getStreak() async {
    final attendances =
        await _isar.massAttendances.where().sortByDateDesc().findAll();
    if (attendances.isEmpty) return 0;

    int streak = 0;
    DateTime expected = DateTime.now();
    expected = DateTime(expected.year, expected.month, expected.day);

    for (final att in attendances) {
      final attDate = DateTime(att.date.year, att.date.month, att.date.day);
      final diff = expected.difference(attDate).inDays;
      if (diff == 0) {
        if (streak == 0) streak = 1;
        expected = attDate.subtract(const Duration(days: 1));
      } else if (diff == 1) {
        streak++;
        expected = attDate.subtract(const Duration(days: 1));
      } else if (streak > 0) {
        break;
      }
    }
    return streak;
  }

  Future<int> getBestStreak() async {
    final attendances =
        await _isar.massAttendances.where().sortByDateDesc().findAll();
    if (attendances.isEmpty) return 0;

    final sorted = List<MassAttendance>.from(attendances)
      ..sort((a, b) => a.date.compareTo(b.date));

    int best = 0;
    int current = 0;
    DateTime? lastDate;

    for (final att in sorted) {
      final attDate = DateTime(att.date.year, att.date.month, att.date.day);
      if (lastDate == null) {
        current = 1;
      } else {
        final diff = attDate.difference(lastDate).inDays;
        if (diff == 1) {
          current++;
        } else {
          best = best > current ? best : current;
          current = 1;
        }
      }
      lastDate = attDate;
    }
    best = best > current ? best : current;
    return best;
  }

  Future<void> saveTask(MinistryTask task) async {
    await _isar.writeTxn(() async {
      await _isar.ministryTasks.put(task);
    });
  }

  Future<List<MinistryTask>> getTasks() async {
    return _isar.ministryTasks.where().findAll();
  }

  Future<void> deleteAttendance(DateTime date, ServiceType type) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await _isar.writeTxn(() async {
      final existing = await _isar.massAttendances
          .filter()
          .dateEqualTo(normalized)
          .findFirst();
      if (existing != null) {
        existing.services =
            existing.services.where((s) => s != type).toList();
        if (existing.services.isEmpty) {
          await _isar.massAttendances.delete(existing.id);
        } else {
          await _isar.massAttendances.put(existing);
        }
      }
    });
  }
}
