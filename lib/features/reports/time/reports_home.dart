import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/date_format_provider.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../core/providers/tx_colors_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/seal_mark.dart';
import '../../../shared/widgets/sheet_title.dart';
import '../../../shared/widgets/tappable.dart';
import 'report_period.dart';

/// The period chips every time report shares (Month … Custom), with the
/// range and what it's compared with under them.
class ReportSpanChips extends ConsumerWidget {
  const ReportSpanChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final state = ref.watch(reportSpanProvider);
    final period = ref.watch(reportPeriodProvider);
    final notifier = ref.read(reportSpanProvider.notifier);
    Widget chip(ReportSpan span, String label) => AppChip(
          label: label,
          selected: state.span == span,
          onTap: () => span == ReportSpan.custom
              ? _pickCustom(context, ref)
              : notifier.set(span),
        );
    final last = period.end.subtract(const Duration(days: 1));
    final range = period.length == 1
        ? formatMonth(period.buckets.first, year: true)
        : '${formatMonth(period.buckets.first, short: true, year: true)} – '
            '${formatMonth(period.buckets.last, short: true, year: true)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            chip(ReportSpan.month, tr.rptSpanMonth),
            chip(ReportSpan.months3, tr.rptSpan3),
            chip(ReportSpan.months6, tr.rptSpan6),
            chip(ReportSpan.months12, tr.rptSpan12),
            chip(ReportSpan.year, tr.rptSpanYear),
            chip(ReportSpan.custom, tr.rptSpanCustom),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Text(
            tr.rptComparedWith(
                period.startDay == null
                    ? range
                    : '${formatDate(period.start)} – ${formatDate(last)}',
                period.length),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ts(context)),
          ),
        ),
      ],
    );
  }

  /// Two month pickers in a sheet: from, to.
  Future<void> _pickCustom(BuildContext context, WidgetRef ref) async {
    final tr = S.of(context);
    final now = DateTime.now();
    final months = [
      for (var i = 0; i < 36; i++) DateTime(now.year, now.month - i, 1),
    ];
    final current = ref.read(reportPeriodProvider);
    var from = current.buckets.first;
    var to = current.buckets.last;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget picker(String label, DateTime value, ValueChanged<DateTime> on) {
            return Expanded(
              child: DropdownButtonFormField<DateTime>(
                initialValue: months.contains(value) ? value : months.first,
                icon: AppIcons.dropdown,
                decoration: InputDecoration(labelText: label),
                items: [
                  for (final m in months)
                    DropdownMenuItem(
                        value: m, child: Text(formatMonth(m, year: true))),
                ],
                onChanged: (v) {
                  if (v != null) setSheet(() => on(v));
                },
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SheetTitle(tr.rptSpanCustom.replaceAll('…', '')),
                Row(children: [
                  picker(tr.rptPickFrom, from, (v) => from = v),
                  const SizedBox(width: 12),
                  picker(tr.rptPickTo, to, (v) => to = v),
                ]),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(tr.commonDone),
                ),
              ]),
            ),
          );
        },
      ),
    );
    if (ok != true) return;
    if (to.isBefore(from)) (from, to) = (to, from);
    ref.read(reportSpanProvider.notifier).setCustom(from, to);
  }
}

/// Totals for the selected period and the one before it.
final reportTotalsProvider =
    Provider<AsyncValue<({PeriodTotals now, PeriodTotals before})>>((ref) {
  final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
  final period = ref.watch(reportPeriodProvider);
  return ref.watch(transactionEntriesProvider).whenData((entries) => (
        now: periodTotals(entries, period, base),
        before: periodTotals(entries, period.previous, base),
      ));
});

/// The Reports tab: pick a period, read how it went in a few sentences,
/// then open any report from the library.
class ReportsHome extends ConsumerWidget {
  const ReportsHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final totals = ref.watch(reportTotalsProvider).value;
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final colors = ref.watch(txColorsProvider);
    String money(double v) => formatAmount(v, currency: base);
    String? delta(double now, double before) {
      if (before.abs() < 0.005) return null;
      final pct = ((now - before) / before.abs() * 100).round();
      return '${pct >= 0 ? '+' : '−'}${pct.abs()}%';
    }

