import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'tappable.dart';

/// Standardized card container used across all screens.
///
/// Uses the design token values: radius 16, padding 16h/14v, an
/// accent-tinted surface and a soft shadow in light mode (Cashew style —
/// no border except a faint edge in the black theme). Tappable cards get a
/// platform-aware ripple.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.sf(context),
      borderRadius: CardTokens.borderRadius,
      border: AppColors.cardBorder(context) == Colors.transparent
          ? null
          : Border.all(color: AppColors.cardBorder(context)),
      boxShadow: AppColors.cardShadow(context),
    );

    final content = Padding(
      padding: padding ?? CardTokens.padding,
      child: child,
    );

    Widget card;
    if (onTap != null || onLongPress != null) {
      card = DecoratedBox(
        decoration: decoration,
        child: ClipRRect(
          borderRadius: CardTokens.borderRadius,
          child: Tappable(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: CardTokens.borderRadius,
            child: content,
          ),
        ),
      );
    } else {
      card = DecoratedBox(
        decoration: decoration,
        child: content,
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: card);
    }
    return card;
  }
}
