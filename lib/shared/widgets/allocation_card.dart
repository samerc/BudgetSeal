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
  });

  Color get _typeColor => switch (type) {
        'saving' => AppColors.accent,
        'flexible' => AppColors.caution,
        _ => AppColors.accent,
      };

  bool get _isSaving => type == 'saving';
  bool get _isSavingWithGoal => _isSaving && targetAmount != null && targetAmount! > 0;

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
    } else if (_isSaving) {
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
    // Overspent if any currency balance is negative
    final isOverspent = balanceByCurrency.values.any((v) => v < -0.01);

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
    } else if (isOverspent) {
      borderColor = AppColors.overspent.withValues(alpha: 0.5);
    } else if (_isSavingWithGoal && targetCcyBalance >= targetAmount!) {
      borderColor = AppColors.healthy.withValues(alpha: 0.35);
    } else if (hasTarget && targetCcyBalance > 0 && targetCcyBalance < targetAmount! * 0.1) {
      borderColor = AppColors.caution.withValues(alpha: 0.45);
    } else if (hasTarget && targetCcyBalance >= targetAmount!) {
      borderColor = AppColors.healthy.withValues(alpha: 0.35);
    } else {
      borderColor = AppColors.bd(context);
    }

    // Icon for savings envelopes when no category icon
    final IconData savingsIcon = _isSavingWithGoal
        ? Icons.track_changes_rounded
        : Icons.savings_rounded;

    return Container(
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
                    if (_isSavingWithGoal && progress != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: AppColors.bd(context),
                          color: progress >= 1.0
                              ? AppColors.healthy
                              : AppColors.accent,
                        ),
                      ),
                    ]
                    // For spending envelopes: show standard progress bar
                    else if (!_isSaving && hasTarget && progress != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: AppColors.bd(context),
                          color: isOverspent
                              ? AppColors.overspent
                              : progress >= 1.0
                                  ? AppColors.healthy
                                  : _typeColor,
                        ),
                      ),
                    ],
                    // For savings-open: no progress bar at all
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Balance — show in base currency only
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOverspent)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.warning_amber_rounded,
                              size: 14, color: AppColors.overspent),
                        ),
                      if (_isSaving && !isOverspent)
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
                          color: isOverspent
                              ? AppColors.overspent
                              : AppColors.tp(context),
                        ),
                      ),
                    ],
                  ),
                  if (_isSavingWithGoal) ...[
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
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                  ] else if (hasTarget && !_isSaving)
                    Text(
                      '/ ${formatAmount(targetAmount!, currency: effectiveTargetCurrency)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                ],
              ),
              // Spend button (only for non-savings)
              if (onSpend != null && !_isSaving) ...[
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
    );
  }
}
