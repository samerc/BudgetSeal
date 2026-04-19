import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/format_number.dart';
import 'category_icon.dart';

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
  @override
  Widget build(BuildContext context) {
    final effectiveTargetCurrency = targetCurrency ?? baseCurrency;
    final mainBalance = balanceByCurrency[effectiveTargetCurrency] ?? 0.0;
    final otherBalances = Map.of(balanceByCurrency)
      ..remove(effectiveTargetCurrency);
    final hasTarget = targetAmount != null && targetAmount! > 0;
    final progress =
        hasTarget ? (mainBalance / targetAmount!).clamp(0.0, 1.0) : null;
    final isOverspent = mainBalance < 0;

    final bool hasCategoryIcon = categoryName != null;
    final Color iconColor = categoryColorHex != null
        ? Color(int.parse('FF${categoryColorHex!.replaceAll('#', '')}', radix: 16))
        : _typeColor;

    // Determine urgency border color
    final Color borderColor;
    if (isOverspent) {
      borderColor = AppColors.overspent.withValues(alpha: 0.5);
    } else if (_isSavingWithGoal && mainBalance >= targetAmount!) {
      borderColor = AppColors.healthy.withValues(alpha: 0.35);
    } else if (hasTarget && mainBalance > 0 && mainBalance < targetAmount! * 0.1) {
      borderColor = AppColors.caution.withValues(alpha: 0.45);
    } else if (hasTarget && mainBalance >= targetAmount!) {
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
              // Icon: envelope emoji > category icon > savings icon > default
              () {
                // Envelope's own icon takes priority
                if (envelopeIcon != null && envelopeIcon!.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(envelopeIcon!,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                }
                if (hasCategoryIcon) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CategoryIcon(
                      categoryName: categoryName!,
                      emoji: categoryIcon,
                      color: iconColor,
                      size: 36,
                    ),
                  );
                }
                if (_isSaving) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(savingsIcon,
                          size: 20, color: AppColors.accent),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }(),
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
              // Balance
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
                        formatAmount(mainBalance, currency: effectiveTargetCurrency),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isOverspent
                              ? AppColors.overspent
                              : AppColors.tp(context),
                        ),
                      ),
                      // Show other currency balances with context
                      for (final entry in otherBalances.entries)
                        if (entry.value.abs() > 0.001)
                          Text(
                            entry.value > 0
                                ? ' + ${formatAmount(entry.value, currency: entry.key)}'
                                : ' · ${formatAmount(entry.value.abs(), currency: entry.key)} spent',
                            style: TextStyle(
                              fontSize: 10,
                              color: entry.value > 0
                                  ? AppColors.ts(context)
                                  : AppColors.overspent,
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
