import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/daos/ledger_dao.dart';
import '../../core/engine/period_engine.dart' show budgetPeriodFor;
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';

const _dismissedKey = 'period_summary_dismissed';

/// First week of a new budget period: how the last one went (funded vs
/// spent, base currency) with a shortcut to fund the new one. Dismissable
/// per period.
class PeriodSummaryCard extends ConsumerStatefulWidget {
  const PeriodSummaryCard({super.key});

  @override
  ConsumerState<PeriodSummaryCard> createState() => _PeriodSummaryCardState();
}

class _PeriodSummaryCardState extends ConsumerState<PeriodSummaryCard> {
  ({double funded, double spent, String currency, String periodKey})? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final household = ref.read(householdProvider).value;
      if (household == null) return;
      final current = budgetPeriodFor(household.periodStartDay);
      // Only during the first week of the period.
      if (DateTime.now().difference(current.start).inDays >= 7) return;
      final key = current.start.toIso8601String().substring(0, 10);
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_dismissedKey) == key) return;
      final last = budgetPeriodFor(household.periodStartDay,
          current.start.subtract(const Duration(days: 1)));
      final dao = LedgerDao(ref.read(databaseProvider));
      final base = household.baseCurrency;
      double sum(Map<String, Map<String, double>> m) =>
          m.values.fold(0.0, (t, byCur) => t + (byCur[base] ?? 0));
      final funded =
          sum(await dao.fundedInPeriod(household.id, last.start, last.end));
      final spent = sum(await dao
          .watchSpendingInPeriod(household.id, last.start, last.end)
          .first);
      if (funded <= 0 && spent <= 0) return; // nothing to report
      if (mounted) {
        setState(() => _data =
            (funded: funded, spent: spent, currency: base, periodKey: key));
      }
    } catch (e) {
      debugPrint('[PeriodSummary] Error loading: $e');
    }
  }

  Future<void> _dismiss() async {
    final key = _data?.periodKey;
    setState(() => _data = null);
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedKey, key);
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (d == null) return const SizedBox.shrink();
    final tr = S.of(context);
    final left = d.funded - d.spent;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_repeat_rounded,
                  size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr.periodSummaryTitle,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.th(context)),
                onPressed: _dismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr.periodSummaryBody(
              formatAmount(d.spent, currency: d.currency),
              formatAmount(d.funded, currency: d.currency),
            ),
            style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
          ),
          if (left.abs() >= 0.01)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                left > 0
                    ? tr.periodSummaryUnder(
                        formatAmount(left, currency: d.currency))
                    : tr.periodSummaryOver(
                        formatAmount(-left, currency: d.currency)),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: left > 0 ? AppColors.healthy : AppColors.overspent),
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => context.push('/funding'),
              child: Text(tr.periodSummaryFund),
            ),
          ),
        ],
      ),
    );
  }
}
