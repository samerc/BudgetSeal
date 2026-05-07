import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/allocations_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/period_reset_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/allocation_card.dart';

import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/skeleton_loader.dart';

class AllocationsScreen extends ConsumerStatefulWidget {
  const AllocationsScreen({super.key});

  @override
  ConsumerState<AllocationsScreen> createState() => _AllocationsScreenState();
}

class _AllocationsScreenState extends ConsumerState<AllocationsScreen>
    with AutomaticKeepAliveClientMixin {
  static const _typeOrder = ['spending', 'saving', 'flexible'];

  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _sectionTitle(String type) => switch (type) {
        'spending' => 'Spending',
        'saving' => 'Savings',
        'flexible' => 'Flexible',
        _ => type[0].toUpperCase() + type.substring(1),
      };

  static IconData _sectionIcon(String type) => switch (type) {
        'spending' => Icons.shopping_bag_rounded,
        'saving' => Icons.savings_rounded,
        'flexible' => Icons.tune_rounded,
        _ => Icons.category_rounded,
      };

  static Color _sectionColor(String type, BuildContext context) => switch (type) {
        'saving' => AppColors.accent,
        'flexible' => AppColors.caution,
        _ => AppColors.tp(context),
      };

  @override
  bool get wantKeepAlive => true;

  void _showEnvelopeHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How Envelopes Work'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _helpRow('1', 'Create envelopes for each spending category'),
            const SizedBox(height: 10),
            _helpRow('2', 'Set a monthly budget target for each'),
            const SizedBox(height: 10),
            _helpRow('3', 'Fund envelopes when you get paid'),
            const SizedBox(height: 10),
            _helpRow('4', 'Spend from envelopes — track what\'s left'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
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
            color: AppColors.accent.withValues(alpha: 0.1),
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
    final allocationsAsync = ref.watch(allocationsProvider);
    final unallocatedAsync = ref.watch(unallocatedProvider);
    final household = ref.watch(householdProvider).value;
    final baseCurrency = household?.baseCurrency ?? 'USD';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allocationsProvider);
          ref.invalidate(unallocatedProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
        slivers: [
          // ── Header (dashboard style) ──
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Budget',
                        style: TextStyle(
                          color: AppColors.tp(context),
                          fontSize: TypographyTokens.screenTitleSize,
                          fontWeight: TypographyTokens.screenTitleWeight,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Search envelopes',
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
                    IconButton(
                      tooltip: 'How envelopes work',
                      icon: Icon(Icons.help_outline_rounded,
                          color: AppColors.ts(context)),
                      onPressed: () => _showEnvelopeHelp(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search bar ──
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
                    hintText: 'Search envelopes...',
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

          // ── Period Reset Banner ──
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
                    color: AppColors.caution.withValues(alpha: 0.1),
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
                            Text('New period started',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.tp(context))),
                            Text(
                              '${pendingIds.length} envelope(s) need review',
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
                        child: const Text('Review'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Budget Summary (hidden during search) ──
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
                final totalSpent = baseAllocs.fold<double>(
                  0.0,
                  (sum, a) {
                    final bal = a.balanceByCurrency[baseCurrency] ?? 0;
                    return bal < 0 ? sum + bal.abs() : sum;
                  },
                );
                final totalRemaining = baseAllocs.fold<double>(
                  0.0,
                  (sum, a) => sum + (a.balanceByCurrency[baseCurrency] ?? 0),
                );

                if (allocations.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(CardTokens.radius),
                    ),
                    child: Row(
                      children: [
                        _SummaryItem(
                          label: 'Budgeted',
                          amount: totalBudgeted,
                          currency: baseCurrency,
                          color: AppColors.tp(context),
                        ),
                        _SummaryDivider(context: context),
                        _SummaryItem(
                          label: 'Spent',
                          amount: totalSpent,
                          currency: baseCurrency,
                          color: AppColors.overspent,
                        ),
                        _SummaryDivider(context: context),
                        _SummaryItem(
                          label: 'Remaining',
                          amount: totalRemaining,
                          currency: baseCurrency,
                          color: AppColors.healthy,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Unallocated Banner (hidden during search) ──
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

          // ── Allocations List ──
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

              // Group by type, preserving order.
              final grouped = <String, List<AllocationWithBalance>>{};
              for (final type in _typeOrder) {
                final items = filtered
                    .where((a) => a.data.allocation.type == type)
                    .toList();
                if (items.isNotEmpty) grouped[type] = items;
              }
              // Catch any types not in the predefined order.
              for (final a in filtered) {
                final t = a.data.allocation.type;
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
                          'No envelopes match "$_searchQuery"',
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
                message: "Couldn't load your data",
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
        tooltip: 'Create envelope',
        onPressed: () => context.push('/allocations/new'),
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
      for (final a in items) {
        final cat = a.data.category;
        widgets.add(
          AllocationCard(
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
            onTap: () {
              hapticLight();
              context.push('/allocations/${a.data.allocation.id}');
            },
            onSpend: () {
              // Pre-fill with the first linked category.
              final cat = a.data.category;
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
          ),
        );
      }
    }

    return widgets;
  }
}

// ─────────────────────────────────────────────
// Budget Summary Item
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// Unallocated Banner
// ─────────────────────────────────────────────
class _UnallocatedBanner extends StatelessWidget {
  final Map<String, double> unallocated;
  final String baseCurrency;
  final bool hasAllocations;

  const _UnallocatedBanner({
    required this.unallocated,
    required this.baseCurrency,
    this.hasAllocations = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseAmount = unallocated[baseCurrency] ?? 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unallocated',
                    style: TextStyle(
                        color: AppColors.ts(context), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  CurrencyDisplay(
                    amount: baseAmount,
                    currency: baseCurrency,
                    amountStyle: TextStyle(
                      color: AppColors.tp(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (unallocated.length > 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: unallocated.entries
                      .where((e) => e.key != baseCurrency)
                      .map((e) => Text(
                            formatAmount(e.value, currency: e.key),
                            style: TextStyle(
                                color: AppColors.ts(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ))
                      .toList(),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasAllocations ? () => context.push('/funding') : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              label: const Text(
                'Fund Envelopes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.mail_rounded,
                  size: 36, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            Text(
              'No envelopes yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create an envelope to start budgeting.\nTap ? for help.',
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
                label: const Text(
                  'Create Envelope',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
