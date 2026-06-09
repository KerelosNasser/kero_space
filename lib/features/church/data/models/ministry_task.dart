import 'package:isar/isar.dart';

part 'ministry_task.g.dart';

enum MinistryTaskStatus {
  todo,
  inProgress,
  done,
}

@Collection()
class MinistryTask {
  Id id = Isar.autoIncrement;

  late String title;
  String? description;
  
  @enumerated
  late MinistryTaskStatus status;

  DateTime? deadline;

  String? serverId;
  DateTime? syncedAt;
  DateTime locallyModifiedAt = DateTime.now();
}
