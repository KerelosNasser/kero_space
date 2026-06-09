import 'package:isar/isar.dart';

part 'ministry_member.g.dart';

@Collection()
class MinistryMember {
  Id id = Isar.autoIncrement;

  late String name;
  late String role;
  String? contact;
  late DateTime joinDate;

  String? serverId;
  DateTime? syncedAt;
  DateTime locallyModifiedAt = DateTime.now();
}
