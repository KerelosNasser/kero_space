import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FinanceNotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> triggerRenewalNotification(String name, double amount) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'finance_renewals_channel',
      'Finance Renewals',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id: 999,
      title: 'Subscription Renewed',
      body: 'Subscription $name automatically logged: -$amount EGP.',
      notificationDetails: platformDetails,
    );
  }

  Future<void> triggerSalaryNotification(String source, double amount) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'finance_salary_channel',
      'Finance Salary',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id: 888,
      title: 'Monthly Salary Logged',
      body: 'Monthly salary automatically logged: +$amount EGP into $source.',
      notificationDetails: platformDetails,
    );
  }
}
