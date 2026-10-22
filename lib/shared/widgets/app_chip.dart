import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'tappable.dart';

/// The app's one choice/filter chip: a pill that is a pastel fill with a
/// colored border when selected, and a quiet surface-variant pill when not.
///
/// [color] tints the selected state (defaults to the accent) — e.g. the
/// expense/income color for a type filter.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    final fg = selected
        ? (color == null ? AppColors.accentText(context) : c)
        : AppColors.ts(context);
    final radius = BorderRadius.circular(RadiusTokens.pill);
    return Tappable(
      onTap: onTap,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (color == null
                  ? AppColors.accentLight
                  : AppColors.pastel(context, c))
              : AppColors.sfv(context),
          borderRadius: radius,
          border: Border.all(
            color: selected ? c : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
