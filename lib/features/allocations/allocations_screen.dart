import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:drift/drift.dart' hide Column;

import '../../core/engine/period_engine.dart' show budgetPeriodFor;
import '../../core/database/app_database.dart' show Category;
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/objectives_provider.dart';
import '../../core/providers/period_reset_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/utils/calendar_days.dart';
import '../../shared/widgets/envelope_row.dart';
import '../../shared/widgets/budget_progress.dart';
import '../../shared/widgets/ready_to_assign_banner.dart';

import '../../core/providers/premium_provider.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/tappable.dart';
import 'archived_envelopes_sheet.dart';
import 'move_money_sheet.dart';
import 'period_summary_card.dart';
import 'reorder_envelopes_sheet.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/theme/app_icons.dart';
import '../../core/providers/seal_provider.dart';
import '../../core/providers/sinking_fund_provider.dart';
import 'sinking_fund_widgets.dart';

class AllocationsScreen extends ConsumerStatefulWidget {
  const AllocationsScreen({super.key});

  @override
  ConsumerState<AllocationsScreen> createState() => _AllocationsScreenState();
}

class _AllocationsScreenState extends ConsumerState<AllocationsScreen>
    with AutomaticKeepAliveClientMixin {
  static const _typeOrder = ['sinking', 'spending', 'flexible'];

  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showSearch = false;

  /// Planned amounts per allocation ID (allocationId → amount).
  Map<String, double> _plannedByAllocation = {};
  /// Planned currency per allocation ID.
  Map<String, String> _plannedCurrencyByAllocation = {};

  /// Remap legacy 'saving' type to 'flexible'
  static String _normalizeType(String type) =>
      type == 'saving' ? 'flexible' : type;

  @override
  void initState() {
    super.initState();
    _loadPlannedAmounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlannedAmounts() async {
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      // Planned expenses due by the end of this budget period (later months
      // aren't this period's budget; earlier unposted ones still are).
      final household = ref.read(householdProvider).value;
      final periodEnd =
          budgetPeriodFor(household?.periodStartDay ?? 1).end;
      final baseCurrency = household?.baseCurrency ?? 'USD';
      final planned = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.status.equals('planned') &
                t.deleted.equals(false) &
                t.type.equals('expense') &
                t.createdAt.isSmallerThanValue(periodEnd)))
          .get();

      if (planned.isEmpty) {
        if (mounted) {
          setState(() {
            _plannedByAllocation = {};
            _plannedCurrencyByAllocation = {};
          });
        }
        return;
      }

      // Fetch their lines
      final txIds = planned.map((t) => t.id).toList();
      final lines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.isIn(txIds)))
          .get();

      // Fetch all categories to get categoryId → allocationId mapping
      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catToAlloc = <String, String>{};
      for (final c in categories) {
        if (c.allocationId != null) {
          catToAlloc[c.id] = c.allocationId!;
        }
      }
      // Unlinked subcategories spend from the parent's envelope (as in
      // AllocationEngine.recordTransaction).
      for (final c in categories) {
        if (c.allocationId == null && c.parentId != null) {
          final parentAlloc = catToAlloc[c.parentId];
          if (parentAlloc != null) catToAlloc[c.id] = parentAlloc;
        }
      }

      // Only amounts in the envelope's own currency are summed — never mix
      // currencies (the card shows "$X planned" in that currency).
      final allocs = await (db.select(db.allocations)
            ..where((a) => a.householdId.equals(householdId)))
          .get();
      final allocCurrency = {
        for (final a in allocs) a.id: a.targetCurrency ?? baseCurrency,
      };

      // Map lines → allocations and sum amounts
      final amountMap = <String, double>{};
      final currencyMap = <String, String>{};

      for (final line in lines) {
        if (line.categoryId == null) continue;
        final allocId = catToAlloc[line.categoryId];
        if (allocId == null) continue;
        final currency = allocCurrency[allocId] ?? baseCurrency;
        if (line.currency != currency) continue;
        amountMap[allocId] = (amountMap[allocId] ?? 0) + line.amount;
        currencyMap[allocId] = currency;
      }

      // For transactions without lines, use header categoryId
      for (final tx in planned) {
        if (tx.categoryId == null) continue;
        // Check if this tx already had lines processed
        final hasLines = lines.any((l) => l.transactionId == tx.id);
        if (hasLines) continue;
        final allocId = catToAlloc[tx.categoryId];
        if (allocId == null) continue;
        final currency = allocCurrency[allocId] ?? baseCurrency;
        if (tx.currency != currency) continue;
        amountMap[allocId] = (amountMap[allocId] ?? 0) + tx.amount;
        currencyMap[allocId] = currency;
      }

      if (mounted) {
        setState(() {
          _plannedByAllocation = amountMap;
          _plannedCurrencyByAllocation = currencyMap;
        });
      }
    } catch (e) {
      debugPrint('[AllocationsScreen] Error loading planned amounts: $e');
    }
  }

  String _sectionTitle(String type) => switch (type) {
        'spending' => S.of(context).allocSectionSpending,
        'flexible' => S.of(context).allocSectionFlexible,
        'sinking' => S.of(context).sinkSection,
        _ => type[0].toUpperCase() + type.substring(1),
      };

  @override
  bool get wantKeepAlive => true;

  void _showEnvelopeHelp(BuildContext context) {
    final l = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.allocHelpTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _helpRow('1', l.allocHelpStep1),
            const SizedBox(height: 10),
            _helpRow('2', l.allocHelpStep2),
            const SizedBox(height: 10),
            _helpRow('3', l.allocHelpStep3),
            const SizedBox(height: 10),
            _helpRow('4', l.allocHelpStep4),
          ],
        ),
        actions: [
          FilledButton(
            style: DialogButtons.filled,
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.allocGotIt),
          ),
        ],
      ),
    );
  }

  Widget _helpRow(String num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.pastel(context, AppColors.accent,
                light: 0.85, dark: 0.78),
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
          child: Center(
            child: Text(num,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = S.of(context);
    final allocationsAsync = ref.watch(visibleAllocationsProvider);
    final unallocatedAsync = ref.watch(unallocatedProvider);
    final household = ref.watch(householdProvider).value;
    final baseCurrency = household?.baseCurrency ?? 'USD';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allocationsProvider);
          ref.invalidate(unallocatedProvider);
          _loadPlannedAmounts();
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
        slivers: [
          // -- Header: Cashew large title that collapses on scroll --
          LargeTitleHeader(
            title: l.allocTitle,
            actions: [
              IconButton(
                tooltip: l.allocSearchTooltip,
                icon: Icon(
                  _showSearch
                      ? AppIcons.magnifyingGlassMinus
                      : AppIcons.magnifyingGlass,
                  color: AppColors.ts(context),
                ),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(AppIcons.dotsThreeVertical,
                    color: AppColors.ts(context)),
                onSelected: (v) {
                  if (v == 'reorder') {
                    showReorderEnvelopesSheet(context, ref);
                  } else if (v == 'archived') {
                    showArchivedEnvelopesSheet(context, ref);
                  } else if (v == 'help') {
                    _showEnvelopeHelp(context);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'reorder',
                    child: Row(children: [
                      Icon(AppIcons.list,
                          size: 20, color: AppColors.ts(context)),
                      const SizedBox(width: 12),
                      Text(l.allocReorderTitle),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'archived',
                    child: Row(children: [
                      Icon(AppIcons.boxArrowUp,
                          size: 20, color: AppColors.ts(context)),
                      const SizedBox(width: 12),
                      Text(l.allocArchivedTitle),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'help',
                    child: Row(children: [
                      Icon(AppIcons.question,
                          size: 20, color: AppColors.ts(context)),
                      const SizedBox(width: 12),
                      Text(l.allocHelpTooltip),
                    ]),
                  ),
                ],
              ),
            ],
          ),

          // -- Search bar --
          if (_showSearch)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: l.allocSearchHint,
                    hintStyle: TextStyle(color: AppColors.th(context)),
                    prefixIcon:
                        Icon(AppIcons.magnifyingGlass, color: AppColors.ts(context)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(AppIcons.x, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.tp(context),
                  ),
                ),
              ),
            ),

          // -- Last period summary (first week of a new period) --
          if (_searchQuery.isEmpty)
            const SliverToBoxAdapter(child: PeriodSummaryCard()),

          // -- Period Reset Banner --
          if (_searchQuery.isEmpty)
          SliverToBoxAdapter(
            child: ref.watch(pendingResetProvider).when(
              data: (pendingIds) {
                if (pendingIds.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.pastel(context, AppColors.caution,
                        light: 0.85, dark: 0.78),
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.clockClockwise,
                          size: 20, color: AppColors.caution),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                l.allocNEnvelopesNeedReset(pendingIds.length),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.tp(context))),
                            Text(
                              l.allocNewPeriodStarted,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.ts(context)),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.push('/period-transition'),
                        child: Text(l.allocReview),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // -- Unallocated Banner (hidden during search) --
          if (_searchQuery.isEmpty)
          SliverToBoxAdapter(
            child: unallocatedAsync.when(
              data: (unallocated) => ReadyToAssignBanner(
                unallocated: unallocated,
                baseCurrency: baseCurrency,
                hasAllocations: (allocationsAsync.value?.isNotEmpty ?? false),
                anyFunded: allocationsAsync.value?.any((a) => a
                        .balanceByCurrency.values
                        .any((v) => v > 0.005)) ??
                    false,
                anyOverspent: allocationsAsync.value?.any((a) => a
                        .balanceByCurrency.values
                        .any((v) => v < -0.005)) ??
                    false,
              ),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // -- Budgeted · spent · left, as three small tiles (base
          // currency, spending envelopes only — the same "budgeted" as the
          // Activity tab's month card; savings targets aren't a month's
          // budget) --
          if (_searchQuery.isEmpty)
          SliverToBoxAdapter(
            child: Builder(builder: (context) {
              final allocations = allocationsAsync.value ?? const [];
              if (allocations.isEmpty) return const SizedBox.shrink();
              // Only base-currency envelopes: currencies never mix.
              final baseAllocs = allocations.where((a) =>
                  a.data.allocation.type == 'spending' &&
                  (a.data.allocation.targetCurrency ?? baseCurrency) ==
                      baseCurrency);
              final totalBudgeted = baseAllocs.fold<double>(
                  0.0, (sum, a) => sum + (a.data.allocation.targetAmount ?? 0.0));
              final period = BudgetProgress.currentPeriod(
                  household?.periodStartDay ?? 1);
              // In base money, other currencies at their rate — the same
              // number as the Activity month card's Spent.
              final spending = ref
                      .watch(baseEnvelopeSpendingProvider(
                          (from: period.start, to: period.end)))
                      .value ??
                  const <String, double>{};
              final totalSpent = baseAllocs.fold<double>(0.0,
                  (sum, a) => sum + (spending[a.data.allocation.id] ?? 0));
              final daysLeft =
                  calendarDaysBetween(DateTime.now(), period.end).clamp(0, 999);
              final left = totalBudgeted - totalSpent;
              Widget tile(String label, double value, {bool over = false}) =>
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.sfv(context),
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: TypographyTokens.captionSize,
                                  color: AppColors.ts(context))),
                          // Long amounts (LBP) shrink instead of wrapping.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                                formatAmount(value, currency: baseCurrency),
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: over
                                        ? AppColors.overspent
                                        : AppColors.tp(context))),
                          ),
                        ],
                      ),
                    ),
                  );
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(children: [
                  tile(l.allocBudgetedLabel, totalBudgeted),
                  const SizedBox(width: 8),
                  tile(l.allocSpentLabel, totalSpent),
                  const SizedBox(width: 8),
                  tile(l.allocDaysLeft(daysLeft), left, over: left < -0.005),
                ]),
              );
            }),
          ),

          // -- Goals & Loans shortcut --
          if (_searchQuery.isEmpty)
          SliverToBoxAdapter(
            child: _GoalsLoansBanner(),
          ),

          // -- Allocations List --
          allocationsAsync.when(
            data: (allocations) {
              if (allocations.isEmpty) {
                return const SliverFillRemaining(child: _EmptyState());
              }

              // Filter by search query.
              final filtered = _searchQuery.isEmpty
                  ? allocations
                  : allocations
                      .where((a) => a.data.allocation.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();

              // Group by normalized type, preserving order.
              final grouped = <String, List<AllocationWithBalance>>{};
              for (final type in _typeOrder) {
                final items = filtered
                    .where((a) => _normalizeType(a.data.allocation.type) == type)
                    .toList();
                if (items.isNotEmpty) grouped[type] = items;
              }
              // Catch any types not in the predefined order.
              for (final a in filtered) {
                final t = _normalizeType(a.data.allocation.type);
                if (!_typeOrder.contains(t)) {
                  grouped.putIfAbsent(t, () => []).add(a);
                }
              }

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: AppIcons.magnifyingGlassMinus,
                    title: l.allocNoMatch(_searchQuery),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildGroupedList(context, grouped, baseCurrency),
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: SkeletonList(),
            ),
            error: (e, _) => SliverFillRemaining(
              child: ErrorRetry(
                message: l.commonCouldntLoadData,
                details: '$e',
                onRetry: () => ref.invalidate(allocationsProvider),
              ),
            ),
          ),

          // Other members' private envelopes: one line, so the money on
          // this tab still adds up.
          if (ref.watch(privateBalancesProvider)
                  case final private when private.isNotEmpty &&
                      _searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: AppColors.card(context),
                  child: Row(children: [
                    Icon(AppIcons.lock, size: 20, color: AppColors.ts(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l.familyPrivateLine,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    Text(
                      private.entries
                          .where((e) => e.value.abs() > 0.005)
                          .map((e) => formatAmount(e.value, currency: e.key))
                          .join(' · '),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              ),
            ),

          // Bottom padding so FAB doesn't cover last card.
          const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
        ],
      ),
      ),
      // Hidden while there are no envelopes: the empty state's button is
      // the same action.
      floatingActionButton: (allocationsAsync.value?.isEmpty ?? true)
          ? null
          : FloatingActionButton(
        heroTag: 'fab_allocations',
        tooltip: l.allocCreateTooltip,
        onPressed: () {
          final allocs = ref.read(visibleAllocationsProvider).value ?? [];
          if (!checkFreeLimit(context, ref, allocs.length, FreeLimits.maxEnvelopes, 'envelopes')) return;
          context.push('/allocations/new');
        },
        child: const Icon(AppIcons.plus),
      ),
    );
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    Map<String, List<AllocationWithBalance>> grouped,
    String baseCurrency,
  ) {
    final l = S.of(context);
    final widgets = <Widget>[];
    final pendingIds = ref.watch(pendingResetProvider).value ?? const <String>[];
    final sealedIds =
        ref.watch(sealedEnvelopesProvider).value ?? const <String>{};
    final spending = ref.watch(periodSpendingProvider).value ?? const {};
    final funds = ref.watch(sinkingFundsProvider).value ?? const {};
    // Envelope → its linked category (categories.allocationId; a top-level
    // one wins over a subcategory). The legacy allocations.categoryId join
    // is empty for envelopes created since categories link themselves.
    final linkedCat = <String, Category>{};
    for (final c in ref.watch(categoriesProvider).value ?? const <Category>[]) {
      final id = c.allocationId;
      if (id == null) continue;
      final existing = linkedCat[id];
      if (existing == null ||
          (existing.parentId != null && c.parentId == null)) {
        linkedCat[id] = c;
      }
    }

    bool isOver(AllocationWithBalance a) =>
        overspentCurrency(a.balanceByCurrency,
            a.data.allocation.targetCurrency ?? baseCurrency) !=
        null;

    Widget row(AllocationWithBalance a) {
      final alloc = a.data.allocation;
      final cur = alloc.targetCurrency ?? baseCurrency;
      final cat = linkedCat[alloc.id] ?? a.data.category;
      final fund = funds[alloc.id];
      if (fund != null && !isOver(a)) {
        return SinkingFundRow(
          key: ValueKey(alloc.id),
          fund: fund,
          baseCurrency: baseCurrency,
          icon: alloc.icon ?? cat?.icon,
          color: cat != null ? AppColors.fromHex(cat.colorHex) : AppColors.accent,
          onTap: () {
            hapticLight();
            context.push('/allocations/${alloc.id}');
          },
        );
      }
      return EnvelopeRow(
        key: ValueKey(alloc.id),
        needsReview: pendingIds.contains(alloc.id),
        sealed: sealedIds.contains(alloc.id),
        name: alloc.name,
        type: alloc.type,
        balanceByCurrency: a.balanceByCurrency,
        baseCurrency: baseCurrency,
        targetAmount: alloc.targetAmount,
        targetCurrency: alloc.targetCurrency,
        secondTargetAmount: alloc.secondTargetAmount,
        secondTargetCurrency: alloc.secondTargetCurrency,
        secondSpent: alloc.secondTargetCurrency == null
            ? 0
            : spending[alloc.id]?[alloc.secondTargetCurrency] ?? 0,
        envelopeIcon: alloc.icon,
        categoryName: cat?.name,
        categoryIcon: cat?.icon,
        categoryColorHex: cat?.colorHex,
        spent: spending[alloc.id]?[cur] ?? 0,
        plannedAmount: _plannedByAllocation[alloc.id],
        plannedCurrency: _plannedCurrencyByAllocation[alloc.id],
        onTap: () {
          hapticLight();
          context.push('/allocations/${alloc.id}');
        },
        onCover: () {
          final overCur = overspentCurrency(a.balanceByCurrency, cur) ?? cur;
          showMoveMoneySheet(context, ref,
              toId: alloc.id,
              currency: overCur,
              amount: -(a.balanceByCurrency[overCur] ?? 0),
              cover: true);
        },
      );
    }

    Widget card(List<AllocationWithBalance> items, {Color? color}) {
      return Container(
        decoration: color == null
            ? AppColors.card(context)
            : BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(CardTokens.radius)),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 14,
                  color: AppColors.bd(context)),
            row(items[i]),
          ],
        ]),
      );
    }

    Widget header(String title, int count, double? total,
        {bool first = false, String? trailing}) {
      if (trailing != null) {
        // A line of its own under the title: amounts in two currencies
        // don't fit beside it.
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header(title, count, null, first: first),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 4, end: 4, bottom: 8),
                child: Text(trailing,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ts(context))),
              ),
            ]);
      }
      return Padding(
        padding: EdgeInsetsDirectional.only(
            top: first ? 4 : 20, bottom: 8, start: 4, end: 4),
        child: Row(children: [
          SectionHeader(title),
          const SizedBox(width: 8),
          Text('$count',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.th(context))),
          const Spacer(),
          if (total != null)
            Text(formatAmount(total, currency: baseCurrency),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: total < 0
                        ? AppColors.overspent
                        : AppColors.ts(context))),
        ]),
      );
    }

    // Overspent envelopes first, in their own tinted card (not while
    // searching: then every match stays in its section).
    final overspent = _searchQuery.isEmpty
        ? [for (final items in grouped.values) ...items.where(isOver)]
        : const <AllocationWithBalance>[];
    if (overspent.isNotEmpty) {
      widgets.add(header(l.allocNeedsAttention, overspent.length, null,
          first: true));
      widgets.add(card(overspent,
          color: AppColors.pastel(context, AppColors.overspent,
              light: 0.9, dark: 0.82)));
    }

    for (final entry in grouped.entries) {
      final items = entry.value.where((a) => !overspent.contains(a)).toList();
      if (items.isEmpty) continue;
      // Section total in base currency only (no mixing).
      final sectionTotal = entry.value.fold<double>(
          0.0, (sum, a) => sum + (a.balanceByCurrency[baseCurrency] ?? 0));
      // Sinking funds: what they take this month, per currency.
      String? trailing;
      if (entry.key == 'sinking') {
        final month = <String, double>{};
        for (final a in entry.value) {
          funds[a.data.allocation.id]?.thisPeriod.forEach(
              (c, v) => month[c] = (month[c] ?? 0) + v);
        }
        trailing = month.isEmpty
            ? null
            : S.of(context).sinkThisMonth(fundAmounts(month, baseCurrency));
      }
      widgets.add(header(_sectionTitle(entry.key), entry.value.length,
          entry.key == 'sinking' ? null : sectionTotal,
          first: widgets.isEmpty, trailing: trailing));
      widgets.add(card(items));
    }

    return widgets;
  }
}

