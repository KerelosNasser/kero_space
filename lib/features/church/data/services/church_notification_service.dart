import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class ChurchNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _churchChannel = AndroidNotificationDetails(
    'church_channel',
    'Church Reminders',
    channelDescription: 'Reminders for confession and mass attendance',
    importance: Importance.max,
    priority: Priority.high,
  );

  static const _channelDetails =
      NotificationDetails(android: _churchChannel);

  Future<void> init() async {
    tz_data.initializeTimeZones();
    const initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initDarwin = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initDarwin,
    );
    await _plugin.initialize(settings: initSettings);
  }

  /// Schedule a reminder every Sunday at 7 AM for mass.
  Future<void> scheduleSundayReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    // Find next Sunday
    final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    final nextSunday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilSunday,
      7, // 7 AM
      0,
    );

    await _plugin.zonedSchedule(
      id: 10,
      title: 'Sunday Liturgy',
      body: 'Blessed Sunday — don\'t miss the Divine Liturgy today.',
      scheduledDate: nextSunday,
      notificationDetails: _channelDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Schedule a reminder on Wednesday and Friday mornings for fasting.
  Future<void> scheduleFastingReminder() async {
    final now = tz.TZDateTime.now(tz.local);

    for (final weekday in [DateTime.wednesday, DateTime.friday]) {
      final daysUntil = (weekday - now.weekday + 7) % 7;
      final nextDay = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + daysUntil,
        7, // 7 AM
        0,
      );
      await _plugin.zonedSchedule(
        id: 20 + weekday,
        title: 'Fasting Day',
        body: weekday == DateTime.wednesday
            ? 'Wednesday fast — fish is allowed today.'
            : 'Friday fast — fish is allowed today.',
        scheduledDate: nextDay,
        notificationDetails: _channelDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> scheduleMonthlyConfessionReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month + 1, 1, 10, 0);

    await _plugin.zonedSchedule(
      id: 1,
      title: 'Confession Reminder',
      body: 'Time for your monthly confession.',
      scheduledDate: scheduledDate,
      notificationDetails: _channelDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> triggerMissedConfessionReminder() async {
    const urgentChannel = AndroidNotificationDetails(
      'church_channel_urgent',
      'Urgent Church Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      id: 2,
      title: 'Confession Missed',
      body:
          'It has been 14 days since your last log. Return to your spiritual routine.',
      notificationDetails:
          const NotificationDetails(android: urgentChannel),
    );
  }
}
