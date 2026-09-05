import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceProfileStatus {
  final bool isEnrolled;
  final int samplesCount;
  final DateTime? enrolledAt;
  final String phrase;

  const VoiceProfileStatus({
    required this.isEnrolled,
    required this.samplesCount,
    this.enrolledAt,
    this.phrase = 'Hey Trobio',
  });
}

class VoiceEnrollmentService {
  static const MethodChannel _platform = MethodChannel('kero_space/main_methods');

  static const String _prefWakeWordEnabled = 'voice_wake_word_enabled';
  static const String _prefSensitivity = 'voice_wake_sensitivity';
  static const String _prefScreenOffWake = 'voice_screen_off_wake';

  Future<bool> isDefaultAssistant() async {
    try {
      final bool? isDefault = await _platform.invokeMethod('checkDefaultAssistant');
      return isDefault ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openAssistantSettings() async {
    try {
      await _platform.invokeMethod('openAssistantSettings');
    } catch (_) {}
  }

  Future<void> testWakeWordTrigger() async {
    try {
      await _platform.invokeMethod('testWakeWord');
    } catch (_) {}
  }

  Future<VoiceProfileStatus> getProfileStatus() async {
    try {
      final result = await _platform.invokeMapMethod<String, dynamic>('getVoiceProfileStatus');
      if (result != null) {
        final isEnrolled = result['isEnrolled'] as bool? ?? false;
        final count = result['samplesCount'] as int? ?? 0;
        final ts = result['enrolledAt'] as int? ?? 0;
        return VoiceProfileStatus(
          isEnrolled: isEnrolled,
          samplesCount: count,
          enrolledAt: ts > 0 ? DateTime.fromMillisecondsSinceEpoch(ts) : null,
          phrase: result['phrase'] as String? ?? 'Hey Trobio',
        );
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final isEnrolled = prefs.getBool('voice_profile_enrolled') ?? false;
    return VoiceProfileStatus(
      isEnrolled: isEnrolled,
      samplesCount: isEnrolled ? 3 : 0,
      enrolledAt: isEnrolled ? DateTime.now() : null,
    );
  }

  Future<bool> saveVoiceProfile({required int samplesCount}) async {
    try {
      await _platform.invokeMethod('saveVoiceProfile', {'samplesCount': samplesCount});
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_profile_enrolled', true);
    await prefs.setInt('voice_profile_samples', samplesCount);
    await prefs.setString('voice_profile_date', DateTime.now().toIso8601String());
    return true;
  }

  Future<void> clearVoiceProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('voice_profile_enrolled');
    await prefs.remove('voice_profile_samples');
    await prefs.remove('voice_profile_date');
    try {
      await _platform.invokeMethod('saveVoiceProfile', {'samplesCount': 0});
    } catch (_) {}
  }

  Future<bool> isWakeWordEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefWakeWordEnabled) ?? true;
  }

  Future<void> setWakeWordEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefWakeWordEnabled, enabled);
  }

  Future<double> getSensitivity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_prefSensitivity) ?? 0.85;
  }

  Future<void> setSensitivity(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefSensitivity, value);
  }

  Future<bool> isScreenOffWakeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefScreenOffWake) ?? true;
  }

  Future<void> setScreenOffWakeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefScreenOffWake, enabled);
  }
}
