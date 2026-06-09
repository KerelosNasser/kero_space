import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/productivity_collections.dart';

class LocalCalendarRepository {
  static const _channel = MethodChannel('kero_space/calendar');

  Future<List<CalendarEvent>> getLocalEvents() async {
    try {
      final status = await Permission.calendarFullAccess.request();
      if (!status.isGranted) {
        final readOnlyStatus = await Permission.calendarReadOnly.request();
        if (!readOnlyStatus.isGranted) {
            debugPrint('Calendar permission denied by user.');
            return [];
        }
      }

      final String result = await _channel.invokeMethod('getEvents');
      final List<dynamic> jsonList = jsonDecode(result);
      
      return jsonList.map((json) {
        return CalendarEvent()
          ..deviceId = 'local'
          ..platform = 'android'
          ..title = json['title']
          ..startTime = DateTime.fromMillisecondsSinceEpoch(json['startTime'])
          ..endTime = DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          ..source = 'SAMSUNG'
          ..allDay = json['allDay'];
      }).toList();
    } catch (e) {
      debugPrint('Failed to get local events: $e');
      return [];
    }
  }
}
