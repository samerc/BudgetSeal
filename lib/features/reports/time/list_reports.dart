import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/accounts_provider.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/date_format_provider.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/providers/tx_colors_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/utils/note_text.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/tappable.dart';
import 'report_widgets.dart';
import 'reports_home.dart';

Widget _loading() => const Padding(
    padding: EdgeInsets.all(48),
    child: Center(child: CircularProgressIndicator()));

Widget _empty(String title, IconData icon) => Padding(
    padding: const EdgeInsets.all(32),
    child: EmptyState(icon: icon, title: title));

Widget _rows(BuildContext context, List<Widget> rows) => ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, color: AppColors.bd(context)),
          rows[i],
        ],
      ]),
    );

Widget _amount(String text, {Color? color}) => Text(text,
    style: TextStyle(
        fontFamily: TypographyTokens.displayFamily,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: color));

/// The largest single expenses in the period (base currency); a row opens
/// the transaction.
class BiggestReport extends ConsumerWidget {
  const BiggestReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final t = ref.watch(reportTotalsProvider).value?.now;
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    return ReportScaffold(
      title: tr.rptBiggest,
      children: [
        if (t == null)
          _loading()
        else if (t.biggest.isEmpty)
          _empty(tr.rptNothingInPeriod, AppIcons.receipt)
        else
          _rows(context, [
            for (final b in t.biggest)
              () {
                final tx = b.entry.tx;
                final catId = b.entry.lines.firstOrNull?.categoryId ?? tx.categoryId;
                final cat = cats[catId];
                final note = visibleNote(tx.note).split(' — ').first.trim();
                return Tappable(
                  onTap: () => context.push('/transactions/${tx.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      if (cat != null)
                        CategoryIcon(
                          categoryName: cat.name,
                          emoji: cat.icon,
                          color: AppColors.fromHex(cat.colorHex),
                          size: 36,
                          circular: true,
                        )
                      else
                        const SizedBox(width: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                note.isNotEmpty
                                    ? note
                                    : (cat?.name ?? tr.rptUncategorized),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                            Text(
                                [
                                  formatDate(tx.createdAt.toLocal()),
                                  if (cat != null && note.isNotEmpty) cat.name,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.ts(context))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _amount(formatAmount(b.amount, currency: base)),
                    ]),
                  ),
                );
              }(),
          ]),
      ],
    );
  }
}

/// Money in and out of each account in the period, in its own currency.
class AccountsReport extends ConsumerWidget {
  const AccountsReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final t = ref.watch(reportTotalsProvider).value?.now;
    final colors = ref.watch(txColorsProvider);
    final accounts = {
      for (final a in ref.watch(accountsProvider).value ?? const <Account>[])
        a.id: a,
    };
    final flows = (t?.accountFlow.entries.toList() ?? [])
      ..sort((a, b) => b.value.outflow.compareTo(a.value.outflow));
    return ReportScaffold(
      title: tr.rptAccounts,
      children: [
        if (t == null)
          _loading()
        else if (flows.isEmpty)
          _empty(tr.rptNothingInPeriod, AppIcons.wallet)
        else
          _rows(context, [
            for (final f in flows)
              () {
                final acc = accounts[f.key];
                final cur = acc?.currency ?? '';
                final net = f.value.inflow - f.value.outflow;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(acc?.name ?? tr.txDetailUnknownAccount,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(
                              '${tr.rptIn} ${formatAmount(f.value.inflow, currency: cur)} · '
                              '${tr.rptOut} ${formatAmount(f.value.outflow, currency: cur)}',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.ts(context))),
                        ],
                      ),
                    ),
                    _amount(
                        '${net >= 0 ? '+' : '−'}${formatAmount(net.abs(), currency: cur)}',
                        color: net >= 0 ? colors.income : colors.expense),
                  ]),
                );
              }(),
          ]),
      ],
    );
  }
}