    // The story: kept, the top category, how spending moved.
    final story = <String>[];
    if (totals != null) {
      final t = totals.now;
      if (t.income > 0.005 && t.kept >= 0) {
        story.add(tr.rptStoryKept((t.kept / t.income * 100).round()));
      } else if (t.income > 0.005) {
        story.add(tr.rptStoryOverspent(money(-t.kept)));
      } else if (t.spent > 0.005) {
        story.add(tr.rptStorySpentOnly(money(t.spent)));
      } else {
        story.add(tr.rptStoryNothing);
      }
      final top = (t.byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .firstOrNull;
      if (top != null && top.value > 0.005) {
        story.add(tr.rptStoryTop(
            cats[top.key]?.name ?? tr.rptUncategorized, money(top.value)));
      }
      final before = totals.before.spent;
      if (before > 0.005 && t.spent > 0.005) {
        final pct = ((t.spent - before) / before * 100).round();
        story.add(pct.abs() < 3
            ? tr.rptStorySame
            : pct < 0
                ? tr.rptStoryLess(-pct)
                : tr.rptStoryMore(pct));
      }
    }

    Widget tile(String label, String value, String? sub, {Color? subColor}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: AppColors.card(context, radius: RadiusTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                // One line: IntrinsicHeight measures it unscaled.
                child: Text(value,
                    maxLines: 1,
                    style: const TextStyle(
                        fontFamily: TypographyTokens.displayFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ),
              if (sub != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(sub,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: subColor ?? AppColors.ts(context))),
                ),
            ],
          ),
        ),
      );
    }

    Color good(bool up) => up ? colors.income : colors.expense;
    final t = totals?.now;
    final b = totals?.before;
    final year = DateTime.now().year;

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      children: [
        const ReportSpanChips(),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: AppColors.card(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(story.firstOrNull ?? '',
                  style: const TextStyle(
                      fontFamily: TypographyTokens.displayFamily,
                      fontSize: 21,
                      height: 1.25,
                      fontWeight: FontWeight.w800)),
              for (final line in story.skip(1))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(line,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ts(context))),
                ),
            ],
          ),
        ),
        if (t != null && b != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            // Equal heights: each tile as tall as the tallest.
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              tile(tr.rptEarned, money(t.income), delta(t.income, b.income),
                  subColor: good(t.income >= b.income)),
              const SizedBox(width: 8),
              tile(tr.rptSpent, money(t.spent), delta(t.spent, b.spent),
                  subColor: good(t.spent <= b.spent)),
              const SizedBox(width: 8),
              tile(
                  tr.rptKept,
                  money(t.kept),
                  t.income > 0.005
                      ? tr.rptOfIncome((t.kept / t.income * 100).round())
                      : null),
            ])),
          ),
        _group(context, tr.rptGroupBudget, AppColors.accent, [
          _Row(AppIcons.chartBar, tr.rptBudgetVsActual, tr.rptBudgetVsActualSub,
              'budget'),
          _Row(AppIcons.lightbulb, tr.rptInsights, tr.rptInsightsSub, 'insights'),
        ]),
        _group(context, tr.rptGroupSpending, AppColors.overspent, [
          _Row(AppIcons.chartLineUp, tr.rptSpendingTime, tr.rptSpendingTimeSub,
              'spending'),
          _Row(AppIcons.chartPie, tr.rptCategories, tr.rptCategoriesSub,
              'categories'),
          _Row(AppIcons.mapPin, tr.rptPlaces, tr.rptPlacesSub, 'places'),
          _Row(AppIcons.arrowUp, tr.rptBiggest, tr.rptBiggestSub, 'biggest'),
          _Row(AppIcons.calendarBlank, tr.rptOverview, tr.rptOverviewSub,
              'overview'),
        ]),
        _group(context, tr.rptGroupMoney, AppColors.healthy, [
          _Row(AppIcons.trendUp, tr.rptIncomeSpending, tr.rptIncomeSpendingSub,
              'money'),
          _Row(AppIcons.scales, tr.rptBalanceSheet, tr.rptBalanceSheetSub,
              'balance'),
          _Row(AppIcons.wallet, tr.rptAccounts, tr.rptAccountsSub, 'accounts'),
          _Row(AppIcons.currencyCircleDollar, tr.rptCurrencies,
              tr.rptCurrenciesSub, 'currencies'),
        ]),
        _group(context, tr.rptGroupCommitments, AppColors.caution, [
          _Row(AppIcons.arrowsClockwise, tr.rptSubscriptions,
              tr.rptSubscriptionsSub, 'subscriptions'),
          _Row(AppIcons.flag, tr.rptGoals, tr.rptGoalsSub, null,
              route: '/objectives'),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Material(
            color: AppColors.accentBright,
            borderRadius: BorderRadius.circular(RadiusTokens.hero),
            child: Tappable(
              borderRadius: BorderRadius.circular(RadiusTokens.hero),
              onTap: () => context.push('/reports/view/year'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const SealMark(size: 44, inverse: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr.rptYearReview('$year'),
                            style: TextStyle(
                                fontFamily: TypographyTokens.displayFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkOn(AppColors.accentBright))),
                        Text(tr.rptYearReviewSub,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkOn(AppColors.accentBright)
                                    .withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  Icon(AppIcons.caretRight,
                      size: 18, color: AppColors.inkOn(AppColors.accentBright)),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _group(
      BuildContext context, String title, Color tint, List<_Row> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 8),
          child: SectionHeader(title),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppColors.card(context),
          child: Column(children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                    height: 1,
                    indent: 66,
                    endIndent: 16,
                    color: AppColors.bd(context)),
              _row(context, rows[i], tint),
            ],
          ]),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, _Row r, Color tint) {
    return Tappable(
      onTap: () => context.push(r.route ?? '/reports/view/${r.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.pastel(context, tint, light: 0.82, dark: 0.75),
              shape: BoxShape.circle,
            ),
            child: Icon(r.icon,
                size: 18,
                color: AppColors.pastel(context, tint,
                    light: 0.35, dark: 0.3, inverse: true)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                Text(r.sub,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.ts(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(AppIcons.caretRight, size: 16, color: AppColors.th(context)),
        ]),
      ),
    );
  }
}

class _Row {
  final IconData icon;
  final String title;
  final String sub;
  final String? id;
  final String? route;
  const _Row(this.icon, this.title, this.sub, this.id, {this.route});
}
