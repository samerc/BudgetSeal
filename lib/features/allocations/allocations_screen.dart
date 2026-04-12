import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/allocations_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/allocation_card.dart';
import '../../shared/widgets/balance_chip.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/skeleton_loader.dart';

class AllocationsScreen extends ConsumerStatefulWidget {
  const AllocationsScreen({super.key});

  @override
  ConsumerState<AllocationsScreen> createState() => _AllocationsScreenState();
}

class _AllocationsScreenState extends ConsumerState<AllocationsScreen> {
  static const _typeOrder = ['spending', 'saving', 'flexible'];

  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Force refresh allocations and unallocated balances when page opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(allocationsProvider);
      ref.invalidate(unallocatedProvider);
    });
  }

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
  Widget build(BuildContext context) {
    final allocationsAsync = ref.watch(allocationsProvider);
    final unallocatedAsync = ref.watch(unallocatedProvider);
    final household = ref.watch(householdProvider).value;
    final baseCurrency = household?.baseCurrency ?? 'USD';

    return Scaffold(
      body: CustomScrollView(
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
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
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
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search envelopes...',
                    hintStyle: const TextStyle(color: AppColors.textHint),
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

          // ── Budget Summary ──
          SliverToBoxAdapter(
            child: allocationsAsync.when(
              data: (allocations) {
                final totalBudgeted = allocations.fold<double>(
                  0.0,
                  (sum, a) => sum + (a.data.allocation.targetAmount ?? 0.0),
                );
                final totalSpent = allocations.fold<double>(
                  0.0,
                  (sum, a) {
                    final bal = a.totalInBase;
                    return bal < 0 ? sum + bal.abs() : sum;
                  },
                );
                final totalRemaining = allocations.fold<double>(
                  0.0,
                  (sum, a) => sum + a.totalInBase,
                );

                if (allocations.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.sfv(context),
                      borderRadius: BorderRadius.circular(14),
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

          // ── Unallocated Banner ──
          SliverToBoxAdapter(
            child: unallocatedAsync.when(
              data: (unallocated) => _UnallocatedBanner(
                unallocated: unallocated,
                baseCurrency: baseCurrency,
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

      // Compute section total balance.
      final sectionTotal = items.fold<double>(
        0.0,
        (sum, a) => sum + a.totalInBase,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _sectionColor(type, context),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
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

      for (final a in items) {
        final cat = a.data.category;
        widgets.add(
          AllocationCard(
            name: a.data.allocation.name,
            type: a.data.allocation.type,
            periodicity: a.data.allocation.periodicity,
            balanceByCurrency: a.balanceByCurrency,
            baseCurrency: baseCurrency,
            targetAmount: a.data.allocation.targetAmount,
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
                    'currency': baseCurrency,
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

  const _UnallocatedBanner({
    required this.unallocated,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final baseAmount = unallocated[baseCurrency] ?? 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2A3F6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
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
                  const Text(
                    'Unallocated',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  CurrencyDisplay(
                    amount: baseAmount,
                    currency: baseCurrency,
                    amountStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
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
                      .map((e) =>
                          BalanceChip(balance: e.value, currency: e.key))
                      .toList(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/funding'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF2A3F6A)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 48, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Envelope Budgeting',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Give every dollar a job. Assign your money to envelopes and spend only what you\'ve set aside.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Steps
          _StepCard(
            number: '1',
            title: 'Create envelopes',
            description:
                'Make an envelope for each spending category: Groceries, Rent, Entertainment, etc.',
            icon: Icons.add_circle_outline_rounded,
          ),
          const SizedBox(height: 10),
          _StepCard(
            number: '2',
            title: 'Set a monthly budget',
            description:
                'Decide how much you want to spend in each envelope per month. This is your target.',
            icon: Icons.track_changes_rounded,
          ),
          const SizedBox(height: 10),
          _StepCard(
            number: '3',
            title: 'Fund your envelopes',
            description:
                'When you get paid, distribute money into your envelopes. Use "Fund Envelopes" to fill them up.',
            icon: Icons.savings_rounded,
          ),
          const SizedBox(height: 10),
          _StepCard(
            number: '4',
            title: 'Spend with confidence',
            description:
                'When you record a transaction, it draws from the envelope. You always know what\'s left.',
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/allocations/new'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Create your first envelope',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
