import 'package:flutter/material.dart';

import '../../features/transactions/widgets/currency_sheet.dart';
import '../theme/app_colors.dart';

/// A read-only field that opens the currency picker sheet when tapped.
class CurrencyPickerField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final Color? textColor;

  /// Optional list of currency codes to show in "Recently Used".
  final List<String> recentCurrencies;

  const CurrencyPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.textColor,
    this.recentCurrencies = const [],
  });

  @override
  Widget build(BuildContext context) {
    final flag = kCurrencyFlags[value];
    final symbol = kCurrencySymbols[value];

    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CurrencySheet(
            current: value,
            recentCurrencies: recentCurrencies,
          ),
        );
        if (result != null) onChanged(result);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: textColor?.withValues(alpha: 0.6) ??
                  AppColors.ts(context)),
          filled: true,
          fillColor: textColor != null
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.sfv(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: Icon(Icons.expand_more_rounded,
              color: textColor?.withValues(alpha: 0.5) ??
                  AppColors.th(context)),
        ),
        child: Row(
          children: [
            if (flag != null) ...[
              Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: textColor ?? AppColors.tp(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (symbol != null) ...[
              const SizedBox(width: 4),
              Text(
                symbol,
                style: TextStyle(
                  color: (textColor ?? AppColors.tp(context))
                      .withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
