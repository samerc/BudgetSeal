import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// PocketPlan logo widget — used in splash, dashboard header, and onboarding.
/// Currently renders as a styled text + icon mark; replace with SVG asset when available.
class PocketPlanLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final Color? color;

  const PocketPlanLogo({
    super.key,
    this.size = 40,
    this.showTagline = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                size: size, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              'PocketPlan',
              style: TextStyle(
                fontSize: size * 0.7,
                fontWeight: FontWeight.w800,
                color: logoColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Your money, your plan.',
            style: TextStyle(
              fontSize: size * 0.28,
              color: logoColor.withValues(alpha: 0.75),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
