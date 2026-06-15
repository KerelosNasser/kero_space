import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kero_space/core/app_theme.dart';

class DeepWorkTimerWidget extends StatefulWidget {
  final VoidCallback onStartDeepWork;

  const DeepWorkTimerWidget({super.key, required this.onStartDeepWork});

  @override
  State<DeepWorkTimerWidget> createState() => _DeepWorkTimerWidgetState();
}

class _DeepWorkTimerWidgetState extends State<DeepWorkTimerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _isActive = false;
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isActive = true;
      _remainingSeconds = 25 * 60; // 25 mins
    });
    
    widget.onStartDeepWork();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remainingSeconds = 0;
    });
  }

  String get _timeString {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isActive ? null : _startTimer,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isActive ? _pulseAnimation.value : 1.0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: _isActive 
                    ? [AppTheme.accentViolet.withValues(alpha: 0.8), AppTheme.accentRose.withValues(alpha: 0.8)]
                    : [Theme.of(context).cardColor, Theme.of(context).cardColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: _isActive ? [
                  BoxShadow(
                    color: AppTheme.accentViolet.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isActive ? "Deep Work Active" : "Start Deep Work",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isActive ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isActive ? "Strict app blocking enabled." : "25 min focus block",
                        style: TextStyle(
                          fontSize: 14,
                          color: _isActive ? Colors.white70 : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (_isActive)
                    Text(
                      _timeString,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.play_circle_fill, size: 36, color: AppTheme.accentViolet),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
