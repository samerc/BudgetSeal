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
      // Theme-aware sweep — a fixed near-white flashed in dark mode.
      highlightColor: AppColors.isDark
          ? AppColors.lightenPastel(AppColors.sfv(context), 0.08)
          : AppColors.lightenPastel(AppColors.sfv(context), 0.6),
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

/// A row-shaped skeleton (Cashew "ghost transaction"): icon circle plus a
/// title bar, a shorter subtitle bar and an amount bar.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SkeletonLoader(height: 44, width: 44, borderRadius: 22),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                    widthFactor: 0.6,
                    child: SkeletonLoader(height: 14, borderRadius: 7)),
                SizedBox(height: 8),
                FractionallySizedBox(
                    widthFactor: 0.35,
                    child: SkeletonLoader(height: 11, borderRadius: 6)),
              ],
            ),
          ),
          SizedBox(width: 14),
          SkeletonLoader(height: 16, width: 64, borderRadius: 8),
        ],
      ),
    );
  }
}

/// Multiple skeleton cards for list loading.
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 6});

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
