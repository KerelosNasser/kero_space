import 'package:isar/isar.dart';

part 'telemetry_collections.g.dart';

@collection
class ScreenEvent {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform; // 'android' or 'windows'
  late String eventType; // 'WAKE', 'SLEEP', 'UNLOCK'
  late DateTime timestamp;
}

@collection
class AppUsageRecord {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String packageName;
  late int foregroundMs;
  late DateTime date;
}
