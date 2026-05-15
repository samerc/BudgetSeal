import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/category_icon.dart';
import '../../core/providers/daily_spending_provider.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/spending_heatmap.dart';
import '../../shared/widgets/hint_banner.dart' show showHintIfNeeded;
import '../../shared/widgets/skeleton_loader.dart';

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

// ═════════════════════════════════════════════════════════════════════════════
// Reports Hub Screen
// ═════════════════════════════════════════════════════════════════════════════

class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showHintIfNeeded(
        context,
        hintId: 'reports_intro',
        icon: Icons.insights_rounded,
        title: 'Explore your spending patterns',
        body:
            'Switch between tabs to see different views. The Insights tab shows your financial health.',
      );
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Set the module-level base currency for _baseAmount helper
    _reportsBaseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Reports',
                style: TextStyle(
                  fontSize: TypographyTokens.screenTitleSize,
                  fontWeight: TypographyTokens.screenTitleWeight,
                  color: AppColors.tp(context),
                ),
              ),
            ),
            // ── Tab bar ──
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.tp(context),
              unselectedLabelColor: AppColors.ts(context),
              labelStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w400),
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Categories'),
                Tab(text: 'Insights'),
                Tab(text: 'Balance Sheet'),
              ],
            ),
            // ── Tab content ──
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _OverviewTab(),
                  _CategoriesTab(),
                  _InsightsTab(),
                  _BalanceSheetTab(),
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
    final now = DateTime.now();
    return DateTime(now.year, now.month - _selectedMonthsBack, 1);
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
        final net = totalIncome - totalExpense;

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

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final dx = details.primaryVelocity ?? 0;
            if (dx > 0) {
              setState(() => _selectedMonthsBack++);
            } else if (dx < 0 && _selectedMonthsBack > 0) {
              setState(() => _selectedMonthsBack--);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            child: Column(
              children: [
                // Month navigator
                _MonthNav(
                  month: month,
                  onPrev: () => setState(() => _selectedMonthsBack++),
                  onNext: _selectedMonthsBack > 0
                      ? () => setState(() => _selectedMonthsBack--)
                      : null,
                ),
                const SizedBox(height: 12),
                _MonthlySummaryCard(
                  income: totalIncome,
                  expense: totalExpense,
                  net: net,
                  lastMonthExpense: prevExpense,
                  dailyRate: daysElapsed > 0 ? totalExpense / daysElapsed : 0,
                  daysLeft: daysLeft,
                  currency: baseCurrency,
                ),
                const SizedBox(height: 16),
                // Spending Heatmap
                _HeatmapSection(baseCurrency: baseCurrency),
                const SizedBox(height: 16),
                // Toggle: Trend vs Daily Pace
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showDailyPace = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_showDailyPace
                                ? AppColors.accent.withValues(alpha: 0.12)
                                : AppColors.sfv(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('6-Month Trend',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: !_showDailyPace
                                      ? AppColors.accent
                                      : AppColors.ts(context),
                                )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showDailyPace = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _showDailyPace
                                ? AppColors.accent.withValues(alpha: 0.12)
                                : AppColors.sfv(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('Daily Pace',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _showDailyPace
                                      ? AppColors.accent
                                      : AppColors.ts(context),
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorRetry(
        message: "Couldn't load your data",
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

    if (maxY == 0) {
      return Center(
          child: Text('No spending this month',
              style: TextStyle(color: AppColors.ts(context))));
    }

    return SizedBox(
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
                      fontSize: 10, color: AppColors.th(context))),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
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
              color: AppColors.accent.withValues(alpha: 0.08),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.grid_view_rounded, size: 16,
                color: AppColors.ts(context)),
            const SizedBox(width: 8),
            Text('Spending Activity',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context))),
            const Spacer(),
            Text('$year',
                style: TextStyle(
                    fontSize: 11, color: AppColors.th(context))),
          ]),
          const SizedBox(height: 12),
          heatmapAsync.when(
            data: (data) => SpendingHeatmap(
              data: data,
              baseCurrency: baseCurrency,
            ),
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 100,
              child: Center(child: Text('Failed to load')),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(context, AppColors.sfv(context), 'None'),
              const SizedBox(width: 12),
              _legendDot(context, AppColors.overspent.withValues(alpha: 0.4), 'Expense'),
              const SizedBox(width: 12),
              _legendDot(context, AppColors.healthy.withValues(alpha: 0.4), 'Income'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Each square is one day. Darker = higher amount. '
            'Scroll left to see past months.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.th(context)),
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
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.th(context))),
      ],
    );
  }
}

