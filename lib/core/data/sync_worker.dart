import 'dart:isolate';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'sync_outbox_repository.dart';
import 'isar_service.dart';
import 'sync_outbox_record.dart';

class SyncWorker {
  static Future<void> triggerSync(String dbDirectory) async {
    await Isolate.run(() async {
      // Open Isar inside the isolate
      await IsarService.init(dbDirectory);
      
      final repo = SyncOutboxRepository();
      final batch = await repo.getPendingBatch();
      
      if (batch.isNotEmpty) {
        // Mocking HTTP Sync for now
        final baseUrl = Platform.isWindows ? 'localhost' : '192.168.1.100';
        final endpoint = 'https://$baseUrl:8443';
        debugPrint('Syncing ${batch.length} records to $endpoint...');
        
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
