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
  screenChannel.receiveBroadcastStream().listen(
    (event) async {
      if (!IsarService.isInitialized) return;
      try {
        final data = jsonDecode(event as String) as Map<String, dynamic>;
        final type = data['type'] as String;
        final timestampMs = data['timestamp'] as int;
        final screenEvent = ScreenEvent()
          ..deviceId = 'android'
          ..platform = 'android'
          ..eventType = type
          ..timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
        await IsarService.instance.writeTxn(
          () => IsarService.instance.screenEvents.put(screenEvent),
        );
        debugPrint('KeroSpace BG: ScreenEvent written — $type');
      } catch (e) {
        debugPrint('KeroSpace BG: Error writing ScreenEvent: $e');
      }
    },
    onError: (e) => debugPrint('KeroSpace BG: screenChannel error: $e'),
  );

  const EventChannel accessChannel = EventChannel('kero_space/accessibility');
  accessChannel.receiveBroadcastStream().listen(
    (event) async {
      if (!IsarService.isInitialized) return;
      try {
        final raw = event as String;
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final type = data['type'] as String;
        final timestampMs = data['timestamp'] as int;
        if (type == 'CLICK') {
          final clickEvent = TelemetryEvent()
            ..deviceId = 'android'
            ..platform = 'android'
            ..name = 'click'
            ..dataJson = raw
            ..timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
          await IsarService.instance.writeTxn(
            () => IsarService.instance.telemetryEvents.put(clickEvent),
          );
          debugPrint('KeroSpace BG: Click TelemetryEvent written');
        }
      } catch (e) {
        debugPrint('KeroSpace BG: Error writing AccessibilityEvent: $e');
      }
    },
    onError: (e) => debugPrint('KeroSpace BG: accessChannel error: $e'),
  );

  const EventChannel wakeWordChannel = EventChannel('kero_space/wake_word');
  wakeWordChannel.receiveBroadcastStream().listen(
    (event) => debugPrint('KeroSpace BG: Wake Word Event: $event'),
    onError: (e) => debugPrint('KeroSpace BG: wakeWordChannel error: $e'),
  );

  const EventChannel usageChannel = EventChannel('kero_space/usage_stats');
  usageChannel.receiveBroadcastStream().listen(
    (event) async {
      if (!IsarService.isInitialized) return;
      try {
        final list = jsonDecode(event as String) as List<dynamic>;
        final today = DateTime.now().toLocal();
        final todayDate = DateTime(today.year, today.month, today.day);
        await IsarService.instance.writeTxn(() async {
          for (final item in list) {
            final packageName = item['packageName'] as String;
            final foregroundMs = item['foregroundTimeMs'] as int;
            final existing = await IsarService.instance.appUsageRecords
                .filter()
                .packageNameEqualTo(packageName)
                .dateEqualTo(todayDate)
                .findFirst();
            if (existing != null) {
              existing.foregroundMs = foregroundMs;
              await IsarService.instance.appUsageRecords.put(existing);
            } else {
              await IsarService.instance.appUsageRecords.put(
                AppUsageRecord()
                  ..deviceId = 'android'
                  ..platform = 'android'
                  ..packageName = packageName
                  ..foregroundMs = foregroundMs
                  ..date = todayDate,
              );
            }
          }
        });
        debugPrint('KeroSpace BG: Wrote ${list.length} AppUsageRecords to Isar');
      } catch (e) {
        debugPrint('KeroSpace BG: Error writing UsageStats: $e');
      }
    },
    onError: (e) => debugPrint('KeroSpace BG: usageChannel error: $e'),
  );
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
