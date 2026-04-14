import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:drift/drift.dart' hide Column;

import '../../core/database/app_database.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/age_of_money_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/hint_banner.dart' show showHintIfNeeded;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showWeekly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showHintIfNeeded(
        context,
        hintId: 'dashboard_welcome',
        icon: Icons.waving_hand_rounded,
        title: 'Welcome to PocketPlan!',
        body:
            'This is your financial overview. Tap the quick actions below to start recording transactions.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(householdProvider).value;
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
          ref.invalidate(accountsWithBalanceProvider);
          ref.invalidate(allocationsProvider);
          ref.invalidate(unallocatedProvider);
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
                              _greeting(),
                              style: TextStyle(
                                color: AppColors.ts(context),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              household?.name ?? 'PocketPlan',
                              style: TextStyle(
                                color: AppColors.tp(context),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
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

            // Status Card (budget status + velocity + age of money combined)
            SliverToBoxAdapter(
              child: _StatusCard(
                allocationsAsync: allocationsAsync,
                txAsync: txAsync,
                baseCurrency: baseCurrency,
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
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
                            baseAmt += l.amount * l.exchangeRateToBase;
                          }
                        } else {
                          baseAmt = e.tx.amount * e.tx.exchangeRateToBase;
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
                              catColors[name] = _hexToColor(cat.colorHex);
                            }
                          } else {
                            catSpend['Other'] =
                                (catSpend['Other'] ?? 0) + baseAmt;
                          }
                        }
                      }

                      return _SpendingOverviewCard(
                        income: totalIncome,
                        expense: totalExpense,
                        currency: baseCurrency,
                        categorySpend: catSpend,
                        categoryColors: catColors,
                        showWeekly: _showWeekly,
                        onTogglePeriod: () =>
                            setState(() => _showWeekly = !_showWeekly),
                      );
                    },
                    loading: () => const _ShimmerCard(height: 220),
                    error: (e, _) => ErrorRetry(
                      message: "Couldn't load your data",
                      details: '$e',
                      onRetry: () =>
                          ref.invalidate(currentMonthTransactionsProvider),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Actions
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
                        color: AppColors.healthy,
                        onTap: () => context.push('/funding'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Zone 2: Your money ────────────────────────────
                  _SectionHeader(label: 'YOUR MONEY'),
                  const SizedBox(height: 8),
                  // Net Worth Card
                  accountsAsync.when(
                    data: (accounts) {
                      final Map<String, double> totals = {};
                      for (final ab in accounts) {
                        totals[ab.account.currency] =
                            (totals[ab.account.currency] ?? 0) + ab.balance;
                      }
                      return _NetWorthCard(
                        totals: totals,
                        baseCurrency: baseCurrency,
                      );
                    },
                    loading: () => const _ShimmerCard(height: 100),
                    error: (e, _) => ErrorRetry(
                      message: "Couldn't load your data",
                      details: '$e',
                      onRetry: () =>
                          ref.invalidate(accountsWithBalanceProvider),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Envelope Health + Budget Insights (merged)
                  allocationsAsync.when(
                    data: (allocations) {
                      if (allocations.isEmpty) return const SizedBox.shrink();

                      final insights = <_BudgetInsight>[];
                      int healthy = 0, caution = 0, overspent = 0;

                      for (final a in allocations) {
                        final bal = a.balanceByCurrency.values
                            .fold(0.0, (s, v) => s + v);
                        final target = a.data.allocation.targetAmount;

                        if (bal < 0) {
                          overspent++;
                          insights.add(_BudgetInsight(
                            name: a.data.allocation.name,
                            message:
                                'is ${formatAmount(bal.abs())} over its limit',
                            severity: 2,
                          ));
                        } else if (bal < 10) {
                          caution++;
                        } else {
                          healthy++;
                          if (target != null &&
                              target > 0 &&
                              bal / target <= 0.2) {
                            insights.add(_BudgetInsight(
                              name: a.data.allocation.name,
                              message:
                                  'has only ${(bal / target * 100).round()}% left',
                              severity: 1,
                            ));
                          }
                        }
                      }

                      return _EnvelopeHealthCard(
                        total: allocations.length,
                        healthy: healthy,
                        caution: caution,
                        overspent: overspent,
                        insights: insights,
                      );
                    },
                    loading: () => const SizedBox(height: 48),
                    error: (e, _) => ErrorRetry(
                      message: "Couldn't load your data",
                      details: '$e',
                      onRetry: () =>
                          ref.invalidate(allocationsProvider),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Unallocated
                  unallocatedAsync.when(
                    data: (unallocated) {
                      final baseAmount = unallocated[baseCurrency] ?? 0.0;
                      return _SummaryRow(
                        label: 'Ready to assign',
                        subtitle: 'Money not yet in an envelope',
                        amount: baseAmount,
                        currency: baseCurrency,
                        color: baseAmount >= 0
                            ? AppColors.accent
                            : AppColors.overspent,
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: () => context.push('/funding'),
                      );
                    },
                    loading: () => const SizedBox(height: 48),
                    error: (e, _) => ErrorRetry(
                      message: "Couldn't load your data",
                      details: '$e',
                      onRetry: () =>
                          ref.invalidate(unallocatedProvider),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Zone 3: Activity ──────────────────────────────
                  _SectionHeader(label: 'ACTIVITY'),
                  const SizedBox(height: 8),
                  // Quick Templates (above recent transactions)
                  _QuickTemplatesSection(),

                  // Recent Transactions
                  Text(
                    'Recent',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  recentTxAsync.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.sf(context),
                            borderRadius: BorderRadius.circular(14),
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
                      return Column(
                        children: recent
                            .map((e) => _RecentTxTile(
                                  entry: e,
                                  categoryMap: categoryMap,
                                ))
                            .toList(),
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
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showGlobalSearch(BuildContext context, WidgetRef ref) {
    showSearch(context: context, delegate: _GlobalSearchDelegate(ref));
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ─── Status Card (combined: budget status + velocity + age of money) ────────

class _StatusCard extends ConsumerWidget {
  final AsyncValue<List<AllocationWithBalance>> allocationsAsync;
  final AsyncValue<List<TransactionEntry>> txAsync;
  final String baseCurrency;

  const _StatusCard({
    required this.allocationsAsync,
    required this.txAsync,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageAsync = ref.watch(ageOfMoneyProvider);

    // Compute budget status
    String? budgetLine;
    Color? budgetColor;
    IconData? budgetIcon;

    final allocations = allocationsAsync.value;
    final entries = txAsync.value;

    if (allocations != null && entries != null) {
      double totalTarget = 0;
      bool hasTargets = false;
      for (final a in allocations) {
        final target = a.data.allocation.targetAmount;
        if (target != null && target > 0) {
          totalTarget += target;
          hasTargets = true;
        }
      }

      if (hasTargets) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        double monthExpense = 0;
        for (final e in entries) {
          if (e.tx.type == 'expense' &&
              e.tx.createdAt.isAfter(monthStart)) {
            if (e.lines.isNotEmpty) {
              for (final l in e.lines) {
                monthExpense += l.amount * l.exchangeRateToBase;
              }
            } else {
              monthExpense += e.tx.amount * e.tx.exchangeRateToBase;
            }
          }
        }

        final diff = totalTarget - monthExpense;
        final isUnder = diff >= 0;
        budgetColor = isUnder ? AppColors.healthy : AppColors.overspent;
        budgetIcon = isUnder
            ? Icons.check_circle_outline_rounded
            : Icons.warning_amber_rounded;
        budgetLine = isUnder
            ? '${formatAmount(diff, currency: baseCurrency)} left to spend this month'
            : '${formatAmount(diff.abs(), currency: baseCurrency)} over budget this month';
      }
    }

    // Compute velocity
    String? velocityLine;
    Color? velocityColor;
    if (entries != null && allocations != null) {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final daysElapsed = now.difference(monthStart).inDays + 1;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      double monthExpense = 0;
      for (final e in entries) {
        if (e.tx.type == 'expense' &&
            e.tx.createdAt.isAfter(monthStart)) {
          if (e.lines.isNotEmpty) {
            for (final l in e.lines) {
              monthExpense += l.amount * l.exchangeRateToBase;
            }
          } else {
            monthExpense += e.tx.amount * e.tx.exchangeRateToBase;
          }
        }
      }

      if (monthExpense > 0) {
        final dailyRate = monthExpense / daysElapsed;
        final projected = dailyRate * daysInMonth;

        double totalBudget = 0;
        for (final a in allocations) {
          final t = a.data.allocation.targetAmount;
          if (t != null && t > 0) totalBudget += t;
        }

        if (totalBudget <= 0) {
          velocityColor = AppColors.accent;
        } else if (projected <= totalBudget * 0.85) {
          velocityColor = AppColors.healthy;
        } else if (projected <= totalBudget) {
          velocityColor = AppColors.caution;
        } else {
          velocityColor = AppColors.overspent;
        }

        final projectedLabel = projected >= 1000
            ? '${formatAmount(projected / 1000, currency: '')}K'
            : formatAmount(projected, currency: baseCurrency);

        velocityLine =
            'Spending ${formatAmount(dailyRate, currency: baseCurrency)}/day \u00b7 ~$projectedLabel by month end';
      }
    }

    // Age of money
    String? ageLine;
    final ageValue = ageAsync.value;
    if (ageValue != null) {
      ageLine = ageValue == 1
          ? 'Money sits 1 day before being spent'
          : 'Money sits $ageValue days before being spent';
    }

    // If nothing to show, collapse
    if (budgetLine == null && velocityLine == null && ageLine == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? (budgetColor ?? AppColors.accent).withValues(alpha: 0.12)
              : (budgetColor ?? AppColors.accent).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (budgetColor ?? AppColors.accent).withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (budgetLine != null)
              _StatusLine(
                icon: budgetIcon!,
                color: budgetColor!,
                text: budgetLine,
              ),
            if (velocityLine != null) ...[
              if (budgetLine != null) const SizedBox(height: 4),
              _StatusLine(
                icon: Icons.speed_rounded,
                color: velocityColor ?? AppColors.accent,
                text: velocityLine,
              ),
            ],
            if (ageLine != null) ...[
              if (budgetLine != null || velocityLine != null)
                const SizedBox(height: 4),
              _StatusLine(
                icon: Icons.schedule_rounded,
                color: ageValue != null && ageValue >= 30
                    ? AppColors.healthy
                    : ageValue != null && ageValue >= 15
                        ? AppColors.caution
                        : AppColors.overspent,
                text: ageLine,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StatusLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
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
        borderRadius: BorderRadius.circular(14),
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
              SizedBox(
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
                                  child: Text(
                                      formatAmount(expense, currency: currency),
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
              ),
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
        Text('$prefix${formatAmount(amount, currency: currency)}',
            style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color)),
      ],
    );
  }
}

// ─── Net Worth Card ─────────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  final Map<String, double> totals;
  final String baseCurrency;
  const _NetWorthCard({required this.totals, required this.baseCurrency});

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.account_balance_rounded,
                size: 14, color: Colors.white60),
            SizedBox(width: 6),
            Text('Total across all accounts',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          ...totals.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(formatAmount(e.value, currency: e.key),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Quick Action ───────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: 'Add $label',
        button: true,
        child: Tooltip(
          message: 'Add $label',
          child: GestureDetector(
            onTap: () {
              hapticLight();
              onTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
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

// ─── Summary Row ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _SummaryRow(
      {required this.label,
      this.subtitle,
      required this.amount,
      required this.currency,
      required this.color,
      required this.icon,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.bd(context)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.tp(context))),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.ts(context))),
                ],
              )),
          Text(formatAmount(amount, currency: currency),
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16, color: color)),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.th(context)),
          ],
        ]),
      ),
    );
  }
}

// ─── Envelope Health Card (merged health bar + budget insights) ─────────────

class _EnvelopeHealthCard extends StatelessWidget {
  final int total, healthy, caution, overspent;
  final List<_BudgetInsight> insights;

  const _EnvelopeHealthCard({
    required this.total,
    required this.healthy,
    required this.caution,
    required this.overspent,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Envelopes',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ts(context))),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(children: [
            if (healthy > 0)
              Expanded(
                  flex: healthy,
                  child: Container(height: 8, color: AppColors.healthy)),
            if (caution > 0)
              Expanded(
                  flex: caution,
                  child: Container(height: 8, color: AppColors.caution)),
            if (overspent > 0)
              Expanded(
                  flex: overspent,
                  child: Container(height: 8, color: AppColors.overspent)),
          ]),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _HealthLabel(
              count: healthy, label: 'On track', color: AppColors.healthy),
          _HealthLabel(
              count: caution, label: 'Running low', color: AppColors.caution),
          _HealthLabel(
              count: overspent,
              label: 'Overspent',
              color: AppColors.overspent),
        ]),
        // Budget insights inline
        if (insights.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.bd(context)),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.notifications_active_rounded,
                size: 14, color: AppColors.overspent),
            const SizedBox(width: 6),
            Text('Heads up',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.overspent)),
          ]),
          const SizedBox(height: 8),
          ...insights.take(3).map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                          i.severity >= 2
                              ? Icons.warning_rounded
                              : Icons.info_outline_rounded,
                          size: 14,
                          color: i.severity >= 2
                              ? AppColors.overspent
                              : AppColors.caution),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text('${i.name} ${i.message}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.tp(context)))),
                    ]),
              )),
        ],
      ]),
    );
  }
}

