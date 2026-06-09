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
