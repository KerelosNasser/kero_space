import 'package:flutter/material.dart';
import 'shimmer_primitives.dart';

class HealthSkeleton extends StatelessWidget {
  const HealthSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const ShimmerCircle(diameter: 200),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ShimmerBox(width: 80, height: 80),
              ShimmerBox(width: 80, height: 80),
              ShimmerBox(width: 80, height: 80),
            ],
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: ShimmerLine(width: 120),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    const ShimmerBox(width: 48, height: 48, borderRadius: 8),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerLine(width: 150),
                        SizedBox(height: 8),
                        ShimmerLine(width: 80),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
