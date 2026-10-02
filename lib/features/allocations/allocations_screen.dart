import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:drift/drift.dart' hide Column;

import '../../core/engine/period_engine.dart' show budgetPeriodFor;
import '../../core/database/app_database.dart' show Category;
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/objectives_provider.dart';
import '../../core/providers/period_reset_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/allocation_card.dart';
import '../../shared/widgets/budget_progress.dart';

import '../../shared/widgets/currency_display.dart';
import '../../core/providers/premium_provider.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/tappable.dart';
import '../../shared/theme/brand_palette.dart';
import 'archived_envelopes_sheet.dart';
import 'move_money_sheet.dart';

class AllocationsScreen extends ConsumerStatefulWidget {
  const AllocationsScreen({super.key});

  @override
  ConsumerState<AllocationsScreen> createState() => _AllocationsScreenState();
}

class _AllocationsScreenState extends ConsumerState<AllocationsScreen>
    with AutomaticKeepAliveClientMixin {
  static const _typeOrder = ['spending', 'flexible'];

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
        _ => type[0].toUpperCase() + type.substring(1),
      };

  static IconData _sectionIcon(String type) => switch (type) {
        'spending' => Icons.shopping_bag_rounded,
        'flexible' => Icons.savings_rounded,
        _ => Icons.category_rounded,
      };

  static Color _sectionColor(String type, BuildContext context) =>
      AppColors.tp(context);

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
            borderRadius: BorderRadius.circular(7),
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
    final allocationsAsync = ref.watch(allocationsProvider);
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
                      ? Icons.search_off_rounded
                      : Icons.search_rounded,
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
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.ts(context)),
                onSelected: (v) {
                  if (v == 'archived') {
                    showArchivedEnvelopesSheet(context, ref);
                  } else if (v == 'help') {
                    _showEnvelopeHelp(context);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'archived',
                    child: Row(children: [
                      Icon(Icons.unarchive_outlined,
                          size: 20, color: AppColors.ts(context)),
                      const SizedBox(width: 12),
                      Text(l.allocArchivedTitle),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'help',
                    child: Row(children: [
                      Icon(Icons.help_outline_rounded,
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
                        Icon(Icons.search_rounded, color: AppColors.ts(context)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.sfv(context),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.tp(context),
                  ),
                ),
              ),
            ),

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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.caution.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.update_rounded,
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

          // -- Budget Summary (hidden during search) --
          if (_searchQuery.isEmpty)
          SliverToBoxAdapter(
            child: allocationsAsync.when(
              data: (allocations) {
                // Only sum base-currency envelopes for the summary
                // to avoid mixing currencies (e.g., USD + LBP raw).
                final baseAllocs = allocations.where((a) =>
                    (a.data.allocation.targetCurrency ?? baseCurrency) ==
                    baseCurrency);
                final totalBudgeted = baseAllocs.fold<double>(
                  0.0,
                  (sum, a) => sum + (a.data.allocation.targetAmount ?? 0.0),
                );
                // Spent this period from the ledger (a negative balance
                // only shows overdrafts, not normal spending).
                final spending = ref.watch(periodSpendingProvider).value ?? {};
                final totalSpent = baseAllocs.fold<double>(
                  0.0,
                  (sum, a) =>
                      sum +
                      (spending[a.data.allocation.id]?[baseCurrency] ?? 0),
                );
                final totalRemaining = baseAllocs.fold<double>(
                  0.0,
                  (sum, a) => sum + (a.balanceByCurrency[baseCurrency] ?? 0),
                );

                if (allocations.isEmpty) return const SizedBox.shrink();

                final nonBaseCount = allocations
                    .where((a) =>
                        (a.data.allocation.targetCurrency ?? baseCurrency) !=
                        baseCurrency)
                    .length;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.sfv(context),
                          borderRadius: BorderRadius.circular(CardTokens.radius),
                        ),
                        child: Row(
                          children: [
                            _SummaryItem(
                              label: l.allocBudgeted,
                              amount: totalBudgeted,
                              currency: baseCurrency,
                              color: AppColors.tp(context),
                            ),
                            _SummaryDivider(context: context),
                            _SummaryItem(
                              label: l.allocSpent,
                              amount: totalSpent,
                              currency: baseCurrency,
                              color: AppColors.overspent,
                            ),
                            _SummaryDivider(context: context),
                            _SummaryItem(
                              label: l.allocRemaining,
                              amount: totalRemaining,
                              currency: baseCurrency,
                              color: AppColors.healthy,
                            ),
                          ],
                        ),
                      ),
                      if (nonBaseCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l.allocBaseCurrencyOnly(baseCurrency, nonBaseCount),
                            style: TextStyle(
                                fontSize: 10, color: AppColors.th(context)),
                          ),
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
              data: (unallocated) => _UnallocatedBanner(
                unallocated: unallocated,
                baseCurrency: baseCurrency,
                hasAllocations: (allocationsAsync.value?.isNotEmpty ?? false),
              ),
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ),
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
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: AppColors.th(context)),
                        const SizedBox(height: 12),
                        Text(
                          l.allocNoMatch(_searchQuery),
                          style: TextStyle(
                            color: AppColors.ts(context),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
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

          // Bottom padding so FAB doesn't cover last card.
          const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_allocations',
        tooltip: l.allocCreateTooltip,
        onPressed: () {
          final allocs = ref.read(allocationsProvider).value ?? [];
          if (!checkFreeLimit(context, ref, allocs.length, FreeLimits.maxEnvelopes, 'envelopes')) return;
          context.push('/allocations/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    Map<String, List<AllocationWithBalance>> grouped,
    String baseCurrency,
  ) {
    final widgets = <Widget>[];
    final period = BudgetProgress.currentPeriod(
        ref.read(householdProvider).value?.periodStartDay ?? 1);

    for (final entry in grouped.entries) {
      final type = entry.key;
      final items = entry.value;

      // Compute section total in base currency only (avoid mixing).
      final sectionTotal = items.fold<double>(
        0.0,
        (sum, a) => sum + (a.balanceByCurrency[baseCurrency] ?? 0),
      );

      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            top: widgets.isEmpty ? 4 : 20,
            bottom: 8,
            left: 4,
          ),
          child: Row(
            children: [
              Icon(
                _sectionIcon(type),
                size: 16,
                color: _sectionColor(type, context),
              ),
              const SizedBox(width: 8),
              Text(
                _sectionTitle(type),
                style: TextStyle(
                  fontSize: TypographyTokens.sectionHeaderSize,
                  fontWeight: TypographyTokens.sectionHeaderWeight,
                  color: _sectionColor(type, context),
                  letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.th(context),
                ),
              ),
              const Spacer(),
              Text(
                formatAmount(sectionTotal, currency: baseCurrency),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sectionTotal < 0
                      ? AppColors.overspent
                      : AppColors.ts(context),
                ),
              ),
            ],
          ),
        ),
      );

      final pendingIds = ref.watch(pendingResetProvider).value ?? [];
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
      for (int idx = 0; idx < items.length; idx++) {
        final a = items[idx];
        final cat = linkedCat[a.data.allocation.id] ?? a.data.category;
        widgets.add(
          TweenAnimationBuilder<double>(
            key: ValueKey(a.data.allocation.id),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + idx * 60),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - v)),
                child: child,
              ),
            ),
            child: AllocationCard(
            needsReview: pendingIds.contains(a.data.allocation.id),
            name: a.data.allocation.name,
            type: a.data.allocation.type,
            periodicity: a.data.allocation.periodicity,
            balanceByCurrency: a.balanceByCurrency,
            baseCurrency: baseCurrency,
            targetAmount: a.data.allocation.targetAmount,
            targetCurrency: a.data.allocation.targetCurrency,
            envelopeIcon: a.data.allocation.icon,
            categoryName: cat?.name,
            categoryIcon: cat?.icon,
            categoryColorHex: cat?.colorHex,
            // Current budget period → daily allowance + today marker.
            periodStart: period.start,
            periodEnd: period.end,
            plannedAmount: _plannedByAllocation[a.data.allocation.id],
            plannedCurrency: _plannedCurrencyByAllocation[a.data.allocation.id],
            onTap: () {
              hapticLight();
              context.push('/allocations/${a.data.allocation.id}');
            },
            onCover: () {
              final cur = a.data.allocation.targetCurrency ?? baseCurrency;
              showMoveMoneySheet(context, ref,
                  toId: a.data.allocation.id,
                  currency: cur,
                  amount: -(a.balanceByCurrency[cur] ?? 0),
                  cover: true);
            },
            onSpend: () {
              // Pre-fill with the linked category.
              context.push('/add-transaction', extra: cat != null ? {
                'editType': 'expense',
                'editLines': [
                  {
                    'categoryId': cat.id,
                    'categoryName': cat.name,
                    'currency': a.data.allocation.targetCurrency ?? baseCurrency,
                  }
                ],
              } : null);
            },
          )),
        );
      }
    }

    return widgets;
  }
}

