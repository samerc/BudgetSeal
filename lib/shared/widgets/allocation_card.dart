import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/format_number.dart';
import '../theme/design_tokens.dart';
import 'budget_progress.dart';

class AllocationCard extends StatelessWidget {
  final String name;
  final String type;
  final String periodicity;
  final Map<String, double> balanceByCurrency;
  final String baseCurrency;
  final double? targetAmount;
  final String? targetCurrency;
  final String? envelopeIcon; // emoji icon set on the envelope itself
  final VoidCallback? onTap;
  final VoidCallback? onSpend;

  /// Shown instead of the spend button while the envelope is overspent:
  /// move money in to bring it back to zero.
  final VoidCallback? onCover;

  /// Optional linked-category info for displaying a category icon.
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColorHex;

  /// Whether this envelope needs manual period review (amber glow).
  final bool needsReview;

  /// Optional period boundaries for daily allowance calculation.
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// Planned expense amount committed to this envelope (not yet posted).
  final double? plannedAmount;

  /// Currency of the planned amount (defaults to targetCurrency or baseCurrency).
  final String? plannedCurrency;

  const AllocationCard({
    super.key,
    required this.name,
    required this.type,
    required this.periodicity,
    required this.balanceByCurrency,
    required this.baseCurrency,
    this.targetAmount,
    this.targetCurrency,
    this.envelopeIcon,
    this.onTap,
    this.onSpend,
    this.onCover,
    this.needsReview = false,
    this.categoryName,
    this.categoryIcon,
    this.categoryColorHex,
    this.periodStart,
    this.periodEnd,
    this.plannedAmount,
    this.plannedCurrency,
  });

  /// Normalize: legacy 'saving' type is treated as 'flexible'
  String get _effectiveType => type == 'saving' ? 'flexible' : type;

  Color get _typeColor => switch (_effectiveType) {
        'flexible' => AppColors.accent,
        _ => AppColors.accent,
      };

  bool get _isFlexible => _effectiveType == 'flexible';
  bool get _isFlexibleWithGoal => _isFlexible && targetAmount != null && targetAmount! > 0;

