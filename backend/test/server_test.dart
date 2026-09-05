import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  final port = '8085';
  final host = 'http://127.0.0.1:$port';
  late Process p;
  final tempDbFile = File('data/test_sync_db.json');

  setUp(() async {
    if (await tempDbFile.exists()) {
      await tempDbFile.delete();
    }
    p = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {
        'PORT': port,
        'SYNC_DB_PATH': tempDbFile.path,
      },
    );
    // Wait for server to start and print to stdout.
    await p.stdout.first;
  });

  tearDown(() async {
    p.kill();
    if (await tempDbFile.exists()) {
      await tempDbFile.delete();
    }
  });

  test('Health check endpoint returns healthy status', () async {
    final response = await get(Uri.parse('$host/health'));
    expect(response.statusCode, 200);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    expect(body['status'], 'healthy');
    expect(body.containsKey('timestamp'), isTrue);
  });

  test('Sync batch endpoint ingests records and pull endpoint retrieves them', () async {
    final batchPayload = jsonEncode({
      'records': [
        {
          'id': 101,
          'entityId': 'tx-001',
          'collectionName': 'transactions',
          'operation': 'CREATE',
          'payload': {'amount': 150.0, 'category': 'groceries'},
          'createdAt': '2026-09-05T12:00:00Z',
        },
        {
          'id': 102,
          'entityId': 'habit-001',
          'collectionName': 'habits',
          'operation': 'CREATE',
          'payload': {'name': 'Morning Prayer'},
          'createdAt': '2026-09-05T12:05:00Z',
        }
      ]
    });

    final batchResponse = await post(
      Uri.parse('$host/sync/batch'),
      headers: {'content-type': 'application/json'},
      body: batchPayload,
    );

    expect(batchResponse.statusCode, 200);
    final batchBody = jsonDecode(batchResponse.body) as Map<String, dynamic>;
    expect(batchBody['status'], 'ok');
    expect(batchBody['synced_count'], 2);
    expect(batchBody['synced_ids'], containsAll([101, 102]));

    // Pull back records
    final pullResponse = await get(Uri.parse('$host/sync/pull'));
    expect(pullResponse.statusCode, 200);
    final pullBody = jsonDecode(pullResponse.body) as Map<String, dynamic>;
    expect(pullBody['status'], 'ok');
    expect(pullBody['count'], 2);

    // Pull filtered by collection
    final filteredPull = await get(Uri.parse('$host/sync/pull?collection=transactions'));
    expect(filteredPull.statusCode, 200);
    final filteredBody = jsonDecode(filteredPull.body) as Map<String, dynamic>;
    expect(filteredBody['count'], 1);
    expect(filteredBody['records'][0]['entityId'], 'tx-001');
  });

  test('404 for unknown endpoint', () async {
    final response = await get(Uri.parse('$host/unknown_route'));
    expect(response.statusCode, 404);
  });
}
