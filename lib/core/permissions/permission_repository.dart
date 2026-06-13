import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRepository {
  static const _platform = MethodChannel('kero_space/main_methods');

  Future<bool> hasAccessibilityService() async {
    try {
      final bool? isEnabled = await _platform.invokeMethod('checkAccessibility');
      return isEnabled ?? false;
    } catch (_) {
      return true; // Assume true if not implemented natively yet
    }
  }

  Future<bool> hasUsageStats() async {
    try {
      final bool? isEnabled = await _platform.invokeMethod('checkUsageStats');
      return isEnabled ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<bool> hasNotificationListener() async {
    try {
      final bool? isEnabled = await _platform.invokeMethod('checkNotificationListener');
      return isEnabled ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<bool> hasRecordAudio() async {
    return await Permission.microphone.isGranted;
  }

  Future<bool> hasBatteryOptimizationExemption() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  Future<void> requestRecordAudio() async {
    await Permission.microphone.request();
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _platform.invokeMethod('openAccessibilitySettings');
    } catch (_) {
      await openAppSettings();
    }
  }

  Future<void> openUsageStatsSettings() async {
    try {
      await _platform.invokeMethod('openUsageStatsSettings');
    } catch (_) {
      await openAppSettings();
    }
  }

  Future<void> openNotificationListenerSettings() async {
    try {
      await _platform.invokeMethod('openNotificationListenerSettings');
    } catch (_) {
      await openAppSettings();
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    await Permission.ignoreBatteryOptimizations.request();
  }
}
