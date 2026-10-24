import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../core/engine/recurring_engine.dart' show recurringAmountOn;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../shared/utils/save_errors.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/calculator_amount_field.dart'
    show showCalculatorSheet;
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'recurring_format.dart';
import 'recurring_screen.dart' show EditRecurringSheet;
import '../../shared/utils/calendar_days.dart';

/// Shows recurring transactions sorted by next due date,
/// with visual urgency indicators for overdue / due soon items.
class UpcomingBillsScreen extends ConsumerStatefulWidget {
  /// A bill to open on arrival (a notification's "Log it" button).
  final String? openBillId;
  const UpcomingBillsScreen({super.key, this.openBillId});

  @override
  ConsumerState<UpcomingBillsScreen> createState() =>
      _UpcomingBillsScreenState();
}

class _UpcomingBillsScreenState
    extends ConsumerState<UpcomingBillsScreen> {
  List<RecurringTransaction> _bills = [];
  bool _loading = true;
  Object? _error;
  late String? _pendingOpen = widget.openBillId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(databaseProvider);
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final items = await (db.select(db.recurringTransactions)
            ..where((r) => r.householdId.equals(householdId))
            ..where((r) => r.enabled.equals(true))
            ..where((r) => r.deleted.equals(false))
            ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
          .get();

      if (mounted) {
        setState(() {
          _bills = items;
          _loading = false;
          _error = null;
        });
        final open = _pendingOpen;
        _pendingOpen = null;
        final bill = items.where((b) => b.id == open).firstOrNull;
        if (bill != null) _showBillActions(bill);
      }
    } catch (e) {
      debugPrint('[UpcomingBills] Error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  /// Tap a bill: post it now (paying early) or skip this occurrence.
  Future<void> _showBillActions(RecurringTransaction bill) async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetTitle(bill.title.isNotEmpty ? bill.title : tr.subUntitled),
            ListTile(
              leading: const Icon(AppIcons.checkCircle),
              title: Text(bill.askFirst ? tr.billConfirmPost : tr.upcomingPostNow),
              subtitle: Text(bill.askFirst
                  ? tr.billConfirmPostDesc
                  : tr.upcomingPostNowDesc),
              onTap: () => Navigator.pop(ctx, 'post'),
            ),
            ListTile(
              leading: const Icon(AppIcons.calendarBlank),
              title: Text(tr.upcomingPaidOnDay),
              subtitle: Text(tr.upcomingPaidOnDayDesc),
              onTap: () => Navigator.pop(ctx, 'post-on'),
            ),
            ListTile(
              leading: const Icon(AppIcons.skipForward),
              title: Text(tr.upcomingSkip),
              subtitle: Text(tr.upcomingSkipDesc),
              onTap: () => Navigator.pop(ctx, 'skip'),
            ),
            ListTile(
              leading: const Icon(AppIcons.pencilSimple),
              title: Text(tr.commonEdit),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'edit') {
      if (bill.isSubscription) {
        await context.push('/subscriptions/${bill.id}');
      } else {
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EditRecurringSheet(item: bill),
        );
      }
      _load();
      return;
    }
    DateTime? paidOn;
    if (action == 'post-on') {
      // Overdue: start on the due date; never after today (a future-dated
      // payment would move balances but stay hidden in Activity).
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = bill.nextDueDate;
      paidOn = await showDatePicker(
        context: context,
        initialDate: due.isBefore(today) ? due : today,
        firstDate: DateTime(today.year - 1, today.month, today.day),
        lastDate: today,
      );
      if (paidOn == null || !mounted) return;
    }
    // Ask-first bills: confirm this time's amount (starts on the usual one).
    double? amount;
    if (bill.askFirst && action != 'skip') {
      amount = await showCalculatorSheet(
          context, recurringAmountOn(bill, bill.nextDueDate),
          title: bill.title.isNotEmpty ? bill.title : tr.subUntitled,
          subtitle: tr.billToConfirm);
      if (amount == null || amount <= 0 || !mounted) return;
    }
    try {
      final engine = ref.read(recurringEngineProvider);
      if (action == 'post' || action == 'post-on') {
        await engine.postNow(bill.id, on: paidOn, amount: amount);
      } else {
        await engine.skipNext(bill.id);
      }
      ref.invalidate(transactionEntriesProvider);
      ref.invalidate(monthlyTransactionsProvider);
      ref.invalidate(allocationsProvider);
      rescheduleBillReminders(ref);
      messenger.showSnackBar(SnackBar(
        content: Text(action == 'skip' ? tr.upcomingSkipped : tr.upcomingPosted),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      debugPrint('[UpcomingBills] $action failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(txSaveErrorText(tr, e)),
        behavior: SnackBarBehavior.floating,
      ));
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            LargeTitleHeader(title: tr.upcomingTitle, back: true),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SkeletonList(),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorRetry(
                  message: tr.recurringLoadFailed,
                  details: '$_error',
                  onRetry: () {
                    setState(() => _loading = true);
                    _load();
                  },
                ),
              )
            else if (_bills.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: AppIcons.calendarCheck,
                  title: tr.upcomingNoTitle,
                  subtitle: tr.upcomingNoSubtitle,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.separated(
                  itemCount: _bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _BillCard(
                    bill: _bills[i],
                    onTap: () => _showBillActions(_bills[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BillCard extends ConsumerWidget {
  final RecurringTransaction bill;
  final VoidCallback onTap;
  const _BillCard({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final due = bill.nextDueDate;
    final daysUntil = calendarDaysBetween(now, due);
    final isOverdue = daysUntil < 0;

    // Cashew's bill colors: blue for upcoming, indigo for overdue — calm,
    // not alarming red/amber/green.
    final urgencyColor =
        isOverdue ? AppColors.billOverdue : AppColors.billUpcoming;

    final tr = S.of(context);
    final toConfirm = bill.askFirst && daysUntil <= 0;
    final urgencyLabel = toConfirm
        ? tr.billToConfirm
        : isOverdue
        ? tr.upcomingOverdue(-daysUntil)
        : daysUntil == 0
            ? tr.upcomingDueToday
            : daysUntil == 1
                ? tr.upcomingDueTomorrow
                : tr.upcomingDueInDays(daysUntil);

    final typeIcon = switch (bill.type) {
      'income' => AppIcons.arrowDown,
      'transfer' => AppIcons.arrowsLeftRight,
      _ => AppIcons.arrowUp,
    };

    final typeColor = ref.watch(txColorsProvider).forType(bill.type);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: CategoryIconTokens.compactSize,
                height: CategoryIconTokens.compactSize,
                decoration: BoxDecoration(
                  color: AppColors.pastel(context, typeColor,
                      light: 0.8, dark: 0.7),
                  shape: BoxShape.circle,
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
                      recurringFrequencyLabel(
                          tr, bill.frequency, bill.interval),
                      style: TextStyle(
                        fontSize: TypographyTokens.txSubtitleSize,
                        color: AppColors.ts(context),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatSignedAmount(recurringAmountOn(bill, bill.nextDueDate),
                    currency: bill.currency, type: bill.type),
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
              color: AppColors.pastel(context, urgencyColor,
                  light: 0.85, dark: 0.8),
              borderRadius: BorderRadius.circular(RadiusTokens.md),
            ),
            child: Row(
              children: [
                Icon(
                  toConfirm
                      ? AppIcons.pencilSimple
                      : isOverdue
                          ? AppIcons.warningFill
                          : AppIcons.clock,
                  size: 14,
                  color: urgencyColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    urgencyLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: urgencyColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatDate(due),
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
}
