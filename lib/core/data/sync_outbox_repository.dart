import 'package:isar/isar.dart';
import 'isar_service.dart';
import 'sync_outbox_record.dart';

class SyncOutboxRepository {
  Future<void> addToOutbox(SyncOutboxRecord record) async {
    await IsarService.instance.writeTxn(() async {
      await IsarService.instance.syncOutboxRecords.put(record);
    });
  }

  Future<List<SyncOutboxRecord>> getPendingBatch({int limit = 50}) async {
    return IsarService.instance.syncOutboxRecords
        .filter()
        .statusEqualTo('PENDING')
        .sortByCreatedAt()
        .limit(limit)
        .findAll();
  }
}
