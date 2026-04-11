import 'package:flutter/material.dart';

import '../../features/transactions/widgets/currency_sheet.dart';
import '../theme/app_colors.dart';

/// A read-only field that opens the currency picker sheet when tapped.
class CurrencyPickerField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final Color? textColor;

  const CurrencyPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CurrencySheet(current: value),
        );
        if (result != null) onChanged(result);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: textColor?.withValues(alpha: 0.6) ??
                  AppColors.textSecondary),
          filled: true,
          fillColor: textColor != null
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: Icon(Icons.expand_more_rounded,
              color: textColor?.withValues(alpha: 0.5) ??
                  AppColors.textHint),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: textColor ?? AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
