import 'package:flutter/material.dart';
import 'shimmer_primitives.dart';

class TelemetrySkeleton extends StatelessWidget {
  const TelemetrySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLine(width: 200),
          const SizedBox(height: 24),
          const ShimmerBox(width: double.infinity, height: 200, borderRadius: 12),
          const SizedBox(height: 32),
          const ShimmerLine(width: 120),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: ShimmerBox(width: double.infinity, height: 100)),
              SizedBox(width: 16),
              Expanded(child: ShimmerBox(width: double.infinity, height: 100)),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerBox(width: double.infinity, height: 100),
        ],
      ),
    );
  }
}
