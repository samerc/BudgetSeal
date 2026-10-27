import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/ledger_dao.dart';
import '../../../core/engine/budget_history.dart';
import '../../../core/providers/allocations_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/family_provider.dart';
import '../../../core/providers/household_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/tappable.dart';
import '../../../shared/theme/app_icons.dart';
import 'report_period.dart';
import 'report_widgets.dart';

/// bucket → envelope id → how it did, in the base currency.
final envelopeHistoryProvider =
    FutureProvider<Map<DateTime, Map<String, EnvelopePeriodStat>>>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final household = ref.watch(householdProvider).value;
  // Recomputed when balances move.
  ref.watch(visibleAllocationsProvider);
  if (household == null) return const {};
  final dao = LedgerDao(ref.read(databaseProvider));
  return {
    for (final b in period.buckets)
      b: await envelopePeriodStats(dao,
          householdId: household.id,
          start: period.range(b).start,
          end: period.range(b).end,
          currency: household.baseCurrency),
  };
});

/// Budget vs actual: per month what an envelope (or all of them) had to
/// spend and what it spent, then every envelope's held / over record.
class BudgetReport extends ConsumerStatefulWidget {
  const BudgetReport({super.key});

  @override
  ConsumerState<BudgetReport> createState() => _BudgetReportState();
}

class _BudgetReportState extends ConsumerState<BudgetReport> {
  /// Null = all envelopes.
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final period = ref.watch(reportPeriodProvider);
    final history = ref.watch(envelopeHistoryProvider);
    final names = {
      for (final a in ref.watch(visibleAllocationsProvider).value ??
          const <AllocationWithBalance>[])
        a.data.allocation.id: a.data.allocation.name,
    };
    String money(double v) => formatAmount(v, currency: base);

