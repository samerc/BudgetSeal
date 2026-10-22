import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_icons.dart';

/// ‹ Month › — the one month/period navigator (Reports tabs, Export report).
/// [onNext] null = the current month: the arrow hides but keeps its space.
class MonthNav extends StatelessWidget {
  const MonthNav({
    super.key,
    required this.label,
    required this.onPrev,
    this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(AppIcons.caretLeft),
          onPressed: onPrev,
          color: AppColors.ts(context),
        ),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.tp(context),
            ),
          ),
        ),
        // No future months: hidden (but keeps its space) on the current one.
        Visibility(
          visible: onNext != null,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: IconButton(
            icon: const Icon(AppIcons.caretRight),
            onPressed: onNext,
            color: AppColors.ts(context),
          ),
        ),
      ],
    );
  }
}
