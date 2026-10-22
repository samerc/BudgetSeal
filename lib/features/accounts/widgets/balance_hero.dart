import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/tappable.dart';

/// Cashew's wallet header: the one look for a balance / net worth hero
/// (Home's net worth, the Accounts total, an account's balance, the Reports
/// balance sheet). Pastel accent fill, hero radius, no shadow.
class BalanceHero extends StatelessWidget {
  const BalanceHero({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RadiusTokens.hero);
    final fill = AppColors.pastel(context, AppColors.accent,
        light: 0.82, dark: 0.75);
    final content = Padding(padding: padding, child: child);
    if (onTap == null) {
      return DecoratedBox(
        decoration: BoxDecoration(color: fill, borderRadius: radius),
        child: content,
      );
    }
    return Tappable(
      onTap: onTap,
      borderRadius: radius,
      color: fill,
      child: content,
    );
  }
}

/// The label above a hero amount ("Net worth", "Current balance").
TextStyle balanceHeroLabelStyle(BuildContext context) => TextStyle(
      fontSize: TypographyTokens.bodySize,
      fontWeight: FontWeight.w600,
      color: AppColors.ts(context),
    );

/// A hero amount: display face, w800. Negative balances turn red (status).
TextStyle balanceHeroAmountStyle(BuildContext context,
        {double? value, double size = TypographyTokens.amountLargeSize}) =>
    TextStyle(
      fontSize: size,
      fontFamily: TypographyTokens.displayFamily,
      fontWeight: FontWeight.w800,
      color: (value ?? 0) < 0 ? AppColors.overspent : AppColors.tp(context),
    );
