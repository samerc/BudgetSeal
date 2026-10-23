import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:drift/drift.dart' hide Column;

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/age_of_money_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/report_stats_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/budget_progress.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/category_icon.dart';
import '../../core/providers/daily_spending_provider.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/spending_heatmap.dart';
import '../../shared/widgets/hint_banner.dart' show showHintIfNeeded;
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/utils/note_text.dart';
import '../../shared/theme/app_icons.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../shared/widgets/tappable.dart';
import '../accounts/account_type.dart';
import '../accounts/widgets/balance_hero.dart';
import 'widgets/income_expense_summary.dart';
import 'widgets/month_nav.dart';
import 'time/reports_home.dart';
import '../../shared/utils/calendar_days.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: compute base amount from a transaction entry.
// Skips lines where currency differs from base but rate is 1.0 (not set).
// ─────────────────────────────────────────────────────────────────────────────
String _reportsBaseCurrency = 'USD'; // set from provider before use

double _baseAmount(TransactionEntry e) {
  if (e.lines.isNotEmpty) {
    double sum = 0;
    for (final l in e.lines) {
      if (!isRealRate(l.currency, _reportsBaseCurrency, l.exchangeRateToBase)) continue;
      sum += l.amount * l.exchangeRateToBase;
    }
    return sum;
  }
  if (!isRealRate(e.tx.currency, _reportsBaseCurrency, e.tx.exchangeRateToBase)) return 0;
  return e.tx.amount * e.tx.exchangeRateToBase;
}

/// Budget period start day the reports use, or null for calendar months
/// (set by the hub from [reportsStartDayProvider]).
int? _reportsStartDay;

/// The selected bucket, [back] months/periods before the current one.
DateTime _reportMonth(int back) {
  final b = reportBucketFor(DateTime.now(), _reportsStartDay);
  return DateTime(b.year, b.month - back, 1);
}

Map<String?, double> _baseAmountByCategory(TransactionEntry e) =>
    baseAmountByCategory(e, _reportsBaseCurrency);

// ═════════════════════════════════════════════════════════════════════════════
// Reports Hub Screen
// ═════════════════════════════════════════════════════════════════════════════

class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showHintIfNeeded(
        context,
        hintId: 'reports_intro',
        icon: AppIcons.chartLineUp,
        title: S.of(context).reportsHintTitle,
        body: S.of(context).reportsHintBody,
      );
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Set the module-level base currency for _baseAmount helper
    _reportsBaseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    _reportsStartDay = ref.watch(reportsStartDayProvider);
    final periodDay = ref.watch(householdProvider).value?.periodStartDay ?? 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        S.of(context).reportsTitle,
                        style: TextStyle(
                          fontSize: TypographyTokens.screenTitleSize,
                          fontFamily: TypographyTokens.displayFamily,
                          fontWeight: TypographyTokens.screenTitleWeight,
                          color: AppColors.tp(context),
                        ),
                      ),
                    ),
                  ),
                  // Calendar months vs budget periods (start day ≠ 1 only).
                  if (periodDay != 1)
                    PopupMenuButton<bool>(
                      icon: Icon(AppIcons.calendar,
                          color: _reportsStartDay != null
                              ? AppColors.accent
                              : AppColors.ts(context)),
                      initialValue: _reportsStartDay != null,
                      onSelected: (v) =>
                          ref.read(reportsByPeriodProvider.notifier).set(v),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: false,
                            child: Text(S.of(context).reportsCalendarMonths)),
                        PopupMenuItem(
                            value: true,
                            child: Text(S.of(context).reportsBudgetPeriods)),
                      ],
                    ),
                ],
              ),
            ),
            // ── Period chips, the story and the report library ──
            const Expanded(child: ReportsHome()),
          ],
        ),
      ),
    );
  }
}

