import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:drift/drift.dart' hide Column;

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/report_stats_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/section_header.dart';
import '../../core/providers/dashboard_layout_provider.dart';
import '../../core/providers/period_reset_provider.dart';
import '../../shared/widgets/animated_amount.dart';
import '../../shared/widgets/rolling_number.dart';
import '../../shared/widgets/error_retry.dart';
import 'dashboard_customize_sheet.dart';
import '../../shared/widgets/hint_banner.dart' show showHintIfNeeded;
import '../../shared/widgets/tappable.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  bool _showWeekly = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() => _showWeekly = prefs.getBool('dashboard_show_weekly') ?? false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showHintIfNeeded(
        context,
        hintId: 'dashboard_welcome',
        icon: Icons.waving_hand_rounded,
        title: 'Welcome to PocketPlan!',
        body:
            'Start by adding your first expense — tap the + button on the Activity tab. '
            'Then head to the Budget tab to create envelopes and assign your money.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final household = ref.watch(householdProvider).value;
    // Trigger period auto-reset check on each build (FutureProvider caches)
    ref.watch(periodResetCheckProvider);
    final layout = ref.watch(dashboardLayoutProvider);
    final accountsAsync = ref.watch(accountsWithBalanceProvider);
    final allocationsAsync = ref.watch(allocationsProvider);
    final unallocatedAsync = ref.watch(unallocatedProvider);
    final txAsync = ref.watch(currentMonthTransactionsProvider);
    final recentTxAsync = ref.watch(recentTransactionsProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final categoryMap = {for (final c in categories) c.id: c};
    final baseCurrency = household?.baseCurrency ?? 'USD';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate root providers — dependents (unallocatedProvider, etc.)
          // refresh automatically via Riverpod's dependency graph.
          ref.invalidate(accountsWithBalanceProvider);
          ref.invalidate(allocationsProvider);
          ref.invalidate(currentMonthTransactionsProvider);
          ref.invalidate(recentTransactionsProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
          slivers: [
            // ── Zone 1: At-a-glance ─────────────────────────────
            // Header (Greeting + Search)
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Household',
                              style: TextStyle(
                                color: AppColors.ts(context),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              household?.name ?? 'PocketPlan',
                              style: TextStyle(
                                color: AppColors.tp(context),
                                fontSize: TypographyTokens.screenTitleSize,
                                fontWeight: TypographyTokens.screenTitleWeight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Customize',
                        icon: Icon(Icons.tune_rounded,
                            color: AppColors.ts(context), size: 20),
                        onPressed: () => showDashboardCustomizeSheet(context),
                      ),
                      IconButton(
                        tooltip: 'Search',
                        icon: Icon(Icons.search_rounded,
                            color: AppColors.ts(context)),
                        onPressed: () => _showGlobalSearch(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate(_buildOrderedSections(
                  layout: layout,
                  txAsync: txAsync,
                  accountsAsync: accountsAsync,
                  allocationsAsync: allocationsAsync,
                  unallocatedAsync: unallocatedAsync,
                  recentTxAsync: recentTxAsync,
                  baseCurrency: baseCurrency,
                  categoryMap: categoryMap,
                  context: context,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrderedSections({
    required List<DashboardSectionConfig> layout,
    required AsyncValue<List<TransactionEntry>> txAsync,
    required AsyncValue<List<AccountWithBalance>> accountsAsync,
    required AsyncValue<List<AllocationWithBalance>> allocationsAsync,
    required AsyncValue<Map<String, double>> unallocatedAsync,
    required AsyncValue<List<TransactionEntry>> recentTxAsync,
    required String baseCurrency,
    required Map<String, Category> categoryMap,
    required BuildContext context,
  }) {
    final sectionWidgets = <DashboardSection, List<Widget>>{};

    // Build all section widget lists
    sectionWidgets[DashboardSection.spending] = [
                  // ── Spending Overview with Donut + Toggle ──
                  txAsync.when(
                    data: (entries) {
                      final now = DateTime.now();
                      final DateTime cutoff;
                      if (_showWeekly) {
                        cutoff = now.subtract(const Duration(days: 7));
                      } else {
                        cutoff = DateTime(now.year, now.month, 1);
                      }
                      final filtered = entries
                          .where((e) => e.tx.createdAt.isAfter(cutoff));

                      double totalIncome = 0;
                      double totalExpense = 0;
                      final catSpend = <String, double>{};
                      final catColors = <String, Color>{};

                      for (final e in filtered) {
                        double baseAmt = 0;
                        if (e.lines.isNotEmpty) {
                          for (final l in e.lines) {
                            if (!isRealRate(l.currency, baseCurrency, l.exchangeRateToBase)) continue;
                            baseAmt += l.amount * l.exchangeRateToBase;
                          }
                        } else {
                          if (isRealRate(e.tx.currency, baseCurrency, e.tx.exchangeRateToBase)) {
                            baseAmt = e.tx.amount * e.tx.exchangeRateToBase;
                          }
                        }
                        if (e.tx.type == 'income') totalIncome += baseAmt;
                        if (e.tx.type == 'expense') {
                          totalExpense += baseAmt;
                          final catId = e.tx.categoryId;
                          if (catId != null) {
                            final cat = categoryMap[catId];
                            final name = cat?.name ?? 'Other';
                            catSpend[name] =
                                (catSpend[name] ?? 0) + baseAmt;
                            if (cat != null &&
                                !catColors.containsKey(name)) {
                              catColors[name] = AppColors.fromHex(cat.colorHex);
                            }
                          } else {
                            catSpend['Other'] =
                                (catSpend['Other'] ?? 0) + baseAmt;
                          }
                        }
                      }

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, child) => Opacity(
                          opacity: v,
                          child: Transform.scale(scale: 0.92 + 0.08 * v, child: child),
                        ),
                        child: _SpendingOverviewCard(
                        income: totalIncome,
                        expense: totalExpense,
                        currency: baseCurrency,
                        categorySpend: catSpend,
                        categoryColors: catColors,
                        showWeekly: _showWeekly,
                        onTogglePeriod: () {
                            setState(() => _showWeekly = !_showWeekly);
                            SharedPreferences.getInstance().then((p) =>
                                p.setBool('dashboard_show_weekly', _showWeekly));
                          },
                      ));
                    },
                    loading: () => const _ShimmerCard(height: 220),
                    error: (e, _) => ErrorRetry(
                      message: "Couldn't load your data",
                      details: '$e',
                      onRetry: () =>
                          ref.invalidate(currentMonthTransactionsProvider),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Spending insight — one actionable sentence
                  Builder(builder: (_) {
                    final statsAsync = ref.watch(reportStatsProvider);
                    final stats = statsAsync.value;
                    if (stats == null) return const SizedBox.shrink();
                    final now = DateTime.now();
                    final thisMonth = DateTime(now.year, now.month, 1);
                    final lastMonth = DateTime(now.year, now.month - 1, 1);
                    final current = stats.monthly[thisMonth];
                    final previous = stats.monthly[lastMonth];
                    if (current == null || previous == null ||
                        current.expense == 0 || previous.expense == 0) {
                      return const SizedBox.shrink();
                    }

                    // Find biggest category increase
                    String? topCat;
                    double topIncrease = 0;
                    for (final entry in current.categorySpend.entries) {
                      final prevAmt = previous.categorySpend[entry.key] ?? 0;
                      if (prevAmt > 0 && entry.value > prevAmt * 1.2) {
                        final increase = ((entry.value - prevAmt) / prevAmt * 100).round();
                        if (increase > topIncrease) {
                          topIncrease = increase.toDouble();
                          topCat = categoryMap[entry.key]?.name ?? 'a category';
                        }
                      }
                    }

                    // Overall comparison
                    final pctChange = ((current.expense - previous.expense) / previous.expense * 100).round();

                    String? message;
                    IconData? icon;
                    Color? color;

                    if (topCat != null && topIncrease >= 30) {
                      message = '$topCat spending is ${topIncrease.round()}% higher than last month';
                      icon = Icons.trending_up_rounded;
                      color = AppColors.caution;
                    } else if (pctChange <= -15) {
                      message = 'Spending is ${pctChange.abs()}% lower than last month — nice!';
                      icon = Icons.trending_down_rounded;
                      color = AppColors.healthy;
                    } else if (pctChange >= 20) {
                      message = 'Spending is $pctChange% higher than last month';
                      icon = Icons.trending_up_rounded;
                      color = AppColors.caution;
                    }

                    if (message == null) {
                      message = 'Spending is on track this month';
                      icon = Icons.check_circle_outline_rounded;
                      color = AppColors.healthy;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: color!.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(message,
                                style: TextStyle(fontSize: 12, color: color,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
    ];

    sectionWidgets[DashboardSection.quickActions] = [
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.remove_rounded,
                        label: 'Expense',
                        color: ref.watch(txColorsProvider).expense,
                        onTap: () => context.push('/add-transaction',
                            extra: {'editType': 'expense'}),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.add_rounded,
                        label: 'Income',
                        color: ref.watch(txColorsProvider).income,
                        onTap: () => context.push('/add-transaction',
                            extra: {'editType': 'income'}),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Transfer',
                        color: ref.watch(txColorsProvider).transfer,
                        onTap: () => context.push('/add-transaction',
                            extra: {'editType': 'transfer'}),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.savings_rounded,
                        label: 'Fund',
                        tooltip: 'Fund envelopes',
                        color: const Color(0xFF7E57C2),
                        onTap: () => context.push('/funding'),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.call_split_rounded,
                        label: 'Split',
                        tooltip: 'Split a bill',
                        color: const Color(0xFFFF8A65),
                        onTap: () => context.push('/bill-splitter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
    ];

    sectionWidgets[DashboardSection.money] = [
                  // Compact money overview: Net Worth + Unallocated
                  accountsAsync.when(
                    data: (accounts) {
                      final Map<String, double> totals = {};
                      for (final ab in accounts) {
                        totals[ab.account.currency] =
                            (totals[ab.account.currency] ?? 0) + ab.balance;
                      }
                      final baseNetWorth = totals[baseCurrency] ?? 0.0;
                      final otherNetWorthCount = totals.keys
                          .where((k) => k != baseCurrency)
                          .length;

                      return unallocatedAsync.when(
                        data: (unallocated) {
                          final unallocBase = unallocated[baseCurrency] ?? 0.0;
                          final otherUnallocCount = unallocated.keys
                              .where((k) => k != baseCurrency && (unallocated[k] ?? 0).abs() > 0.01)
                              .length;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.sf(context),
                              borderRadius: BorderRadius.circular(CardTokens.radius),
                              border: Border.all(color: AppColors.bd(context)),
                            ),
                            child: Row(
                              children: [
                                // Net Worth
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.push('/accounts'),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.account_balance_rounded,
                                                size: 13, color: AppColors.ts(context)),
                                            const SizedBox(width: 5),
                                            Text('Net Worth',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.ts(context))),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        RollingNumber(
                                          amount: baseNetWorth,
                                          currency: baseCurrency,
                                          lazyFirstRender: false,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.tp(context),
                                          ),
                                        ),
                                        if (otherNetWorthCount > 0)
                                          Text(
                                            '+ $otherNetWorthCount other',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.th(context)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Divider
                                Container(
                                  width: 1,
                                  height: 40,
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                  color: AppColors.bd(context),
                                ),
                                // Unallocated
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.push('/funding'),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.account_balance_wallet_outlined,
                                                size: 13, color: AppColors.ts(context)),
                                            const SizedBox(width: 5),
                                            Text('Unallocated',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.ts(context))),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        RollingNumber(
                                          amount: unallocBase,
                                          currency: baseCurrency,
                                          lazyFirstRender: false,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: unallocBase >= 0
                                                ? AppColors.tp(context)
                                                : AppColors.overspent,
                                          ),
                                        ),
                                        if (otherUnallocCount > 0)
                                          Text(
                                            '+ $otherUnallocCount other',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.th(context)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(height: 60),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                    loading: () => const _ShimmerCard(height: 60),
                    error: (e, _) => ErrorRetry(
                      message: "Couldn't load your data",
                      details: '$e',
                      onRetry: () =>
                          ref.invalidate(accountsWithBalanceProvider),
                    ),
                  ),
                  const SizedBox(height: 16),
    ];

    sectionWidgets[DashboardSection.activity] = [
                  const SectionHeader('Activity'),
                  const SizedBox(height: 8),
                  // Quick Templates (above recent transactions)
                  _QuickTemplatesSection(),
                  const SizedBox(height: 4),
                  recentTxAsync.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.sf(context),
                            borderRadius: BorderRadius.circular(CardTokens.radius),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    size: 36, color: AppColors.th(context)),
                                const SizedBox(height: 8),
                                Text('No transactions yet',
                                    style: TextStyle(
                                        color: AppColors.ts(context))),
                              ],
                            ),
                          ),
                        );
                      }
                      final recent = entries.take(5).toList();
                      final hasToday = recent.any((e) {
                        final d = e.tx.createdAt.toLocal();
                        final now = DateTime.now();
                        return d.year == now.year &&
                            d.month == now.month &&
                            d.day == now.day;
                      });
                      return Column(
                        children: [
                          if (!hasToday)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.wb_sunny_rounded,
                                        size: 16, color: AppColors.accent),
                                    const SizedBox(width: 8),
                                    Text(
                                      'No transactions today — tap + to add one',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ...recent.asMap().entries.map((e) =>
                            TweenAnimationBuilder<double>(
                              key: ValueKey(e.value.tx.id),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 300 + e.key * 80),
                              curve: Curves.easeOut,
                              builder: (_, v, child) => Opacity(opacity: v, child: child),
                              child: _RecentTxTile(
                                entry: e.value,
                                categoryMap: categoryMap,
                              ),
                            )),
                        ],
                      );
                    },
                    loading: () => const _ShimmerCard(height: 200),
                    error: (e, _) => ErrorRetry(
                      message: "Couldn't load your data",
                      details: '$e',
                      onRetry: () =>
                          ref.invalidate(recentTransactionsProvider),
                    ),
                  ),
    ];

    // Build ordered list from provider layout
    final result = <Widget>[];
    for (final config in layout) {
      if (config.visible && sectionWidgets.containsKey(config.section)) {
        result.addAll(sectionWidgets[config.section]!);
      }
    }
    return result;
  }


  void _showGlobalSearch(BuildContext context, WidgetRef ref) {
    showSearch(context: context, delegate: _GlobalSearchDelegate(ref));
  }

}

// ─── Spending Overview Card with Donut Chart ───────────────────────────────

class _SpendingOverviewCard extends StatelessWidget {
  final double income;
  final double expense;
  final String currency;
  final Map<String, double> categorySpend;
  final Map<String, Color> categoryColors;
  final bool showWeekly;
  final VoidCallback onTogglePeriod;

  const _SpendingOverviewCard({
    required this.income,
    required this.expense,
    required this.currency,
    required this.categorySpend,
    required this.categoryColors,
    required this.showWeekly,
    required this.onTogglePeriod,
  });

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    final periodLabel =
        showWeekly ? 'Last 7 Days' : DateFormat('MMMM').format(DateTime.now());
    final sorted = categorySpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sorted.take(5).toList();
    final defaultColors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF64748B),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(periodLabel,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ts(context))),
              GestureDetector(
                onTap: onTogglePeriod,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sfv(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    showWeekly ? 'This Month' : 'Last 7 Days',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Semantics(
                label: expense > 0
                    ? 'Spending chart, total ${formatAmount(expense, currency: currency)}, ${topCategories.length} categories'
                    : 'No spending this period',
                child: SizedBox(
                width: 120,
                height: 120,
                child: expense > 0
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                            sections:
                                topCategories.asMap().entries.map((e) {
                              final color =
                                  categoryColors[e.value.key] ??
                                      defaultColors[
                                          e.key % defaultColors.length];
                              return PieChartSectionData(
                                value: e.value.value,
                                color: color,
                                radius: 20,
                                showTitle: false,
                              );
                            }).toList(),
                          )),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 60,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: AnimatedAmount(
                                      amount: expense,
                                      currency: currency,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.tp(context))),
                                ),
                              ),
                              Text('spent',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.ts(context))),
                            ],
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pie_chart_outline_rounded,
                                size: 32, color: AppColors.th(context)),
                            const SizedBox(height: 4),
                            Text('No spending',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.ts(context))),
                          ],
                        ),
                      ),
              )),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniStat(
                        label: 'Income',
                        amount: income,
                        color: AppColors.healthy,
                        currency: currency,
                        prefix: '+'),
                    const SizedBox(height: 8),
                    _MiniStat(
                        label: 'Expenses',
                        amount: expense,
                        color: AppColors.overspent,
                        currency: currency,
                        prefix: '-'),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                          height: 1, color: AppColors.bd(context)),
                    ),
                    _MiniStat(
                        label: 'Net',
                        amount: net.abs(),
                        color: net >= 0
                            ? AppColors.healthy
                            : AppColors.overspent,
                        currency: currency,
                        prefix: net >= 0 ? '+' : '-',
                        bold: true),
                  ],
                ),
              ),
            ],
          ),
          if (topCategories.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: topCategories.asMap().entries.map((e) {
                final color = categoryColors[e.value.key] ??
                    defaultColors[e.key % defaultColors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(e.value.key,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.ts(context))),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String prefix;
  final bool bold;
  final String? currency;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.color,
    this.prefix = '',
    this.bold = false,
    this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 13, color: AppColors.ts(context))),
        AnimatedAmount(
            amount: amount,
            currency: currency,
            prefix: prefix.isNotEmpty ? prefix : null,
            style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color)),
      ],
    );
  }
}

