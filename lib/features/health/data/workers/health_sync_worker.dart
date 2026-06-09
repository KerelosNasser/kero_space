import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:health/health.dart';
import 'package:kero_space/features/health/data/repositories/health_connect_repository.dart';
import 'package:kero_space/core/data/isar_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      debugPrint("HealthSyncWorker executed task: $task");
      
      // We must initialize Isar because isolates do not share the main Isar instance
      final dir = await getApplicationDocumentsDirectory();
      await IsarService.init(dir.path);

      final healthRepo = HealthConnectRepository();
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      
      // 1. Sync Steps (Every 30 minutes)
      // Look back 1 hour just to cover overlaps
      await healthRepo.syncBiometrics(now.subtract(const Duration(hours: 1)), now, isBackground: true, specificTypes: [HealthDataType.STEPS]);
      
      // 2. Sync Heart Rate (Every 12 hours)
      final lastHrSyncStr = prefs.getString('last_hr_sync');
      DateTime? lastHrSync = lastHrSyncStr != null ? DateTime.tryParse(lastHrSyncStr) : null;
      
      if (lastHrSync == null || now.difference(lastHrSync).inHours >= 12) {
        debugPrint("Syncing Heart Rate (12h interval met)");
        // Fetch last 12 hours of heart rate
        await healthRepo.syncBiometrics(now.subtract(const Duration(hours: 12)), now, isBackground: true, specificTypes: [HealthDataType.HEART_RATE]);
        await prefs.setString('last_hr_sync', now.toIso8601String());
      }
      
      // 3. Sync Sleep (Every 24 hours)
      final lastSleepSyncStr = prefs.getString('last_sleep_sync');
      DateTime? lastSleepSync = lastSleepSyncStr != null ? DateTime.tryParse(lastSleepSyncStr) : null;
      
      if (lastSleepSync == null || now.difference(lastSleepSync).inHours >= 24) {
        debugPrint("Syncing Sleep (24h interval met)");
        // Fetch last 48 hours of sleep to ensure we don't miss overnight sessions
        await healthRepo.syncBiometrics(now.subtract(const Duration(hours: 48)), now, isBackground: true, specificTypes: [HealthDataType.SLEEP_SESSION]);
        await prefs.setString('last_sleep_sync', now.toIso8601String());
      }

      return true;
    } catch (e) {
      debugPrint("HealthSyncWorker failed: $e");
      return false;
    }
  });
}

class HealthSyncWorker {
  static const String _taskName = "healthSyncTask";

  static Future<void> initialize() async {
    if (kIsWeb || !Platform.isAndroid) return;
    
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> registerPeriodicTask() async {
    if (kIsWeb || !Platform.isAndroid) return;

    await Workmanager().registerPeriodicTask(
      "1",
      _taskName,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
      ),
    );
  }
}
