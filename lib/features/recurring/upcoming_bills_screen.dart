import 'package:drift/drift.dart'
    show BooleanExpressionOperators, ComparableExpr, OrderingTerm;
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
import '../../shared/widgets/calculator_amount_field.dart'
    show showCalculatorSheet;
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/sheet_title.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/tappable.dart';
import 'recurring_format.dart';
import 'recurring_screen.dart' show EditRecurringSheet;
import '../../shared/utils/calendar_days.dart';

/// Recurring bills and incomes by next due date, in two groups (this week,
/// later) of compact rows; the due label grows stronger as a bill nears.
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
            // A finished series keeps its last nextDueDate — it isn't due
            // (as Home's bill boxes).
            ..where((r) =>
                r.endDate.isNull() | r.nextDueDate.isSmallerOrEqual(r.endDate))
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

  /// "This week" (late, and due in the next 7 days) and "Later": a
  /// header with what goes out and comes in (base currency only), then one
  /// card of compact rows.
  List<Widget> _sections(BuildContext context) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency;
    final now = DateTime.now();
    final soon = <RecurringTransaction>[];
    final later = <RecurringTransaction>[];
    for (final b in _bills) {
      (calendarDaysBetween(now, b.nextDueDate) < 7 ? soon : later).add(b);
    }
    String sums(List<RecurringTransaction> bills) {
      var out = 0.0, inn = 0.0;
      for (final b in bills) {
        if (b.currency != base) continue;
        final v = recurringAmountOn(b, b.nextDueDate);
        if (b.type == 'expense') out += v;
        if (b.type == 'income') inn += v;
      }
      return [
        if (out > 0.005) tr.billsSumOut(formatAmount(out, currency: base)),
        if (inn > 0.005) tr.billsSumIn(formatAmount(inn, currency: base)),
      ].join(' · ');
    }

    final out = <Widget>[];
    for (final (title, bills) in [
      (tr.billsThisWeek, soon),
      (tr.billsLater, later),
    ]) {
      if (bills.isEmpty) continue;
      out.add(SliverPadding(
        padding: EdgeInsets.fromLTRB(16, out.isEmpty ? 8 : 20, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Row(children: [
            SectionHeader(title),
            const SizedBox(width: 8),
            Expanded(
              child: Text(sums(bills),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: TypographyTokens.captionSize,
                      color: AppColors.ts(context))),
            ),
          ]),
        ),
      ));
      out.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Container(
            decoration: AppColors.card(context),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              for (var i = 0; i < bills.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1,
                      indent: 70,
                      endIndent: 14,
                      color: AppColors.bd(context)),
                _BillRow(
                  bill: bills[i],
                  onTap: () => _showBillActions(bills[i]),
                ),
              ],
            ]),
          ),
        ),
      ));
    }
    out.add(const SliverPadding(padding: EdgeInsets.only(bottom: 32)));
    return out;
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
              ..._sections(context),
          ],
        ),
      ),
    );
  }
}

/// One bill: a date block, the name with how often and when ("Due in 2
/// days" as a pill in the last 3 days, violet when late), the amount in ink
/// (income keeps its colour; red is for overspending).
class _BillRow extends ConsumerWidget {
  final RecurringTransaction bill;
  final VoidCallback onTap;
  const _BillRow({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final due = bill.nextDueDate;
    final daysUntil = calendarDaysBetween(now, due);
    final isOverdue = daysUntil < 0;
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
    // Gently stronger as it nears: plain text, then the calm blue pill in
    // the last 3 days, violet once late (Cashew's bill colours).
    final Color? pill = isOverdue || toConfirm
        ? AppColors.billOverdue
        : daysUntil <= 3
            ? AppColors.billUpcoming
            : null;
    final amountColor = switch (bill.type) {
      'income' => ref.watch(txColorsProvider).income,
      'transfer' => AppColors.ts(context),
      _ => AppColors.tp(context),
    };
    final subStyle = TextStyle(
        fontSize: TypographyTokens.txSubtitleSize,
        color: AppColors.ts(context));

    return Tappable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 14, 10),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Column(children: [
                Text(formatMonth(due, short: true).toUpperCase(),
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.th(context))),
                Text(formatNumber(due.day.toDouble(), decimals: 0),
                    style: TextStyle(
                        fontFamily: TypographyTokens.displayFamily,
                        fontSize: 20,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tp(context))),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title.isNotEmpty ? bill.title : tr.subUntitled,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: TypographyTokens.txTitleSize,
                      fontWeight: TypographyTokens.txTitleWeight,
                      color: AppColors.tp(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // How often stays whole; the due label takes the rest
                  // (two loose Flexibles split the width in half).
                  Row(children: [
                    Text(
                      recurringFrequencyLabel(
                          tr, bill.frequency, bill.interval),
                      maxLines: 1,
                      style: subStyle,
                    ),
                    Text(' · ', style: subStyle),
                    Flexible(
                      child: Container(
                        padding: pill == null
                            ? EdgeInsets.zero
                            : const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 1),
                        decoration: pill == null
                            ? null
                            : BoxDecoration(
                                color: AppColors.pastel(context, pill,
                                    light: 0.85, dark: 0.8),
                                borderRadius:
                                    BorderRadius.circular(RadiusTokens.sm),
                              ),
                        child: Text(urgencyLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: subStyle.copyWith(
                              fontWeight: pill == null
                                  ? FontWeight.w400
                                  : FontWeight.w700,
                              color: pill,
                            )),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatSignedAmount(recurringAmountOn(bill, bill.nextDueDate),
                  currency: bill.currency, type: bill.type),
              style: TextStyle(
                fontSize: TypographyTokens.amountRegularSize,
                fontWeight: FontWeight.w800,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
