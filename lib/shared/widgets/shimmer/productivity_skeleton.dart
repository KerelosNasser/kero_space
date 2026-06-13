import 'package:flutter/material.dart';
import 'shimmer_primitives.dart';

class ProductivitySkeleton extends StatelessWidget {
  const ProductivitySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLine(width: 150),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    ShimmerCircle(diameter: 24),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLine(width: double.infinity),
                          SizedBox(height: 8),
                          ShimmerBox(width: 60, height: 24, borderRadius: 12),
                        ],
                      ),
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
