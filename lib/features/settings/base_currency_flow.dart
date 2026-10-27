import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/base_currency_change.dart';
import '../../core/fx/fx_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/services/household_members.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/calculator_amount_field.dart';

/// Settings › Base currency, after a new currency [to] was picked. With
/// nothing recorded yet it just switches; otherwise it asks for the rate
/// that converts the history ([changeBaseCurrency]). On a shared budget the
/// change syncs to the other phones like any edit.
Future<void> changeBaseCurrencyFlow(
    BuildContext context, WidgetRef ref, Household household, String to) async {
  final tr = S.of(context);
  final db = ref.read(databaseProvider);
  final messenger = ScaffoldMessenger.of(context);
  final from = household.baseCurrency;
  void snack(String text) => messenger.showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  try {
    final anyTx = await (db.selectOnly(db.transactions)
          ..addColumns([db.transactions.id])
          ..where(db.transactions.householdId.equals(household.id))
          ..limit(1))
        .getSingleOrNull();
    final shared = await HouseholdMembers.hasOthers(db, household.id);

    double? rate; // 1 [from] = rate [to]
    if (anyTx != null) {
      try {
        rate = await ref.read(fxServiceProvider).getRateWithCache(from, to);
      } catch (_) {
        rate = await latestCachedRate(db, from, to);
      }
      if (rate != null && rate <= 0) rate = null;
      // Ask until confirmed; "Change rate" closes the dialog for the
      // calculator (a sheet opened from a dialog crashes) and comes back.
      while (true) {
        if (!context.mounted) return;
        final r = rate;
        // Shown the way round that reads as a number above 1.
        final inverted = r != null && r < 1;
        final shown = r == null ? null : (inverted ? 1 / r : r);
        final (a, b) = inverted ? (to, from) : (from, to);
        final answer = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr.baseChangeTitle(to)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr.baseChangeBody(to),
                    style: TextStyle(fontSize: 14, color: AppColors.ts(ctx))),
                if (shared) ...[
                  const SizedBox(height: 8),
                  Text(tr.baseChangeSharedNote,
                      style:
                          TextStyle(fontSize: 14, color: AppColors.ts(ctx))),
                ],
                const SizedBox(height: 12),
                if (shown != null)
                  Text(
                    tr.quickRateLine(a, formatNumber(roundRate(shown),
                        decimals: shown >= 100 ? 0 : (shown >= 1 ? 2 : 6)), b),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  )
                else
                  Text(tr.baseChangeNoRate,
                      style: const TextStyle(color: AppColors.caution)),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'rate'),
                    icon: const Icon(AppIcons.pencilSimple, size: 18),
                    label: Text(tr.baseChangeEditRate),
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                style: DialogButtons.outlined,
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr.commonCancel),
              ),
              FilledButton(
                style: DialogButtons.filled,
                onPressed:
                    r == null ? null : () => Navigator.pop(ctx, 'change'),
                child: Text(tr.commonChange),
              ),
            ],
          ),
        );
        if (answer == null) return;
        if (answer == 'change') break;
        if (!context.mounted) return;
        final typed = await showCalculatorSheet(context, shown ?? 0,
            title: tr.baseChangeRateSheet(a, b));
        if (typed != null && typed > 0) rate = inverted ? 1 / typed : typed;
      }
      await changeBaseCurrency(db, household.id, from, to, rate!);
    } else {
      await changeBaseCurrency(db, household.id, from, to, 1);
    }
    snack(tr.baseCurrencySaved(to));
  } catch (e) {
    debugPrint('[Settings] Change base currency failed: $e');
    snack(tr.commonSomethingWentWrong);
  }
}