// ─── Quick Action ───────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: tooltip ?? 'Add $label',
        button: true,
        child: Tooltip(
          message: tooltip ?? 'Add $label',
          child: Tappable(
            onTap: onTap,
            borderRadius: BorderRadius.circular(CardTokens.radius),
            scaleFactor: 0.93,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(CardTokens.radius),
              ),
              child: Column(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Recent Transaction Tile ──────────────────────────────────────────────── ────────────────────────────────────────────────

class _RecentTxTile extends ConsumerWidget {
  final TransactionEntry entry;
  final Map<String, Category> categoryMap;
  const _RecentTxTile({required this.entry, required this.categoryMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = entry.tx;
    final txColors = ref.watch(txColorsProvider);
    final typeColor = txColors.forType(tx.type);
    final cat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
    final catColor =
        cat != null ? AppColors.fromHex(cat.colorHex) : AppColors.accent;
    return GestureDetector(
      onTap: () => context.push('/transactions/${tx.id}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(CardTokens.radius),
          ),
          child: Row(children: [
            CategoryIcon(
              categoryName: cat?.name ?? '',
              emoji: cat?.icon,
              color: catColor,
              size: 38,
              circular: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        cat?.name ??
                            (tx.note.isNotEmpty
                                ? tx.note
                                : tx.type[0].toUpperCase() +
                                    tx.type.substring(1)),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.tp(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                        formatDate(tx.createdAt.toLocal()),
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.th(context))),
                  ]),
            ),
            const SizedBox(width: 10),
            Text(formatSignedAmount(tx.amount, currency: tx.currency, type: tx.type),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: typeColor),
                textAlign: TextAlign.right),
          ]),
        ),
      ),
    );
  }

}

