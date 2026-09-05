import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/features/voice/data/services/voice_enrollment_service.dart';

class VoiceAssistantSettingsScreen extends StatefulWidget {
  const VoiceAssistantSettingsScreen({super.key});

  @override
  State<VoiceAssistantSettingsScreen> createState() => _VoiceAssistantSettingsScreenState();
}

class _VoiceAssistantSettingsScreenState extends State<VoiceAssistantSettingsScreen>
    with SingleTickerProviderStateMixin {
  final VoiceEnrollmentService _service = VoiceEnrollmentService();

  bool _isLoading = true;
  bool _isDefaultAssistant = false;
  VoiceProfileStatus _profileStatus = const VoiceProfileStatus(isEnrolled: false, samplesCount: 0);
  bool _wakeWordEnabled = true;
  double _sensitivity = 0.85;
  bool _screenOffWake = true;

  // Training state
  bool _isTraining = false;
  int _trainingStep = 0; // 0, 1, 2
  bool _isRecordingSample = false;
  double _audioLevel = 0.0;
  Timer? _waveformTimer;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loadState();
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    final isDefault = await _service.isDefaultAssistant();
    final profile = await _service.getProfileStatus();
    final wakeEnabled = await _service.isWakeWordEnabled();
    final sens = await _service.getSensitivity();
    final screenWake = await _service.isScreenOffWakeEnabled();

    if (mounted) {
      setState(() {
        _isDefaultAssistant = isDefault;
        _profileStatus = profile;
        _wakeWordEnabled = wakeEnabled;
        _sensitivity = sens;
        _screenOffWake = screenWake;
        _isLoading = false;
      });
    }
  }

  void _startSampleRecording() {
    setState(() {
      _isRecordingSample = true;
      _audioLevel = 0.1;
    });

    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted) {
        setState(() {
          _audioLevel = 0.2 + (math.Random().nextDouble() * 0.7);
        });
      }
    });

    // Simulate sample capture duration (2 seconds)
    Future.delayed(const Duration(milliseconds: 2200), () async {
      _waveformTimer?.cancel();
      if (!mounted) return;

      HapticFeedback.mediumImpact();
      if (_trainingStep < 2) {
        setState(() {
          _isRecordingSample = false;
          _trainingStep++;
          _audioLevel = 0.0;
        });
      } else {
        // Complete training
        await _service.saveVoiceProfile(samplesCount: 3);
        final updated = await _service.getProfileStatus();
        if (mounted) {
          setState(() {
            _isRecordingSample = false;
            _isTraining = false;
            _trainingStep = 0;
            _audioLevel = 0.0;
            _profileStatus = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice Match training completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant & Wake Word'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadState,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildAssistantCard(colors),
                  const SizedBox(height: 16),
                  _buildVoiceMatchCard(colors),
                  const SizedBox(height: 16),
                  _buildWakeWordPreferences(colors),
                  const SizedBox(height: 16),
                  _buildLiveTestCard(colors),
                ],
              ),
            ),
    );
  }

  Widget _buildAssistantCard(AppColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDefaultAssistant
              ? colors.accentPrimary.withValues(alpha: 0.4)
              : colors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.accentPrimary, colors.accentSecondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assistant_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Default Digital Assistant',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gemini / Bixby System Integration',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDefaultAssistant
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDefaultAssistant ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Text(
                  _isDefaultAssistant ? 'DEFAULT' : 'NOT SET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isDefaultAssistant ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'When Trobio is selected as your default digital assistant app in Android settings, you can summon it instantly via corner swipe, long-pressing the power button, or over the lock screen without OS restrictions.',
            style: TextStyle(fontSize: 13, height: 1.4, color: colors.textPrimary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await _service.openAssistantSettings();
                await Future.delayed(const Duration(seconds: 1));
                _loadState();
              },
              icon: const Icon(Icons.settings_suggest_rounded, size: 18),
              label: Text(
                _isDefaultAssistant
                    ? 'Manage Android Assistant Settings'
                    : 'Set Trobio as Default Assistant',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMatchCard(AppColorScheme colors) {
    final isEnrolled = _profileStatus.isEnrolled;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accentSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.record_voice_over_rounded, color: colors.accentSecondary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voice Match (Enrollment)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Personalized "Hey Trobio" Training',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isTraining) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isEnrolled ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: isEnrolled ? Colors.green : colors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEnrolled ? 'Voice Model Active' : 'No Voice Model Enrolled',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          isEnrolled
                              ? 'Trained with ${_profileStatus.samplesCount} audio samples'
                              : 'Teach Trobio your voice to awaken the app when you speak',
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        _isTraining = true;
                        _trainingStep = 0;
                        _isRecordingSample = false;
                      });
                    },
                    icon: Icon(isEnrolled ? Icons.refresh_rounded : Icons.mic_rounded, size: 18),
                    label: Text(
                      isEnrolled ? 'Retrain Voice' : 'Train Voice Model',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (isEnrolled) ...[
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    tooltip: 'Delete Voice Profile',
                    onPressed: () async {
                      await _service.clearVoiceProfile();
                      _loadState();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ],
              ],
            ),
          ] else ...[
            // Interactive 3-step Training Wizard
            _buildTrainingWizard(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildTrainingWizard(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sample ${_trainingStep + 1} of 3',
                style: TextStyle(fontWeight: FontWeight.w700, color: colors.accentPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _waveformTimer?.cancel();
                  setState(() => _isTraining = false);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_trainingStep + (_isRecordingSample ? 0.5 : 0.0)) / 3.0,
              backgroundColor: colors.borderSubtle,
              valueColor: AlwaysStoppedAnimation(colors.accentPrimary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Say clearly into microphone:',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            '"Hey Trobio"',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          // Audio waveform animation
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(18, (index) {
                final height = _isRecordingSample
                    ? math.max(6.0, 48.0 * (math.sin((index + 1) * 0.5 + _audioLevel * 4).abs()))
                    : 6.0;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 70),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 4,
                  height: height,
                  decoration: BoxDecoration(
                    color: _isRecordingSample
                        ? colors.accentPrimary
                        : colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          if (!_isRecordingSample)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _startSampleRecording,
              icon: const Icon(Icons.mic, size: 18),
              label: Text('Record Sample ${_trainingStep + 1}'),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
                ),
                const SizedBox(width: 10),
                const Text('Listening...', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWakeWordPreferences(AppColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wake Word Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Listen for "Hey Trobio"', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Keeps low-power on-device listener active'),
            value: _wakeWordEnabled,
            onChanged: (val) async {
              setState(() => _wakeWordEnabled = val);
              await _service.setWakeWordEnabled(val);
            },
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Awaken Screen from Lock', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Bypasses keyguard and lights up display when wake word is heard'),
            value: _screenOffWake,
            onChanged: (val) async {
              setState(() => _screenOffWake = val);
              await _service.setScreenOffWakeEnabled(val);
            },
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Detection Sensitivity', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                _sensitivity > 0.88 ? 'High' : (_sensitivity > 0.75 ? 'Balanced' : 'Strict'),
                style: TextStyle(fontWeight: FontWeight.w700, color: colors.accentPrimary),
              ),
            ],
          ),
          Slider(
            value: _sensitivity,
            min: 0.60,
            max: 0.95,
            divisions: 7,
            label: '${(_sensitivity * 100).toInt()}%',
            onChanged: (val) async {
              setState(() => _sensitivity = val);
              await _service.setSensitivity(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTestCard(AppColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Assistant Trigger',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Simulate hearing "Hey Trobio" to verify bottom sheet overlay and VoiceBloc response.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                HapticFeedback.heavyImpact();
                await _service.testWakeWordTrigger();
              },
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text(
                'Test Trigger ("Hey Trobio")',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
