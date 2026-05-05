import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// Standardized card container used across all screens.
///
/// Uses the design token values: radius 14, padding 16h/14v,
/// theme-aware background and border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.sf(context),
      borderRadius: CardTokens.borderRadius,
      border: Border.all(color: AppColors.bd(context)),
    );

    final content = Padding(
      padding: padding ?? CardTokens.padding,
      child: child,
    );

    Widget card = DecoratedBox(
      decoration: decoration,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: CardTokens.borderRadius,
                child: content,
              ),
            )
          : content,
    );

    if (onTap != null) {
      // Wrap with ClipRRect so ink splash respects radius
      card = ClipRRect(
        borderRadius: CardTokens.borderRadius,
        child: DecoratedBox(
          decoration: decoration,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: CardTokens.borderRadius,
              child: content,
            ),
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
