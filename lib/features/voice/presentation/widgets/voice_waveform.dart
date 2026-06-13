import 'package:flutter/material.dart';

class VoiceWaveform extends StatelessWidget {
  final bool isListening;

  const VoiceWaveform({super.key, required this.isListening});

  @override
  Widget build(BuildContext context) {
    // For V1, we'll use a simple animated container placeholder if the Rive asset isn't present
    // or a pulsing mic icon. The design spec mentions "Rive waveform", so ideally we load 
    // an asset from assets/animations/voice_wave.riv, but since we don't have the asset downloaded 
    // yet, we'll use a simple flutter animation fallback.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isListening ? 80 : 60,
      height: isListening ? 80 : 60,
      decoration: BoxDecoration(
        color: isListening ? Colors.blue.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.mic,
          color: isListening ? Colors.blue : Colors.grey,
          size: isListening ? 40 : 30,
        ),
      ),
    );
  }
}
