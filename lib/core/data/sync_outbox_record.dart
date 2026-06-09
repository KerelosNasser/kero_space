import 'package:isar/isar.dart';

part 'sync_outbox_record.g.dart';

@collection
class SyncOutboxRecord {
  Id id = Isar.autoIncrement;
  late String entityId;
  late String collectionName;
  late String operation; // 'CREATE', 'UPDATE', 'DELETE'
  late String payloadJson;
  @Index()
  late DateTime createdAt;
  @Index()
  String status = 'PENDING'; // 'PENDING', 'SYNCED', 'FAILED'
  String? error;
}
