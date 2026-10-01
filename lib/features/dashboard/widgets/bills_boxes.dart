import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/household_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/widgets/tappable.dart';

/// Enabled recurring bills, live from the database.
final _enabledRecurringProvider =
    StreamProvider.autoDispose<List<RecurringTransaction>>((ref) {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return Stream.value(const []);
  return (db.select(db.recurringTransactions)
        ..where((r) => r.householdId.equals(householdId))
        ..where((r) => r.enabled.equals(true))
        ..where((r) => r.deleted.equals(false)))
      .watch();
});

/// Cashew's home "Upcoming" / "Overdue" boxes: count + total of bills due
/// in the next 7 days and (when any) bills already past due. Hidden when the
/// user has no recurring bills at all.
class BillsBoxes extends ConsumerWidget {
  const BillsBoxes({super.key, required this.baseCurrency});

  final String baseCurrency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(_enabledRecurringProvider).value ?? const [];
    if (bills.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));
    final upcoming = <RecurringTransaction>[];
    final overdue = <RecurringTransaction>[];
    for (final b in bills) {
      final due = b.nextDueDate.toLocal();
      if (due.isBefore(today)) {
        overdue.add(b);
      } else if (due.isBefore(weekEnd)) {
        upcoming.add(b);
      }
    }

    final dark = AppColors.isDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _Box(
              label: S.of(context).dashUpcoming,
              icon: Icons.event_rounded,
              color: dark ? const Color(0xFF7DC2DD) : const Color(0xFF58A4C2),
              bills: upcoming,
              baseCurrency: baseCurrency,
              wide: overdue.isEmpty,
            ),
          ),
          // The recurring engine posts due bills at launch, so overdue is
          // rare — only show that box when something is actually late.
          if (overdue.isNotEmpty) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _Box(
              label: S.of(context).dashOverdue,
              icon: Icons.history_rounded,
              color: dark ? const Color(0xFF8395FF) : const Color(0xFF6577E0),
              bills: overdue,
              baseCurrency: baseCurrency,
            ),
          ),
          ],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.label,
    required this.icon,
    required this.color,
    required this.bills,
    required this.baseCurrency,
    this.wide = false,
  });

  /// Single full-width box: label left, amount + count right.
  final bool wide;
  final String label;
  final IconData icon;
  final Color color;
  final List<RecurringTransaction> bills;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    // Only base-currency bills are summed — never mix currencies.
    final total = bills
        .where((b) => b.currency == baseCurrency)
        .fold<double>(0, (sum, b) => sum + b.amount);
    final bg = AppColors.pastel(context, color, light: 0.85, dark: 0.75);
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.tp(context),
            ),
          ),
        ),
      ],
    );
    final amount = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        formatAmount(total, currency: baseCurrency),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
    final count = Text(
      S.of(context).dashBillsCount(bills.length),
      style: TextStyle(
        fontSize: 13,
        color: AppColors.tp(context).withValues(alpha: 0.6),
      ),
    );

    return Tappable(
      onTap: () => context.push('/upcoming-bills'),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: wide
            ? Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [amount, count],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 8),
                  amount,
                  const SizedBox(height: 2),
                  count,
                ],
              ),
      ),
    );
  }
}
