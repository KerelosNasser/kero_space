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
    final colors = context.appColors;
    return Shimmer.fromColors(
      baseColor: colors.bgElevated,
      highlightColor: colors.borderSubtle.withValues(alpha: 0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.bgElevated,
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
    final colors = context.appColors;
    return Shimmer.fromColors(
      baseColor: colors.bgElevated,
      highlightColor: colors.borderSubtle.withValues(alpha: 0.5),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: colors.bgElevated,
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