// ─── Global Search ──────────────────────────────────────────────────────────

class _GlobalSearchDelegate extends SearchDelegate<String?> {
  final WidgetRef ref;
  _GlobalSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Search transactions, accounts...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: AppColors.sf(context), elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: AppColors.th(context)),
          border: InputBorder.none),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _body(context);
  @override
  Widget buildSuggestions(BuildContext context) => _body(context);

  Widget _body(BuildContext context) {
    if (query.length < 2) {
      return Center(
          child: Text('Type at least 2 characters',
              style: TextStyle(color: AppColors.ts(context))));
    }
    final q = query.toLowerCase();
    final entries =
        ref.read(transactionEntriesProvider).value ?? [];
    final accounts =
        ref.read(accountsWithBalanceProvider).value ?? [];
    final categories = ref.read(categoriesProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c};

    final matchTx = entries.where((e) {
      if (e.tx.note.toLowerCase().contains(q)) return true;
      if (e.accountName.toLowerCase().contains(q)) return true;
      final cat = e.tx.categoryId != null ? catMap[e.tx.categoryId] : null;
      if (cat != null && cat.name.toLowerCase().contains(q)) return true;
      return false;
    }).take(10).toList();

    final matchAcct = accounts
        .where((a) => a.account.name.toLowerCase().contains(q))
        .take(5)
        .toList();

    final matchCat = categories
        .where((c) => c.name.toLowerCase().contains(q))
        .take(5)
        .toList();

    if (matchTx.isEmpty && matchAcct.isEmpty && matchCat.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded,
            size: 48, color: AppColors.th(context)),
        const SizedBox(height: 12),
        Text('No results for "$query"',
            style: TextStyle(color: AppColors.ts(context))),
      ]));
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (matchAcct.isNotEmpty) ...[
        _sectionHead(context, 'Accounts'),
        ...matchAcct.map((a) => ListTile(
              leading:
                  Icon(Icons.credit_card_rounded, color: AppColors.accent),
              title: Text(a.account.name),
              subtitle: Text(
                  '${a.account.currency} \u00b7 ${formatAmount(a.balance, currency: a.account.currency)}'),
              onTap: () {
                close(context, null);
                context.push('/accounts/${a.account.id}');
              },
            )),
        const SizedBox(height: 8),
      ],
      if (matchCat.isNotEmpty) ...[
        _sectionHead(context, 'Categories'),
        ...matchCat.map((c) {
          final color = _hex(c.colorHex);
          return ListTile(
            leading: CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(c.name[0],
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600))),
            title: Text(c.name),
            subtitle: Text(c.transactionType),
            onTap: () => close(context, null),
          );
        }),
        const SizedBox(height: 8),
      ],
      if (matchTx.isNotEmpty) ...[
        _sectionHead(context, 'Transactions'),
        ...matchTx.map((e) {
          final cat = e.tx.categoryId != null
              ? catMap[e.tx.categoryId]
              : null;
          return ListTile(
            leading: Icon(
              e.tx.type == 'income'
                  ? Icons.arrow_downward_rounded
                  : e.tx.type == 'expense'
                      ? Icons.arrow_upward_rounded
                      : Icons.swap_horiz_rounded,
              color: e.tx.type == 'income'
                  ? AppColors.healthy
                  : e.tx.type == 'expense'
                      ? AppColors.overspent
                      : AppColors.accent,
            ),
            title: Text(cat?.name ??
                (e.tx.note.isNotEmpty ? e.tx.note : e.tx.type)),
            subtitle: Text(
                '${formatDate(e.tx.createdAt.toLocal())} \u00b7 ${formatAmount(e.tx.amount, currency: e.tx.currency)}'),
            onTap: () {
              close(context, null);
              context.push('/transactions/${e.tx.id}');
            },
          );
        }),
      ],
    ]);
  }

  Widget _sectionHead(BuildContext context, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Text(t,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ts(context),
              letterSpacing: 0.5)));

  Color _hex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ─── Quick-use Templates Section ──────────────────────────────────────────

