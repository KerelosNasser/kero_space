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

@collection
class TelemetryEvent {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String name;
  late String dataJson;
  late DateTime timestamp;
}
