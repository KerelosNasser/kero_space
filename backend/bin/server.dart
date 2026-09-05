import 'dart:convert';
import 'dart:io';

import 'package:backend/sync_store.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

Middleware corsHeaders() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  };

  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await innerHandler(request);
      return response.change(headers: headers);
    };
  };
}

void main(List<String> args) async {
  final dbPath = Platform.environment['SYNC_DB_PATH'] ?? 'data/sync_db.json';
  final syncStore = SyncStore(filePath: dbPath);
  await syncStore.init();

  final router = Router();

  // Health check endpoint
  router.get('/health', (Request req) {
    return Response.ok(
      jsonEncode({
        'status': 'healthy',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'total_records': syncStore.totalRecords,
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // Batch sync ingestion endpoint
  router.post('/sync/batch', (Request req) async {
    try {
      final bodyStr = await req.readAsString();
      if (bodyStr.trim().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Empty request body'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final dynamic decoded = jsonDecode(bodyStr);
      List<Map<String, dynamic>> recordsList = [];

      if (decoded is List) {
        recordsList = decoded.cast<Map<String, dynamic>>();
      } else if (decoded is Map<String, dynamic> && decoded['records'] is List) {
        recordsList = (decoded['records'] as List).cast<Map<String, dynamic>>();
      } else {
        return Response.badRequest(
          body: jsonEncode({'error': 'Expected JSON array or object with "records" array'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final syncedIds = await syncStore.ingestBatch(recordsList);

      return Response.ok(
        jsonEncode({
          'status': 'ok',
          'synced_count': syncedIds.length,
          'synced_ids': syncedIds,
          'server_time': DateTime.now().toUtc().toIso8601String(),
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stack) {
      stderr.writeln('Error in /sync/batch: $e\n$stack');
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // Pull delta sync endpoint
  router.get('/sync/pull', (Request req) {
    try {
      final since = req.url.queryParameters['since'];
      final collection = req.url.queryParameters['collection'];

      final records = syncStore.getRecords(since: since, collection: collection);

      return Response.ok(
        jsonEncode({
          'status': 'ok',
          'count': records.length,
          'records': records.map((r) => r.toJson()).toList(),
          'server_time': DateTime.now().toUtc().toIso8601String(),
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  stdout.writeln('Server listening on port ${server.port}');
}
