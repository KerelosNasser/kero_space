import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/presentation/widgets/overview_tab.dart';
import 'package:kero_space/features/finance/presentation/widgets/subscriptions_tab.dart';

void main() {
  test('OverviewTab and SubscriptionsTab widgets can be defined', () {
    expect(OverviewTab, isNotNull);
    expect(SubscriptionsTab, isNotNull);
  });
}
