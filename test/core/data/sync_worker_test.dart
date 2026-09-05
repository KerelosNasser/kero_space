import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/core/data/sync_worker.dart';

void main() {
  group('SyncWorker Endpoint Formatting', () {
    test('formats empty or null url with default fallback', () {
      final endpoint = SyncWorker.formatEndpoint(null);
      expect(endpoint, contains('8080'));
    });

    test('prepends http scheme if missing', () {
      final endpoint = SyncWorker.formatEndpoint('192.168.1.50:8080');
      expect(endpoint, 'http://192.168.1.50:8080');
    });

    test('preserves https scheme and port', () {
      final endpoint = SyncWorker.formatEndpoint('https://my-server.local:8443');
      expect(endpoint, 'https://my-server.local:8443');
    });

    test('appends default port 8080 when port is omitted', () {
      final endpoint = SyncWorker.formatEndpoint('192.168.1.100');
      expect(endpoint, 'http://192.168.1.100:8080');
    });
  });
}
