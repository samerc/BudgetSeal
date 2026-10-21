import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A reusable empty-state placeholder used across all screens.
///
/// Cashew NoResults style: icon in a pastel circle, bold title, optional
/// subtitle and a filled action button — all themed via [AppColors].
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cashew NoResults: the icon sits in a large pastel circle.
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.pastel(context, AppColors.accent,
                    light: 0.82, dark: 0.75),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.accent),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: AppColors.ts(context),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              // The screen's main call to action: the theme's filled button.
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