class _QuickTemplatesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdIdProvider);
    if (householdId == null) return const SizedBox.shrink();

    final db = ref.watch(databaseProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c};

    return FutureBuilder<List<TransactionTemplate>>(
      future: (db.select(db.transactionTemplates)
            ..where((t) => t.householdId.equals(householdId))
            ..orderBy([(t) => OrderingTerm.desc(t.useCount)])
            ..limit(3))
          .get(),
      builder: (context, snapshot) {
        final templates = snapshot.data;
        if (templates == null || templates.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Templates',
                    style: TextStyle(
                      fontSize: TypographyTokens.cardTitleSize,
                      fontWeight: TypographyTokens.cardTitleWeight,
                      color: AppColors.tp(context),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/templates'),
                    child: Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: templates.map((t) {
                  final isIncome = t.type == 'income';
                  final color =
                      isIncome ? AppColors.healthy : AppColors.overspent;
                  final cat = t.categoryId != null
                      ? catMap[t.categoryId]
                      : null;

                  return GestureDetector(
                    onTap: () async {
                      // Increment use count
                      await (db.update(db.transactionTemplates)
                            ..where((r) => r.id.equals(t.id)))
                          .write(TransactionTemplatesCompanion(
                        useCount: Value(t.useCount + 1),
                        lastUsedAt: Value(DateTime.now()),
                      ));

                      if (context.mounted) {
                        context.push('/add-transaction', extra: {
                          'editType': t.type,
                          'editNote': t.title,
                          'editLines': [
                            {
                              'amount': t.amount,
                              'currency': t.currency,
                              'accountId': t.accountId,
                              'categoryId': t.categoryId,
                              'categoryName': cat?.name,
                              'note': '',
                            }
                          ],
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            t.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tp(context),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatAmount(t.amount, currency: t.currency),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}


// ─── Shimmer placeholder ────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
      ),
    );
  }
}
