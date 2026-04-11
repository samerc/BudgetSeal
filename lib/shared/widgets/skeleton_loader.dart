import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';


/// A shimmer skeleton placeholder for loading states.
class SkeletonLoader extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.sfv(context),
      highlightColor: Colors.grey.shade50,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A card-shaped skeleton for lists.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: SkeletonLoader(height: 72),
    );
  }
}

/// Multiple skeleton cards for list loading.
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(count, (_) => const SkeletonCard()),
      ),
    );
  }
}
