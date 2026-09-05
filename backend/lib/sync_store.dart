import 'dart:convert';
import 'dart:io';

class SyncRecord {
  final int? clientOutboxId;
  final String entityId;
  final String collectionName;
  final String operation; // 'CREATE', 'UPDATE', 'DELETE'
  final dynamic payload;
  final String createdAt;
  final String updatedAt;

  SyncRecord({
    this.clientOutboxId,
    required this.entityId,
    required this.collectionName,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'clientOutboxId': clientOutboxId,
        'entityId': entityId,
        'collectionName': collectionName,
        'operation': operation,
        'payload': payload,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory SyncRecord.fromJson(Map<String, dynamic> json) {
    return SyncRecord(
      clientOutboxId: json['clientOutboxId'] as int?,
      entityId: json['entityId'] as String? ?? '',
      collectionName: json['collectionName'] as String? ?? '',
      operation: json['operation'] as String? ?? 'CREATE',
      payload: json['payload'],
      createdAt: json['createdAt'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ?? DateTime.now().toUtc().toIso8601String(),
    );
  }
}

class SyncStore {
  final String filePath;
  final Map<String, SyncRecord> _records = {};

  SyncStore({this.filePath = 'data/sync_db.json'});

  Future<void> init() async {
    final file = File(filePath);
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          final recordsList = decoded['records'] as List<dynamic>? ?? [];
          for (final item in recordsList) {
            if (item is Map<String, dynamic>) {
              final record = SyncRecord.fromJson(item);
              _records['${record.collectionName}:${record.entityId}'] = record;
            }
          }
        }
      } catch (e) {
        stderr.writeln('Warning: Failed to parse sync store at $filePath: $e');
      }
    }
  }

  Future<List<int>> ingestBatch(List<Map<String, dynamic>> rawRecords) async {
    final List<int> syncedOutboxIds = [];
    final nowIso = DateTime.now().toUtc().toIso8601String();

    for (final raw in rawRecords) {
      final clientOutboxId = raw['id'] is int
          ? raw['id'] as int
          : (raw['clientOutboxId'] is int ? raw['clientOutboxId'] as int : null);
      final entityId = (raw['entityId'] ?? '').toString();
      final collectionName = (raw['collectionName'] ?? '').toString();
      final operation = (raw['operation'] ?? 'CREATE').toString();
      
      dynamic payload = raw['payload'] ?? raw['payloadJson'];
      if (payload is String) {
        try {
          payload = jsonDecode(payload);
        } catch (_) {
          // Keep string if not json
        }
      }

      final createdAt = (raw['createdAt'] ?? nowIso).toString();

      final record = SyncRecord(
        clientOutboxId: clientOutboxId,
        entityId: entityId,
        collectionName: collectionName,
        operation: operation,
        payload: payload,
        createdAt: createdAt,
        updatedAt: nowIso,
      );

      _records['$collectionName:$entityId'] = record;

      if (clientOutboxId != null) {
        syncedOutboxIds.add(clientOutboxId);
      }
    }

    await _persist();
    return syncedOutboxIds;
  }

  List<SyncRecord> getRecords({String? since, String? collection}) {
    DateTime? sinceDate;
    if (since != null) {
      sinceDate = DateTime.tryParse(since);
    }

    return _records.values.where((rec) {
      if (collection != null && collection.isNotEmpty && rec.collectionName != collection) {
        return false;
      }
      if (sinceDate != null) {
        final recUpdated = DateTime.tryParse(rec.updatedAt);
        if (recUpdated == null || !recUpdated.isAfter(sinceDate)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get totalRecords => _records.length;

  Future<void> _persist() async {
    final file = File(filePath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final data = {
      'version': 1,
      'lastSaved': DateTime.now().toUtc().toIso8601String(),
      'records': _records.values.map((r) => r.toJson()).toList(),
    };

    final tempFile = File('${file.path}.tmp');
    await tempFile.writeAsString(jsonEncode(data), flush: true);
    await tempFile.rename(file.path);
  }
}
