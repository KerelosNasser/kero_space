import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kero_space/features/voice/data/services/voice_enrollment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VoiceEnrollmentService service;
  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    SharedPreferences.setMockInitialValues({});
    service = VoiceEnrollmentService();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('kero_space/main_methods'),
      (MethodCall call) async {
        methodCalls.add(call);
        switch (call.method) {
          case 'checkDefaultAssistant':
            return true;
          case 'openAssistantSettings':
            return true;
          case 'testWakeWord':
            return true;
          case 'getVoiceProfileStatus':
            return <String, dynamic>{
              'isEnrolled': true,
              'samplesCount': 3,
              'enrolledAt': 1700000000000,
              'phrase': 'Hey Trobio',
            };
          case 'saveVoiceProfile':
            return true;
          default:
            return null;
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

  test('isDefaultAssistant queries platform method channel', () async {
    final isDefault = await service.isDefaultAssistant();
    expect(isDefault, isTrue);
    expect(methodCalls.any((c) => c.method == 'checkDefaultAssistant'), isTrue);
  });

  test('openAssistantSettings invokes platform method channel', () async {
    await service.openAssistantSettings();
    expect(methodCalls.any((c) => c.method == 'openAssistantSettings'), isTrue);
  });

  test('testWakeWordTrigger invokes platform method channel', () async {
    await service.testWakeWordTrigger();
    expect(methodCalls.any((c) => c.method == 'testWakeWord'), isTrue);
  });

  test('getProfileStatus maps platform response to VoiceProfileStatus model', () async {
    final status = await service.getProfileStatus();
    expect(status.isEnrolled, isTrue);
    expect(status.samplesCount, 3);
    expect(status.phrase, 'Hey Trobio');
    expect(status.enrolledAt, isNotNull);
  });

  test('preferences persist sensitivity and toggles', () async {
    await service.setWakeWordEnabled(false);
    expect(await service.isWakeWordEnabled(), isFalse);

    await service.setSensitivity(0.92);
    expect(await service.getSensitivity(), closeTo(0.92, 0.001));

    await service.setScreenOffWakeEnabled(true);
    expect(await service.isScreenOffWakeEnabled(), isTrue);
  });

  test('saveVoiceProfile invokes native channel with sample count', () async {
    await service.saveVoiceProfile(samplesCount: 3);
    final call = methodCalls.firstWhere((c) => c.method == 'saveVoiceProfile');
    expect(call.arguments['samplesCount'], 3);
  });
}
