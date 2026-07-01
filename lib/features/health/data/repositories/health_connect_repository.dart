import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:kero_space/core/data/isar_service.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'dart:io';

@lazySingleton
class HealthConnectRepository {
  final Health _health = Health();
  
  // Define the types to track
  final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
  ];

  Future<bool> hasPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final permissions = [HealthDataAccess.READ, HealthDataAccess.READ, HealthDataAccess.READ];
    try {
      return await _health.hasPermissions(_types, permissions: permissions) ?? false;
    } catch (e) {
      debugPrint("Error checking health permissions: $e");
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final granted = await hasPermissions();
    if (granted) return true;

    final permissions = [HealthDataAccess.READ, HealthDataAccess.READ, HealthDataAccess.READ];
    try {
      return await _health.requestAuthorization(_types, permissions: permissions);
    } catch (e) {
      debugPrint("Error requesting health permissions: $e");
      return false;
    }
  }

  Future<void> syncBiometrics(DateTime startTime, DateTime endTime, {bool isBackground = false, List<HealthDataType>? specificTypes}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    
    final typesToFetch = specificTypes ?? _types;
    final permissions = List.filled(typesToFetch.length, HealthDataAccess.READ);
    bool hasPermissions = await _health.hasPermissions(typesToFetch, permissions: permissions) ?? false;
    
    if (!hasPermissions) {
      if (isBackground) {
        // Do not pop up permission dialogs in the background isolate!
        debugPrint("Aborting background sync: Health permissions not granted.");
        return;
      } else {
        hasPermissions = await requestPermissions();
        if (!hasPermissions) return;
      }
    }

    try {
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: endTime,
        types: typesToFetch,
      );

      final isar = IsarService.instance;

      List<HealthRecord> recordsToSave = [];
      List<String> stringTypesToDelete = [];

      for (var t in typesToFetch) {
        if (t == HealthDataType.STEPS) stringTypesToDelete.add('STEPS');
        if (t == HealthDataType.HEART_RATE) stringTypesToDelete.add('HEART_RATE');
        if (t == HealthDataType.SLEEP_SESSION) stringTypesToDelete.add('SLEEP');
      }

      for (var dataPoint in healthData) {
        // Prepare string type mapping
        String typeString = '';
        double value = 0.0;

        if (dataPoint.type == HealthDataType.STEPS) {
          typeString = 'STEPS';
          value = (dataPoint.value as NumericHealthValue).numericValue.toDouble();
        } else if (dataPoint.type == HealthDataType.HEART_RATE) {
          typeString = 'HEART_RATE';
          value = (dataPoint.value as NumericHealthValue).numericValue.toDouble();
        } else if (dataPoint.type == HealthDataType.SLEEP_SESSION) {
          typeString = 'SLEEP';
          // Store duration in minutes
          value = dataPoint.dateTo.difference(dataPoint.dateFrom).inMinutes.toDouble();
        }

        if (typeString.isNotEmpty) {
          recordsToSave.add(
            HealthRecord()
              ..deviceId = 'local'
              ..platform = 'Android'
              ..type = typeString
              ..value = value
              ..timestamp = dataPoint.dateFrom
          );
        }
      }

      if (recordsToSave.isNotEmpty) {
        await isar.writeTxn(() async {
          // Prevent duplication by deleting overlapping records of the synced types
          for (var type in stringTypesToDelete) {
            await isar.healthRecords
                .where()
                .typeEqualTo(type)
                .filter()
                .timestampBetween(startTime, endTime)
                .deleteAll();
          }
          
          await isar.healthRecords.putAll(recordsToSave);
        });
        debugPrint("Synced ${recordsToSave.length} health records to Isar.");
      }
    } catch (e) {
      debugPrint("Error syncing health data: $e");
    }
  }
}
