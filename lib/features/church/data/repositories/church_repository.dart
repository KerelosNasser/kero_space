import 'package:isar/isar.dart';
import '../models/mass_attendance.dart';
import '../models/ministry_task.dart';
import '../models/ministry_member.dart';

class ChurchRepository {
  final Isar _isar;

  ChurchRepository(this._isar);

  Future<void> markAttendance(DateTime date, AttendanceType type) async {
    final record = MassAttendance()
      ..date = DateTime(date.year, date.month, date.day)
      ..attendanceType = type;

    await _isar.writeTxn(() async {
      await _isar.massAttendances.put(record);
    });
  }

  Future<List<MassAttendance>> getAttendances() async {
    return _isar.massAttendances.where().sortByDate().findAll();
  }
  
  Future<void> saveTask(MinistryTask task) async {
    await _isar.writeTxn(() async {
      await _isar.ministryTasks.put(task);
    });
  }

  Future<List<MinistryTask>> getTasks() async {
    return _isar.ministryTasks.where().findAll();
  }
}
