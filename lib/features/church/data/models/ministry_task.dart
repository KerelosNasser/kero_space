import 'package:isar/isar.dart';

part 'ministry_task.g.dart';

enum MinistryTaskStatus { todo, inProgress, done }

@Collection()
class MinistryTask {
  Id id = Isar.autoIncrement;

  late String title;
  String? description;

  @enumerated
  late MinistryTaskStatus status;

  DateTime? deadline;
  int priority = 3;
  String? assignedTo;

  String? serverId;
  DateTime? syncedAt;
  DateTime locallyModifiedAt = DateTime.now();

  MinistryTask copyWith({
    String? title,
    String? description,
    MinistryTaskStatus? status,
    DateTime? deadline,
    int? priority,
    String? assignedTo,
  }) {
    return MinistryTask()
      ..id = id
      ..title = title ?? this.title
      ..description = description ?? this.description
      ..status = status ?? this.status
      ..deadline = deadline ?? this.deadline
      ..priority = priority ?? this.priority
      ..assignedTo = assignedTo ?? this.assignedTo
      ..serverId = serverId
      ..syncedAt = syncedAt
      ..locallyModifiedAt = DateTime.now();
  }
}
