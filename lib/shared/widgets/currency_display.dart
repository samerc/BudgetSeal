import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/format_number.dart';

/// Shows native amount large, base currency equivalent small below it.
class CurrencyDisplay extends StatelessWidget {
  final double amount;
  final String currency;
  final double? baseAmount;
  final String? baseCurrency;
  final TextStyle? amountStyle;

  const CurrencyDisplay({
    super.key,
    required this.amount,
    required this.currency,
    this.baseAmount,
    this.baseCurrency,
    this.amountStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatAmount(amount, currency: currency),
          style: amountStyle ??
              Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (baseAmount != null && baseCurrency != null && baseCurrency != currency)
          Text(
            '≈ ${formatAmount(baseAmount!, currency: baseCurrency)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}