// ── Spending Gauge (like the TD screenshot) ─────────────────────────────────

class _MonthlySummaryCard extends StatelessWidget {
  final double income, expense, net;
  final double lastMonthExpense;
  final double dailyRate;
  final int daysLeft;
  final String currency;

  const _MonthlySummaryCard({
    required this.income,
    required this.expense,
    required this.net,
    required this.lastMonthExpense,
    required this.dailyRate,
    required this.daysLeft,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final projected = dailyRate * DateUtils.getDaysInMonth(now.year, now.month);

    // Comparison with last month
    String? comparison;
    Color? comparisonColor;
    if (lastMonthExpense > 0) {
      final diff = ((expense - lastMonthExpense) / lastMonthExpense * 100).abs();
      if (expense < lastMonthExpense) {
        comparison = '${diff.round()}% less than last month';
        comparisonColor = AppColors.healthy;
      } else if (expense > lastMonthExpense) {
        comparison = '${diff.round()}% more than last month';
        comparisonColor = AppColors.overspent;
      } else {
        comparison = 'Same as last month';
        comparisonColor = AppColors.ts(context);
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        children: [
          // Header
          Text(DateFormat('MMMM yyyy').format(now),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ts(context))),
          const SizedBox(height: 16),
          // Main stats row
          Row(
            children: [
              Expanded(
                child: _statColumn(
                  context,
                  label: 'Income',
                  amount: income,
                  color: AppColors.healthy,
                ),
              ),
              Container(
                  width: 1, height: 40, color: AppColors.bd(context)),
              Expanded(
                child: _statColumn(
                  context,
                  label: 'Expenses',
                  amount: expense,
                  color: AppColors.overspent,
                ),
              ),
              Container(
                  width: 1, height: 40, color: AppColors.bd(context)),
              Expanded(
                child: _statColumn(
                  context,
                  label: 'Net',
                  amount: net,
                  color: net >= 0 ? AppColors.healthy : AppColors.overspent,
                  prefix: net >= 0 ? '+' : '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.bd(context), height: 1),
          const SizedBox(height: 12),
          // Pace + projection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily pace',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.ts(context))),
              Text(
                '${formatAmount(dailyRate, currency: currency)}/day',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Projected total',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.ts(context))),
              Text(
                '~${formatAmount(projected, currency: currency)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context)),
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
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  size: 16,
                  color: comparisonColor,
                ),
                const SizedBox(width: 6),
                Text(comparison,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: comparisonColor)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statColumn(BuildContext context,
      {required String label,
      required double amount,
      required Color color,
      String prefix = ''}) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: AppColors.ts(context))),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$prefix${formatAmount(amount, currency: currency)}',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ),
      ],
    );
  }
}

// ── 6-Month Trend Chart ─────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final maxVal = [
      ...incomeByMonth,
      ...expenseByMonth,
    ].fold(0.0, (a, b) => a > b ? a : b);

    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('6-Month Trend',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context))),
          const SizedBox(height: 16),
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
                            Container(
                              width: 10,
                              height: incH.clamp(2, 100),
                              decoration: BoxDecoration(
                                  color: AppColors.healthy,
                                  borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(width: 2),
                            Container(
                              width: 10,
                              height: expH.clamp(2, 100),
                              decoration: BoxDecoration(
                                  color: AppColors.overspent,
                                  borderRadius: BorderRadius.circular(3)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(DateFormat('MMM').format(months[i]),
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.th(context))),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.healthy,
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text('Income',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.ts(context))),
              const SizedBox(width: 16),
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.overspent,
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text('Expense',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.ts(context))),
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

  DateTime get _periodStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month - _selectedMonthsBack, 1);
  }

  DateTime get _periodEnd {
    final start = _periodStart;
    return DateTime(start.year, start.month + 1, 0, 23, 59, 59);
  }

  void _showCategoryTransactions(
    BuildContext context, {
    required String categoryName,
    required Color color,
    required List<TransactionEntry> transactions,
    required Map<String, Category> categoryMap,
  }) {
    final catTxns = transactions.where((e) {
      final catId = e.tx.categoryId;
      final cat = catId != null ? categoryMap[catId] : null;
      final name = cat?.name ?? 'Uncategorized';
      return name == categoryName;
    }).toList()
      ..sort((a, b) => b.tx.createdAt.compareTo(a.tx.createdAt));

    hapticLight();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.bd(ctx),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        categoryName.isNotEmpty
                            ? categoryName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(ctx),
                      ),
                    ),
                  ),
                  Text(
                    '${catTxns.length} transaction${catTxns.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.ts(ctx),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: catTxns.isEmpty
                  ? Center(
                      child: Text('No transactions',
                          style: TextStyle(color: AppColors.ts(ctx))))
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: catTxns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = catTxns[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.tx.note.isNotEmpty
                                          ? e.tx.note
                                          : 'No note',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: e.tx.note.isNotEmpty
                                            ? AppColors.tp(ctx)
                                            : AppColors.th(ctx),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat.MMMd()
                                          .format(e.tx.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.ts(ctx),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatAmount(_baseAmount(e)),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tp(ctx),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
        final filtered = entries
            .where((e) =>
                e.tx.type == 'expense' &&
                e.tx.createdAt.isAfter(_periodStart) &&
                e.tx.createdAt.isBefore(_periodEnd))
            .toList();

        // Aggregate by category
        final catSpend = <String, double>{};
        final catCount = <String, int>{};
        final catColors = <String, Color>{};

        for (final e in filtered) {
          final catId = e.tx.categoryId;
          final cat = catId != null ? categoryMap[catId] : null;
          final name = cat?.name ?? 'Uncategorized';
          catSpend[name] = (catSpend[name] ?? 0) + _baseAmount(e);
          catCount[name] = (catCount[name] ?? 0) + 1;
          if (cat != null && !catColors.containsKey(name)) {
            catColors[name] = AppColors.fromHex(cat.colorHex);
          }
        }

        // Compute last month's spend per category for comparison
        final prevMonthStart = DateTime(
            _periodStart.year, _periodStart.month - 1, 1);
        final prevMonthEnd = DateTime(
            prevMonthStart.year, prevMonthStart.month + 1, 0, 23, 59, 59);
        final lastMonthSpend = <String, double>{};
        for (final e in entries) {
          if (e.tx.type != 'expense') continue;
          final d = e.tx.createdAt;
          if (d.isAfter(prevMonthStart) && d.isBefore(prevMonthEnd)) {
            final catId = e.tx.categoryId;
            final cat = catId != null ? categoryMap[catId] : null;
            final name = cat?.name ?? 'Uncategorized';
            lastMonthSpend[name] =
                (lastMonthSpend[name] ?? 0) + _baseAmount(e);
          }
        }

        final sortedBySpend = catSpend.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final sortedByCount = catCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return GestureDetector(
          dragStartBehavior: DragStartBehavior.start,
          onHorizontalDragEnd: (details) {
            final dx = details.primaryVelocity ?? 0;
            if (dx > 0) {
              setState(() => _selectedMonthsBack++);
              hapticLight();
            } else if (dx < 0 && _selectedMonthsBack > 0) {
              setState(() => _selectedMonthsBack--);
              hapticLight();
            }
          },
          child: Column(
          children: [
            // Month selector
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _MonthNav(
                month: _periodStart,
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
                  _ToggleChip(
                    label: 'TOP SPENDING',
                    selected: !_showByTransactions,
                    onTap: () =>
                        setState(() => _showByTransactions = false),
                  ),
                  const SizedBox(width: 8),
                  _ToggleChip(
                    label: 'TOP TRANSACTIONS',
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
                  ? Center(
                      child: Text('No expenses this period',
                          style: TextStyle(color: AppColors.ts(context))))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: _showByTransactions
                          ? sortedByCount.length
                          : sortedBySpend.length,
                      itemBuilder: (_, i) {
                        if (_showByTransactions) {
                          final entry = sortedByCount[i];
                          final color = catColors[entry.key] ??
                              AppColors.accent;
                          return _CategoryRow(
                            name: entry.key,
                            value:
                                '${entry.value} transaction${entry.value == 1 ? '' : 's'}',
                            amount: catSpend[entry.key] ?? 0,
                            color: color,
                            lastMonthAmount: lastMonthSpend[entry.key],
                            onTap: () => _showCategoryTransactions(
                              context,
                              categoryName: entry.key,
                              color: color,
                              transactions: filtered,
                              categoryMap: categoryMap,
                            ),
                          );
                        } else {
                          final entry = sortedBySpend[i];
                          final color = catColors[entry.key] ??
                              AppColors.accent;
                          return _CategoryRow(
                            name: entry.key,
                            value:
                                '${catCount[entry.key] ?? 0} transaction${(catCount[entry.key] ?? 0) == 1 ? '' : 's'}',
                            amount: entry.value,
                            color: color,
                            lastMonthAmount: lastMonthSpend[entry.key],
                            onTap: () => _showCategoryTransactions(
                              context,
                              categoryName: entry.key,
                              color: color,
                              transactions: filtered,
                              categoryMap: categoryMap,
                            ),
                          );
                        }
                      },
                    ),
            ),
          ],
          ),
        );
      },
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorRetry(
        message: "Couldn't load your data",
        details: '$e',
        onRetry: () => ref.invalidate(transactionEntriesProvider),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final String value;
  final double amount;
  final Color color;
  final VoidCallback? onTap;
  final double? lastMonthAmount;

  const _CategoryRow({
    required this.name,
    required this.value,
    required this.amount,
    required this.color,
    this.onTap,
    this.lastMonthAmount,
  });

  @override
  Widget build(BuildContext context) {
    // Build comparison indicator
    Widget? comparisonWidget;
    if (lastMonthAmount != null) {
      final last = lastMonthAmount!;
      if (last > 0 && amount > 0) {
        final pctChange = ((amount - last) / last * 100).round();
        if (pctChange > 0) {
          comparisonWidget = Text(
            '\u2191 $pctChange%',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.overspent),
          );
        } else if (pctChange < 0) {
          comparisonWidget = Text(
            '\u2193 ${pctChange.abs()}%',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.healthy),
          );
        } else {
          comparisonWidget = Text(
            '\u2014',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ts(context)),
          );
        }
      } else if (last == 0 && amount > 0) {
        comparisonWidget = Text(
          'NEW',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.accent),
        );
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tp(context))),
                Row(
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.ts(context))),
                    if (comparisonWidget != null) ...[
                      const SizedBox(width: 8),
                      comparisonWidget,
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(formatAmount(amount),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context))),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.th(context)),
        ],
      ),
    ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Tab 4: Cumulative Spending (day-by-day area chart vs typical)
