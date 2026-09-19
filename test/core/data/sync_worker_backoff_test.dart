import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/core/data/sync_worker.dart';

void main() {
  group('SyncWorker Backoff & Retry Logic Tests', () {
    test('calculateBackoff returns zero for non-positive retries', () {
      expect(SyncWorker.calculateBackoff(0), Duration.zero);
      expect(SyncWorker.calculateBackoff(-1), Duration.zero);
    });

    test('calculateBackoff calculates exponential delay', () {
      // retry 1: 2s * 2^1 = 4s
      final delay1 = SyncWorker.calculateBackoff(1, baseDelay: const Duration(seconds: 2));
      expect(delay1.inSeconds, 4);

      // retry 2: 2s * 2^2 = 8s
      final delay2 = SyncWorker.calculateBackoff(2, baseDelay: const Duration(seconds: 2));
      expect(delay2.inSeconds, 8);

      // retry 3: 2s * 2^3 = 16s
      final delay3 = SyncWorker.calculateBackoff(3, baseDelay: const Duration(seconds: 2));
      expect(delay3.inSeconds, 16);
    });

    test('calculateBackoff respects maxDelay cap', () {
      final delay = SyncWorker.calculateBackoff(
        10,
        baseDelay: const Duration(seconds: 2),
        maxDelay: const Duration(seconds: 60),
      );
      expect(delay.inSeconds, 60);
    });

    test('calculateBackoff adds jitter correctly', () {
      final delay = SyncWorker.calculateBackoff(
        2,
        baseDelay: const Duration(seconds: 2),
        jitterMs: 500,
      );
      expect(delay.inMilliseconds, 8500);
    });
  });
}
