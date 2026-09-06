import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class VoiceWaveform extends StatelessWidget {
  final bool isListening;

  const VoiceWaveform({super.key, required this.isListening});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primaryColor = colors.domainVoice;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isListening ? 80 : 60,
      height: isListening ? 80 : 60,
      decoration: BoxDecoration(
        color: isListening ? primaryColor.withValues(alpha: 0.2) : colors.textSecondary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.mic,
          color: isListening ? primaryColor : colors.textSecondary,
          size: isListening ? 40 : 30,
        ),
      ),
    );
  }
}
