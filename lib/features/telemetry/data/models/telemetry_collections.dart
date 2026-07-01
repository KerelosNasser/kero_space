import 'package:isar/isar.dart';

part 'telemetry_collections.g.dart';

@collection
class ScreenEvent {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform; // 'android' or 'windows'
  @Index(composite: [CompositeIndex('timestamp')])
  late String eventType; // 'WAKE', 'SLEEP', 'UNLOCK'
  @Index()
  late DateTime timestamp;
}

@collection
class AppUsageRecord {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  @Index(composite: [CompositeIndex('date')])
  late String packageName;
  late int foregroundMs;
  @Index()
  late DateTime date;
}

@collection
class TelemetryEvent {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  @Index(composite: [CompositeIndex('timestamp')])
  late String name;
  late String dataJson;
  @Index()
  late DateTime timestamp;
}
