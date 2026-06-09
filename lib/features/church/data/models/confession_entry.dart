import 'package:isar/isar.dart';

part 'confession_entry.g.dart';

@Collection(accessor: 'confessions')
class ConfessionEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  late List<int> encryptedPayload;
  
  // No sync fields because confessions are strictly local and excluded from sync outbox
}
