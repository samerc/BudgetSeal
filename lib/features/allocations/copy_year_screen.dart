import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/engine/planned_engine.dart';
import '../../core/engine/sinking_fund.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/sinking_fund_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/theme/app_icons.dart';
import 'sinking_fund_widgets.dart' show fundAmounts;

/// "Copy from last year": once the new schedule is decided, start it from
/// the past year's payments a year later — pick which, raise each currency
/// by a percentage, and save them as planned payments (still editable).
class CopyYearScreen extends ConsumerStatefulWidget {
  final String fundId;
  const CopyYearScreen({super.key, required this.fundId});

  @override
  ConsumerState<CopyYearScreen> createState() => _CopyYearScreenState();
}

class _CopyYearScreenState extends ConsumerState<CopyYearScreen> {
  final Map<String, double> _raise = {};
  final Set<int> _off = {};
  bool _initialized = false;
  bool _saving = false;

  double _raised(double v, String currency) {
    final r = v * (1 + (_raise[currency] ?? 0) / 100);
    final f = math.pow(10, currencyDecimals(currency));
    return (r * f).round() / f;
  }

  Future<void> _save(List<({FundPayment payment, bool alreadyPlanned})> rows,
      String? categoryId, List<Account> accountList) async {
    final tr = S.of(context);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    setState(() => _saving = true);
    var added = 0;
    try {
      final accounts = {for (final a in accountList) a.id: a};
      final engine = PlannedEngine(ref.read(databaseProvider));
      for (var i = 0; i < rows.length; i++) {
        if (_off.contains(i)) continue;
        final p = rows[i].payment;
        // One part per currency, from the account it came from last year
        // (or any live account in that currency).
        final parts = <PlanPart>[];
        for (final e in p.amounts.entries) {
          final acc = p.accountIds
                  .map((id) => accounts[id])
                  .whereType<Account>()
                  .where((a) => a.currency == e.key && !a.archived)
                  .firstOrNull ??
              accounts.values
                  .where((a) => a.currency == e.key && !a.archived)
                  .firstOrNull;
          if (acc == null) continue;
          parts.add(PlanPart(
              amount: _raised(e.value, e.key),
              currency: e.key,
              accountId: acc.id));
        }
        if (parts.isEmpty) continue;
        await engine.save(
          householdId: householdId,
          type: 'expense',
          accountId: parts.first.accountId,
          amount: parts.first.amount,
          currency: parts.first.currency,
          categoryId: categoryId,
          note: p.title,
          date: p.date,
          createdBy: 'user',
          deviceId: 'local',
          parts: parts,
        );
        added++;
      }
      if (!mounted) return;
      hapticMedium();
      final messenger = ScaffoldMessenger.maybeOf(context);
      context.pop();
      messenger?.showSnackBar(SnackBar(
        content: Text(tr.sinkCopied(added)),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      debugPrint('[CopyYear] save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr.plannedSaveFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final fund = ref.watch(sinkingFundsProvider).value?[widget.fundId];
    final category = (ref.watch(categoriesProvider).value ?? const <Category>[])
        .where((c) => c.allocationId == widget.fundId)
        .firstOrNull;
    final rows = fund == null
        ? const <({FundPayment payment, bool alreadyPlanned})>[]
        : copyFromLastYear(fund.history);
    if (!_initialized && fund != null) {
      _initialized = true;
      for (var i = 0; i < rows.length; i++) {
        if (rows[i].alreadyPlanned) _off.add(i);
      }
    }
    final currencies = {for (final r in rows) ...r.payment.amounts.keys}.toList()
      ..sort((a, b) => a == base ? -1 : b == base ? 1 : a.compareTo(b));
    final count = rows.length - _off.length;

    return Scaffold(
      appBar: AppBar(title: Text(tr.sinkCopyLastYear)),
      bottomNavigationBar: rows.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton(
                  onPressed: _saving || count == 0 || accounts.isEmpty
                      ? null
                      : () => _save(rows, category?.id, accounts),
                  child: Text(tr.sinkCopyAdd(count)),
                ),
              ),
            ),
      body: fund == null
          ? const SizedBox.shrink()
          : rows.isEmpty
              ? EmptyState(
                  icon: AppIcons.copy,
                  title: tr.sinkCopyNothing,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(tr.sinkCopyHelp,
                        style: TextStyle(
                            fontSize: 14, color: AppColors.ts(context))),
                    const SizedBox(height: 16),
                    Text(tr.sinkRaiseAll,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ts(context))),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final c in currencies)
                        Container(
                          width: 150,
                          padding: const EdgeInsetsDirectional.only(start: 12),
                          decoration: BoxDecoration(
                              color: AppColors.sfv(context),
                              borderRadius:
                                  BorderRadius.circular(RadiusTokens.md)),
                          child: Row(children: [
                            Text(c,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: CalculatorAmountField(
                                value: _raise[c] ?? 0,
                                onChanged: (v) => setState(() => _raise[c] = v),
                                hintText: '0',
                                fontSize: 16,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 12),
                              child: Text('%',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ts(context))),
                            ),
                          ]),
                        ),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      decoration: AppColors.card(context),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Material(
                        type: MaterialType.transparency,
                        child: Column(children: [
                          for (var i = 0; i < rows.length; i++)
                            _row(context, tr, base, i, rows[i]),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(tr.sinkCopyNote,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.ts(context))),
                  ],
                ),
    );
  }

  Widget _row(BuildContext context, S tr, String base, int i,
      ({FundPayment payment, bool alreadyPlanned}) row) {
    final p = row.payment;
    final on = !_off.contains(i);
    final raised = {
      for (final e in p.amounts.entries) e.key: _raised(e.value, e.key),
    };
    final changed = raised.entries.any((e) => e.value != p.amounts[e.key]);
    return CheckboxListTile(
      value: on,
      onChanged: (v) => setState(() => v == true ? _off.remove(i) : _off.add(i)),
      controlAffinity: ListTileControlAffinity.leading,
      title: Row(children: [
        Expanded(
          child: Text(formatDate(p.date),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        if (row.alreadyPlanned)
          Text(tr.sinkAlreadyPlanned,
              style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
      ]),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (p.title.isNotEmpty) Text(p.title, style: const TextStyle(fontSize: 13)),
        Text(fundAmounts(raised, base),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context))),
        if (changed)
          Text(tr.sinkLastYear(fundAmounts(p.amounts, base)),
              style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
      ]),
    );
  }
}