    return ReportScaffold(
      title: tr.rptBudgetVsActual,
      children: history.when(
        loading: () => [
          const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator())),
        ],
        error: (e, _) => [
          Padding(
            padding: const EdgeInsets.all(32),
            child: EmptyState(
                icon: AppIcons.warning, title: tr.commonCouldntLoadData),
          ),
        ],
        data: (h) {
          // Envelopes with any activity in the period, by name.
          final ids = <String>{
            for (final m in h.values)
              for (final e in m.entries)
                if (e.value.outcome != EnvelopeOutcome.idle &&
                    names.containsKey(e.key))
                  e.key,
          }.toList()
            ..sort((a, b) => names[a]!.compareTo(names[b]!));
          if (ids.isEmpty) {
            return [
              Padding(
                padding: const EdgeInsets.all(32),
                child: EmptyState(
                    icon: AppIcons.envelopeSimple, title: tr.rptNoEnvelopes),
              ),
            ];
          }
          if (_selected != null && !ids.contains(_selected)) _selected = null;
          final pick = _selected == null ? ids : [_selected!];

          // Per month: planned (what the envelopes had), spent, over?
          final months = [
            for (final b in period.buckets)
              () {
                double planned = 0, spent = 0;
                var over = false, active = false;
                for (final id in pick) {
                  final s = h[b]?[id];
                  if (s == null || s.outcome == EnvelopeOutcome.idle) continue;
                  active = true;
                  planned += s.endBalance + s.spent;
                  spent += s.spent;
                  if (s.outcome == EnvelopeOutcome.over) over = true;
                }
                return (
                  bucket: b,
                  planned: planned < 0 ? 0.0 : planned,
                  spent: spent,
                  over: over,
                  active: active
                );
              }(),
          ];
          final active = months.where((m) => m.active).toList();
          final held = active.where((m) => !m.over).length;
          final avgSpent = active.isEmpty
              ? 0.0
              : active.fold(0.0, (t, m) => t + m.spent) / active.length;
          final avgPlanned = active.isEmpty
              ? 0.0
              : active.fold(0.0, (t, m) => t + m.planned) / active.length;

          return [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                children: [
                  AppChip(
                    label: tr.rptAllEnvelopes,
                    selected: _selected == null,
                    onTap: () => setState(() => _selected = null),
                  ),
                  for (final id in ids) ...[
                    const SizedBox(width: 8),
                    AppChip(
                      label: names[id]!,
                      selected: _selected == id,
                      onTap: () => setState(() => _selected = id),
                    ),
                  ],
                ],
              ),
            ),
            ReportCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportHeadline(tr.rptHeldOf(held, active.length),
                      sub: tr.rptAvgOf(money(avgSpent), money(avgPlanned))),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 190,
                    child: _chart(context, months.map((m) => (
                          label: axisMonth(m.bucket),
                          planned: m.planned,
                          spent: m.spent,
                          over: m.over,
                        )).toList(), money),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 14, runSpacing: 6, children: [
                    LegendItem(AppColors.accentBright, tr.rptLegendHeld),
                    LegendItem(AppColors.overspent, tr.rptLegendOver),
                    LegendItem(_plannedColor(context), tr.rptLegendPlanned),
                  ]),
                ],
              ),
            ),
            ReportSection(tr.rptTrackRecord,
                note: period.length > 1
                    ? '${axisMonth(period.buckets.first)} → ${axisMonth(period.buckets.last)}'
                    : null),
            ReportCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(children: [
                for (var i = 0; i < ids.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppColors.bd(context)),
                  _trackRow(context, tr, ids[i], names[ids[i]]!, h,
                      period.buckets, money),
                ],
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Wrap(spacing: 16, runSpacing: 6, children: [
                LegendItem(AppColors.accentBright, tr.rptHeld),
                LegendItem(AppColors.overspent, tr.rptWentOver, ring: true),
                LegendItem(AppColors.sfv(context), tr.rptNotUsed),
              ]),
            ),
          ];
        },
      ),
    );
  }

  Color _plannedColor(BuildContext context) =>
      AppColors.pastel(context, AppColors.accentBright, light: 0.7, dark: 0.7);

  Widget _chart(
      BuildContext context,
      List<({String label, double planned, double spent, bool over})> months,
      String Function(double) money) {
    final top = niceMax(months.fold(
        0.0, (m, x) => [m, x.planned, x.spent].reduce((a, b) => a > b ? a : b)));
    final ts = AppColors.ts(context);
    return BarChart(BarChartData(
      maxY: top,
      minY: 0,
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: top / 2,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AppColors.bd(context), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: top / 2,
            getTitlesWidget: (v, _) => Text(axisAmount(v),
                style: TextStyle(fontSize: 11, color: ts)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= months.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(months[i].label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: months[i].over ? AppColors.overspent : ts)),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppColors.tp(context),
          getTooltipItem: (group, _, rod, __) {
            final m = months[group.x];
            return BarTooltipItem(
              '${m.label}\n${money(m.spent)} / ${money(m.planned)}',
              TextStyle(
                  color: AppColors.bg(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            );
          },
        ),
      ),
      barGroups: [
        for (var i = 0; i < months.length; i++)
          BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: months[i].spent,
              width: months.length > 8 ? 10 : 16,
              color: months[i].over
                  ? AppColors.overspent
                  : AppColors.accentBright,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: months[i].planned > 0,
                toY: months[i].planned,
                color: _plannedColor(context),
              ),
            ),
          ]),
      ],
    ));
  }

  Widget _trackRow(
    BuildContext context,
    S tr,
    String id,
    String name,
    Map<DateTime, Map<String, EnvelopePeriodStat>> h,
    List<DateTime> buckets,
    String Function(double) money,
  ) {
    // At most the last 12 months as dots.
    final shown = buckets.length > 12
        ? buckets.sublist(buckets.length - 12)
        : buckets;
    final stats = [for (final b in buckets) h[b]?[id]];
    final active = stats
        .where((s) => s != null && s.outcome != EnvelopeOutcome.idle)
        .cast<EnvelopePeriodStat>()
        .toList();
    final held = active.where((s) => s.outcome == EnvelopeOutcome.held).length;
    final avgSpent = active.isEmpty
        ? 0.0
        : active.fold(0.0, (t, s) => t + s.spent) / active.length;
    final avgPlanned = active.isEmpty
        ? 0.0
        : active.fold(0.0, (t, s) => t + s.endBalance + s.spent) /
            active.length;
    Widget dot(EnvelopePeriodStat? s) {
      final o = s?.outcome ?? EnvelopeOutcome.idle;
      return Container(
        width: 13,
        height: 13,
        margin: const EdgeInsetsDirectional.only(start: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (o) {
            EnvelopeOutcome.held => AppColors.accentBright,
            EnvelopeOutcome.over => null,
            EnvelopeOutcome.idle => AppColors.sfv(context),
          },
          border: o == EnvelopeOutcome.over
              ? Border.all(color: AppColors.overspent, width: 2.5)
              : null,
        ),
      );
    }

    return Tappable(
      onTap: () => setState(() => _selected = id),
      child: Semantics(
        label: '$name: ${tr.rptHeldOf(held, active.length)}',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(tr.rptAvgOfShort(money(avgSpent), money(avgPlanned)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context))),
                ],
              ),
            ),
            for (final b in shown) dot(h[b]?[id]),
            SizedBox(
              width: 40,
              child: Text('$held/${active.length}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }
}
