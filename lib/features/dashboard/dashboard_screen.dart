import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:drift/drift.dart' hide Column;

import '../capture/review_screen.dart';
import '../family/requests_screen.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/providers/accounts_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/hide_amounts_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/report_stats_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/section_header.dart';
import '../../core/providers/dashboard_layout_provider.dart';
import '../../core/providers/period_reset_provider.dart';
import '../../shared/widgets/animated_amount.dart';
import '../../shared/widgets/rolling_number.dart';
import '../../shared/widgets/error_retry.dart';
import 'dashboard_customize_sheet.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/tappable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/premium_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../transactions/widgets/tx_tile.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/empty_state.dart';
import '../accounts/account_type.dart';
import '../accounts/widgets/balance_hero.dart';
import '../reports/widgets/income_expense_summary.dart';
import '../../core/providers/getting_started_provider.dart';
import 'widgets/getting_started_card.dart';
import 'widgets/budget_focus.dart';

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
          // Pulling down fetches the other phones' changes first.
          final failed =
              await ref.read(syncProvider.notifier).pullToRefresh();
          if (failed != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(S.of(context).syncPullFailed(failed)),
              behavior: SnackBarBehavior.floating,
            ));
          }
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
            // ── Header: Cashew large title that collapses on scroll ──
            LargeTitleHeader(
              title: household?.name ?? S.of(context).dashboardDefaultName,
              actions: [
                // Hide amounts — before showing the screen to someone.
                IconButton(
                  tooltip: ref.watch(hideAmountsProvider)
                      ? S.of(context).amountsShow
                      : S.of(context).tileHideAmounts,
                  icon: Icon(
                      ref.watch(hideAmountsProvider)
                          ? AppIcons.eyeSlash
                          : AppIcons.eye,
                      color: AppColors.ts(context),
                      size: 22),
                  onPressed: () =>
                      ref.read(hideAmountsProvider.notifier).toggle(),
                ),
                IconButton(
                  tooltip: S.of(context).dashboardCustomizeTooltip,
                  icon: Icon(AppIcons.slidersHorizontal,
                      color: AppColors.ts(context), size: 22),
                  onPressed: () => showDashboardCustomizeSheet(context),
                ),
                IconButton(
                  tooltip: S.of(context).dashboardSearchTooltip,
                  icon: Icon(AppIcons.magnifyingGlass,
                      color: AppColors.ts(context)),
                  onPressed: () => _showGlobalSearch(context, ref),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
    final gs = ref.watch(gettingStartedProvider).value;
    final checklistShown = !ref.watch(gettingStartedHiddenProvider) &&
        gs != null &&
        !gs.allDone;

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
                      // From the cutoff on: income booked at 00:00 on the
                      // 1st belongs to the month.
                      final filtered = entries
                          .where((e) => !e.tx.createdAt.isBefore(cutoff));

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
                          // Per line, so split transactions show their
                          // real categories.
                          final otherLabel =
                              S.of(context).dashboardOtherCategory;
                          baseAmountByCategory(e, baseCurrency)
                              .forEach((catId, amt) {
                            final cat =
                                catId != null ? categoryMap[catId] : null;
                            final name = cat?.name ?? otherLabel;
                            catSpend[name] = (catSpend[name] ?? 0) + amt;
                            if (cat != null && !catColors.containsKey(name)) {
                              catColors[name] = AppColors.fromHex(cat.colorHex);
                            }
                          });
                        }
                      }

                      // Hide spending overview entirely when no activity
                      if (totalExpense == 0 && totalIncome == 0) {
                        return const SizedBox.shrink();
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
                      message: S.of(context).commonCouldntLoadData,
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
                          topCat = categoryMap[entry.key]?.name ?? S.of(context).dashboardOtherCategory;
                        }
                      }
                    }

                    // Overall comparison
                    final pctChange = ((current.expense - previous.expense) / previous.expense * 100).round();

                    String? message;
                    IconData? icon;
                    Color? color;

                    final sl = S.of(context);
                    if (topCat != null && topIncrease >= 30) {
                      message = sl.dashboardCatSpendingHigher(topCat, topIncrease.round());
                      icon = AppIcons.trendUp;
                      color = AppColors.caution;
                    } else if (pctChange <= -15) {
                      message = sl.dashboardSpendingLowerNice(pctChange.abs());
                      icon = AppIcons.trendDown;
                      color = AppColors.healthy;
                    } else if (pctChange >= 20) {
                      message = sl.dashboardSpendingHigher(pctChange);
                      icon = AppIcons.trendUp;
                      color = AppColors.caution;
                    }

                    if (message == null) {
                      message = sl.dashboardSpendingOnTrack;
                      icon = AppIcons.checkCircle;
                      color = AppColors.healthy;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.pastel(context, color!,
                            light: 0.88, dark: 0.8),
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(message,
                                style: TextStyle(
                                    fontSize: TypographyTokens.captionSize,
                                    color: color,
                                    fontWeight: TypographyTokens.captionWeight)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
    ];

    sectionWidgets[DashboardSection.quickActions] = [
                  SectionHeader(S.of(context).dashboardSectionQuickLabel),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final qs = S.of(context);
                    final hasEnvelopes = allocationsAsync.value?.isNotEmpty ?? false;
                    return Row(
                    children: [
                      _QuickAction(
                        icon: AppIcons.minus,
                        label: qs.typeExpense,
                        onTap: () => context.push('/add-transaction',
                            extra: {'editType': 'expense'}),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: AppIcons.plus,
                        label: qs.typeIncome,
                        onTap: () => context.push('/add-transaction',
                            extra: {'editType': 'income'}),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: AppIcons.arrowsLeftRight,
                        label: qs.dashboardQuickTransfer,
                        onTap: () => context.push('/add-transaction',
                            extra: {'editType': 'transfer'}),
                      ),
                      if (hasEnvelopes) ...[
                        const SizedBox(width: 10),
                        _QuickAction(
                          icon: AppIcons.piggyBank,
                          label: qs.dashboardQuickFund,
                          tooltip: qs.dashboardFundEnvelopesTooltip,
                          onTap: () => context.push('/funding'),
                        ),
                      ],
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: AppIcons.arrowsSplit,
                        label: qs.dashboardQuickSplit,
                        tooltip: qs.dashboardSplitBillTooltip,
                        onTap: () {
                          if (!checkPremiumAccess(context, ref, PremiumFeature.billSplitter)) return;
                          context.push('/bill-splitter');
                        },
                      ),
                    ],
                  );
                  }),
                  const SizedBox(height: 20),
    ];

    sectionWidgets[DashboardSection.budget] = [
                  // Ready to assign, overspent, bills and safe to spend.
                  BudgetFocus(baseCurrency: baseCurrency),
                  const SizedBox(height: 8),
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
                        data: (_) {
                          // The shared balance hero (Accounts, account
                          // detail, Reports balance sheet).
                          return BalanceHero(
                            onTap: () => context.push('/accounts'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(S.of(context).dashboardNetWorth,
                                    style: balanceHeroLabelStyle(context)),
                                const SizedBox(height: Spacing.xs),
                                // Large amounts shrink to one line instead of wrapping.
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: RollingNumber(
                                    amount: baseNetWorth,
                                    currency: baseCurrency,
                                    lazyFirstRender: false,
                                    style: balanceHeroAmountStyle(context,
                                        value: baseNetWorth),
                                  ),
                                ),
                                if (otherNetWorthCount > 0)
                                  Text(
                                    S.of(context).dashboardOtherCount(otherNetWorthCount),
                                    style: TextStyle(
                                        fontSize: TypographyTokens.captionSize,
                                        color: AppColors.ts(context)),
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
                      message: S.of(context).commonCouldntLoadData,
                      details: '$e',
                      onRetry: () =>
                          ref.invalidate(accountsWithBalanceProvider),
                    ),
                  ),
                  const SizedBox(height: 16),
    ];

    sectionWidgets[DashboardSection.activity] = [
                  // Quick Templates (only shown when templates exist — handled internally)
                  _QuickTemplatesSection(),
                  const SizedBox(height: 4),
                  recentTxAsync.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        // Money comes in first, then gets jobs. The
                        // checklist already offers this step.
                        return EmptyState(
                          icon: AppIcons.receipt,
                          title: S.of(context).dashboardNoTransactionsYet,
                          actionLabel: checklistShown
                              ? null
                              : S.of(context).dashboardRecordIncome,
                          onAction: checklistShown
                              ? null
                              : () => context.push('/add-transaction',
                                  extra: {'editType': 'income'}),
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
                                  color: AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                                ),
                                child: Row(
                                  children: [
                                    Icon(AppIcons.sun,
                                        size: 16, color: AppColors.accentText(context)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        S.of(context).dashboardNoTransactionsToday,
                                        style: TextStyle(
                                          fontSize: TypographyTokens.captionSize,
                                          fontWeight: TypographyTokens.captionWeight,
                                          color: AppColors.accentText(context),
                                        ),
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
                              child: TxTile(
                                entry: e.value,
                                categoryMap: categoryMap,
                                showBalance: false,
                                showDate: true,
                              ),
                            )),
                        ],
                      );
                    },
                    loading: () => const _ShimmerCard(height: 200),
                    error: (e, _) => ErrorRetry(
                      message: S.of(context).commonCouldntLoadData,
                      details: '$e',
                      onRetry: () =>
                          ref.invalidate(recentTransactionsProvider),
                    ),
                  ),
    ];

    // Build ordered list from provider layout; the getting-started
    // checklist (new budgets only) leads.
    // Bank alerts waiting to be added lead after it.
    final result = <Widget>[
      const GettingStartedCard(),
      const ReviewAlertsCard(),
      const RequestsCard(),
    ];
    for (final config in layout) {
      if (config.visible && sectionWidgets.containsKey(config.section)) {
        result.addAll(sectionWidgets[config.section]!);
      }
    }
    return result;
  }


  void _showGlobalSearch(BuildContext context, WidgetRef ref) {
    showSearch(context: context, delegate: _GlobalSearchDelegate(ref, S.of(context)));
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
    final sorted = categorySpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sorted.take(5).toList();
    // Subcategories inherit their parent's color, so siblings would draw as
    // one solid ring — shift the shade each time a color repeats. A slice
    // without a category color (uncategorized) uses the accent, as in
    // Reports > Categories.
    final sliceColors = <Color>[];
    final seen = <int, int>{};
    for (var i = 0; i < topCategories.length; i++) {
      final base = categoryColors[topCategories[i].key] ?? AppColors.accent;
      final repeat = seen.update(base.toARGB32(), (n) => n + 1, ifAbsent: () => 0);
      sliceColors.add(AppColors.repeatShade(base, repeat));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Spending" and a two-way switch that names both periods (one
          // chip naming the other period read as the card's own title).
          Row(
            children: [
              Expanded(
                child: Text(S.of(context).dashSpendingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: TypographyTokens.cardTitleSize,
                        fontWeight: TypographyTokens.cardTitleWeight,
                        color: AppColors.tp(context))),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final (weekly, label) in [
                    (false, S.of(context).dashboardThisMonth),
                    (true, S.of(context).dashboardLast7Days),
                  ])
                    Tappable(
                      onTap: weekly == showWeekly ? null : onTogglePeriod,
                      borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      color: weekly == showWeekly
                          ? AppColors.sf(context)
                          : Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Text(label,
                            style: TextStyle(
                              fontSize: TypographyTokens.overlineSize,
                              fontWeight: weekly == showWeekly
                                  ? FontWeight.w800
                                  : TypographyTokens.overlineWeight,
                              color: weekly == showWeekly
                                  ? AppColors.tp(context)
                                  : AppColors.ts(context),
                            )),
                      ),
                    ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Semantics(
                label: expense > 0
                    ? S.of(context).dashboardChartSemantic(formatAmount(expense, currency: currency), topCategories.length)
                    : S.of(context).dashboardNoSpendingSemantic,
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
                              final color = sliceColors[e.key];
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
                                          fontSize: TypographyTokens.amountRegularSize,
                                          fontFamily: TypographyTokens.displayFamily,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.tp(context))),
                                ),
                              ),
                              Text(S.of(context).dashboardSpent,
                                  style: TextStyle(
                                      fontSize: TypographyTokens.miniSize,
                                      color: AppColors.ts(context))),
                            ],
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AppIcons.chartPie,
                                size: 32, color: AppColors.th(context)),
                            const SizedBox(height: 4),
                            Text(S.of(context).dashboardNoSpending,
                                style: TextStyle(
                                    fontSize: TypographyTokens.overlineSize,
                                    color: AppColors.ts(context))),
                          ],
                        ),
                      ),
              )),
              const SizedBox(width: 20),
              Expanded(
                child: IncomeExpenseSummary(
                  income: income,
                  expense: expense,
                  currency: currency,
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
                final color = sliceColors[e.key];
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
                            fontSize: TypographyTokens.captionSize,
                            color: AppColors.ts(context))),
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