// -----------------------------------------
// Budget Summary Item
// -----------------------------------------
class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.ts(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatAmount(amount, currency: currency),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  final BuildContext context;
  const _SummaryDivider({required this.context});

  @override
  Widget build(BuildContext _) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.bd(context),
    );
  }
}

// -----------------------------------------
// Unallocated Banner
// -----------------------------------------
class _UnallocatedBanner extends StatefulWidget {
  final Map<String, double> unallocated;
  final String baseCurrency;
  final bool hasAllocations;

  const _UnallocatedBanner({
    required this.unallocated,
    required this.baseCurrency,
    this.hasAllocations = false,
  });

  @override
  State<_UnallocatedBanner> createState() => _UnallocatedBannerState();
}

class _UnallocatedBannerState extends State<_UnallocatedBanner>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animController;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    final baseAmount = widget.unallocated[widget.baseCurrency] ?? 0.0;
    final hasOtherCurrencies = widget.unallocated.length > 1;
    // The brand banner: the bright accent in every theme, dark ink on it.
    const ink = brandInk;
    final fill = AppColors.accentBright;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(RadiusTokens.dialog - 5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.allocReadyToAssign,
                        style: TextStyle(
                          color: ink.withValues(alpha: 0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      CurrencyDisplay(
                        amount: baseAmount,
                        currency: widget.baseCurrency,
                        amountStyle: const TextStyle(
                          color: ink,
                          fontSize: 30,
                          fontFamily: TypographyTokens.displayFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasOtherCurrencies)
                        Tappable(
                          onTap: _toggle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _expanded
                                      ? l.allocHideOtherCurrencies
                                      : l.allocOtherCurrencies(
                                          widget.unallocated.length - 1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ink,
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _expanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 250),
                                  child: const Icon(Icons.expand_more_rounded,
                                      color: ink, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: widget.hasAllocations
                      ? () => context.push('/funding')
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: ink,
                    foregroundColor: fill,
                    disabledBackgroundColor: ink.withValues(alpha: 0.15),
                    disabledForegroundColor: ink.withValues(alpha: 0.45),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    l.allocAssign,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),

          // -- Expandable currency breakdown --
          SizeTransition(
            sizeFactor: _expandAnim,
            axisAlignment: -1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightenPastel(fill, 0.35),
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                ),
                child: Column(
                  children: widget.unallocated.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: ink.withValues(alpha: 0.7),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatAmount(e.value, currency: e.key),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: e.value < 0
                                  ? AppColors.darkenPastel(
                                      AppColors.overspent, 0.2)
                                  : ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------
// Goals & Loans Banner
// -----------------------------------------
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow(context),
        ),
        child: Tappable(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.sf(context),
        onTap: () => context.push('/objectives'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.pastel(context, AppColors.accent,
                      light: 0.85, dark: 0.78),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.flag_rounded,
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
              Icon(Icons.chevron_right_rounded,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.pastel(context, AppColors.accent,
                    light: 0.85, dark: 0.78),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.mail_rounded,
                  size: 36, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            Text(
              l.allocNoYet,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.allocCreateHelp,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.ts(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/allocations/new'),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  l.allocCreateButton,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
