import 'package:flutter/material.dart';
import 'shimmer_primitives.dart';

class FinanceSkeleton extends StatelessWidget {
  const FinanceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: double.infinity, height: 160, borderRadius: 16),
          const SizedBox(height: 32),
          const ShimmerLine(width: 100),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: ShimmerBox(width: double.infinity, height: 80)),
              SizedBox(width: 16),
              Expanded(child: ShimmerBox(width: double.infinity, height: 80)),
            ],
          ),
          const SizedBox(height: 32),
          const ShimmerLine(width: 120),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLine(width: 150),
                        SizedBox(height: 8),
                        ShimmerLine(width: 80),
                      ],
                    ),
                    ShimmerLine(width: 60),
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
