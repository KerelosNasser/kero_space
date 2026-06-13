import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Entrypoint for the headless FlutterEngine spawned by Android.
@pragma('vm:entry-point')
void backgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("KeroSpace: Background Isolate Started.");

  // TODO: Initialize Isar and DI here.
  // For now, listen to the channels.

  const EventChannel screenChannel = EventChannel('kero_space/screen_events');
  screenChannel.receiveBroadcastStream().listen((event) {
    debugPrint("KeroSpace Background: Received Screen Event: $event");
    // Write to Isar
  });

  const EventChannel accessChannel = EventChannel('kero_space/accessibility');
  accessChannel.receiveBroadcastStream().listen((event) {
    debugPrint("KeroSpace Background: Received Accessibility Event: $event");
    // Handle scrolling blocker logic
  });

  const EventChannel wakeWordChannel = EventChannel('kero_space/wake_word');
  wakeWordChannel.receiveBroadcastStream().listen((event) {
    debugPrint("KeroSpace Background: Received Wake Word Event: $event");
    // Handle wake word
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
