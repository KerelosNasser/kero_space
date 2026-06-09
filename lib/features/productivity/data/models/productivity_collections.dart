import 'package:isar/isar.dart';

part 'productivity_collections.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String title;
  bool isCompleted = false;
  DateTime? dueDate;
  late DateTime createdAt;
}

@collection
class Note {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String title;
  late String contentJson;
  late DateTime updatedAt;
}

@collection
class CalendarEvent {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String title;
  late DateTime startTime;
  late DateTime endTime;
  late String source; // 'SAMSUNG', 'GOOGLE', 'LOCAL'
}
