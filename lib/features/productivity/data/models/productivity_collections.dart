import 'package:isar/isar.dart';

part 'productivity_collections.g.dart';

enum TaskType { project, task, subtask }

@collection
class Task {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String title;
  String? description;
  bool isCompleted = false;
  DateTime? dueDate;
  late DateTime createdAt;
  late DateTime updatedAt;

  @Enumerated(EnumType.name)
  late TaskType type;
  int? parentId;
  int? linkedNoteId;
}

@collection
class Note {
  Id id = Isar.autoIncrement;
  late String deviceId;
  late String platform;
  late String title;
  late String quillDelta;
  late DateTime updatedAt;
  late DateTime createdAt;
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
  bool allDay = false;
}