// ─── Quick Action ───────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? tooltip;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.tooltip});

  @override
  Widget build(BuildContext context) {
    // One family: card tiles with the accent in the icon circle — colour
    // is kept for meaning (overspent, income), not for buttons.
    return Expanded(
      child: Semantics(
        label: tooltip ?? S.of(context).dashboardAddLabel(label),
        button: true,
        child: Tooltip(
          message: tooltip ?? S.of(context).dashboardAddLabel(label),
          child: DecoratedBox(
            decoration: AppColors.card(context),
            child: Tappable(
              onTap: onTap,
              borderRadius: BorderRadius.circular(CardTokens.radius),
              color: AppColors.sf(context),
              scaleFactor: 0.93,
              haptic: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(children: [
                  Container(
                    width: CategoryIconTokens.compactSize,
                    height: CategoryIconTokens.compactSize,
                    decoration: BoxDecoration(
                      color: AppColors.pastel(context, AppColors.accent,
                          light: 0.85, dark: 0.78),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon,
                        size: 20, color: AppColors.accentText(context)),
                  ),
                  const SizedBox(height: 6),
                  // Five actions share the width: shrink the label rather
                  // than cut it ("Expen…") on narrow phones.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label,
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: TypographyTokens.captionSize,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tp(context))),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Global Search ──────────────────────────────────────────────────────────

class _GlobalSearchDelegate extends SearchDelegate<String?> {
  final WidgetRef ref;
  final S _s;
  _GlobalSearchDelegate(this.ref, this._s);

  @override
  String get searchFieldLabel => _s.dashboardSearchPlaceholder;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    // The app's AppBar theme as is; only the search field drops the
    // filled input look so it reads as the bar's title.
    return theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: AppColors.th(context)),
          border: InputBorder.none),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
              icon: const Icon(AppIcons.x),
              onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(AppIcons.arrowLeft),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _body(context);
  @override
  Widget buildSuggestions(BuildContext context) => _body(context);

  Widget _body(BuildContext context) {
    if (query.length < 2) {
      return EmptyState(
        icon: AppIcons.magnifyingGlass,
        title: S.of(context).dashboardTypeAtLeast2,
      );
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
      return EmptyState(
        icon: AppIcons.magnifyingGlassMinus,
        title: S.of(context).searchNoMatches,
        subtitle: S.of(context).dashboardNoResultsFor(query),
      );
    }

    final s = S.of(context);
    String typeLabel(String type) => switch (type) {
          'income' => s.typeIncome,
          'transfer' => s.typeTransfer,
          _ => s.typeExpense,
        };

    return ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        children: [
      if (matchAcct.isNotEmpty) ...[
        _sectionHead(context, s.dashboardSearchAccounts),
        ...matchAcct.map((a) => ListTile(
              leading: AccountTypeBadge(a.account.type,
                  size: CategoryIconTokens.compactSize),
              title: Text(a.account.name),
              subtitle: Text(
                  '${accountTypeLabel(s, a.account.type)} · ${formatAmount(a.balance, currency: a.account.currency)}'),
              onTap: () {
                close(context, null);
                context.push('/accounts/${a.account.id}');
              },
            )),
        const SizedBox(height: Spacing.sm),
      ],
      if (matchCat.isNotEmpty) ...[
        _sectionHead(context, s.dashboardSearchCategories),
        ...matchCat.map((c) => ListTile(
              leading: CategoryIcon(
                categoryName: c.name,
                emoji: c.icon,
                color: AppColors.fromHex(c.colorHex),
                size: CategoryIconTokens.compactSize,
                circular: true,
              ),
              title: Text(c.name),
              subtitle: Text(typeLabel(c.transactionType)),
              onTap: () => close(context, null),
            )),
        const SizedBox(height: Spacing.sm),
      ],
      if (matchTx.isNotEmpty) ...[
        _sectionHead(context, s.dashboardSearchTransactions),
        // The same rows as Activity and Home: category emoji, the line's
        // own amount and currency, the user's income/expense colors.
        ...matchTx.map((e) => TxTile(
              entry: e,
              categoryMap: catMap,
              showBalance: false,
              showDate: true,
              onTap: () {
                close(context, null);
                context.push('/transactions/${e.tx.id}');
              },
            )),
      ],
    ]);
  }

  Widget _sectionHead(BuildContext context, String t) => SectionHeader(t,
      padding: const EdgeInsetsDirectional.fromSTEB(
          Spacing.lg, Spacing.xs, Spacing.lg, Spacing.xs));

}

// ─── Quick-use Templates Section ──────────────────────────────────────────

class _QuickTemplatesSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_QuickTemplatesSection> createState() =>
      _QuickTemplatesSectionState();
}

class _QuickTemplatesSectionState
    extends ConsumerState<_QuickTemplatesSection> {
  late Future<List<TransactionTemplate>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) {
      _templatesFuture = Future.value([]);
      return;
    }
    _templatesFuture = (db.select(db.transactionTemplates)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.useCount)])
          ..limit(3))
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final catMap = {for (final c in categories) c.id: c};
    final db = ref.read(databaseProvider);
    final txColors = ref.watch(txColorsProvider);

    return FutureBuilder<List<TransactionTemplate>>(
      future: _templatesFuture,
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
              SectionHeader(
                S.of(context).dashboardQuickTemplates,
                trailing: TextButton(
                  onPressed: () => context.push('/templates'),
                  child: Text(S.of(context).dashboardViewAll),
                ),
              ),
              const SizedBox(height: Spacing.headerToCard),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: templates.map((t) {
                  final color = txColors.forType(t.type);
                  final cat = t.categoryId != null
                      ? catMap[t.categoryId]
                      : null;

                  return Tappable(
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                    scaleFactor: 0.95,
                    haptic: true,
                    onTap: () async {
                      // Increment use count
                      await (db.update(db.transactionTemplates)
                            ..where((r) => r.id.equals(t.id)))
                          .write(TransactionTemplatesCompanion(
                        useCount: Value(t.useCount + 1),
                        lastUsedAt: Value(DateTime.now()),
                        lastModified: Value(DateTime.now()),
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
                        color: AppColors.pastel(context, color,
                            light: 0.88, dark: 0.8),
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.lightning,
                              size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            t.title,
                            style: TextStyle(
                              fontSize: TypographyTokens.captionSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tp(context),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatAmount(t.amount, currency: t.currency),
                            style: TextStyle(
                              fontSize: TypographyTokens.captionSize,
                              fontWeight: TypographyTokens.amountSmallWeight,
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
    return SkeletonLoader(
      height: height,
      borderRadius: CardTokens.radius,
    );
  }
}