  Widget _buildIcon(BuildContext context, Color color, IconData savingsIcon) {
    final Widget inner;
    if (envelopeIcon != null && envelopeIcon!.isNotEmpty) {
      inner = Text(envelopeIcon!, style: const TextStyle(fontSize: 22));
    } else if (categoryIcon != null &&
        categoryIcon!.isNotEmpty &&
        categoryIcon != 'category') {
      inner = Text(categoryIcon!, style: const TextStyle(fontSize: 22));
    } else if (_isFlexible) {
      inner = Icon(savingsIcon,
          size: 22,
          color: AppColors.pastel(context, color,
              light: 0.5, dark: 0.5, inverse: true));
    } else {
      inner = Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.pastel(context, color,
              light: 0.5, dark: 0.5, inverse: true),
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.pastel(context, color, light: 0.55, dark: 0.45),
        shape: BoxShape.circle,
      ),
      child: Center(child: inner),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTargetCurrency = targetCurrency ?? baseCurrency;
    // Use target currency balance for display when envelope has a specific target currency
    final targetCcyBalance = balanceByCurrency[effectiveTargetCurrency] ?? 0.0;
    // Display currency: show in target currency if set, otherwise base
    final displayCurrency = effectiveTargetCurrency;
    final displayBalance = targetCcyBalance;
    final hasTarget = targetAmount != null && targetAmount! > 0;
    // Unclamped progress for the circular ring (allows overspend arc > 1.0)
    final rawProgress = hasTarget ? (targetCcyBalance / targetAmount!) : null;
    // Clamped progress for LinearProgressIndicator (must be 0.0–1.0)
    final progress = rawProgress?.clamp(0.0, 1.0);
    // Overspent: target currency balance is negative
    final isTargetOverspent = targetCcyBalance < -0.01;
    // Cross-currency balances: other currencies with non-zero balance
    final otherCurrencyBalances = <String, double>{};
    for (final entry in balanceByCurrency.entries) {
      if (entry.key != effectiveTargetCurrency && entry.value.abs() > 0.01) {
        otherCurrencyBalances[entry.key] = entry.value;
      }
    }
    final crossCurrencyDebt = Map.fromEntries(
        otherCurrencyBalances.entries.where((e) => e.value < -0.01));
    final hasCrossDebt = crossCurrencyDebt.isNotEmpty;
    final Color iconColor = categoryColorHex != null
        ? AppColors.fromHex(categoryColorHex!)
        : _typeColor;

    // Determine urgency border color
    final Color borderColor;
    if (needsReview) {
      borderColor = AppColors.caution.withValues(alpha: 0.6);
    } else if (isTargetOverspent) {
      borderColor = AppColors.overspent.withValues(alpha: 0.5);
    } else if (hasCrossDebt) {
      borderColor = AppColors.caution.withValues(alpha: 0.5);
    } else if (!_isFlexible && hasTarget && targetCcyBalance > 0 && targetCcyBalance < targetAmount! * 0.1) {
      borderColor = AppColors.caution.withValues(alpha: 0.45);
    } else {
      // Healthy/full cards stay borderless — the bar already says it.
      borderColor = AppColors.bd(context);
    }

    // Icon for savings envelopes when no category icon
    final IconData savingsIcon = _isFlexibleWithGoal
        ? Icons.track_changes_rounded
        : Icons.savings_rounded;

    // Build semantic label for screen readers
    final semanticParts = <String>[name];
    if (displayBalance != 0 || hasTarget) {
      semanticParts.add(formatAmount(displayBalance, currency: displayCurrency));
    }
    if (hasTarget) {
      final pct = progress != null ? (progress * 100).round() : 0;
      semanticParts.add(S.of(context).a11yPctOfTarget(
          pct, formatAmount(targetAmount!, currency: effectiveTargetCurrency)));
    }
    if (_isFlexible) semanticParts.add(S.of(context).a11yFlexibleEnvelope);
    if (needsReview) semanticParts.add(S.of(context).a11yNeedsReview);

    // Cashew budgetContainer: tinted with the envelope's own color.
    final cardColor =
        AppColors.pastel(context, iconColor, light: 0.88, dark: 0.8);
    final showBar = hasTarget && progress != null;
    // The bar shows what's LEFT, so the pace marker sits at the share that
    // should still be left today (1 − elapsed). Fill past it = on track.
    final elapsed = !_isFlexible
        ? BudgetProgress.fractionOfPeriod(periodStart, periodEnd)
        : null;
    final todayFraction = elapsed == null ? null : 1 - elapsed;

    String? subtitle;
    if (_isFlexibleWithGoal) {
      subtitle = S.of(context).allocPercentSaved((progress! * 100).round());
    } else if (hasTarget && !_isFlexible) {
      final parts = <String>[
        S.of(context).objOfTarget(
            formatAmount(targetAmount!, currency: effectiveTargetCurrency)),
      ];
      if (displayBalance > 0 && periodStart != null && periodEnd != null) {
        final daysLeft = periodEnd!.difference(DateTime.now()).inDays;
        if (daysLeft > 0) {
          parts.add(S.of(context).allocDailyBudget(
              formatAmount(displayBalance / daysLeft, currency: displayCurrency),
              daysLeft));
        }
      }
      subtitle = parts.join(' · ');
    }

    return Semantics(
      label: semanticParts.join(', '),
      button: onTap != null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(RadiusTokens.lg + 4),
          // Status signals keep a colored edge; healthy cards have none.
          border: borderColor == AppColors.bd(context)
              ? null
              : Border.all(color: borderColor, width: 1.5),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(RadiusTokens.lg + 4),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _buildIcon(context, iconColor, savingsIcon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.tp(context))),
                            if (subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.tp(context)
                                            .withValues(alpha: 0.6))),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isTargetOverspent)
                                const Padding(
                                  padding:
                                      EdgeInsetsDirectional.only(end: 4),
                                  child: Icon(Icons.warning_amber_rounded,
                                      size: 16, color: AppColors.overspent),
                                ),
                              Text(
                                formatAmount(displayBalance,
                                    currency: displayCurrency),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: TypographyTokens.displayFamily,
                                  fontWeight: FontWeight.w700,
                                  color: isTargetOverspent
                                      ? AppColors.overspent
                                      : AppColors.tp(context),
                                ),
                              ),
                            ],
                          ),
                          if (hasCrossDebt)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.caution,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    S.of(context).allocOtherCurrencies(
                                        crossCurrencyDebt.length),
                                    style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.caution),
                                  ),
                                ],
                              ),
                            ),
                          if (plannedAmount != null && plannedAmount! > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${formatAmount(plannedAmount!, currency: plannedCurrency ?? effectiveTargetCurrency)} ${S.of(context).plannedChipLabel}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tp(context)
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (onCover != null && isTargetOverspent) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: AppColors.overspent,
                          shape: const StadiumBorder(),
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: onCover,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              child: Text(S.of(context).allocCoverButton,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ] else if (onSpend != null && !_isFlexible) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: AppColors.pastel(context, iconColor,
                              light: 0.6, dark: 0.55),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onSpend,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.shopping_cart_outlined,
                                  size: 18, color: AppColors.tp(context)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (showBar) ...[
                    const SizedBox(height: 12),
                    BudgetProgress(
                      progress: rawProgress!,
                      color: iconColor,
                      height: 14,
                      todayFraction: todayFraction,
                      overspent: isTargetOverspent,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
