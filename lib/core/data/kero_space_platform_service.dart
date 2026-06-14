import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_service.dart';
import '../../features/telemetry/data/models/telemetry_collections.dart';

/// Entrypoint for the headless FlutterEngine spawned by Android.
@pragma('vm:entry-point')
void backgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("KeroSpace: Background Isolate Started.");

  try {
    final dir = await getApplicationDocumentsDirectory();
    await IsarService.init(dir.path);
    debugPrint("KeroSpace Background: Isar initialized.");
  } catch (e) {
    debugPrint("KeroSpace Background: Failed to initialize Isar: $e");
  }

  const EventChannel screenChannel = EventChannel('kero_space/screen_events');
  screenChannel.receiveBroadcastStream().listen((event) async {
    debugPrint("KeroSpace Background: Received Screen Event: $event");
    try {
      final data = jsonDecode(event as String);
      final type = data['type'] as String;
      final timestampMs = data['timestamp'] as int;

      final screenEvent = ScreenEvent()
        ..deviceId = 'android'
        ..platform = 'android'
        ..eventType = type
        ..timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);

      await IsarService.instance.writeTxn(() async {
        await IsarService.instance.screenEvents.put(screenEvent);
      });
      debugPrint("KeroSpace Background: Wrote ScreenEvent to Isar: $type");
    } catch (e) {
      debugPrint("KeroSpace Background: Error writing ScreenEvent: $e");
    }
  });

  const EventChannel accessChannel = EventChannel('kero_space/accessibility');
  accessChannel.receiveBroadcastStream().listen((event) async {
    debugPrint("KeroSpace Background: Received Accessibility Event: $event");
    try {
      final data = jsonDecode(event);
      final type = data['type'] as String;
      final timestampMs = data['timestamp'] as int;

      if (type == 'CLICK') {
        final clickEvent = TelemetryEvent()
          ..deviceId = 'android'
          ..platform = 'android'
          ..name = 'click'
          ..dataJson = event as String
          ..timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);

        await IsarService.instance.writeTxn(() async {
          await IsarService.instance.telemetryEvents.put(clickEvent);
        });
        debugPrint("KeroSpace Background: Wrote Click TelemetryEvent to Isar");
      }
    } catch (e) {
      debugPrint("KeroSpace Background: Error writing AccessibilityEvent: $e");
    }
  });

  const EventChannel wakeWordChannel = EventChannel('kero_space/wake_word');
  wakeWordChannel.receiveBroadcastStream().listen((event) {
    debugPrint("KeroSpace Background: Received Wake Word Event: $event");
  });

  const EventChannel usageChannel = EventChannel('kero_space/usage_stats');
  usageChannel.receiveBroadcastStream().listen((event) async {
    debugPrint("KeroSpace Background: Received Usage Stats: $event");
    try {
      final List<dynamic> list = jsonDecode(event as String);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await IsarService.instance.writeTxn(() async {
        for (final item in list) {
          final packageName = item['packageName'] as String;
          final foregroundMs = item['foregroundTimeMs'] as int;

          final existing = await IsarService.instance.appUsageRecords
              .filter()
              .packageNameEqualTo(packageName)
              .dateEqualTo(today)
              .findFirst();

          if (existing != null) {
            existing.foregroundMs = foregroundMs;
            await IsarService.instance.appUsageRecords.put(existing);
          } else {
            final record = AppUsageRecord()
              ..deviceId = 'android'
              ..platform = 'android'
              ..packageName = packageName
              ..foregroundMs = foregroundMs
              ..date = today;
            await IsarService.instance.appUsageRecords.put(record);
          }
        }
      });
      debugPrint("KeroSpace Background: Wrote AppUsageRecords to Isar");
    } catch (e) {
      debugPrint("KeroSpace Background: Error writing Usage Stats: $e");
    }
  });
}

class KeroSpacePlatformService {
  static const MethodChannel _methodChannel = MethodChannel('kero_space/methods');

  Future<void> showOverlay(String packageName, int durationSeconds) async {
    await _methodChannel.invokeMethod('showOverlay', {
      'packageName': packageName,
      'durationSeconds': durationSeconds,
    });
  }

  Future<void> dismissOverlay() async {
    await _methodChannel.invokeMethod('dismissOverlay');
  }

  /// Syncs blacklist rules to Kotlin EncryptedSharedPreferences.
  /// Call after every BlacklistRepository write.
  Future<void> setBlacklistRules(String rulesJson) async {
    await _methodChannel.invokeMethod('setBlacklistRules', {'rulesJson': rulesJson});
  }

  /// Start or stop an agent. agentId: 'accessibility' | 'usage_guard' | 'screen_event' | 'wake_word'
  Future<void> toggleAgent(String agentId, bool enabled) async {
    await _methodChannel.invokeMethod('toggleAgent', {'agentId': agentId, 'enabled': enabled});
  }

  /// Returns current enabled status of all 4 agents.
  Future<Map<String, bool>> getAgentStatuses() async {
    final result = await _methodChannel.invokeMapMethod<String, bool>('getAgentStatuses');
    return result ?? {};
  }
}
