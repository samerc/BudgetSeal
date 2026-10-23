import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/accounts_provider.dart';
import '../../../core/providers/date_format_provider.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../core/providers/tx_colors_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import 'report_period.dart';
import 'report_widgets.dart';
import 'reports_home.dart';

/// Income vs spending month by month with what was kept, then net worth
/// over the period (base-currency accounts).
class MoneyReport extends ConsumerWidget {
  const MoneyReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final period = ref.watch(reportPeriodProvider);
    final totals = ref.watch(reportTotalsProvider).value?.now;
    final colors = ref.watch(txColorsProvider);
    final entries = ref.watch(transactionEntriesProvider).value;
    final accounts = ref.watch(accountsWithBalanceProvider).value;
    String money(double v) => formatAmount(v, currency: base);
    final ts = AppColors.ts(context);

    if (totals == null) {
      return ReportScaffold(title: tr.rptIncomeSpending, children: const [
        Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator())),
      ]);
    }

    final n = period.length;
    final income = [for (final b in period.buckets) totals.incomeByBucket[b] ?? 0.0];
    final spent = [for (final b in period.buckets) totals.spentByBucket[b] ?? 0.0];
    final below = [for (var i = 0; i < n; i++) income[i] - spent[i]]
        .where((k) => k < -0.005)
        .length;
    final maxY = niceMax([...income, ...spent].fold(0.0, (m, v) => v > m ? v : m));
    final kept = totals.kept;

    // Net worth at the period start and at each bucket's end (up to today).
    final today = DateTime.now();
    final cuts = [
      period.start,
      for (final b in period.buckets)
        period.range(b).end.isAfter(today) ? today : period.range(b).end,
    ];
    final worth = entries == null || accounts == null
        ? null
        : netWorthAt(
            entries,
            {
              for (final a in accounts)
                a.account.id: (balance: a.balance, currency: a.account.currency),
            },
            base,
            cuts);

    return ReportScaffold(
      title: tr.rptIncomeSpending,
      children: [
        ReportCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportHeadline(
                kept >= 0
                    ? tr.rptKeptAmount(money(kept))
                    : tr.rptSpentMoreAmount(money(-kept)),
                sub: [
                  if (totals.income > 0.005 && kept >= 0)
                    tr.rptKeptShare((kept / totals.income * 100).round()),
                  if (n > 1) below == 0 ? tr.rptAllAbove : tr.rptSomeBelow(below),
                ].join(' '),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 210,
                child: BarChart(BarChartData(
                  maxY: maxY,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 2,
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
                        interval: maxY / 2,
                        getTitlesWidget: (v, _) => Text(axisAmount(v),
                            style: TextStyle(fontSize: 11, color: ts)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= n) return const SizedBox.shrink();
                          if (n > 8 && i.isOdd) return const SizedBox.shrink();
                          final k = income[i] - spent[i];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text(axisMonth(period.buckets[i]),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: ts)),
                              Text(
                                  '${k >= 0 ? '+' : '−'}${axisAmount(k.abs())}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: k < 0
                                          ? AppColors.overspent
                                          : AppColors.tp(context))),
                            ]),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.tp(context),
                      getTooltipItem: (group, _, rod, rodIndex) =>
                          BarTooltipItem(
                        money(rod.toY),
                        TextStyle(
                            color: AppColors.bg(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < n; i++)
                      BarChartGroupData(x: i, barsSpace: 2, barRods: [
                        BarChartRodData(
                          toY: income[i],
                          width: n > 8 ? 6 : 10,
                          color: colors.income,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: spent[i],
                          width: n > 8 ? 6 : 10,
                          color: colors.expense,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ]),
                  ],
                )),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 14, runSpacing: 6, children: [
                LegendItem(colors.income, tr.typeIncome),
                LegendItem(colors.expense, tr.rptSpent),
                Text(tr.rptKeptRow, style: TextStyle(fontSize: 12, color: ts)),
              ]),
            ],
          ),
        ),
        if (worth != null) _netWorth(context, tr, worth, cuts, period, money, base),
      ],
    );
  }

  Widget _netWorth(BuildContext context, S tr, List<double> worth,
      List<DateTime> cuts, ReportPeriod period, String Function(double) money,
      String base) {
    final ts = AppColors.ts(context);
    final change = worth.last - worth.first;
    final lo = worth.reduce((a, b) => a < b ? a : b);
    final hi = worth.reduce((a, b) => a > b ? a : b);
    final pad = (hi - lo).abs() < 1 ? (hi.abs() * 0.1 + 1) : (hi - lo) * 0.15;
    final gold = AppColors.accentText(context);
    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr.reportsNetWorth,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                textAlign: TextAlign.end,
                tr.rptSince(
                    '${change >= 0 ? '+' : '−'}${money(change.abs())}',
                    formatMonth(period.buckets.first)),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: change >= 0 ? AppColors.healthy : AppColors.overspent)),
            ),
          ]),
          Text(money(worth.last),
              style: const TextStyle(
                  fontFamily: TypographyTokens.displayFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: LineChart(LineChartData(
              minY: lo - pad,
              maxY: hi + pad,
              gridData: FlGridData(
                drawVerticalLine: false,
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
                    reservedSize: 40,
                    getTitlesWidget: (v, meta) =>
                        v == meta.min || v == meta.max
                            ? const SizedBox.shrink()
                            : Text(axisAmount(v),
                                style: TextStyle(fontSize: 11, color: ts)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 1 || i >= cuts.length || v != i.toDouble()) {
                        return const SizedBox.shrink();
                      }
                      if (cuts.length > 9 && i.isOdd) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(axisMonth(period.buckets[i - 1]),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ts)),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.tp(context),
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        '${formatDate(cuts[s.x.toInt()])}\n${money(s.y)}',
                        TextStyle(
                            color: AppColors.bg(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < worth.length; i++)
                      FlSpot(i.toDouble(), worth[i]),
                  ],
                  isCurved: false,
                  barWidth: 2,
                  color: gold,
                  dotData: FlDotData(
                    checkToShowDot: (s, _) => s.x == worth.length - 1,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 5,
                        color: gold,
                        strokeWidth: 2,
                        strokeColor: AppColors.sf(context)),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.pastel(context, AppColors.accentBright,
                        light: 0.8, dark: 0.82),
                  ),
                ),
              ],
            )),
          ),
          const SizedBox(height: 10),
          Text(tr.rptNetWorthNote(base),
              style: TextStyle(fontSize: 12, height: 1.4, color: ts)),
        ],
      ),
    );
  }
}
