import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/features/productivity/presentation/widgets/device_lockout_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DeviceLockoutSheet renders presets and dispatches startDeviceLockout', (tester) async {
    final List<MethodCall> methodCalls = [];

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('kero_space/methods'),
      (call) async {
        methodCalls.add(call);
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: DeviceLockoutSheet(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Warning
    expect(find.text('Keep Me Out'), findsOneWidget);
    expect(find.text('Full Phone Lockout & Screen Sleep'), findsOneWidget);
    expect(find.textContaining('This turns your screen off immediately'), findsOneWidget);

    // Verify Presets
    expect(find.text('15m'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '30m'), findsOneWidget);
    expect(find.text('1h'), findsOneWidget);

    // Tap 45m preset
    await tester.tap(find.text('45m'));
    await tester.pumpAndSettle();

    expect(find.text('45m'), findsWidgets);

    // Tap Lock Button
    await tester.tap(find.text('Lock Phone & Turn Off Screen'));
    await tester.pump();

    // Verify method channel call
    expect(methodCalls.any((c) => c.method == 'startDeviceLockout' && c.arguments['durationMinutes'] == 45), true);
  });
}
