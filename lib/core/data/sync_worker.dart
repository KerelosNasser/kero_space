import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'isar_service.dart';
import 'sync_outbox_record.dart';
import 'sync_outbox_repository.dart';

class SyncResult {
  final bool success;
  final int syncedCount;
  final int pendingCount;
  final String? errorMessage;

  const SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.pendingCount = 0,
    this.errorMessage,
  });
}

class SyncWorker {
  static String formatEndpoint(String? rawUrl) {
    var url = (rawUrl ?? '').trim();
    if (url.isEmpty) {
      final host = Platform.isWindows ? '127.0.0.1' : '10.0.2.2';
      return 'http://$host:8080';
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri != null && !uri.hasPort) {
      return '$url:8080';
    }

    return url;
  }

  static Future<SyncResult> triggerSync({
    String? dbDirectory,
    String? dockerUrl,
    Dio? dioClient,
  }) async {
    if (!IsarService.isInitialized) {
      if (dbDirectory == null || dbDirectory.isEmpty) {
        return const SyncResult(
          success: false,
          errorMessage: 'Isar not initialized and dbDirectory is null',
        );
      }
      await IsarService.init(dbDirectory);
    }

    final repo = SyncOutboxRepository();
    final batch = await repo.getPendingBatch(limit: 100);

    if (batch.isEmpty) {
      final remaining = await repo.getPendingCount();
      return SyncResult(success: true, syncedCount: 0, pendingCount: remaining);
    }

    final endpoint = formatEndpoint(dockerUrl);
    final targetUrl = '$endpoint/sync/batch';

    final dio = dioClient ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
          ),
        );

    final payload = {
      'records': batch.map((r) {
        dynamic parsedPayload;
        try {
          parsedPayload = jsonDecode(r.payloadJson);
        } catch (_) {
          parsedPayload = r.payloadJson;
        }
        return {
          'id': r.id,
          'entityId': r.entityId,
          'collectionName': r.collectionName,
          'operation': r.operation,
          'payload': parsedPayload,
          'createdAt': r.createdAt.toIso8601String(),
        };
      }).toList(),
    };

    try {
      final response = await dio.post(
        targetUrl,
        data: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<int> syncedIds = [];
        if (data is Map && data['synced_ids'] is List) {
          syncedIds = (data['synced_ids'] as List)
              .whereType<num>()
              .map((n) => n.toInt())
              .toList();
        } else {
          syncedIds = batch.map((r) => r.id).toList();
        }

        await IsarService.instance.writeTxn(() async {
          for (var record in batch) {
            if (syncedIds.contains(record.id)) {
              record.status = 'SYNCED';
              record.error = null;
              await IsarService.instance.syncOutboxRecords.put(record);
            }
          }
        });

        final remaining = await repo.getPendingCount();
        return SyncResult(
          success: true,
          syncedCount: syncedIds.length,
          pendingCount: remaining,
        );
      } else {
        final errorMsg = 'Server returned HTTP ${response.statusCode}';
        await _recordBatchError(batch, errorMsg);
        final remaining = await repo.getPendingCount();
        return SyncResult(
          success: false,
          syncedCount: 0,
          pendingCount: remaining,
          errorMessage: errorMsg,
        );
      }
    } catch (e) {
      final errorMsg = e.toString();
      debugPrint('SyncWorker error: $errorMsg');
      await _recordBatchError(batch, errorMsg);
      final remaining = await repo.getPendingCount();
      return SyncResult(
        success: false,
        syncedCount: 0,
        pendingCount: remaining,
        errorMessage: errorMsg,
      );
    }
  }

  static Future<void> _recordBatchError(
      List<SyncOutboxRecord> batch, String error) async {
    try {
      await IsarService.instance.writeTxn(() async {
        for (var record in batch) {
          record.error = error;
          await IsarService.instance.syncOutboxRecords.put(record);
        }
      });
    } catch (e) {
      debugPrint('Failed to save sync error to outbox: $e');
    }
  }
}
