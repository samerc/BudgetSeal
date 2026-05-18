import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/format_number.dart';
import 'animated_circular_progress.dart';

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

  /// Optional linked-category info for displaying a category icon.
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColorHex;

  /// Whether this envelope needs manual period review (amber glow).
  final bool needsReview;

  /// Optional period boundaries for daily allowance calculation.
  final DateTime? periodStart;
  final DateTime? periodEnd;

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
    this.needsReview = false,
    this.categoryName,
    this.categoryIcon,
    this.categoryColorHex,
    this.periodStart,
    this.periodEnd,
  });

  /// Normalize: legacy 'saving' type is treated as 'flexible'
  String get _effectiveType => type == 'saving' ? 'flexible' : type;

  Color get _typeColor => switch (_effectiveType) {
        'flexible' => AppColors.accent,
        _ => AppColors.accent,
      };

  bool get _isFlexible => _effectiveType == 'flexible';
  bool get _isFlexibleWithGoal => _isFlexible && targetAmount != null && targetAmount! > 0;

  Widget _buildIcon(BuildContext context, bool hasTarget, double? rawProgress,
      bool isOverspent, bool hasCategoryIcon, Color iconColor, IconData savingsIcon) {
    // Determine the inner content — always render something
    Widget inner;
    if (envelopeIcon != null && envelopeIcon!.isNotEmpty) {
      inner = Text(envelopeIcon!, style: const TextStyle(fontSize: 18));
    } else if (hasCategoryIcon && categoryIcon != null &&
        categoryIcon!.isNotEmpty && categoryIcon != 'category') {
      // Show the category emoji directly (not wrapped in CategoryIcon)
      inner = Text(categoryIcon!, style: const TextStyle(fontSize: 18));
    } else if (_isFlexible) {
      inner = Icon(savingsIcon, size: 18, color: AppColors.accent);
    } else {
      // Fallback: first letter of name
      inner = Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _typeColor,
        ),
      );
    }

    // Wrap in circular progress ring when there's a target
    if (hasTarget && rawProgress != null) {
      final ringColor = isOverspent
          ? AppColors.overspent
          : rawProgress >= 1.0
              ? AppColors.healthy
              : _typeColor;
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: AnimatedCircularProgress(
          progress: rawProgress,
          color: ringColor,
          overspendColor: AppColors.overspent,
          trackColor: AppColors.bd(context),
          strokeWidth: 3,
          size: 40,
          child: inner,
        ),
      );
    }

    // No target — show icon in a consistent rounded container
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _typeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: inner),
      ),
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
    // Legacy compatibility: either condition counts as "overspent" for border
    final isOverspent = isTargetOverspent;

    final bool hasCategoryIcon = categoryName != null;
    Color parsedColor = _typeColor;
    if (categoryColorHex != null) {
      try {
        parsedColor = Color(
            int.parse('FF${categoryColorHex!.replaceAll('#', '')}', radix: 16));
      } catch (_) {
        // Invalid hex string — keep fallback color
      }
    }
    final Color iconColor = parsedColor;

    // Determine urgency border color
    final Color borderColor;
    if (needsReview) {
      borderColor = AppColors.caution.withValues(alpha: 0.6);
    } else if (isTargetOverspent) {
      borderColor = AppColors.overspent.withValues(alpha: 0.5);
    } else if (hasCrossDebt) {
      borderColor = AppColors.caution.withValues(alpha: 0.5);
    } else if (_isFlexibleWithGoal && targetCcyBalance >= targetAmount!) {
      borderColor = AppColors.healthy.withValues(alpha: 0.35);
    } else if (hasTarget && targetCcyBalance > 0 && targetCcyBalance < targetAmount! * 0.1) {
      borderColor = AppColors.caution.withValues(alpha: 0.45);
    } else if (hasTarget && targetCcyBalance >= targetAmount!) {
      borderColor = AppColors.healthy.withValues(alpha: 0.35);
    } else {
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
      semanticParts.add('$pct% of ${formatAmount(targetAmount!, currency: effectiveTargetCurrency)}');
    }
    if (_isFlexible) semanticParts.add('flexible envelope');
    if (needsReview) semanticParts.add('needs review');

    return Semantics(
      label: semanticParts.join(', '),
      button: onTap != null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Icon: with circular progress ring when target exists
              _buildIcon(context, hasTarget, rawProgress, isOverspent,
                  hasCategoryIcon, iconColor, savingsIcon),
              // Name + progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.tp(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    // For savings with goal: show progress bar
                    if (_isFlexibleWithGoal && progress != null) ...[
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: val,
                            minHeight: 4,
                            backgroundColor: AppColors.bd(context),
                            color: progress >= 1.0
                                ? AppColors.healthy
                                : AppColors.accent,
                          ),
                        ),
                      ),
                    ]
                    // For spending envelopes: show standard progress bar
                    else if (!_isFlexible && hasTarget && progress != null) ...[
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: val,
                            minHeight: 4,
                            backgroundColor: AppColors.bd(context),
                            color: isTargetOverspent
                                ? AppColors.overspent
                                : progress >= 1.0
                                    ? AppColors.healthy
                                    : _typeColor,
                          ),
                        ),
                      ),
                    ],
                    // Daily allowance (Cashew-style) for spending envelopes
                    if (!_isFlexible && hasTarget && displayBalance > 0 &&
                        periodStart != null && periodEnd != null) ...[
                      () {
                        final now = DateTime.now();
                        final daysLeft = periodEnd!.difference(now).inDays;
                        if (daysLeft > 0) {
                          final daily = displayBalance / daysLeft;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${formatAmount(daily, currency: displayCurrency)}/day for $daysLeft days',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.ts(context),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }(),
                    ],
                    // For savings-open: no progress bar at all
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Balance — target currency + cross-currency debt
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTargetOverspent)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.warning_amber_rounded,
                              size: 14, color: AppColors.overspent),
                        ),
                      if (_isFlexible && !isTargetOverspent)
                        Text(
                          'Saved: ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ts(context),
                          ),
                        ),
                      Text(
                        formatAmount(displayBalance, currency: displayCurrency),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isTargetOverspent
                              ? AppColors.overspent
                              : AppColors.tp(context),
                        ),
                      ),
                    ],
                  ),
                  if (_isFlexibleWithGoal) ...[
                    Text(
                      '${(progress! * 100).round()}% saved',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: progress >= 1.0
                              ? AppColors.healthy
                              : AppColors.accent),
                    ),
                    Text(
                      '/ ${formatAmount(targetAmount!, currency: effectiveTargetCurrency)}',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.th(context)),
                    ),
                  ] else if (hasTarget && !_isFlexible)
                    Text(
                      '/ ${formatAmount(targetAmount!, currency: effectiveTargetCurrency)}',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.th(context)),
                    ),
                  // Cross-currency debt: show amber dot indicator (details on detail screen)
                  if (hasCrossDebt)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.caution,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${crossCurrencyDebt.length} other ${crossCurrencyDebt.length == 1 ? 'currency' : 'currencies'}',
                            style: TextStyle(fontSize: 9, color: AppColors.caution),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              // Spend button (only for non-savings)
              if (onSpend != null && !_isFlexible) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSpend,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.shopping_cart_outlined,
                        size: 16, color: _typeColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ));
  }
}
