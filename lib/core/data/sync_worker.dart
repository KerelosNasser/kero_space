import 'dart:isolate';
import 'package:isar/isar.dart';
import 'sync_outbox_repository.dart';
import 'isar_service.dart';

class SyncWorker {
  static Future<void> triggerSync(String dbDirectory) async {
    await Isolate.run(() async {
      // Open Isar inside the isolate
      await IsarService.init(dbDirectory);
      
      final repo = SyncOutboxRepository();
      final batch = await repo.getPendingBatch();
      
      if (batch.isNotEmpty) {
        // Mocking HTTP Sync for now
        print('Syncing ${batch.length} records to Docker backend...');
        
        await IsarService.instance.writeTxn(() async {
          for (var record in batch) {
            record.status = 'SYNCED';
            await IsarService.instance.syncOutboxRecords.put(record);
          }
        });
      }
      
      // Clean exit
      await IsarService.instance.close();
    });
  }
}
