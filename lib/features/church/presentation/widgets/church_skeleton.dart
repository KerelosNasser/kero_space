import 'package:flutter/material.dart';
import '../../../../shared/widgets/shimmer/shimmer_primitives.dart';

class ChurchSkeleton extends StatelessWidget {
  const ChurchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card skeleton
          const ShimmerBox(width: double.infinity, height: 96, borderRadius: 24),
          const SizedBox(height: 16),
          // Feast card skeleton
          const ShimmerBox(width: double.infinity, height: 72, borderRadius: 16),
          const SizedBox(height: 16),
          // Readings card skeleton
          const ShimmerBox(width: double.infinity, height: 140, borderRadius: 16),
          const SizedBox(height: 16),
          // Upcoming feasts title
          const ShimmerLine(width: 140),
          const SizedBox(height: 12),
          // Upcoming feasts horizontal list
          Row(
            children: [
              const ShimmerBox(width: 130, height: 100, borderRadius: 16),
              const SizedBox(width: 12),
              const ShimmerBox(width: 130, height: 100, borderRadius: 16),
              const SizedBox(width: 12),
              const ShimmerBox(width: 130, height: 100, borderRadius: 16),
            ],
          ),
        ],
      ),
    );
  }
}
