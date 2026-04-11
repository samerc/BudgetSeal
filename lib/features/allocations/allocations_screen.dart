import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/allocations_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    // Force refresh allocations and unallocated balances when page opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(allocationsProvider);
      ref.invalidate(unallocatedProvider);
    });
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
      
      appBar: AppBar(
        
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Envelopes',
          style: TextStyle(
            color: AppColors.tp(context),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
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

              // Group by type, preserving order.
              final grouped = <String, List<AllocationWithBalance>>{};
              for (final type in _typeOrder) {
                final items = allocations
                    .where((a) => a.data.allocation.type == type)
                    .toList();
                if (items.isNotEmpty) grouped[type] = items;
              }
              // Catch any types not in the predefined order.
              for (final a in allocations) {
                final t = a.data.allocation.type;
                if (!_typeOrder.contains(t)) {
                  grouped.putIfAbsent(t, () => []).add(a);
                }
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
            ],
          ),
        ),
      );

      for (final a in items) {
        widgets.add(
          AllocationCard(
            name: a.data.allocation.name,
            type: a.data.allocation.type,
            periodicity: a.data.allocation.periodicity,
            balanceByCurrency: a.balanceByCurrency,
            baseCurrency: baseCurrency,
            targetAmount: a.data.allocation.targetAmount,
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2A3F6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
              borderRadius: BorderRadius.circular(20),
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
