import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security - TLS Pinning', () {
    test('Untrusted certificates must be rejected with HandshakeException', () async {
      // Create a client that does NOT accept bad certificates
      final client = HttpClient();
      // By default badCertificateCallback is null, meaning it rejects bad certs.
      
      try {
        // Attempting to connect to a known badssl endpoint for testing
        final request = await client.getUrl(Uri.parse('https://untrusted-root.badssl.com/'));
        await request.close();
        
        // If it succeeds, the test should fail
        fail('Expected HandshakeException due to untrusted certificate');
      } catch (e) {
        expect(e, isA<HandshakeException>());
      }
    });
  });
}
