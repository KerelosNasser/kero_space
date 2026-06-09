import 'package:isar/isar.dart';

part 'church_collections.g.dart';

@collection
class MassAttendance {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late DateTime date;
}

@collection
class ConfessionEntry {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late DateTime timestamp;
  late List<int> encryptedPayload; // AES-256-GCM
}

@collection
class MinistryTask {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String title;
  late String status; // 'TODO', 'IN_PROGRESS', 'DONE'
  late DateTime createdAt;
}