/// A report from the library as its own screen: the month reports that
/// were tabs (overview, categories, insights, balance sheet) live here;
/// the time reports have their own screens (see [ReportView]).
class LegacyReportPage extends ConsumerWidget {
  final String id;
  final String title;
  const LegacyReportPage({super.key, required this.id, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The tabs read these module-level settings.
    _reportsBaseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    _reportsStartDay = ref.watch(reportsStartDayProvider);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (id) {
        'categories' => const _CategoriesTab(),
        'insights' => const _InsightsTab(),
        'balance' => const _BalanceSheetTab(),
        _ => const _OverviewTab(),
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Tab 1: Overview (Spending gauge + cashflow summary)
// ═════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab();

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  bool _showDailyPace = false;
  int _selectedMonthsBack = 0;

  DateTime get _month {
    return _reportMonth(_selectedMonthsBack);
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionEntriesProvider);
    final baseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';

    final statsAsync = ref.watch(reportStatsProvider);

    return txAsync.when(
      data: (entries) {
        final stats = statsAsync.value;
        final now = DateTime.now();
        final month = _month;
        final isCurrentMonth =
            month.year == now.year && month.month == now.month;

        final currentMonth = stats?.monthly[month];
        final double totalIncome = currentMonth?.income ?? 0;
        final double totalExpense = currentMonth?.expense ?? 0;
        final typical = stats?.typicalMonthlySpend(month) ?? 0;

        // Days elapsed for this month
        final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
        final daysElapsed = isCurrentMonth ? now.day : daysInMonth;
        final daysLeft = isCurrentMonth ? daysInMonth - now.day : 0;

        // Previous month for comparison
        final prevMonth = DateTime(month.year, month.month - 1, 1);
        final prevExpense = stats?.monthly[prevMonth]?.expense ?? 0.0;

        final trend = stats?.monthRange(6, from: month) ?? [];
        final months = trend.map((e) => e.key).toList();
        final incomeByMonth = trend.map((e) => e.value.income).toList();
        final expenseByMonth = trend.map((e) => e.value.expense).toList();

        while (months.length < 6) {
          months.insert(0, DateTime(month.year, month.month - months.length, 1));
          incomeByMonth.insert(0, 0);
          expenseByMonth.insert(0, 0);
        }

        return _MonthSwipe(
          onPrev: () => setState(() => _selectedMonthsBack++),
          onNext: _selectedMonthsBack > 0
              ? () => setState(() => _selectedMonthsBack--)
              : null,
          child: _RefreshableScroll(
            child: Column(
              children: [
                // Month navigator
                MonthNav(
                  label: _periodLabel(month),
                  onPrev: () => setState(() => _selectedMonthsBack++),
                  onNext: _selectedMonthsBack > 0
                      ? () => setState(() => _selectedMonthsBack--)
                      : null,
                ),
                const SizedBox(height: Spacing.md),
                if (totalIncome == 0 && totalExpense == 0)
                  EmptyState(
                    icon: AppIcons.chartLineUp,
                    title: S.of(context).reportsNothingThisMonth,
                    subtitle: S.of(context).reportsNothingThisMonthHint,
                  )
                else
                  _MonthlySummaryCard(
                    income: totalIncome,
                    expense: totalExpense,
                    lastMonthExpense: prevExpense,
                    dailyRate:
                        daysElapsed > 0 ? totalExpense / daysElapsed : 0,
                    daysLeft: daysLeft,
                    currency: baseCurrency,
                    month: month,
                  ),
                const SizedBox(height: Spacing.sectionGap),
                // Spending Heatmap
                _HeatmapSection(baseCurrency: baseCurrency),
                const SizedBox(height: Spacing.sectionGap),
                // Toggle: Trend vs Daily Pace
                Row(
                  children: [
                    AppChip(
                      label: S.of(context).reports6MonthTrend,
                      selected: !_showDailyPace,
                      onTap: () => setState(() => _showDailyPace = false),
                    ),
                    const SizedBox(width: Spacing.sm),
                    AppChip(
                      label: S.of(context).reportsDailyPaceToggle,
                      selected: _showDailyPace,
                      onTap: () => setState(() => _showDailyPace = true),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                if (!_showDailyPace)
                  _TrendChart(
                    months: months,
                    incomeByMonth: incomeByMonth,
                    expenseByMonth: expenseByMonth,
                    baseCurrency: baseCurrency,
                  )
                else
                  _DailyPaceChart(
                    entries: entries,
                    baseCurrency: baseCurrency,
                    typical: typical,
                    month: month,
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(), child: SkeletonList()),
      error: (e, _) => ErrorRetry(
        message: S.of(context).commonCouldntLoadData,
        details: '$e',
        onRetry: () => ref.invalidate(transactionEntriesProvider),
      ),
    );
  }
}

/// Inline daily pace chart (absorbed from Cumulative tab).
class _DailyPaceChart extends StatelessWidget {
  final List<TransactionEntry> entries;
  final String baseCurrency;
  final double typical;
  final DateTime? month;

  const _DailyPaceChart({
    required this.entries,
    required this.baseCurrency,
    required this.typical,
    this.month,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final selectedMonth = month ?? DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
    final lastDay = isCurrentMonth ? now.day : daysInMonth;

    final dailyCumulative = List.filled(daysInMonth + 1, 0.0);
    for (final e in entries) {
      if (e.tx.type != 'expense') continue;
      final d = e.tx.createdAt.toLocal();
      if (d.year == selectedMonth.year && d.month == selectedMonth.month) {
        dailyCumulative[d.day] += _baseAmount(e);
      }
    }
    for (int i = 1; i <= daysInMonth; i++) {
      dailyCumulative[i] += dailyCumulative[i - 1];
    }

    final typicalDaily = typical / daysInMonth;
    final typicalCumulative =
        List.generate(daysInMonth + 1, (i) => typicalDaily * i);

    final allValues = [
      ...dailyCumulative.take(lastDay + 1),
      ...typicalCumulative,
    ];
    final maxY = allValues.fold(0.0, (a, b) => a > b ? a : b);

    // Same empty card as the trend chart.
    if (maxY == 0) return _EmptyChartCard(S.of(context).reportsNoSpending);

    return _ChartCard(
      title: S.of(context).reportsDailyPaceToggle,
      child: SizedBox(
      height: 200,
      child: LineChart(LineChartData(
        minX: 1,
        maxX: daysInMonth.toDouble(),
        minY: 0,
        maxY: maxY * 1.1,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: TextStyle(
                      fontSize: TypographyTokens.miniSize,
                      color: AppColors.th(context))),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.popup(context),
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      formatAmount(s.y, currency: baseCurrency),
                      TextStyle(
                          color: s.bar.color ?? AppColors.tp(context),
                          fontSize: TypographyTokens.captionSize,
                          fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          // Actual cumulative
          LineChartBarData(
            spots: [
              for (int d = 1; d <= lastDay; d++)
                FlSpot(d.toDouble(), dailyCumulative[d]),
            ],
            isCurved: true,
            color: AppColors.accent,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.pastel(context, AppColors.accent,
                  light: 0.85, dark: 0.7),
            ),
          ),
          // Typical pace (dashed)
          LineChartBarData(
            spots: [
              for (int d = 1; d <= daysInMonth; d++)
                FlSpot(d.toDouble(), typicalCumulative[d]),
            ],
            isCurved: false,
            color: AppColors.th(context),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: [4, 4],
          ),
        ],
      )),
      ),
    );
  }
}

// ── Spending Heatmap Section ─────────────────────────────────────────────────

class _HeatmapSection extends ConsumerWidget {
  final String baseCurrency;
  const _HeatmapSection({required this.baseCurrency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final heatmapAsync = ref.watch(dailySpendingProvider(year));

    return _ChartCard(
      title: S.of(context).reportsSpendingActivity,
      trailing: Text('$year',
          style: TextStyle(
              fontSize: TypographyTokens.captionSize,
              color: AppColors.ts(context))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heatmapAsync.when(
            data: (data) => SpendingHeatmap(
              data: data,
              baseCurrency: baseCurrency,
            ),
            loading: () => const SkeletonLoader(
                height: 100, borderRadius: RadiusTokens.md),
            error: (e, _) => ErrorRetry(
              message: S.of(context).commonCouldntLoadData,
              details: '$e',
              onRetry: () => ref.invalidate(dailySpendingProvider(year)),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Legend — matches the cells SpendingHeatmap draws.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(context, AppColors.sfv(context), S.of(context).reportsHeatmapNone),
              const SizedBox(width: Spacing.md),
              _legendDot(context, AppColors.overspent.withValues(alpha: 0.4), S.of(context).typeExpense),
              const SizedBox(width: Spacing.md),
              _legendDot(context, AppColors.healthy.withValues(alpha: 0.4), S.of(context).typeIncome),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            S.of(context).reportsHeatmapHelp,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: TypographyTokens.miniSize,
                color: AppColors.ts(context)),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Text(label,
            style: TextStyle(
                fontSize: TypographyTokens.miniSize,
                color: AppColors.ts(context))),
      ],
    );
  }
}

// ── Monthly summary: income / expenses / net + pace ─────────────────────────

class _MonthlySummaryCard extends StatelessWidget {
  final double income, expense;
  final double lastMonthExpense;
  final double dailyRate;
  final int daysLeft;
  final String currency;
  final DateTime month;

  const _MonthlySummaryCard({
    required this.income,
    required this.expense,
    required this.lastMonthExpense,
    required this.dailyRate,
    required this.daysLeft,
    required this.currency,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final projected = dailyRate * DateUtils.getDaysInMonth(month.year, month.month);

    // Comparison with last month
    String? comparison;
    Color? comparisonColor;
    if (lastMonthExpense > 0) {
      final diff = ((expense - lastMonthExpense) / lastMonthExpense * 100).abs();
      if (expense < lastMonthExpense) {
        comparison = S.of(context).reportsLessThanLast(diff.round());
        comparisonColor = AppColors.healthy;
      } else if (expense > lastMonthExpense) {
        comparison = S.of(context).reportsMoreThanLast(diff.round());
        comparisonColor = AppColors.overspent;
      } else {
        comparison = S.of(context).reportsSameAsLast;
        comparisonColor = AppColors.ts(context);
      }
    }

    TextStyle label() => TextStyle(
        fontSize: TypographyTokens.captionSize, color: AppColors.ts(context));
    TextStyle value() => TextStyle(
        fontSize: TypographyTokens.amountSmallSize,
        fontWeight: TypographyTokens.amountSmallWeight,
        color: AppColors.tp(context));

    return AppCard(
      child: Column(
        children: [
          // The same income / expenses / net block as Home.
          IncomeExpenseSummary(
            income: income,
            expense: expense,
            currency: currency,
          ),
          const SizedBox(height: Spacing.md),
          Divider(color: AppColors.bd(context), height: 1),
          const SizedBox(height: Spacing.md),
          // Pace + projection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.of(context).reportsDailyPace, style: label()),
              Text(
                S.of(context).commonPerDay(
                    formatAmount(dailyRate, currency: currency)),
                style: value(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.of(context).reportsProjectedTotal, style: label()),
              Text(
                '~${formatAmount(projected, currency: currency)}',
                style: value(),
              ),
            ],
          ),
          // Comparison with last month
          if (comparison != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  expense <= lastMonthExpense
                      ? AppIcons.trendDown
                      : AppIcons.trendUp,
                  size: 16,
                  color: comparisonColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(comparison,
                      style: TextStyle(
                          fontSize: TypographyTokens.captionSize,
                          fontWeight: TypographyTokens.captionWeight,
                          color: comparisonColor)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── 6-Month Trend Chart ─────────────────────────────────────────────────────

class _TrendChart extends ConsumerWidget {
  final List<DateTime> months;
  final List<double> incomeByMonth;
  final List<double> expenseByMonth;
  final String baseCurrency;

  const _TrendChart({
    required this.months,
    required this.incomeByMonth,
    required this.expenseByMonth,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(txColorsProvider);
    final maxVal = [
      ...incomeByMonth,
      ...expenseByMonth,
    ].fold(0.0, (a, b) => a > b ? a : b);

    // No income or spending in six months: say so instead of an empty gap
    // under the toggle (same card as the daily pace chart's).
    if (maxVal == 0) return _EmptyChartCard(S.of(context).heatmapNoData);

    Widget bar(double h, Color c) => Container(
          width: 10,
          height: h.clamp(2, 100),
          decoration: BoxDecoration(
              color: c, borderRadius: BorderRadius.circular(3)),
        );
    Widget legend(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: Spacing.xs),
            Text(label,
                style: TextStyle(
                    fontSize: TypographyTokens.miniSize,
                    color: AppColors.ts(context))),
          ],
        );

    return _ChartCard(
      title: S.of(context).reports6MonthTrend,
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final incH =
                    maxVal > 0 ? (incomeByMonth[i] / maxVal) * 100 : 0.0;
                final expH =
                    maxVal > 0 ? (expenseByMonth[i] / maxVal) * 100 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            bar(incH, colors.income),
                            const SizedBox(width: 2),
                            bar(expH, colors.expense),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(formatMonth(months[i], short: true),
                            style: TextStyle(
                                fontSize: TypographyTokens.miniSize,
                                color: AppColors.ts(context))),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              legend(colors.income, S.of(context).typeIncome),
              const SizedBox(width: Spacing.lg),
              legend(colors.expense, S.of(context).typeExpense),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Tab 2: Categories (Top spending + top transactions)
// ═════════════════════════════════════════════════════════════════════════════

class _CategoriesTab extends ConsumerStatefulWidget {
  const _CategoriesTab();

  @override
  ConsumerState<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<_CategoriesTab> {
  int _selectedMonthsBack = 0;
  bool _showByTransactions = false; // false = top spending, true = top tx count

  /// Selected month / budget period (see [reportRangeFor]).
  DateTime get _bucket => _reportMonth(_selectedMonthsBack);
  DateTime get _periodStart => reportRangeFor(_bucket, _reportsStartDay).start;

  /// Exclusive.
  DateTime get _periodEnd => reportRangeFor(_bucket, _reportsStartDay).end;

  void _showCategoryTransactions(
    BuildContext context, {
    required String categoryName,
    Category? category,
    required Color color,
    required List<TransactionEntry> transactions,
    required Map<String, Category> categoryMap,
  }) {
    final uncategorized = S.of(context).commonUncategorized;
    // Only this category's share of each transaction (a split's other
    // lines belong to other rows) — matched by name like the row totals.
    double partFor(TransactionEntry e) {
      var sum = 0.0;
      _baseAmountByCategory(e).forEach((catId, amount) {
        final cat = catId != null ? categoryMap[catId] : null;
        if ((cat?.name ?? uncategorized) == categoryName) sum += amount;
      });
      return sum;
    }

    final parts = <TransactionEntry, double>{};
    for (final e in transactions) {
      final part = partFor(e);
      if (part != 0) parts[e] = part;
    }
    final catTxns = parts.keys.toList()
      ..sort((a, b) => b.tx.createdAt.compareTo(a.tx.createdAt));

    hapticLight();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 20),
              child: Row(
                children: [
                  CategoryIcon(
                    categoryName: categoryName,
                    emoji: category?.icon,
                    color: color,
                    size: CategoryIconTokens.compactSize,
                    circular: true,
                  ),
                  Expanded(
                    child: SheetTitle(
                      categoryName,
                      subtitle: S.of(ctx).reportsTxCount(catTxns.length),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          12, 20, 20, 12),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.bd(ctx)),
            Expanded(
              child: catTxns.isEmpty
                  ? EmptyState(
                      icon: AppIcons.receipt,
                      title: S.of(ctx).reportsNoExpenses)
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.only(
                          top: Spacing.sm, bottom: Spacing.xl),
                      itemCount: catTxns.length,
                      // Rows drawn like TxTile, but with this category's
                      // share of a split (TxTile shows the whole amount).
                      itemBuilder: (_, i) => _CategoryTxRow(
                        entry: catTxns[i],
                        amount: parts[catTxns[i]]!,
                        category: category,
                        categoryName: categoryName,
                        color: color,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionEntriesProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final categoryMap = {for (final c in categories) c.id: c};

    return txAsync.when(
      data: (entries) {
        // [start, end): a transaction at 00:00 on the 1st belongs here.
        final filtered = entries
            .where((e) =>
                e.tx.type == 'expense' &&
                !e.tx.createdAt.isBefore(_periodStart) &&
                e.tx.createdAt.isBefore(_periodEnd))
            .toList();
        final uncategorized = S.of(context).commonUncategorized;

        // Aggregate by category
        final catSpend = <String, double>{};
        final catCount = <String, int>{};
        final catColors = <String, Color>{};
        final catObjs = <String, Category>{};

        for (final e in filtered) {
          final names = <String>{};
          _baseAmountByCategory(e).forEach((catId, amount) {
            final cat = catId != null ? categoryMap[catId] : null;
            final name = cat?.name ?? uncategorized;
            catSpend[name] = (catSpend[name] ?? 0) + amount;
            names.add(name);
            if (cat != null && !catColors.containsKey(name)) {
              catColors[name] = AppColors.fromHex(cat.colorHex);
              catObjs[name] = cat;
            }
          });
          // A transaction counts once per category it touches.
          for (final name in names) {
            catCount[name] = (catCount[name] ?? 0) + 1;
          }
        }

        // Compute last month's spend per category for comparison
        final prevMonthStart = reportRangeFor(
                DateTime(_bucket.year, _bucket.month - 1, 1), _reportsStartDay)
            .start;
        final lastMonthSpend = <String, double>{};
        for (final e in entries) {
          if (e.tx.type != 'expense') continue;
          final d = e.tx.createdAt;
          if (!d.isBefore(prevMonthStart) && d.isBefore(_periodStart)) {
            _baseAmountByCategory(e).forEach((catId, amount) {
              final cat = catId != null ? categoryMap[catId] : null;
              final name = cat?.name ?? uncategorized;
              lastMonthSpend[name] = (lastMonthSpend[name] ?? 0) + amount;
            });
          }
        }

        final sortedBySpend = catSpend.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final sortedByCount = catCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return _MonthSwipe(
          onPrev: () => setState(() => _selectedMonthsBack++),
          onNext: _selectedMonthsBack > 0
              ? () => setState(() => _selectedMonthsBack--)
              : null,
          child: Column(
          children: [
            // Month selector
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: MonthNav(
                label: _periodLabel(_bucket),
                onPrev: () => setState(() => _selectedMonthsBack++),
                onNext: _selectedMonthsBack > 0
                    ? () => setState(() => _selectedMonthsBack--)
                    : null,
              ),
            ),
            // Toggle tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  AppChip(
                    label: S.of(context).reportsTopSpending,
                    selected: !_showByTransactions,
                    onTap: () =>
                        setState(() => _showByTransactions = false),
                  ),
                  const SizedBox(width: Spacing.sm),
                  AppChip(
                    label: S.of(context).reportsTopTransactions,
                    selected: _showByTransactions,
                    onTap: () =>
                        setState(() => _showByTransactions = true),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: filtered.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () => _refreshReports(ref),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          EmptyState(
                              icon: AppIcons.chartPie,
                              title: S.of(context).reportsNoExpenses),
                        ],
                      ),
                    )
                  : Builder(builder: (context) {
                      final rows = _showByTransactions
                          ? [
                              for (final e in sortedByCount)
                                MapEntry(e.key, catSpend[e.key] ?? 0.0)
                            ]
                          : sortedBySpend;
                      final total =
                          catSpend.values.fold<double>(0, (a, b) => a + b);
                      final colors = _distinctColors([
                        for (final r in rows)
                          catColors[r.key] ?? AppColors.accent
                      ]);
                      return RefreshIndicator(
                        onRefresh: () => _refreshReports(ref),
                        child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: rows.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return _CategoryPie(
                              values: [for (final r in rows) r.value],
                              colors: colors,
                              total: total,
                              onSliceTap: (j) => _showCategoryTransactions(
                                context,
                                categoryName: rows[j].key,
                                category: catObjs[rows[j].key],
                                color: colors[j],
                                transactions: filtered,
                                categoryMap: categoryMap,
                              ),
                            );
                          }
                          final entry = rows[i - 1];
                          final color = colors[i - 1];
                          return _CategoryRow(
                            name: entry.key,
                            category: catObjs[entry.key],
                            value: S.of(context)
                                .reportsTxCount(catCount[entry.key] ?? 0),
                            amount: entry.value,
                            share: total > 0 ? entry.value / total : 0,
                            color: color,
                            lastMonthAmount: lastMonthSpend[entry.key],
                            onTap: () => _showCategoryTransactions(
                              context,
                              categoryName: entry.key,
                              category: catObjs[entry.key],
                              color: color,
                              transactions: filtered,
                              categoryMap: categoryMap,
                            ),
                          );
                        },
                      ));
                    }),
            ),
          ],
          ),
        );
      },
      loading: () => const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(), child: SkeletonList()),
      error: (e, _) => ErrorRetry(
        message: S.of(context).commonCouldntLoadData,
        details: '$e',
        onRetry: () => ref.invalidate(transactionEntriesProvider),
      ),
    );
  }
}

/// One transaction in the category sheet: TxTile's layout (category emoji,
/// title, date) with this category's part of the amount.
class _CategoryTxRow extends StatelessWidget {
  const _CategoryTxRow({
    required this.entry,
    required this.amount,
    required this.category,
    required this.categoryName,
    required this.color,
  });

  final TransactionEntry entry;
  final double amount;
  final Category? category;
  final String categoryName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tx = entry.tx;
    final hasNote = tx.note.isNotEmpty;
    return Tappable(
      // Opens the transaction over the sheet.
      onTap: () => context.push('/transactions/${tx.id}'),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
        child: Row(
          children: [
            CategoryIcon(
              categoryName: categoryName,
              emoji: category?.icon,
              color: color,
              size: CategoryIconTokens.compactSize,
              circular: true,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasNote ? visibleNote(tx.note) : categoryName,
                    style: TextStyle(
                      fontSize: TypographyTokens.txTitleSize,
                      fontWeight: TypographyTokens.txTitleWeight,
                      color: AppColors.tp(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDate(tx.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: TypographyTokens.txSubtitleSize,
                      color: AppColors.ts(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              formatAmount(amount, currency: _reportsBaseCurrency),
              style: TextStyle(
                fontSize: TypographyTokens.amountRegularSize,
                fontWeight: TypographyTokens.amountRegularWeight,
                color: AppColors.tp(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subcategories share their parent's color — shift the shade each time a
/// color repeats so slices and bars stay distinguishable.
List<Color> _distinctColors(List<Color> base) {
  final seen = <int, int>{};
  return [
    for (final c in base)
      () {
        final n = seen.update(c.toARGB32(), (v) => v + 1, ifAbsent: () => 0);
        return AppColors.repeatShade(c, n);
      }(),
  ];
}

/// Cashew-style donut above the category list, total in the middle.
class _CategoryPie extends StatelessWidget {
  const _CategoryPie({
    required this.values,
    required this.colors,
    required this.total,
    this.onSliceTap,
  });

  final List<double> values;
  final List<Color> colors;
  final double total;

  /// Tapping a slice opens that category's transactions.
  final ValueChanged<int>? onSliceTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: SizedBox(
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 68,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final i = response?.touchedSection?.touchedSectionIndex;
                  if (event is FlTapUpEvent && i != null && i >= 0) {
                    onSliceTap?.call(i);
                  }
                },
              ),
              sections: [
                for (var i = 0; i < values.length; i++)
                  PieChartSectionData(
                    value: values[i],
                    color: colors[i],
                    radius: 34,
                    showTitle: false,
                  ),
              ],
            )),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatAmount(total, currency: _reportsBaseCurrency),
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: TypographyTokens.displayFamily,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tp(context),
                      ),
                    ),
                  ),
                ),
                Text(
                  S.of(context).dashboardSpent,
                  style: TextStyle(
                      fontSize: TypographyTokens.amountSmallSize,
                      color: AppColors.ts(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cashew CategoryEntry: icon, name + amount, a thin bar for the category's
/// share of the month, then share + count + month-over-month change.
class _CategoryRow extends StatelessWidget {
  final String name;
  final Category? category;
  final String value;
  final double amount;
  final double share;
  final Color color;
  final VoidCallback? onTap;
  final double? lastMonthAmount;

  const _CategoryRow({
    required this.name,
    this.category,
    required this.value,
    required this.amount,
    required this.share,
    required this.color,
    this.onTap,
    this.lastMonthAmount,
  });

  @override
  Widget build(BuildContext context) {
    // Month-over-month comparison
    Widget? comparisonWidget;
    if (lastMonthAmount != null) {
      final last = lastMonthAmount!;
      if (last > 0 && amount > 0) {
        final pctChange = ((amount - last) / last * 100).round();
        if (pctChange != 0) {
          final up = pctChange > 0;
          comparisonWidget = Text(
            '${up ? '↑' : '↓'} ${pctChange.abs()}%',
            style: TextStyle(
                fontSize: TypographyTokens.captionSize,
                fontWeight: FontWeight.w700,
                color: up ? AppColors.overspent : AppColors.healthy),
          );
        }
      } else if (last == 0 && amount > 0) {
        comparisonWidget = Text(
          S.of(context).reportsNewBadge,
          style: TextStyle(
              fontSize: TypographyTokens.overlineSize,
              fontWeight: FontWeight.w800,
              color: AppColors.accentText(context)),
        );
      }
    }

    return Tappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 8),
          child: Row(
            children: [
              CategoryIcon(
                categoryName: name,
                emoji: category?.icon,
                color: color,
                size: CategoryIconTokens.listSize,
                circular: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: TypographyTokens.txTitleSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tp(context))),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            formatAmount(amount,
                                currency: _reportsBaseCurrency),
                            style: TextStyle(
                                fontSize: TypographyTokens.amountRegularSize,
                                fontWeight: FontWeight.w800,
                                color: AppColors.tp(context))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    BudgetProgress(
                      progress: share,
                      color: color,
                      height: 6,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text('${(share * 100).round()}%',
                            style: TextStyle(
                                fontSize: TypographyTokens.captionSize,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ts(context))),
                        Flexible(
                          child: Text(' · $value',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: TypographyTokens.captionSize,
                                  color: AppColors.ts(context))),
                        ),
                        const Spacer(),
                        if (comparisonWidget != null) comparisonWidget,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Tab 5: Insights (analytics moved from dashboard)
// ═════════════════════════════════════════════════════════════════════════════

class _InsightsTab extends ConsumerStatefulWidget {
  const _InsightsTab();

  @override
  ConsumerState<_InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends ConsumerState<_InsightsTab> {
  int _selectedMonthsBack = 0;

  DateTime get _month {
    return _reportMonth(_selectedMonthsBack);
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionEntriesProvider);
    final baseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final categories = ref.watch(categoriesProvider).value ?? [];
    final categoryMap = {for (final c in categories) c.id: c};
    final allocationsAsync = ref.watch(allocationsProvider);
    final ageAsync = ref.watch(ageOfMoneyProvider);

    return txAsync.when(
      data: (entries) {
        final now = DateTime.now();
        final monthStart = reportRangeFor(_month, _reportsStartDay).start;
        final isCurrentMonth =
            monthStart.year == now.year && monthStart.month == now.month;
        final daysInMonth = DateUtils.getDaysInMonth(monthStart.year, monthStart.month);
        final daysElapsed = isCurrentMonth
            ? calendarDaysBetween(monthStart, now) + 1
            : daysInMonth;

        // ── Spending velocity ──
        double monthExpense = 0;
        final monthEnd = reportRangeFor(_month, _reportsStartDay).end;
        for (final e in entries) {
          if (e.tx.type == 'expense' &&
              !e.tx.createdAt.isBefore(monthStart) &&
              e.tx.createdAt.isBefore(monthEnd)) {
            monthExpense += _baseAmount(e);
          }
        }

        final dailyRate =
            monthExpense > 0 ? monthExpense / daysElapsed : 0.0;
        final projected = dailyRate * daysInMonth;

        final allocs = allocationsAsync.value ?? [];
        // Base-currency targets only — never add up amounts in different
        // currencies.
        double totalBudget = 0;
        for (final a in allocs) {
          final alloc = a.data.allocation;
          final t = alloc.targetAmount;
          if ((alloc.targetCurrency ?? baseCurrency) != baseCurrency) continue;
          if (t != null && t > 0) totalBudget += t;
        }

        Color velocityColor;
        if (totalBudget <= 0) {
          velocityColor = AppColors.accent;
        } else if (projected <= totalBudget * 0.85) {
          velocityColor = AppColors.healthy;
        } else if (projected <= totalBudget) {
          velocityColor = AppColors.caution;
        } else {
          velocityColor = AppColors.overspent;
        }

        final velocityFraction = totalBudget > 0
            ? (projected / totalBudget).clamp(0.0, 1.5)
            : 0.0;

        // ── Biggest expense ──
        TransactionEntry? biggest;
        double biggestAmt = 0;
        for (final e in entries) {
          if (e.tx.type == 'expense' &&
              !e.tx.createdAt.isBefore(monthStart) &&
              e.tx.createdAt.isBefore(monthEnd)) {
            final amt = _baseAmount(e);
            if (amt > biggestAmt) {
              biggestAmt = amt;
              biggest = e;
            }
          }
        }

        // ── Subscription summary ──
        final householdId = ref.watch(currentHouseholdIdProvider);
        final db = ref.watch(databaseProvider);

        // ── Age of money ──
        final ageValue = ageAsync.value;

        // ── Income + savings rate ──
        double totalIncome = 0;
        for (final e in entries) {
          if (e.tx.type == 'income' &&
              !e.tx.createdAt.isBefore(monthStart) &&
              e.tx.createdAt.isBefore(monthEnd)) {
            totalIncome += _baseAmount(e);
          }
        }
        final savingsRate =
            totalIncome > 0 ? (totalIncome - monthExpense) / totalIncome : 0.0;

        // ── Actionable tips ──
        final l = S.of(context);
        final tips = <String>[];
        if (totalBudget > 0 && projected > totalBudget) {
          tips.add(l.reportsTipOverPace(formatAmount(projected - totalBudget, currency: baseCurrency)));
        } else if (totalBudget > 0 && projected <= totalBudget * 0.85) {
          tips.add(l.reportsTipUnderPace(formatAmount(totalBudget - projected, currency: baseCurrency)));
        }
        if (savingsRate > 0.2) {
          tips.add(l.reportsTipSavingHigh((savingsRate * 100).round()));
        } else if (savingsRate < 0.05 && totalIncome > 0) {
          tips.add(l.reportsTipSavingLow((savingsRate * 100).round()));
        }
        if (ageValue != null && ageValue < 15) {
          tips.add(l.reportsTipAgeLow(ageValue));
        }

        return _MonthSwipe(
          onPrev: () => setState(() => _selectedMonthsBack++),
          onNext: _selectedMonthsBack > 0
              ? () => setState(() => _selectedMonthsBack--)
              : null,
          child: _RefreshableScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month navigator
              MonthNav(
                label: _periodLabel(_month),
                onPrev: () => setState(() => _selectedMonthsBack++),
                onNext: _selectedMonthsBack > 0
                    ? () => setState(() => _selectedMonthsBack--)
                    : null,
              ),
              const SizedBox(height: Spacing.md),
              if (monthExpense == 0 && totalIncome == 0) ...[
                EmptyState(
                  icon: AppIcons.lightbulb,
                  title: S.of(context).reportsNothingThisMonth,
                  subtitle: S.of(context).reportsNothingThisMonthHint,
                ),
                const SizedBox(height: Spacing.sectionGap),
              ],
              // ── Spending Velocity ──
              if (monthExpense > 0) ...[
                _VelocityCard(
                  dailyRate: dailyRate,
                  projected: projected,
                  totalBudget: totalBudget,
                  velocityColor: velocityColor,
                  velocityFraction: velocityFraction,
                  baseCurrency: baseCurrency,
                  daysElapsed: daysElapsed,
                  daysInMonth: daysInMonth,
                ),
                const SizedBox(height: 16),
              ],

              // ── Biggest Expense ──
              if (biggest != null) ...[
                _BiggestExpenseCard(
                  entry: biggest,
                  amount: biggestAmt,
                  categoryMap: categoryMap,
                  baseCurrency: baseCurrency,
                ),
                const SizedBox(height: 16),
              ],

              // ── Savings Rate ──
              if (totalIncome > 0) ...[
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: CategoryIconTokens.compactSize,
                        height: CategoryIconTokens.compactSize,
                        decoration: BoxDecoration(
                          color: AppColors.pastel(context, savingsRate >= 0.1
                                  ? AppColors.healthy
                                  : AppColors.caution,
                                  light: 0.85, dark: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(AppIcons.piggyBank,
                            size: 20,
                            color: savingsRate >= 0.1
                                ? AppColors.healthy
                                : AppColors.caution),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.of(context).reportsSavingsRate,
                                style: TextStyle(
                                    fontSize: TypographyTokens.captionSize,
                                    color: AppColors.ts(context))),
                            Text('${(savingsRate * 100).round()}%',
                                style: TextStyle(
                                    fontSize: TypographyTokens.amountDisplaySize,
                                    fontFamily: TypographyTokens.displayFamily,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.tp(context))),
                          ],
                        ),
                      ),
                      Text(
                        formatAmount(totalIncome - monthExpense,
                            currency: baseCurrency),
                        style: TextStyle(
                          fontSize: TypographyTokens.amountRegularSize,
                          fontWeight: TypographyTokens.amountRegularWeight,
                          color: savingsRate >= 0
                              ? ref.watch(txColorsProvider).income
                              : ref.watch(txColorsProvider).expense,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Subscription Summary ──
              if (householdId != null)
                _SubscriptionSummaryCard(
                  db: db,
                  householdId: householdId,
                  baseCurrency: baseCurrency,
                ),

              // ── Age of Money ──
              if (ageValue != null) ...[
                _AgeOfMoneyCard(age: ageValue),
                const SizedBox(height: 16),
              ],

              // ── Actionable Tips ──
              if (tips.isNotEmpty) ...[
                SectionHeader(S.of(context).reportsTipsSection,
                padding: const EdgeInsetsDirectional.only(
                    start: 4, bottom: Spacing.headerToCard)),
                ...tips.map((tip) => Container(
                      margin: const EdgeInsets.only(bottom: Spacing.sm),
                      padding: CardTokens.padding,
                      decoration: BoxDecoration(
                        color: AppColors.pastel(context, AppColors.accent,
                            light: 0.88, dark: 0.8),
                        borderRadius: BorderRadius.circular(CardTokens.radius),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(AppIcons.lightbulb,
                              size: 16, color: AppColors.accentText(context)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(tip,
                                style: TextStyle(
                                    fontSize: TypographyTokens.amountSmallSize,
                                    color: AppColors.tp(context),
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        );
      },
      loading: () => const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(), child: SkeletonList()),
      error: (e, _) => ErrorRetry(
        message: S.of(context).commonCouldntLoadData,
        details: '$e',
        onRetry: () => ref.invalidate(transactionEntriesProvider),
      ),
    );
  }
}

// ── Spending Velocity Card (full detail) ────────────────────────────────────

class _VelocityCard extends StatelessWidget {
  final double dailyRate;
  final double projected;
  final double totalBudget;
  final Color velocityColor;
  final double velocityFraction;
  final String baseCurrency;
  final int daysElapsed;
  final int daysInMonth;

  const _VelocityCard({
    required this.dailyRate,
    required this.projected,
    required this.totalBudget,
    required this.velocityColor,
    required this.velocityFraction,
    required this.baseCurrency,
    required this.daysElapsed,
    required this.daysInMonth,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.gauge, size: 18, color: velocityColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(S.of(context).reportsVelocityTitle,
                    style: _cardTitleStyle(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          if (totalBudget > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: velocityFraction.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppColors.pastel(context, velocityColor,
                    light: 0.88, dark: 0.75),
                valueColor: AlwaysStoppedAnimation(velocityColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context).reportsProjected,
                    style: TextStyle(
                        fontSize: TypographyTokens.captionSize,
                        color: AppColors.ts(context))),
                Text(S.of(context).reportsBudget,
                    style: TextStyle(
                        fontSize: TypographyTokens.captionSize,
                        color: AppColors.ts(context))),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatAmount(projected, currency: baseCurrency),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: velocityColor)),
                Text(formatAmount(totalBudget, currency: baseCurrency),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(context))),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              _VelocityStat(
                  label: S.of(context).reportsDailyRate,
                  value:
                      S.of(context).commonPerDay(
                          formatAmount(dailyRate, currency: baseCurrency))),
              const SizedBox(width: 16),
              _VelocityStat(
                  label: S.of(context).reportsDay,
                  value: S.of(context).commonNOfM(daysElapsed, daysInMonth)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VelocityStat extends StatelessWidget {
  final String label;
  final String value;
  const _VelocityStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: TypographyTokens.overlineSize,
                color: AppColors.ts(context))),
        Text(value,
            style: TextStyle(
                fontSize: TypographyTokens.amountSmallSize,
                fontWeight: TypographyTokens.amountSmallWeight,
                color: AppColors.tp(context))),
      ],
    );
  }
}

// ── Biggest Expense Card ────────────────────────────────────────────────────

class _BiggestExpenseCard extends ConsumerWidget {
  final TransactionEntry entry;
  final double amount;
  final Map<String, Category> categoryMap;
  final String baseCurrency;

  const _BiggestExpenseCard({
    required this.entry,
    required this.amount,
    required this.categoryMap,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = entry.tx.categoryId != null
        ? categoryMap[entry.tx.categoryId]
        : null;
    final catName = cat?.name ??
        (entry.tx.note.isNotEmpty
            ? visibleNote(entry.tx.note)
            : S.of(context).typeExpense);
    final expenseColor = ref.watch(txColorsProvider).expense;
    final catColor = cat != null
        ? AppColors.fromHex(cat.colorHex)
        : expenseColor;

    return AppCard(
      onTap: () => context.push('/transactions/${entry.tx.id}'),
        child: Row(
          children: [
            CategoryIcon(
              categoryName: cat?.name ?? '',
              emoji: cat?.icon,
              color: catColor,
              size: CategoryIconTokens.compactSize,
              circular: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.of(context).reportsBiggestExpense,
                      style: TextStyle(
                          fontSize: TypographyTokens.captionSize,
                          color: AppColors.ts(context))),
                  Text(catName, style: _cardTitleStyle(context)),
                  if (entry.tx.note.isNotEmpty && cat != null)
                    Text(visibleNote(entry.tx.note),
                        style: TextStyle(
                            fontSize: TypographyTokens.captionSize,
                            color: AppColors.ts(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(formatAmount(amount, currency: baseCurrency),
                style: TextStyle(
                    fontSize: TypographyTokens.amountDisplaySize,
                    fontFamily: TypographyTokens.displayFamily,
                    fontWeight: TypographyTokens.amountDisplayWeight,
                    color: expenseColor)),
            const SizedBox(width: 4),
            Icon(AppIcons.caretRight,
                size: 18, color: AppColors.th(context)),
          ],
        ),
    );
  }
}

// ── Subscription Summary Card ───────────────────────────────────────────────

class _SubscriptionSummaryCard extends ConsumerWidget {
  final AppDatabase db;
  final String householdId;
  final String baseCurrency;

  const _SubscriptionSummaryCard({
    required this.db,
    required this.householdId,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<RecurringTransaction>>(
      future: (db.select(db.recurringTransactions)
            ..where((r) =>
                r.householdId.equals(householdId) &
                r.enabled.equals(true) &
                r.deleted.equals(false)))
          .get(),
      builder: (context, snap) {
        final recs = snap.data;
        if (recs == null || recs.isEmpty) return const SizedBox.shrink();

        // Base-currency subscriptions only — never add up amounts in
        // different currencies.
        double total = 0;
        for (final r in recs) {
          if (r.currency != baseCurrency) continue;
          final interval = r.interval > 0 ? r.interval : 1;
          double monthly = r.amount;
          switch (r.frequency) {
            case 'daily':
              monthly = r.amount * 30 / interval;
            case 'weekly':
              monthly = r.amount * 4.33 / interval;
            case 'monthly':
              monthly = r.amount / interval;
            case 'yearly':
              monthly = r.amount / (12 * interval);
          }
          total += monthly;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            onTap: () => context.push('/recurring'),
              child: Row(
                children: [
                  Container(
                    width: CategoryIconTokens.compactSize,
                    height: CategoryIconTokens.compactSize,
                    decoration: BoxDecoration(
                      color: AppColors.pastel(context, AppColors.accent,
                          light: 0.85, dark: 0.78),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppIcons.arrowsClockwise,
                        size: 18, color: AppColors.accentText(context)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.of(context).reportsRecurringTitle,
                            style: _cardTitleStyle(context)),
                        Text(
                            S.of(context).reportsRecurringSummary(
                                recs.length,
                                formatAmount(total, currency: baseCurrency)),
                            style: TextStyle(
                                fontSize: TypographyTokens.captionSize,
                                color: AppColors.ts(context))),
                      ],
                    ),
                  ),
                  Icon(AppIcons.caretRight,
                      size: 18, color: AppColors.th(context)),
                ],
              ),
          ),
        );
      },
    );
  }
}

// ── Age of Money Card (full detail) ─────────────────────────────────────────

class _AgeOfMoneyCard extends StatelessWidget {
  final int age;
  const _AgeOfMoneyCard({required this.age});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final String description;
    if (age >= 30) {
      color = AppColors.healthy;
      label = S.of(context).reportsAgeExcellent;
      description = S.of(context).reportsAgeExcellentDesc;
    } else if (age >= 15) {
      color = AppColors.caution;
      label = S.of(context).reportsAgeGettingThere;
      description = S.of(context).reportsAgeGettingDesc;
    } else {
      color = AppColors.overspent;
      label = S.of(context).reportsAgeNeedsWork;
      description = S.of(context).reportsAgeNeedsDesc;
    }

    // Gauge value (target is 30 days)
    final gaugeFraction = (age / 30.0).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(AppIcons.clock, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(S.of(context).reportsAgeTitle,
                    style: _cardTitleStyle(context)),
              ),
              Text(S.of(context).reportsAgeDays(age),
                  style: TextStyle(
                      fontSize: TypographyTokens.amountDisplaySize,
                      fontFamily: TypographyTokens.displayFamily,
                      fontWeight: TypographyTokens.amountDisplayWeight,
                      color: color)),
            ],
          ),
          const SizedBox(height: 12),
          // Gauge bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: gaugeFraction,
              minHeight: 10,
              backgroundColor:
                  AppColors.pastel(context, color, light: 0.88, dark: 0.75),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
              Text(S.of(context).reportsAgeGoal,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.ts(context))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.ts(context),
                height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).reportsAgeExplanation,
            style: TextStyle(
                fontSize: 11,
                color: AppColors.th(context),
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared small widgets
// ═════════════════════════════════════════════════════════════════════════════

/// The navigator label: "October 2026", or a budget period's date range
/// ("25 Sep – 24 Oct").
String _periodLabel(DateTime month) {
  if (_reportsStartDay == null) return formatMonth(month, year: true);
  final r = reportRangeFor(month, _reportsStartDay);
  final f = DateFormat('d MMM');
  return '${f.format(r.start)} – '
      '${f.format(r.end.subtract(const Duration(days: 1)))}';
}

/// Horizontal swipe = previous / next month (mirrored in RTL).
class _MonthSwipe extends StatelessWidget {
  const _MonthSwipe({required this.onPrev, this.onNext, required this.child});

  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      dragStartBehavior: DragStartBehavior.start,
      onHorizontalDragEnd: (details) {
        final dx = details.primaryVelocity ?? 0;
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final goPrev = isRtl ? dx < 0 : dx > 0;
        final goNext = isRtl ? dx > 0 : dx < 0;
        if (goPrev) {
          onPrev();
          hapticLight();
        } else if (goNext && onNext != null) {
          onNext!();
          hapticLight();
        }
      },
      child: child,
    );
  }
}

/// A tab's scrolling body with pull-to-refresh (re-reads the transactions
/// and balances every report is built from).
class _RefreshableScroll extends ConsumerWidget {
  const _RefreshableScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _refreshReports(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        child: child,
      ),
    );
  }
}

Future<void> _refreshReports(WidgetRef ref) async {
  ref.invalidate(transactionEntriesProvider);
  ref.invalidate(accountsWithBalanceProvider);
  ref.invalidate(allocationsProvider);
  ref.invalidate(ageOfMoneyProvider);
  await Future.delayed(const Duration(milliseconds: 300));
}

/// A report card with the standard card title (and an optional trailing
/// widget on the title row).
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, this.trailing, required this.child});

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(title, style: _cardTitleStyle(context))),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: Spacing.md),
          child,
        ],
      ),
    );
  }
}

/// The empty card a chart shows when it has nothing to draw.
class _EmptyChartCard extends StatelessWidget {
  const _EmptyChartCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: SizedBox(
        height: 120,
        child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: AppColors.ts(context))),
        ),
      ),
    );
  }
}

/// The one card-title style on Reports (and Home).
TextStyle _cardTitleStyle(BuildContext context) => TextStyle(
      fontSize: TypographyTokens.cardTitleSize,
      fontWeight: TypographyTokens.cardTitleWeight,
      color: AppColors.tp(context),
    );

// ═════════════════════════════════════════════════════════════════════════════
// Balance Sheet Tab
// ═════════════════════════════════════════════════════════════════════════════

class _BalanceSheetTab extends ConsumerStatefulWidget {
  const _BalanceSheetTab();

  @override
  ConsumerState<_BalanceSheetTab> createState() => _BalanceSheetTabState();
}

class _BalanceSheetTabState extends ConsumerState<_BalanceSheetTab> {
  late DateTime _compareDate;

  @override
  void initState() {
    super.initState();
    // Default: end of last month
    final now = DateTime.now();
    _compareDate = DateTime(now.year, now.month, 0); // last day of prev month
  }

  String? _compareLabel;

  void _showComparePicker(BuildContext context) {
    final now = DateTime.now();
    final l = S.of(context);
    final options = <(String, DateTime)>[
      (l.reportsEndLastWeek,
          now.subtract(Duration(days: now.weekday)).subtract(const Duration(days: 0))),
      (l.reportsEndLastMonth, DateTime(now.year, now.month, 0)),
      (l.reportsSameTimeLastMonth, DateTime(now.year, now.month - 1, now.day)),
      (l.reportsEndLastQuarter, () {
        final qMonth = ((now.month - 1) ~/ 3) * 3;
        return qMonth > 0 ? DateTime(now.year, qMonth + 1, 0) : DateTime(now.year - 1, 12, 31);
      }()),
      (l.reportsEndLastYear, DateTime(now.year - 1, 12, 31)),
      (l.reportsSameTimeLastYear, DateTime(now.year - 1, now.month, now.day)),
      (l.reportsCustom, now),
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetTitle(l.reportsCompareTo),
              Divider(height: 1, color: AppColors.bd(ctx)),
              ...options.map((opt) => ListTile(
                    title: Text(opt.$1,
                        style: TextStyle(
                            fontSize: TypographyTokens.txTitleSize,
                            fontWeight: (_compareLabel ?? l.reportsEndLastMonth) == opt.$1
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: AppColors.tp(ctx))),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (opt.$1 == l.reportsCustom) {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _compareDate,
                          firstDate: now.subtract(const Duration(days: 730)),
                          lastDate: now,
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _compareDate = picked;
                            _compareLabel = formatDate(picked);
                          });
                        }
                      } else {
                        setState(() {
                          _compareDate = opt.$2;
                          _compareLabel = opt.$1;
                        });
                      }
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsWithBalanceProvider);
    final baseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final today = DateTime.now();

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return EmptyState(
              icon: AppIcons.wallet,
              title: S.of(context).healthNoAccounts);
        }

        // We need transaction data to compute historical balances
        return FutureBuilder<Map<String, double>>(
          future: _computeHistoricalBalances(accounts, _compareDate),
          builder: (context, snapshot) {
            final historicalBalances = snapshot.data ?? {};

            // Group accounts by type
            final assetTypes = ['cash', 'bank', 'wallet'];
            final liabilityTypes = ['credit'];

            final assets = accounts
                .where((a) => assetTypes.contains(a.account.type))
                .toList();
            final liabilities = accounts
                .where((a) => liabilityTypes.contains(a.account.type))
                .toList();

            // Totals — only sum base-currency accounts
            double totalAssetsNow = 0, totalAssetsCompare = 0;
            double totalLiabilitiesNow = 0, totalLiabilitiesCompare = 0;
            for (final a in assets) {
              if (a.account.currency == baseCurrency) {
                totalAssetsNow += a.balance;
                totalAssetsCompare += historicalBalances[a.account.id] ?? a.balance;
              }
            }
            for (final a in liabilities) {
              if (a.account.currency == baseCurrency) {
                totalLiabilitiesNow += a.balance;
                totalLiabilitiesCompare +=
                    historicalBalances[a.account.id] ?? a.balance;
              }
            }
            // Liability balances are signed (owed = negative), so add them:
            // an overpaid card (positive) raises net worth instead of
            // lowering it as `- abs()` did.
            final netWorthNow = totalAssetsNow + totalLiabilitiesNow;
            final netWorthCompare =
                totalAssetsCompare + totalLiabilitiesCompare;

            // Per-currency totals for foreign accounts
            final foreignTotals = <String, double>{};
            for (final a in accounts) {
              if (a.account.currency != baseCurrency) {
                foreignTotals[a.account.currency] =
                    (foreignTotals[a.account.currency] ?? 0) + a.balance;
              }
            }

            return RefreshIndicator(
              onRefresh: () => _refreshReports(ref),
              child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                // Compare period selector
                Center(
                  child: AppChip(
                    label: _compareLabel ?? S.of(context).reportsEndLastMonth,
                    icon: AppIcons.calendarBlank,
                    selected: false,
                    onTap: () => _showComparePicker(context),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // Date range display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDate(_compareDate),
                      style: TextStyle(
                          fontSize: TypographyTokens.captionSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ts(context)),
                    ),
                    Icon(AppIcons.arrowRight,
                        size: 14, color: AppColors.th(context)),
                    Text(
                      formatDate(today),
                      style: TextStyle(
                          fontSize: TypographyTokens.captionSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentText(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Assets section
                if (assets.isNotEmpty) ...[
                  _bsSectionHeader(context, S.of(context).reportsAssets,
                      totalAssetsCompare, totalAssetsNow, baseCurrency),
                  ..._groupByType(assets).entries.map((group) =>
                      _bsGroup(context, group.key, group.value,
                          historicalBalances, baseCurrency, totalAssetsNow)),
                ],

                // Liabilities section
                if (liabilities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _bsSectionHeader(context, S.of(context).reportsLiabilities,
                      totalLiabilitiesCompare, totalLiabilitiesNow,
                      baseCurrency),
                  ..._groupByType(liabilities).entries.map((group) =>
                      _bsGroup(context, group.key, group.value,
                          historicalBalances, baseCurrency,
                          totalLiabilitiesNow)),
                ],

                // Net Worth — the shared balance hero.
                const SizedBox(height: Spacing.xl),
                BalanceHero(
                  child: Column(
                    children: [
                      Text(S.of(context).reportsNetWorth,
                          style: balanceHeroLabelStyle(context)),
                      const SizedBox(height: Spacing.sm),
                      // Each side shares the width; a big amount shrinks
                      // to fit instead of overflowing the card.
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatAmount(netWorthCompare,
                                      currency: baseCurrency),
                                  style: TextStyle(
                                    fontSize: TypographyTokens.bodySize,
                                    color: AppColors.ts(context),
                                  ),
                                ),
                              ),
                              Text(
                                formatDate(_compareDate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: TypographyTokens.miniSize,
                                  color: AppColors.ts(context),
                                ),
                              ),
                            ]),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(AppIcons.arrowRight,
                                size: 16,
                                color: AppColors.th(context)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatAmount(netWorthNow,
                                      currency: baseCurrency),
                                  style: balanceHeroAmountStyle(context,
                                      value: netWorthNow),
                                ),
                              ),
                              Text(S.of(context).commonToday,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: TypographyTokens.miniSize,
                                      color: AppColors.ts(context))),
                            ]),
                          ),
                        ],
                      ),
                      // No percentage from zero.
                      if (netWorthCompare.abs() > 0.005) ...[
                        const SizedBox(height: 8),
                        _bsChangeChip(netWorthCompare, netWorthNow),
                      ],
                      // Foreign currency totals
                      if (foreignTotals.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Divider(
                            color: AppColors.bd(context),
                            height: 1),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: foreignTotals.entries.map((e) => Text(
                                formatAmount(e.value, currency: e.key),
                                style: TextStyle(
                                  fontSize: TypographyTokens.amountSmallSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ts(context),
                                ),
                              )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ));
          },
        );
      },
      loading: () => const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(), child: SkeletonList()),
      error: (e, _) => ErrorRetry(
        message: S.of(context).commonCouldntLoadAccounts,
        details: '$e',
        onRetry: () => ref.invalidate(accountsWithBalanceProvider),
      ),
    );
  }

  /// Accounts grouped by their type code ('cash', 'bank', …); the label and
  /// icon come from the code (account_type.dart), never the translated name.
  Map<String, List<AccountWithBalance>> _groupByType(
      List<AccountWithBalance> accounts) {
    final groups = <String, List<AccountWithBalance>>{};
    for (final a in accounts) {
      groups.putIfAbsent(a.account.type, () => []).add(a);
    }
    return groups;
  }

  Widget _bsSectionHeader(BuildContext context, String label,
      double compareTotal, double nowTotal, String currency) {
    return SectionHeader(
      label,
      padding: const EdgeInsetsDirectional.fromSTEB(
          4, 0, 4, Spacing.headerToCard),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatAmount(compareTotal, currency: currency),
              style: TextStyle(
                  fontSize: TypographyTokens.overlineSize,
                  color: AppColors.ts(context))),
          const SizedBox(width: Spacing.xs),
          Icon(AppIcons.arrowRight, size: 12, color: AppColors.th(context)),
          const SizedBox(width: Spacing.xs),
          Text(formatAmount(nowTotal, currency: currency),
              style: TextStyle(
                  fontSize: TypographyTokens.overlineSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context))),
        ],
      ),
    );
  }

  Widget _bsGroup(
    BuildContext context,
    String type,
    List<AccountWithBalance> accounts,
    Map<String, double> historicalBalances,
    String baseCurrency,
    double sectionTotal,
  ) {
    // Split into base-currency and foreign accounts
    final baseAccounts =
        accounts.where((a) => a.account.currency == baseCurrency).toList();
    final foreignAccounts =
        accounts.where((a) => a.account.currency != baseCurrency).toList();

    // Group total from base-currency accounts only
    double groupNow = 0, groupCompare = 0;
    for (final a in baseAccounts) {
      groupNow += a.balance;
      groupCompare += historicalBalances[a.account.id] ?? a.balance;
    }
    final pct = sectionTotal != 0
        ? ((groupNow / sectionTotal) * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      decoration: AppColors.card(context),
      child: Column(
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(accountTypeIcon(type),
                    size: 16, color: accountTypeColor(type)),
                const SizedBox(width: 8),
                Text(accountTypeLabel(S.of(context), type),
                    style: _cardTitleStyle(context)),
                if (baseAccounts.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('$pct%',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.ts(context))),
                ],
                const Spacer(),
                if (baseAccounts.isNotEmpty) ...[
                  Text(formatAmount(groupCompare, currency: baseCurrency),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.ts(context))),
                  const SizedBox(width: 12),
                  Text(formatAmount(groupNow, currency: baseCurrency),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context))),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.bd(context)),
          // Base-currency account rows (with percentages)
          ...baseAccounts.map((a) {
            final now = a.balance;
            final compare = historicalBalances[a.account.id] ?? now;
            final acctPct = sectionTotal != 0
                ? ((now / sectionTotal) * 100).round()
                : 0;
            return _bsAccountRow(
                context, a, compare, now, baseCurrency, '$acctPct%');
          }),
          // Foreign-currency account rows (no percentage, own currency)
          ...foreignAccounts.map((a) {
            final now = a.balance;
            final compare = historicalBalances[a.account.id] ?? now;
            return _bsAccountRow(
                context, a, compare, now, baseCurrency, a.account.currency);
          }),
        ],
      ),
    );
  }

  Widget _bsAccountRow(BuildContext context, AccountWithBalance a,
      double compare, double now, String baseCurrency, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Name + badge
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: Text(a.account.name,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.tp(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                Text(badge,
                    style: TextStyle(
                        fontSize: 10, color: AppColors.ts(context))),
              ],
            ),
          ),
          // Compare balance
          Expanded(
            flex: 2,
            child: Text(
              formatAmount(compare, currency: a.account.currency),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, color: AppColors.ts(context)),
            ),
          ),
          const SizedBox(width: 8),
          // Current balance
          Expanded(
            flex: 2,
            child: Text(
              formatAmount(now, currency: a.account.currency),
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tp(context)),
            ),
          ),
          const SizedBox(width: 4),
          _bsChangeIndicator(compare, now),
        ],
      ),
    );
  }

  Widget _bsChangeIndicator(double compare, double now) {
    if (compare == 0 && now == 0) {
      return Text('—',
          style: TextStyle(fontSize: 10, color: AppColors.th(context)));
    }
    final diff = now - compare;
    if (diff.abs() < 0.01) {
      return Text('—',
          style: TextStyle(fontSize: 10, color: AppColors.th(context)));
    }
    return Icon(
      diff > 0 ? AppIcons.arrowUp : AppIcons.arrowDown,
      size: 14,
      color: diff > 0 ? AppColors.healthy : AppColors.overspent,
    );
  }

  Widget _bsChangeChip(double compare, double now) {
    final diff = now - compare;
    final isUp = diff >= 0;
    final pct = compare != 0 ? ((diff / compare.abs()) * 100) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pastel(context,
            isUp ? AppColors.healthy : AppColors.overspent,
            light: 0.85, dark: 0.75),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? AppIcons.trendUp : AppIcons.trendDown,
            size: 14,
            color: isUp ? AppColors.healthy : AppColors.overspent,
          ),
          const SizedBox(width: 4),
          Text(
            // Sign spelled out: formatNumber may render negatives as (5.0).
            '${isUp ? '+' : '−'}${formatNumber(pct.abs(), decimals: 1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isUp ? AppColors.healthy : AppColors.overspent,
            ),
          ),
        ],
      ),
    );
  }


  /// Compute what each account's balance was at a historical date.
  /// Takes current balance and reverses all transactions after that date.
  /// Uses batched queries instead of N+1 per-account loops.
  Future<Map<String, double>> _computeHistoricalBalances(
      List<AccountWithBalance> accounts, DateTime asOfDate) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return {};

    final result = <String, double>{};
    final acctIds = accounts.map((a) => a.account.id).toSet();

    // Batch 1: all non-deleted transactions after the date for this household
    final txsAfter = await (db.select(db.transactions)
          ..where((t) =>
              t.householdId.equals(householdId) &
              t.deleted.equals(false) &
              t.status.isNull() &
              t.createdAt.isBiggerThanValue(asOfDate)))
        .get();

    if (txsAfter.isEmpty) {
      for (final ab in accounts) {
        result[ab.account.id] = ab.balance;
      }
      return result;
    }

    // Batch 2: all lines for those transactions in one query
    final txIds = txsAfter.map((t) => t.id).toList();
    final allLines = await (db.select(db.transactionLines)
          ..where((l) => l.transactionId.isIn(txIds)))
        .get();

    // Index lines by txId and track which txs have per-line accounts
    final linesByTx = <String, List<TransactionLine>>{};
    final txsWithPerLineAcct = <String>{};
    for (final l in allLines) {
      linesByTx.putIfAbsent(l.transactionId, () => []).add(l);
      if (l.accountId != null) txsWithPerLineAcct.add(l.transactionId);
    }

    // Initialize balances from current
    for (final ab in accounts) {
      result[ab.account.id] = ab.balance;
    }

    // Reverse each transaction's effect on affected accounts
    for (final tx in txsAfter) {
      if (tx.type == 'transfer') {
        // Source: was debited tx.amount, so add it back
        if (acctIds.contains(tx.accountId)) {
          result[tx.accountId] = (result[tx.accountId] ?? 0) + tx.amount;
        }
        // Destination: was credited tx.amount * rate, so subtract it back
        if (tx.destinationAccountId != null &&
            acctIds.contains(tx.destinationAccountId)) {
          result[tx.destinationAccountId!] =
              (result[tx.destinationAccountId!] ?? 0) -
                  tx.amount * tx.exchangeRateToBase;
        }
        continue;
      }

      // Income/expense: check per-line accounts first
      final lines = linesByTx[tx.id] ?? [];
      if (txsWithPerLineAcct.contains(tx.id)) {
        // Per-line: each line's amount is in that line-account's currency
        for (final l in lines) {
          if (l.accountId == null || !acctIds.contains(l.accountId)) continue;
          if (tx.type == 'income') {
            result[l.accountId!] = (result[l.accountId!] ?? 0) - l.amount;
          } else if (tx.type == 'expense') {
            result[l.accountId!] = (result[l.accountId!] ?? 0) + l.amount;
          }
        }
      } else if (acctIds.contains(tx.accountId)) {
        // Header-level: tx.amount is in the account's currency
        if (tx.type == 'income') {
          result[tx.accountId] = (result[tx.accountId] ?? 0) - tx.amount;
        } else if (tx.type == 'expense') {
          result[tx.accountId] = (result[tx.accountId] ?? 0) + tx.amount;
        }
      }
    }

    return result;
  }
}