class _HealthLabel extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _HealthLabel(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$count $label',
          style: TextStyle(fontSize: 11, color: AppColors.ts(context))),
    ]);
  }
}

// ─── Budget Insight ───────────────────────────────────────────────────────

class _BudgetInsight {
  final String name, message;
  final int severity;
  const _BudgetInsight(
      {required this.name, required this.message, required this.severity});
}

// ─── Recent Transaction Tile ────────────────────────────────────────────────

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
        cat != null ? _hexToColor(cat.colorHex) : AppColors.accent;
    return GestureDetector(
      onTap: () => context.push('/transactions/${tx.id}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(14),
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
                        DateFormat('MMM d')
                            .format(tx.createdAt.toLocal()),
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.th(context))),
                  ]),
            ),
            Flexible(
              child: Text(formatSignedAmount(tx.amount, currency: tx.currency, type: tx.type),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: typeColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
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
        _sectionHead('Accounts'),
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
        _sectionHead('Categories'),
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
        _sectionHead('Transactions'),
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
                '${DateFormat('MMM d').format(e.tx.createdAt.toLocal())} \u00b7 ${formatAmount(e.tx.amount, currency: e.tx.currency)}'),
            onTap: () {
              close(context, null);
              context.push('/transactions/${e.tx.id}');
            },
          );
        }),
      ],
    ]);
  }

  Widget _sectionHead(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Text(t,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

// ─── Section Header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.th(context),
        ),
      ),
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
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