/// Spending per currency, each in its own (never converted).
class CurrenciesReport extends ConsumerWidget {
  const CurrenciesReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final t = ref.watch(reportTotalsProvider).value?.now;
    final rows = (t?.spentByCurrency.entries.where((e) => e.value > 0).toList() ??
        [])
      ..sort((a, b) => a.key.compareTo(b.key));
    return ReportScaffold(
      title: tr.rptCurrencies,
      children: [
        if (t == null)
          _loading()
        else if (rows.isEmpty)
          _empty(tr.rptNothingInPeriod, AppIcons.currencyCircleDollar)
        else ...[
          _rows(context, [
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Expanded(
                    child: Text(r.key,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  _amount(formatAmount(r.value, currency: r.key)),
                ]),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text(tr.rptNotConverted,
                style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
          ),
        ],
      ],
    );
  }
}

/// Active recurring expenses (subscriptions, bills) with what each costs a
/// month and a year; totals per currency.
final _recurringCostsProvider =
    FutureProvider<List<RecurringTransaction>>((ref) async {
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return const [];
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final rows = await (db.select(db.recurringTransactions)
        ..where((r) =>
            r.householdId.equals(householdId) &
            r.deleted.equals(false) &
            r.enabled.equals(true) &
            r.type.equals('expense')))
      .get();
  return rows.where((r) => r.endDate == null || r.endDate!.isAfter(now)).toList();
});

/// A recurring amount as a monthly cost.
double perMonth(double amount, String frequency, int interval) {
  final n = interval < 1 ? 1 : interval;
  return switch (frequency) {
    'daily' => amount * 365 / 12 / n,
    'weekly' => amount * 52 / 12 / n,
    'yearly' => amount / 12 / n,
    _ => amount / n,
  };
}

class SubscriptionsReport extends ConsumerWidget {
  const SubscriptionsReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final async = ref.watch(_recurringCostsProvider);
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    return ReportScaffold(
      title: tr.rptSubscriptions,
      chips: false,
      children: [
        ...async.when(
          loading: () => [_loading()],
          error: (_, __) =>
              [_empty(tr.commonCouldntLoadData, AppIcons.warning)],
          data: (rows) {
            if (rows.isEmpty) {
              return [_empty(tr.rptNoSubscriptions, AppIcons.arrowsClockwise)];
            }
            final sorted = [...rows]..sort((a, b) =>
                perMonth(b.amount, b.frequency, b.interval)
                    .compareTo(perMonth(a.amount, a.frequency, a.interval)));
            final totals = <String, double>{};
            for (final r in rows) {
              totals[r.currency] = (totals[r.currency] ?? 0) +
                  perMonth(r.amount, r.frequency, r.interval);
            }
            return [
              ReportCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.rptInTotal,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                    for (final e in totals.entries)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ReportHeadline(
                            tr.rptPerMonth(
                                formatAmount(e.value, currency: e.key)),
                            sub: tr.rptPerYear(
                                formatAmount(e.value * 12, currency: e.key))),
                      ),
                  ],
                ),
              ),
              _rows(context, [
                for (final r in sorted)
                  () {
                    final m = perMonth(r.amount, r.frequency, r.interval);
                    final cat = cats[r.categoryId];
                    final title = r.title.isNotEmpty
                        ? r.title
                        : (r.note.isNotEmpty ? r.note : (cat?.name ?? ''));
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        if (cat != null)
                          CategoryIcon(
                            categoryName: cat.name,
                            emoji: cat.icon,
                            color: AppColors.fromHex(cat.colorHex),
                            size: 36,
                            circular: true,
                          )
                        else
                          const SizedBox(width: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                  tr.rptPerYear(formatAmount(m * 12,
                                      currency: r.currency)),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.ts(context))),
                            ],
                          ),
                        ),
                        _amount(tr.rptPerMonth(
                            formatAmount(m, currency: r.currency))),
                      ]),
                    );
                  }(),
              ]),
            ];
          },
        ),
      ],
    );
  }
}
