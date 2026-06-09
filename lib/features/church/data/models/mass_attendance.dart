import 'package:isar/isar.dart';

part 'mass_attendance.g.dart';

enum AttendanceType {
  liturgy,
  vespers,
}

@Collection()
class MassAttendance {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date;

  @enumerated
  late AttendanceType attendanceType;

  String? serverId;
  DateTime? syncedAt;
  DateTime locallyModifiedAt = DateTime.now();
}
