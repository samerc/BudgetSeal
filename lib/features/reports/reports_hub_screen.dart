import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/categories_provider.dart';
import '../../core/database/app_database.dart' show Category;
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/skeleton_loader.dart';

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: compute base amount from a transaction entry.
// ─────────────────────────────────────────────────────────────────────────────
double _baseAmount(TransactionEntry e) {
  if (e.lines.isNotEmpty) {
    double sum = 0;
    for (final l in e.lines) {
      sum += l.amount * l.exchangeRateToBase;
    }
    return sum;
  }
  return e.tx.amount * e.tx.exchangeRateToBase;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: compute "typical" monthly spending (average of previous months).
// ─────────────────────────────────────────────────────────────────────────────
double _typicalMonthlySpend(List<TransactionEntry> allEntries, DateTime month,
    {int lookback = 6}) {
  double total = 0;
  int counted = 0;
  for (int i = 1; i <= lookback; i++) {
    final m = DateTime(month.year, month.month - i, 1);
    final end = DateTime(m.year, m.month + 1, 1);
    double monthTotal = 0;
    for (final e in allEntries) {
      if (e.tx.type != 'expense') continue;
      final d = e.tx.createdAt;
      if (!d.isBefore(m) && d.isBefore(end)) {
        monthTotal += _baseAmount(e);
      }
    }
    if (monthTotal > 0) {
      total += monthTotal;
      counted++;
    }
  }
  return counted > 0 ? total / counted : 0;
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
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
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
                Tab(text: 'History'),
                Tab(text: 'Cumulative'),
              ],
            ),
            // ── Tab content ──
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _OverviewTab(),
                  _CategoriesTab(),
                  _HistoryTab(),
                  _CumulativeTab(),
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

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionEntriesProvider);
    final baseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';

    return txAsync.when(
      data: (entries) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final thisMonth =
            entries.where((e) => e.tx.createdAt.isAfter(monthStart));

        double totalIncome = 0;
        double totalExpense = 0;
        for (final e in thisMonth) {
          final amt = _baseAmount(e);
          if (e.tx.type == 'income') totalIncome += amt;
          if (e.tx.type == 'expense') totalExpense += amt;
        }

        final typical = _typicalMonthlySpend(entries, monthStart);
        final net = totalIncome - totalExpense;

        // 6-month trend data
        final months = <DateTime>[];
        final incomeByMonth = <double>[];
        final expenseByMonth = <double>[];
        for (int i = 5; i >= 0; i--) {
          final m = DateTime(now.year, now.month - i, 1);
          final end = DateTime(m.year, m.month + 1, 1);
          months.add(m);
          double inc = 0, exp = 0;
          for (final e in entries) {
            final d = e.tx.createdAt;
            if (d.isBefore(m) || !d.isBefore(end)) continue;
            final amt = _baseAmount(e);
            if (e.tx.type == 'income') inc += amt;
            if (e.tx.type == 'expense') exp += amt;
          }
          incomeByMonth.add(inc);
          expenseByMonth.add(exp);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            children: [
              // Spending gauge
              _SpendingGauge(
                spent: totalExpense,
                typical: typical,
                currency: baseCurrency,
              ),
              const SizedBox(height: 20),
              // Income/Expense/Net summary
              _CashflowSummary(
                income: totalIncome,
                expense: totalExpense,
                net: net,
                currency: baseCurrency,
              ),
              const SizedBox(height: 20),
              // 6-month trend
              _TrendChart(
                months: months,
                incomeByMonth: incomeByMonth,
                expenseByMonth: expenseByMonth,
                baseCurrency: baseCurrency,
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

// ── Spending Gauge (like the TD screenshot) ─────────────────────────────────

class _SpendingGauge extends StatelessWidget {
  final double spent;
  final double typical;
  final String currency;

  const _SpendingGauge({
    required this.spent,
    required this.typical,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final fractionOfMonth = dayOfMonth / daysInMonth;

    // Expected spend so far (proportion of typical for this point in month)
    final expectedSoFar = typical * fractionOfMonth;

    // Gauge progress: spent vs expected-so-far (not vs full typical)
    // This makes the gauge meaningful: green = under pace, red = over pace
    final gaugeBase = typical > 0 ? expectedSoFar : spent;
    final gaugeProgress = gaugeBase > 0
        ? (spent / gaugeBase).clamp(0.0, 1.5)
        : (spent > 0 ? 1.0 : 0.0);

    // Color based on pace: are you spending faster or slower than typical?
    Color gaugeColor;
    if (typical == 0) {
      // No historical data — neutral
      gaugeColor = AppColors.accent;
    } else if (spent <= expectedSoFar * 0.8) {
      gaugeColor = AppColors.healthy; // Well under pace
    } else if (spent <= expectedSoFar * 1.1) {
      gaugeColor = AppColors.caution; // Close to pace
    } else {
      gaugeColor = AppColors.overspent; // Over pace
    }

    final difference = typical > 0 ? (typical - spent).abs() : 0.0;
    final isOver = spent > typical;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        children: [
          Text('Monthly Spending',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context))),
          Text('as of ${DateFormat('MMMM d, yyyy').format(now)}',
              style: TextStyle(
                  fontSize: 12, color: AppColors.ts(context))),
          const SizedBox(height: 24),
          // Gauge
          SizedBox(
            width: 200,
            height: 120,
            child: CustomPaint(
              painter: _GaugePainter(
                progress: gaugeProgress,
                color: gaugeColor,
                bgColor: AppColors.bd(context),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 130,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatAmount(spent, currency: currency),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.tp(context),
                        ),
                      ),
                    ),
                  ),
                  Text('SPENT SO FAR',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.ts(context))),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Below/Over typical + Typical spend
          if (typical > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [
                  Text(formatAmount(difference, currency: currency),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isOver
                              ? AppColors.overspent
                              : AppColors.healthy)),
                  Text(isOver ? 'OVER TYPICAL' : 'BELOW TYPICAL',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ts(context))),
                ]),
                const SizedBox(width: 32),
                Column(children: [
                  Text(formatAmount(typical, currency: currency),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tp(context))),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TYPICAL SPEND',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ts(context))),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _showTypicalInfo(context),
                        child: Icon(Icons.help_outline_rounded,
                            size: 14, color: AppColors.th(context)),
                      ),
                    ],
                  ),
                ]),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.th(context)),
                  const SizedBox(width: 6),
                  Text('Add a few months of data to see typical spending',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showTypicalInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 20, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text('Typical Spending'),
          ],
        ),
        content: Text(
          '"Typical Spend" is the average of your total expenses '
          'over the previous 6 months. It gives you a benchmark to '
          'compare this month\'s spending against.\n\n'
          '"Below/Over Typical" shows the difference between what '
          'you\'ve spent this month and your typical full-month total.\n\n'
          'The gauge color reflects your spending pace:\n'
          '• Green — spending slower than usual\n'
          '• Yellow — on track with typical pace\n'
          '• Red — spending faster than usual',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.ts(context),
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.5
  final Color color;
  final Color bgColor;

  _GaugePainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Background arc
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final clampedProgress = progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * clampedProgress,
      false,
      progressPaint,
    );

    // Typical marker (at the end of the arc)
    if (progress > 0) {
      final markerAngle = startAngle + sweepAngle * 1.0;
      final markerPaint = Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill;
      final mx = center.dx + radius * math.cos(markerAngle);
      final my = center.dy + radius * math.sin(markerAngle);
      canvas.drawCircle(Offset(mx, my), 4, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.color != color;
}

// ── Cashflow Summary ────────────────────────────────────────────────────────

class _CashflowSummary extends StatelessWidget {
  final double income, expense, net;
  final String currency;

  const _CashflowSummary({
    required this.income,
    required this.expense,
    required this.net,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = income > expense ? income : expense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        children: [
          _BarRow(
              label: 'Income',
              amount: income,
              currency: currency,
              color: AppColors.healthy,
              maxVal: maxVal),
          const SizedBox(height: 12),
          _BarRow(
              label: 'Expenses',
              amount: expense,
              currency: currency,
              color: AppColors.overspent,
              maxVal: maxVal),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.bd(context)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ts(context))),
              Text(
                formatSignedAmount(net, currency: currency, type: net >= 0 ? 'income' : 'expense'),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color:
                        net >= 0 ? AppColors.healthy : AppColors.overspent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final double maxVal;

  const _BarRow({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.maxVal,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxVal > 0 ? amount / maxVal : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: AppColors.ts(context))),
            Text(formatAmount(amount, currency: currency),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
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
        borderRadius: BorderRadius.circular(16),
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
            catColors[name] = _hexToColor(cat.colorHex);
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

  const _CategoryRow({
    required this.name,
    required this.value,
    required this.amount,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(value,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.ts(context))),
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
// Tab 3: Spending History (monthly gauge cards)
// ═════════════════════════════════════════════════════════════════════════════

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionEntriesProvider);

    return txAsync.when(
      data: (entries) {
        // Find earliest and latest transaction dates
        if (entries.isEmpty) {
          return Center(
              child: Text('No transactions yet',
                  style: TextStyle(color: AppColors.ts(context))));
        }

        final now = DateTime.now();
        final earliest = entries.last.tx.createdAt;
        final months = <DateTime>[];

        // Generate months from current back to earliest
        var m = DateTime(now.year, now.month, 1);
        final stop = DateTime(earliest.year, earliest.month, 1);
        while (!m.isBefore(stop)) {
          months.add(m);
          m = DateTime(m.year, m.month - 1, 1);
        }

        // Group by year
        final byYear = <int, List<DateTime>>{};
        for (final month in months) {
          byYear.putIfAbsent(month.year, () => []).add(month);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: byYear.entries.map((yearEntry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '${yearEntry.key} Monthly Spending',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(context),
                      ),
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: yearEntry.value.length,
                  itemBuilder: (_, i) {
                    final month = yearEntry.value[i];
                    return _MonthGaugeCard(
                      month: month,
                      entries: entries,
                    );
                  },
                ),
              ],
            );
          }).toList(),
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

class _MonthGaugeCard extends StatelessWidget {
  final DateTime month;
  final List<TransactionEntry> entries;

  const _MonthGaugeCard({required this.month, required this.entries});

  @override
  Widget build(BuildContext context) {
    final end = DateTime(month.year, month.month + 1, 1);
    double spent = 0;
    for (final e in entries) {
      if (e.tx.type != 'expense') continue;
      final d = e.tx.createdAt;
      if (!d.isBefore(month) && d.isBefore(end)) {
        spent += _baseAmount(e);
      }
    }

    final typical = _typicalMonthlySpend(entries, month);
    final ratio = typical > 0 ? (spent / typical).clamp(0.0, 1.5) : 0.0;

    Color gaugeColor;
    if (typical == 0) {
      gaugeColor = AppColors.healthy;
    } else if (spent <= typical * 0.8) {
      gaugeColor = AppColors.healthy;
    } else if (spent <= typical) {
      gaugeColor = AppColors.caution;
    } else {
      gaugeColor = AppColors.overspent;
    }

    final monthLabel = DateFormat('MMM').format(month).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mini gauge
          SizedBox(
            width: 60,
            height: 36,
            child: CustomPaint(
              painter: _MiniGaugePainter(
                progress: ratio,
                color: gaugeColor,
                bgColor: AppColors.bd(context),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(monthLabel,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tp(context))),
          const SizedBox(height: 2),
          Text(formatAmount(spent),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tp(context))),
          if (typical > 0)
            Text(formatAmount(typical),
                style: TextStyle(
                    fontSize: 10, color: AppColors.ts(context))),
          Text('TYPICAL',
              style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: AppColors.th(context))),
        ],
      ),
    );
  }
}

class _MiniGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _MiniGaugePainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 4;

    final bg = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bg,
    );

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * progress.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniGaugePainter old) =>
      old.progress != progress || old.color != color;
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

        // Typical cumulative: compute average daily spending from previous months
        final typicalMonthly = _typicalMonthlySpend(entries, month);
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
