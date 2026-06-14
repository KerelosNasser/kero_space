import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/app_theme.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.bgElevated,
      highlightColor: AppTheme.accentPrimary.withValues(alpha: 0.1),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.accentPrimary,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double diameter;

  const ShimmerCircle({super.key, required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.bgElevated,
      highlightColor: AppTheme.accentPrimary.withValues(alpha: 0.1),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: AppTheme.accentPrimary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  final double width;

  const ShimmerLine({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(width: width, height: 16, borderRadius: 4);
  }
}
