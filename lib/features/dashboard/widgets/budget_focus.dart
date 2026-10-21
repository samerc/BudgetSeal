import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart' show Category;
import '../../../core/providers/allocations_provider.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/ready_to_assign_banner.dart';
import '../../allocations/move_money_sheet.dart';
import 'bills_boxes.dart';

/// Home's first section — what the budget needs now: money waiting in
/// Ready to assign, envelopes that are overspent (with Cover), and bills
/// due this week. Budget-first, unlike an expense tracker's home.
class BudgetFocus extends ConsumerWidget {
  final String baseCurrency;

  const BudgetFocus({super.key, required this.baseCurrency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allocations = ref.watch(allocationsProvider).value ?? const [];
    final unallocated = ref.watch(unallocatedProvider).value ?? const {};
    final categories = ref.watch(categoriesProvider).value ?? const [];

    final hasMoneyWaiting =
        unallocated.values.any((v) => v.abs() >= 0.005);
    final showBanner = allocations.isNotEmpty || hasMoneyWaiting;

    // Envelope → its linked category (top-level first), as on the Budget tab.
    final linked = <String, Category>{};
    for (final c in categories) {
      final id = c.allocationId;
      if (id == null) continue;
      if (!linked.containsKey(id) || c.parentId == null) linked[id] = c;
    }
    final overspent = [
      for (final a in allocations)
        if ((a.balanceByCurrency[
                    a.data.allocation.targetCurrency ?? baseCurrency] ??
                0) <
            -0.005)
          a,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBanner)
          ReadyToAssignBanner(
            unallocated: unallocated.isEmpty
                ? {baseCurrency: 0.0}
                : unallocated,
            baseCurrency: baseCurrency,
            hasAllocations: allocations.isNotEmpty,
            margin: const EdgeInsets.only(bottom: 12),
          ),
        if (overspent.isNotEmpty) ...[
          _OverspentCard(
            items: overspent,
            linked: linked,
            baseCurrency: baseCurrency,
          ),
          const SizedBox(height: 12),
        ],
        BillsBoxes(baseCurrency: baseCurrency),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _OverspentCard extends ConsumerWidget {
  final List<AllocationWithBalance> items;
  final Map<String, Category> linked;
  final String baseCurrency;

  const _OverspentCard({
    required this.items,
    required this.linked,
    required this.baseCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        boxShadow: AppColors.cardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 4),
            child: Text(s.homeOverspentTitle(items.length),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.overspent)),
          ),
          for (final a in items) _row(context, ref, a),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, AllocationWithBalance a) {
    final s = S.of(context);
    final alloc = a.data.allocation;
    final cur = alloc.targetCurrency ?? baseCurrency;
    final over = -(a.balanceByCurrency[cur] ?? 0);
    final cat = linked[alloc.id] ?? a.data.category;
    final color =
        cat != null ? AppColors.fromHex(cat.colorHex) : AppColors.accent;
    return InkWell(
      onTap: () => context.push('/allocations/${alloc.id}'),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 8),
        child: Row(
          children: [
            CategoryIcon(
              categoryName: cat?.name ?? alloc.name,
              emoji: alloc.icon ?? cat?.icon,
              color: color,
              size: CategoryIconTokens.compactSize,
              circular: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alloc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tp(context))),
                  Text(s.homeOverBy(formatAmount(over, currency: cur)),
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.overspent)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.overspent,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => showMoveMoneySheet(context, ref,
                    toId: alloc.id, currency: cur, amount: over, cover: true),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(s.allocCoverButton,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkOn(AppColors.overspent))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
