import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// The app icon over a large display title (and optional subtitle) — the
/// hero of the About and Upgrade screens, so both look the same.
class AppIconHero extends StatelessWidget {
  const AppIconHero({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  static const double iconSize = 84;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(RadiusTokens.hero),
          child: Image.asset('assets/icon/app_icon.png',
              width: iconSize, height: iconSize),
        ),
        const SizedBox(height: Spacing.xl),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: TypographyTokens.screenTitleSize,
            fontFamily: TypographyTokens.displayFamily,
            fontWeight: TypographyTokens.screenTitleWeight,
            color: AppColors.tp(context),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: AppColors.ts(context),
            ),
          ),
        ],
      ],
    );
  }
}
