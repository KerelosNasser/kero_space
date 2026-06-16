import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/services/finance_notification_service.dart';

void main() {
  test('FinanceNotificationService exposes trigger function', () {
    final service = FinanceNotificationService();
    expect(service.triggerRenewalNotification, isNotNull);
  });
}
