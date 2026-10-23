import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/date_format_provider.dart';
import '../../../core/providers/household_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/widgets/empty_state.dart';
import 'report_period.dart';
import 'report_widgets.dart';
import 'reports_home.dart';

/// Spending over time: each month stacked by its top categories (the rest
/// as Other), then every category's monthly average, trend line and how
/// the last month compares. Subcategories count toward their parent.
class SpendingReport extends ConsumerWidget {
  const SpendingReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final period = ref.watch(reportPeriodProvider);
    final totals = ref.watch(reportTotalsProvider).value?.now;
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    String money(double v) => formatAmount(v, currency: base);
    String? top(String? id) {
      final c = cats[id];
      return c?.parentId != null && cats.containsKey(c!.parentId)
          ? c.parentId
          : id;
    }

    if (totals == null) {
      return ReportScaffold(title: tr.rptSpendingTime, children: const [
        Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator())),
      ]);
    }
    if (totals.spent <= 0.005) {
      return ReportScaffold(title: tr.rptSpendingTime, children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: EmptyState(
              icon: AppIcons.chartLineUp, title: tr.rptNothingInPeriod),
        ),
      ]);
    }

    // bucket → parent category → spent.
    final byBucket = {
      for (final b in period.buckets)
        b: () {
          final m = <String?, double>{};
          (totals.categoryByBucket[b] ?? const {}).forEach((id, v) {
            final k = top(id);
            m[k] = (m[k] ?? 0) + v;
          });
          return m;
        }(),
    };
    final overall = <String?, double>{};
    for (final m in byBucket.values) {
      m.forEach((k, v) => overall[k] = (overall[k] ?? 0) + v);
    }
    final ranked = overall.entries.where((e) => e.value > 0.005).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final stacked = ranked.take(4).map((e) => e.key).toList();
    final otherColor = AppColors.th(context);
    Color colorOf(String? id) =>
        cats[id] != null ? AppColors.fromHex(cats[id]!.colorHex) : otherColor;
    String nameOf(String? id) => cats[id]?.name ?? tr.rptUncategorized;

    final monthly = [
      for (final b in period.buckets)
        byBucket[b]!.values.fold(0.0, (t, v) => t + v),
    ];
    final n = period.length;
    // Averages start at the first month with spending: months before the
    // app was used aren't months of zero spending.
    final first = monthly.indexWhere((v) => v > 0.005).clamp(0, n - 1);
    final active = n - first;
    final avg = monthly.skip(first).fold(0.0, (t, v) => t + v) / active;
    var hi = first, lo = first;
    for (var i = first; i < n; i++) {
      if (monthly[i] > monthly[hi]) hi = i;
      if (monthly[i] < monthly[lo]) lo = i;
    }
    final ts = AppColors.ts(context);
    final maxY = niceMax(monthly.fold(0.0, (m, v) => v > m ? v : m));

    return ReportScaffold(
      title: tr.rptSpendingTime,
      children: [
        ReportCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportHeadline(
                tr.rptAboutPerMonth(money(avg)),
                sub: active > 1
                    ? tr.rptHighLow(
                        formatMonth(period.buckets[hi]),
                        money(monthly[hi]),
                        formatMonth(period.buckets[lo]),
                        money(monthly[lo]))
                    : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
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
                        reservedSize: 24,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= n) return const SizedBox.shrink();
                          // Busy axis: every other label.
                          if (n > 8 && i.isOdd) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(axisMonth(period.buckets[i]),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: ts)),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.tp(context),
                      getTooltipItem: (group, _, __, ___) => BarTooltipItem(
                        '${formatMonth(period.buckets[group.x])}\n${money(monthly[group.x])}',
                        TextStyle(
                            color: AppColors.bg(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < n; i++)
                      () {
                        final m = byBucket[period.buckets[i]]!;
                        final parts = [
                          for (final id in stacked) (m[id] ?? 0, colorOf(id)),
                          (
                            m.entries
                                .where((e) => !stacked.contains(e.key))
                                .fold(0.0, (t, e) => t + e.value),
                            otherColor
                          ),
                        ];
                        // A 2 px surface gap between segments.
                        var y = 0.0;
                        final gap = maxY * 0.008;
                        final items = <BarChartRodStackItem>[];
                        for (final (v, c) in parts) {
                          if (v <= 0) continue;
                          items.add(BarChartRodStackItem(
                              y, y + v - (v > gap * 2 ? gap : 0), c));
                          y += v;
                        }
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: monthly[i],
                            width: n > 8 ? 12 : 20,
                            rodStackItems: items,
                            color: Colors.transparent,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ]);
                      }(),
                  ],
                )),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 12, runSpacing: 6, children: [
                for (final id in stacked) LegendItem(colorOf(id), nameOf(id)),
                if (ranked.length > stacked.length)
                  LegendItem(otherColor, tr.rptOther),
              ]),
            ],
          ),
        ),
        ReportSection(tr.rptByCategory, note: tr.rptAMonthAvg),
        ReportCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            for (var i = 0; i < ranked.length; i++) ...[
              if (i > 0) Divider(height: 1, color: AppColors.bd(context)),
              _categoryRow(context, tr, ranked[i].key, nameOf(ranked[i].key),
                  colorOf(ranked[i].key), [
                for (final b in period.buckets.skip(first))
                  byBucket[b]![ranked[i].key] ?? 0
              ], period, money),
            ],
          ]),
        ),
      ],
    );
  }

  Widget _categoryRow(BuildContext context, S tr, String? id, String name,
      Color color, List<double> values, ReportPeriod period,
      String Function(double) money) {
    final avg = values.fold(0.0, (t, v) => t + v) / values.length;
    final last = values.last;
    final pct = avg > 0 ? ((last - avg) / avg * 100).round() : 0;
    final lastMonth = formatMonth(period.buckets.last);
    final trend = values.length < 2 || pct.abs() < 5
        ? tr.rptSteady
        : pct > 0
            ? tr.rptAboveAvg(lastMonth, pct)
            : tr.rptBelowAvg(lastMonth, -pct);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Text(trend,
                  style: TextStyle(
                      fontSize: 12,
                      color: pct >= 5 && values.length > 1
                          ? AppColors.overspent
                          : AppColors.ts(context))),
            ],
          ),
        ),
        if (values.length > 1)
          SizedBox(
            width: 72,
            height: 26,
            child: CustomPaint(painter: _Spark(values, color)),
          ),
        SizedBox(
          width: 76,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(money(avg),
                style: const TextStyle(
                    fontFamily: TypographyTokens.displayFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

/// A 2 px trend line through [values], low to high.
class _Spark extends CustomPainter {
  final List<double> values;
  final Color color;
  _Spark(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = 3 + i * (size.width - 6) / (values.length - 1);
      final y = hi == lo
          ? size.height / 2
          : size.height - 3 - (values[i] - lo) / (hi - lo) * (size.height - 6);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color);
  }

  @override
  bool shouldRepaint(_Spark old) => old.values != values || old.color != color;
}
