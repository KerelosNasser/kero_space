import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kero_space/features/settings/presentation/screens/voice_assistant_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'voice_wake_word_enabled': true,
      'voice_wake_sensitivity': 0.85,
      'voice_screen_off_wake': true,
      'voice_profile_enrolled': true,
      'voice_profile_samples': 3,
      'voice_profile_date': '2026-09-05T12:00:00Z',
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('kero_space/main_methods'),
      (MethodCall call) async {
        switch (call.method) {
          case 'checkDefaultAssistant':
            return true;
          case 'getVoiceProfileStatus':
            return <String, dynamic>{
              'isEnrolled': true,
              'samplesCount': 3,
              'enrolledAt': 1700000000000,
              'phrase': 'Hey Trobio',
            };
          default:
            return true;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('kero_space/main_methods'),
      null,
    );
  });

  testWidgets('VoiceAssistantSettingsScreen renders options and cards correctly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: VoiceAssistantSettingsScreen(),
      ),
    );

    // Initial pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Voice Assistant & Wake Word'), findsOneWidget);
    expect(find.text('Default Digital Assistant'), findsOneWidget);
    expect(find.text('Voice Match (Enrollment)'), findsOneWidget);
    expect(find.text('Wake Word Settings'), findsOneWidget);
    expect(find.text('Test Assistant Trigger'), findsOneWidget);
  });
}
