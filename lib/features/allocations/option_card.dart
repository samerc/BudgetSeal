import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/tappable.dart';

/// One single-choice option: icon, title, description and a radio mark.
/// Selected = accent fill with an accent border. Used for the envelope type
/// (new envelope) and the leftover choices (period transition, leftover
/// resolution).
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RadiusTokens.md);
    final fg = selected ? AppColors.accentText(context) : AppColors.ts(context);
    return Tappable(
      onTap: onTap,
      borderRadius: radius,
      color: selected ? AppColors.accentLight : AppColors.sfv(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.tp(context)
                          : AppColors.ts(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: TypographyTokens.captionSize,
                      height: 1.35,
                      color: AppColors.ts(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? AppIcons.radioButtonFill : AppIcons.circle,
              size: 20,
              color: selected ? AppColors.accent : AppColors.th(context),
            ),
          ],
        ),
      ),
    );
  }
}
