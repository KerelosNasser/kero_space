import 'package:isar/isar.dart';

part 'mass_attendance.g.dart';

enum ServiceType {
  liturgy,
  vespers,
  midnightPraise,
  divineLiturgy,
  other,
}

@Collection()
class MassAttendance {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date;

  @enumerated
  List<ServiceType> services = [];

  String? serverId;
  DateTime? syncedAt;
  DateTime locallyModifiedAt = DateTime.now();
}
