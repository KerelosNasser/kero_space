import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:kero_space/features/telemetry/data/models/telemetry_collections.dart';
import 'package:kero_space/features/telemetry/data/repositories/screen_event_repository.dart';

void main() {
  late Isar isar;
  late ScreenEventRepository repo;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open([ScreenEventSchema], directory: Directory.systemTemp.path);
    repo = ScreenEventRepository(isar);
  });

  tearDown(() async => isar.close(deleteFromDisk: true));

  test('getUnlockEvents returns only UNLOCK events in date range', () async {
    final now = DateTime.now();
    await isar.writeTxn(() async {
      await isar.screenEvents.putAll([
        ScreenEvent()
          ..deviceId = 'd1'
          ..platform = 'android'
          ..eventType = 'UNLOCK'
          ..timestamp = now.subtract(const Duration(hours: 1)),
        ScreenEvent()
          ..deviceId = 'd1'
          ..platform = 'android'
          ..eventType = 'SLEEP'
          ..timestamp = now.subtract(const Duration(hours: 2)),
      ]);
    });

    final results = await repo.getUnlockEvents(
      from: now.subtract(const Duration(days: 1)),
      to: now,
    );

    expect(results.length, 1);
    expect(results.first.eventType, 'UNLOCK');
  });

  test('getTotalScreenTimeMs sums WAKE-to-SLEEP durations', () async {
    final now = DateTime.now();
    await isar.writeTxn(() async {
      await isar.screenEvents.putAll([
        ScreenEvent()..deviceId='d1'..platform='android'..eventType='WAKE'
          ..timestamp = now.subtract(const Duration(hours: 2)),
        ScreenEvent()..deviceId='d1'..platform='android'..eventType='SLEEP'
          ..timestamp = now.subtract(const Duration(hours: 1)),
      ]);
    });

    final ms = await repo.getTotalScreenTimeMs(
      from: now.subtract(const Duration(days: 1)),
      to: now,
    );

    expect(ms, closeTo(3600000, 5000));
  });
}
