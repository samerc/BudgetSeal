import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/empty_state.dart';
import '../../l10n/generated/app_localizations.dart';

/// Shows recurring transactions sorted by next due date,
/// with visual urgency indicators for overdue / due soon items.
class UpcomingBillsScreen extends ConsumerStatefulWidget {
  const UpcomingBillsScreen({super.key});

  @override
  ConsumerState<UpcomingBillsScreen> createState() =>
      _UpcomingBillsScreenState();
}

class _UpcomingBillsScreenState
    extends ConsumerState<UpcomingBillsScreen> {
  List<RecurringTransaction> _bills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;

      final items = await (db.select(db.recurringTransactions)
            ..where((r) => r.householdId.equals(householdId))
            ..where((r) => r.enabled.equals(true))
            ..where((r) => r.deleted.equals(false))
            ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
          .get();

      if (mounted) setState(() { _bills = items; _loading = false; });
    } catch (e) {
      debugPrint('[UpcomingBills] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(S.of(context).upcomingTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
              ? EmptyState(
                  icon: Icons.event_available_rounded,
                  title: S.of(context).upcomingNoTitle,
                  subtitle: S.of(context).upcomingNoSubtitle,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _bills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _BillCard(bill: _bills[i]),
                  ),
                ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final RecurringTransaction bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = bill.nextDueDate;
    final daysUntil = due.difference(DateTime(now.year, now.month, now.day)).inDays;
    final isOverdue = daysUntil < 0;
    final isDueSoon = daysUntil <= 3 && !isOverdue;

    final urgencyColor = isOverdue
        ? AppColors.overspent
        : isDueSoon
            ? const Color(0xFFD97706)
            : AppColors.healthy;

    final tr = S.of(context);
    final urgencyLabel = isOverdue
        ? tr.upcomingOverdue(-daysUntil)
        : daysUntil == 0
            ? tr.upcomingDueToday
            : daysUntil == 1
                ? tr.upcomingDueTomorrow
                : tr.upcomingDueInDays(daysUntil);

    final typeIcon = switch (bill.type) {
      'income' => Icons.arrow_downward_rounded,
      'transfer' => Icons.swap_horiz_rounded,
      _ => Icons.arrow_upward_rounded,
    };

    final typeColor = switch (bill.type) {
      'income' => AppColors.healthy,
      'transfer' => AppColors.accent,
      _ => AppColors.overspent,
    };

    return Container(
      padding: CardTokens.padding,
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(
          color: isOverdue
              ? AppColors.overspent.withValues(alpha: 0.3)
              : AppColors.bd(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, size: 18, color: typeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title.isNotEmpty ? bill.title : tr.subUntitled,
                      style: TextStyle(
                        fontSize: TypographyTokens.cardTitleSize,
                        fontWeight: TypographyTokens.cardTitleWeight,
                        color: AppColors.tp(context),
                      ),
                    ),
                    Text(
                      _formatFrequency(bill, tr),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.ts(context),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatAmount(bill.amount, currency: bill.currency),
                style: TextStyle(
                  fontSize: TypographyTokens.amountRegularSize,
                  fontWeight: TypographyTokens.amountRegularWeight,
                  color: typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Urgency row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
                  size: 14,
                  color: urgencyColor,
                ),
                const SizedBox(width: 6),
                Text(
                  urgencyLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: urgencyColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${due.day}/${due.month}/${due.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ts(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFrequency(RecurringTransaction r, S tr) {
    if (r.interval <= 1) {
      return switch (r.frequency) {
        'daily' => tr.freqDaily,
        'weekly' => tr.freqWeekly,
        'monthly' => tr.freqMonthly,
        'yearly' => tr.freqYearly,
        _ => r.frequency,
      };
    }
    return switch (r.frequency) {
      'daily' => tr.freqEveryNDays(r.interval),
      'weekly' => tr.freqEveryNWeeks(r.interval),
      'monthly' => tr.freqEveryNMonths(r.interval),
      'yearly' => tr.freqEveryNYears(r.interval),
      _ => 'Every ${r.interval} ${r.frequency}',
    };
  }
}
