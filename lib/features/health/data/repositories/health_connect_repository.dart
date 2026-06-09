import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:kero_space/core/data/isar_service.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:flutter/foundation.dart';
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

  Future<bool> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];
    
    try {
      bool hasPermissions = await _health.hasPermissions(_types, permissions: permissions) ?? false;
      if (!hasPermissions) {
        hasPermissions = await _health.requestAuthorization(_types, permissions: permissions);
      }
      return hasPermissions;
    } catch (e) {
      debugPrint("Error requesting health permissions: $e");
      return false;
    }
  }

  Future<void> syncBiometrics(DateTime startTime, DateTime endTime) async {
    if (kIsWeb || !Platform.isAndroid) return;
    
    bool hasPermissions = await requestPermissions();
    if (!hasPermissions) return;

    try {
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: endTime,
        types: _types,
      );

      final isar = IsarService.instance;

      List<HealthRecord> recordsToSave = [];

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
          await isar.healthRecords.putAll(recordsToSave);
        });
        debugPrint("Synced ${recordsToSave.length} health records to Isar.");
      }
    } catch (e) {
      debugPrint("Error syncing health data: $e");
    }
  }
}
