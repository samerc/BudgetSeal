import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/accounts_provider.dart';
import '../../features/transactions/widgets/currency_sheet.dart';
import '../theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';

/// A read-only field that opens the currency picker sheet when tapped.
class CurrencyPickerField extends ConsumerWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final Color? textColor;

  /// Optional list of currency codes to show in "Recently Used".
  final List<String> recentCurrencies;

  /// Codes left out of the picker.
  final Set<String> exclude;

  const CurrencyPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.textColor,
    this.recentCurrencies = const [],
    this.exclude = const {},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get unique currencies from user's accounts
    final accounts = ref.watch(accountsProvider).value ?? [];
    final acctCurrencies = accounts.map((a) => a.currency).toSet().toList();
    final flag = kCurrencyFlags[value];
    final symbol = kCurrencySymbols[value];

    // Narrow fields (next to an amount) keep the code first: the symbol
    // goes, then the flag. Measured outside the InputDecorator (~80 px of
    // it is padding and the arrow).
    return LayoutBuilder(builder: (context, box) {
      final showFlag = flag != null && box.maxWidth >= 160;
      final showSymbol = symbol != null && box.maxWidth >= 200;
      return GestureDetector(
        onTap: () async {
          final result = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => CurrencySheet(
              current: value,
              recentCurrencies: recentCurrencies,
              accountCurrencies: acctCurrencies,
              exclude: exclude,
            ),
          );
          if (result != null) onChanged(result);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
                color:
                    textColor?.withValues(alpha: 0.6) ?? AppColors.ts(context)),
            // Fill, radius and padding come from the theme, as for every
            // other input.
            fillColor:
                textColor != null ? Colors.white.withValues(alpha: 0.07) : null,
            suffixIcon: Icon(AppIcons.caretDown,
                color:
                    textColor?.withValues(alpha: 0.5) ?? AppColors.th(context)),
          ),
          child: Row(
            children: [
              if (showFlag) ...[
                Text(flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value,
                  // Same text as a TextField's value.
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: textColor ?? AppColors.tp(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showSymbol) ...[
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
    });
  }
}