class _GoalsLoansBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = S.of(context);
    final objectivesAsync = ref.watch(objectivesProvider);
    final objectives = objectivesAsync.value ?? [];
    if (objectives.isEmpty) return const SizedBox.shrink();

    final goals = objectives.where((o) => o.type == 'goal').length;
    final loans = objectives.where((o) => o.type == 'loan').length;
    final label = [
      if (goals > 0) l.allocGoalsCount(goals),
      if (loans > 0) l.allocLoansCount(loans),
    ].join(' \u00b7 ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      // Shadow outside, fill on Tappable's Material so the ripple is visible.
      child: DecoratedBox(
        decoration: AppColors.card(context),
        child: Tappable(
        borderRadius: CardTokens.borderRadius,
        color: AppColors.sf(context),
        onTap: () => context.push('/objectives'),
        child: Padding(
          padding: CardTokens.padding,
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
                child: Icon(AppIcons.flag,
                    size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.allocGoalsLoans,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context))),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.ts(context))),
                  ],
                ),
              ),
              Icon(AppIcons.caretRight,
                  size: 18, color: AppColors.th(context)),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// -----------------------------------------
// Empty State
// -----------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    return EmptyState(
      art: true,
      icon: AppIcons.envelopeSimple,
      title: l.allocNoYet,
      subtitle: l.allocCreateHelp,
      actionLabel: l.allocCreateButton,
      onAction: () => context.push('/allocations/new'),
    );
  }
}
