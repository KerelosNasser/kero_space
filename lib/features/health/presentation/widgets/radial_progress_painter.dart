import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class PremiumCalorieRing extends StatelessWidget {
  final double value;
  final int current;
  final int target;

  const PremiumCalorieRing({
    super.key,
    required this.value,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = value.clamp(0.0, 1.0);
    final bool isOver = value > 1.0;

    return SizedBox(
      height: 180,
      width: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: RadialProgressPainter(
              progress: progress,
              color: isOver ? AppTheme.accentRose : AppTheme.accentMint,
              trackColor: AppTheme.bgElevated,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$current',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'of $target kcal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (isOver) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${current - target} kcal',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentRose,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}

class RadialProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  RadialProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 8;
    const strokeWidth = 12.0;

    // 1. Draw track
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw active progress arc
    if (progress > 0) {
      final activePaint = Paint()
        ..shader = SweepGradient(
          colors: [
            color.withValues(alpha: 0.5),
            color,
            color,
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: const GradientRotation(-pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        activePaint,
      );

      // Glow overlay
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RadialProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