// ═════════════════════════════════════════════════════════════════════════════

class _CumulativeTab extends ConsumerStatefulWidget {
  const _CumulativeTab();

  @override
  ConsumerState<_CumulativeTab> createState() => _CumulativeTabState();
}

class _CumulativeTabState extends ConsumerState<_CumulativeTab> {
  int _selectedMonthsBack = 0;

  DateTime get _month {
    final now = DateTime.now();
    return DateTime(now.year, now.month - _selectedMonthsBack, 1);
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionEntriesProvider);

    return txAsync.when(
      data: (entries) {
        final month = _month;
        final now = DateTime.now();
        final isCurrentMonth =
            month.year == now.year && month.month == now.month;
        final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
        final lastDay = isCurrentMonth ? now.day : daysInMonth;

        // Daily cumulative spending for this month
        final dailyCumulative = List.filled(daysInMonth + 1, 0.0);
        for (final e in entries) {
          if (e.tx.type != 'expense') continue;
          final d = e.tx.createdAt.toLocal();
          if (d.year == month.year && d.month == month.month) {
            dailyCumulative[d.day] += _baseAmount(e);
          }
        }
        // Make cumulative
        for (int i = 1; i <= daysInMonth; i++) {
          dailyCumulative[i] += dailyCumulative[i - 1];
        }

        // Typical cumulative: use pre-computed stats
        final stats = ref.watch(reportStatsProvider).value;
        final typicalMonthly = stats?.typicalMonthlySpend(month) ?? 0;
        final typicalDaily = typicalMonthly / daysInMonth;
        final typicalCumulative = List.generate(
            daysInMonth + 1, (i) => typicalDaily * i);

        // Max for chart scaling
        final allValues = [
          ...dailyCumulative.take(lastDay + 1),
          ...typicalCumulative,
        ];
        final maxY = allValues.fold(0.0, (a, b) => a > b ? a : b);

        // Build fl_chart spots
        final currentSpots = <FlSpot>[];
        for (int i = 1; i <= lastDay; i++) {
          currentSpots.add(FlSpot(i.toDouble(), dailyCumulative[i]));
        }

        final typicalSpots = <FlSpot>[];
        for (int i = 1; i <= daysInMonth; i++) {
          typicalSpots.add(FlSpot(i.toDouble(), typicalCumulative[i]));
        }

        final monthName = DateFormat('MMMM').format(month);

        return GestureDetector(
          dragStartBehavior: DragStartBehavior.start,
          onHorizontalDragEnd: (details) {
            final dx = details.primaryVelocity ?? 0;
            if (dx > 0) {
              setState(() => _selectedMonthsBack++);
              hapticLight();
            } else if (dx < 0 && _selectedMonthsBack > 0) {
              setState(() => _selectedMonthsBack--);
              hapticLight();
            }
          },
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _MonthNav(
                month: month,
                onPrev: () => setState(() => _selectedMonthsBack++),
                onNext: _selectedMonthsBack > 0
                    ? () => setState(() => _selectedMonthsBack--)
                    : null,
              ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: AppColors.healthy,
                          borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text('Current',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context))),
                  const SizedBox(width: 20),
                  Container(
                      width: 12,
                      height: 3,
                      color: AppColors.th(context)),
                  const SizedBox(width: 6),
                  Text('Typical',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context))),
                ],
              ),
            ),
            // Chart
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
                child: LineChart(
                  LineChartData(
                    minX: 1,
                    maxX: daysInMonth.toDouble(),
                    minY: 0,
                    maxY: maxY > 0 ? maxY * 1.1 : 100,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY > 0 ? maxY / 4 : 25,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: AppColors.bd(context),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 7,
                          getTitlesWidget: (value, meta) {
                            final day = value.toInt();
                            if (day == 1 ||
                                day == 7 ||
                                day == 14 ||
                                day == 21 ||
                                day == daysInMonth) {
                              return Text(
                                '${monthName.substring(0, 3)}. $day',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.th(context)),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              formatAmount(value),
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.th(context)),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      // Typical (dashed)
                      if (typicalMonthly > 0)
                        LineChartBarData(
                          spots: typicalSpots,
                          isCurved: true,
                          color: AppColors.th(context),
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          dashArray: [6, 4],
                          belowBarData: BarAreaData(
                            show: true,
                            color:
                                AppColors.th(context).withValues(alpha: 0.05),
                          ),
                        ),
                      // Current spending
                      LineChartBarData(
                        spots: currentSpots,
                        isCurved: true,
                        color: AppColors.healthy,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, __, ___) {
                            // Only show dot on last point
                            if (spot.x == lastDay.toDouble()) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppColors.healthy,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            }
                            return FlDotCirclePainter(
                                radius: 0,
                                color: Colors.transparent,
                                strokeWidth: 0,
                                strokeColor: Colors.transparent);
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.healthy.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            return LineTooltipItem(
                              'Day ${spot.x.toInt()}\n${formatAmount(spot.y)}',
                              TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          ),
        );
      },
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorRetry(
        message: "Couldn't load your data",
        details: '$e',
        onRetry: () => ref.invalidate(transactionEntriesProvider),
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
    final now = DateTime.now();
    return DateTime(now.year, now.month - _selectedMonthsBack, 1);
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
        final monthStart = _month;
        final isCurrentMonth =
            monthStart.year == now.year && monthStart.month == now.month;
        final daysInMonth = DateUtils.getDaysInMonth(monthStart.year, monthStart.month);
        final daysElapsed = isCurrentMonth
            ? now.difference(monthStart).inDays + 1
            : daysInMonth;

        // ── Spending velocity ──
        double monthExpense = 0;
        final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
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
        double totalBudget = 0;
        for (final a in allocs) {
          final t = a.data.allocation.targetAmount;
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
        final tips = <String>[];
        if (totalBudget > 0 && projected > totalBudget) {
          tips.add('At your current pace, you\'ll exceed your budget by ${formatAmount(projected - totalBudget, currency: baseCurrency)}. Try to slow down.');
        } else if (totalBudget > 0 && projected <= totalBudget * 0.85) {
          tips.add('Great pace! You\'re on track to stay ${formatAmount(totalBudget - projected, currency: baseCurrency)} under budget.');
        }
        if (savingsRate > 0.2) {
          tips.add('You\'re saving ${(savingsRate * 100).round()}% of your income this month. Keep it up!');
        } else if (savingsRate < 0.05 && totalIncome > 0) {
          tips.add('Your savings rate is low (${(savingsRate * 100).round()}%). Try to set aside at least 10-20%.');
        }
        if (ageValue != null && ageValue < 15) {
          tips.add('Your money sits only $ageValue days before being spent. A buffer of 30+ days is healthier.');
        }

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final dx = details.primaryVelocity ?? 0;
            if (dx > 0) {
              setState(() => _selectedMonthsBack++);
            } else if (dx < 0 && _selectedMonthsBack > 0) {
              setState(() => _selectedMonthsBack--);
            }
          },
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month navigator
              _MonthNav(
                month: monthStart,
                onPrev: () => setState(() => _selectedMonthsBack++),
                onNext: _selectedMonthsBack > 0
                    ? () => setState(() => _selectedMonthsBack--)
                    : null,
              ),
              const SizedBox(height: 12),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    borderRadius: BorderRadius.circular(CardTokens.radius),
                    border: Border.all(color: AppColors.bd(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (savingsRate >= 0.1
                                  ? AppColors.healthy
                                  : AppColors.caution)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.savings_rounded,
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
                            Text('Savings Rate',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.ts(context))),
                            Text('${(savingsRate * 100).round()}%',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.tp(context))),
                          ],
                        ),
                      ),
                      Text(
                        formatAmount(totalIncome - monthExpense,
                            currency: baseCurrency),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: savingsRate >= 0
                              ? AppColors.healthy
                              : AppColors.overspent,
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
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('TIPS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.th(context),
                      )),
                ),
                ...tips.map((tip) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(tip,
                                style: TextStyle(
                                    fontSize: 13,
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
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorRetry(
        message: "Couldn't load your data",
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 18, color: velocityColor),
              const SizedBox(width: 8),
              Text('Spending Velocity',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context))),
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
                backgroundColor: velocityColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(velocityColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Projected',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.ts(context))),
                Text('Budget',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.ts(context))),
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
                  label: 'Daily rate',
                  value:
                      '${formatAmount(dailyRate, currency: baseCurrency)}/day'),
              const SizedBox(width: 16),
              _VelocityStat(
                  label: 'Day',
                  value: '$daysElapsed of $daysInMonth'),
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
            style: TextStyle(fontSize: 11, color: AppColors.ts(context))),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.tp(context))),
      ],
    );
  }
}

