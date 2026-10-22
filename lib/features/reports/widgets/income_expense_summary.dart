import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/tx_colors_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/animated_amount.dart';

/// Income / Expenses / Net for a period — the one layout shared by Home's
/// spending card and Reports > Overview. Amounts use the user's income and
/// expense colors (Settings); a zero amount stays neutral.
class IncomeExpenseSummary extends ConsumerWidget {
  const IncomeExpenseSummary({
    super.key,
    required this.income,
    required this.expense,
    required this.currency,
  });

  final double income;
  final double expense;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final colors = ref.watch(txColorsProvider);
    final net = income - expense;
    Color tone(double v, Color c) => v == 0 ? AppColors.ts(context) : c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(context, s.typeIncome, income, tone(income, colors.income),
            income > 0 ? '+' : null),
        const SizedBox(height: Spacing.sm),
        _row(context, s.dashboardLabelExpenses, expense,
            tone(expense, colors.expense), expense > 0 ? '-' : null),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Divider(height: 1, color: AppColors.bd(context)),
        ),
        _row(
            context,
            s.dashboardLabelNet,
            net.abs(),
            tone(net, net > 0 ? colors.income : colors.expense),
            net > 0 ? '+' : (net < 0 ? '-' : null),
            bold: true),
      ],
    );
  }

  Widget _row(BuildContext context, String label, double amount, Color color,
      String? prefix,
      {bool bold = false}) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: TypographyTokens.amountSmallSize,
                color: AppColors.ts(context))),
        const SizedBox(width: 6),
        // Narrow phones / large text: the amount shrinks instead of
        // running past the card edge.
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedAmount(
                  amount: amount,
                  currency: currency,
                  prefix: prefix,
                  style: TextStyle(
                      fontSize: bold
                          ? TypographyTokens.amountDisplaySize
                          : TypographyTokens.amountRegularSize,
                      fontWeight: bold
                          ? TypographyTokens.amountDisplayWeight
                          : TypographyTokens.amountRegularWeight,
                      color: color)),
            ),
          ),
        ),
      ],
    );
  }
}
