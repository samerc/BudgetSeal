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

  @override
  Widget build(BuildContext context) {
    final mainCurrency = balanceByCurrency.keys.firstOrNull ?? baseCurrency;
    final mainBalance = balanceByCurrency[mainCurrency] ?? 0.0;
    final hasTarget = targetAmount != null && targetAmount! > 0;
    final progress =
        hasTarget ? (mainBalance / targetAmount!).clamp(0.0, 1.0) : null;
    final isOverspent = mainBalance < 0;

    final bool hasCategoryIcon = categoryName != null;
    final Color iconColor = categoryColorHex != null
        ? Color(int.parse('FF${categoryColorHex!.replaceAll('#', '')}', radix: 16))
        : _typeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Category icon (if linked)
              if (hasCategoryIcon) ...[
                CategoryIcon(
                  categoryName: categoryName!,
                  emoji: categoryIcon,
                  color: iconColor,
                  size: 36,
                ),
                const SizedBox(width: 10),
              ],
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
                    if (hasTarget && progress != null) ...[
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatAmount(mainBalance, currency: mainCurrency),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isOverspent
                          ? AppColors.overspent
                          : AppColors.tp(context),
                    ),
                  ),
                  if (hasTarget)
                    Text(
                      '/ ${formatAmount(targetAmount!)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                    ),
                ],
              ),
              // Spend button
              if (onSpend != null) ...[
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