// ── Biggest Expense Card ────────────────────────────────────────────────────

class _BiggestExpenseCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cat = entry.tx.categoryId != null
        ? categoryMap[entry.tx.categoryId]
        : null;
    final catName = cat?.name ??
        (entry.tx.note.isNotEmpty ? entry.tx.note : 'Expense');
    final catColor = cat != null
        ? AppColors.fromHex(cat.colorHex)
        : AppColors.overspent;

    return GestureDetector(
      onTap: () => context.push('/transactions/${entry.tx.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(CardTokens.radius),
          border: Border.all(color: AppColors.bd(context)),
        ),
        child: Row(
          children: [
            CategoryIcon(
              categoryName: cat?.name ?? '',
              emoji: cat?.icon,
              color: catColor,
              size: 42,
              circular: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Biggest Expense',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ts(context))),
                  Text(catName,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tp(context))),
                  if (entry.tx.note.isNotEmpty && cat != null)
                    Text(entry.tx.note,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.ts(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(formatAmount(amount, currency: baseCurrency),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.overspent)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.th(context)),
          ],
        ),
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
                r.enabled.equals(true)))
          .get(),
      builder: (context, snap) {
        final recs = snap.data;
        if (recs == null || recs.isEmpty) return const SizedBox.shrink();

        double total = 0;
        for (final r in recs) {
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
          child: GestureDetector(
            onTap: () => context.push('/recurring'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(CardTokens.radius),
                border: Border.all(color: AppColors.bd(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.autorenew_rounded,
                        size: 20, color: AppColors.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recurring Transactions',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tp(context))),
                        Text(
                            '${recs.length} active \u00b7 ${formatAmount(total, currency: baseCurrency)}/mo',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.ts(context))),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.th(context)),
                ],
              ),
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
      label = 'Excellent';
      description =
          'You\'re spending last month\'s income -- a sign of financial stability.';
    } else if (age >= 15) {
      color = AppColors.caution;
      label = 'Getting there';
      description =
          'You\'re building a buffer but not quite there yet. Keep it up!';
    } else {
      color = AppColors.overspent;
      label = 'Needs work';
      description =
          'You\'re living paycheck to paycheck. Try to build up a buffer over time.';
    }

    // Gauge value (target is 30 days)
    final gaugeFraction = (age / 30.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Text('Age of Money',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context))),
              const Spacer(),
              Text('$age days',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
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
              backgroundColor: color.withValues(alpha: 0.1),
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
              Text('Goal: 30+ days',
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
            'Age of Money measures how many days your money sits before '
            'you spend it. It traces each expense back to the income that '
            'funded it (oldest income first).',
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

class _MonthNav extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _MonthNav({
    required this.month,
    required this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: onPrev,
          color: AppColors.ts(context),
        ),
        Text(
          DateFormat('MMMM yyyy').format(month),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.tp(context),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: onNext,
          color: onNext != null
              ? AppColors.ts(context)
              : AppColors.th(context),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.tp(context)
              : AppColors.sfv(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: selected
                ? AppColors.sf(context)
                : AppColors.ts(context),
          ),
        ),
      ),
    );
  }
}

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

  String _compareLabel = 'End of Last Month';

  void _showComparePicker(BuildContext context) {
    final now = DateTime.now();
    final options = <(String, DateTime)>[
      ('End of Last Week',
          now.subtract(Duration(days: now.weekday)).subtract(const Duration(days: 0))),
      ('End of Last Month', DateTime(now.year, now.month, 0)),
      ('Same Time Last Month', DateTime(now.year, now.month - 1, now.day)),
      ('End of Last Quarter', () {
        final qMonth = ((now.month - 1) ~/ 3) * 3;
        return qMonth > 0 ? DateTime(now.year, qMonth + 1, 0) : DateTime(now.year - 1, 12, 31);
      }()),
      ('End of Last Year', DateTime(now.year - 1, 12, 31)),
      ('Same Time Last Year', DateTime(now.year - 1, now.month, now.day)),
      ('Custom...', now),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Compare balances to:',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(ctx))),
              ),
              Divider(height: 1, color: AppColors.bd(ctx)),
              ...options.map((opt) => ListTile(
                    title: Text(opt.$1,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: _compareLabel == opt.$1
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: AppColors.tp(ctx))),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (opt.$1 == 'Custom...') {
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
          return Center(
              child: Text('No accounts',
                  style: TextStyle(color: AppColors.ts(context))));
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
            final netWorthNow = totalAssetsNow - totalLiabilitiesNow.abs();
            final netWorthCompare =
                totalAssetsCompare - totalLiabilitiesCompare.abs();

            // Per-currency totals for foreign accounts
            final foreignTotals = <String, double>{};
            for (final a in accounts) {
              if (a.account.currency != baseCurrency) {
                foreignTotals[a.account.currency] =
                    (foreignTotals[a.account.currency] ?? 0) + a.balance;
              }
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                // Compare period selector
                GestureDetector(
                  onTap: () => _showComparePicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.bd(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14, color: AppColors.ts(context)),
                        const SizedBox(width: 8),
                        Text(
                          _compareLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_more_rounded,
                            size: 18, color: AppColors.ts(context)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Date range display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDate(_compareDate),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ts(context)),
                    ),
                    Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppColors.th(context)),
                    Text(
                      formatDate(today),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Assets section
                if (assets.isNotEmpty) ...[
                  _bsSectionHeader(context, 'ASSETS',
                      totalAssetsCompare, totalAssetsNow, baseCurrency),
                  ..._groupByType(assets).entries.map((group) =>
                      _bsGroup(context, group.key, group.value,
                          historicalBalances, baseCurrency, totalAssetsNow)),
                ],

                // Liabilities section
                if (liabilities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _bsSectionHeader(context, 'LIABILITIES',
                      totalLiabilitiesCompare, totalLiabilitiesNow,
                      baseCurrency),
                  ..._groupByType(liabilities).entries.map((group) =>
                      _bsGroup(context, group.key, group.value,
                          historicalBalances, baseCurrency,
                          totalLiabilitiesNow)),
                ],

                // Net Worth
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, const Color(0xFF2A3F6A)],
                    ),
                    borderRadius: BorderRadius.circular(CardTokens.radius),
                  ),
                  child: Column(
                    children: [
                      Text('NET WORTH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.6),
                          )),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(children: [
                            Text(
                              formatAmount(netWorthCompare,
                                  currency: baseCurrency),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              formatDate(_compareDate),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ]),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.4)),
                          Column(children: [
                            Text(
                              formatAmount(netWorthNow, currency: baseCurrency),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const Text('Today',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.white60)),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _bsChangeChip(netWorthCompare, netWorthNow),
                      // Foreign currency totals
                      if (foreignTotals.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Divider(
                            color: Colors.white.withValues(alpha: 0.15),
                            height: 1),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: foreignTotals.entries.map((e) => Text(
                                formatAmount(e.value, currency: e.key),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorRetry(
        message: "Couldn't load accounts",
        details: '$e',
        onRetry: () => ref.invalidate(accountsWithBalanceProvider),
      ),
    );
  }

  Map<String, List<AccountWithBalance>> _groupByType(
      List<AccountWithBalance> accounts) {
    final groups = <String, List<AccountWithBalance>>{};
    for (final a in accounts) {
      final type = a.account.type[0].toUpperCase() + a.account.type.substring(1);
      groups.putIfAbsent(type, () => []).add(a);
    }
    return groups;
  }

  Widget _bsSectionHeader(BuildContext context, String label,
      double compareTotal, double nowTotal, String currency) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: label == 'ASSETS' ? AppColors.healthy : AppColors.overspent,
              )),
          ),
          Expanded(
            flex: 2,
            child: Text(formatAmount(compareTotal, currency: currency),
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: 11, color: AppColors.ts(context))),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(formatAmount(nowTotal, currency: currency),
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tp(context))),
          ),
          const SizedBox(width: 22), // space for change indicator column
        ],
      ),
    );
  }

  Widget _bsGroup(
    BuildContext context,
    String typeName,
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                Icon(_typeIcon(typeName), size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(typeName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(context))),
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
      diff > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
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
        color: (isUp ? AppColors.healthy : AppColors.overspent)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: isUp ? AppColors.healthy : AppColors.overspent,
          ),
          const SizedBox(width: 4),
          Text(
            '${isUp ? '+' : ''}${pct.toStringAsFixed(1)}%',
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

  IconData _typeIcon(String type) {
    return switch (type.toLowerCase()) {
      'bank' => Icons.account_balance_rounded,
      'cash' => Icons.payments_rounded,
      'credit' => Icons.credit_card_rounded,
      'wallet' => Icons.account_balance_wallet_rounded,
      _ => Icons.account_balance_rounded,
    };
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
