import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/database/app_database.dart';
import '../../core/engine/recurring_engine.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/transactions_provider.dart';
import '../../core/providers/tx_colors_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/utils/haptics.dart';
import '../../shared/widgets/category_icon.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'widgets/tx_tile.dart';
import 'widgets/tx_ui.dart';
import '../../shared/utils/calendar_days.dart';

/// More › Calendar (also the Recurring screen's calendar button): the month
/// as a grid. Past days show what they cost (base currency, like Activity's
/// day totals); today and later show the bills due (recurring +
/// subscriptions). Tap a day for its transactions and bills; double-tap a
/// past day, or use the button under the list, to add a transaction on it.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month; // first of the shown month
  late DateTime _selected;
  List<RecurringTransaction> _recurring = const [];

  /// How far ahead the bills reach.
  static const _monthsAhead = 12;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;
      final items = await ref.read(recurringEngineProvider).getAll(householdId);
      if (mounted) setState(() => _recurring = items);
    } catch (e) {
      debugPrint('[Calendar] Error loading bills: $e');
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _atLastMonth {
    final last = DateTime(_today.year, _today.month + _monthsAhead);
    return !_month.isBefore(last);
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    if (delta > 0 && _atLastMonth) return;
    hapticLight();
    setState(() {
      _month = next;
      // Today in the current month; elsewhere the same day of month.
      final last = DateTime(next.year, next.month + 1, 0).day;
      _selected = next.year == _today.year && next.month == _today.month
          ? _today
          : DateTime(next.year, next.month, _selected.day.clamp(1, last));
    });
  }

  Future<void> _addOn(DateTime day) async {
    final now = DateTime.now();
    await context.push<String?>('/add-transaction', extra: {
      'editType': 'expense',
      if (day != _today)
        'editDate': DateTime(day.year, day.month, day.day, now.hour, now.minute),
    });
  }

  /// Bills due from today on in the shown month, by day: every occurrence of
  /// each enabled bill (the Upcoming bills rules — short months, interval,
  /// end date, price changes).
  Map<int, List<({RecurringTransaction bill, double amount})>> _billsByDay() {
    final out = <int, List<({RecurringTransaction bill, double amount})>>{};
    final monthEnd = DateTime(_month.year, _month.month + 1, 0);
    if (monthEnd.isBefore(_today)) return out;
    for (final r in _recurring) {
      if (!r.enabled) continue;
      var due = r.nextDueDate;
      final anchor = r.anchorDay ?? due.day;
      for (var guard = 0; guard < 400 && !due.isAfter(monthEnd); guard++) {
        if (r.endDate != null && due.isAfter(r.endDate!)) break;
        final day = DateTime(due.year, due.month, due.day);
        if (!day.isBefore(_today) &&
            day.year == _month.year &&
            day.month == _month.month) {
          out.putIfAbsent(day.day, () => []).add(
              (bill: r, amount: recurringAmountOn(r, day)));
        }
        due = advanceRecurringDate(due, r.frequency, r.interval,
            anchorDay: anchor);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final isFutureMonth = _month.isAfter(DateTime(_today.year, _today.month));
    // A future month has no transactions yet; skip the query.
    final entriesAsync = isFutureMonth
        ? const AsyncValue<List<TransactionEntry>>.data([])
        : ref.watch(monthlyTransactionsProvider(
            (year: _month.year, month: _month.month)));
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final categoryMap = {for (final c in categories) c.id: c};

    return Scaffold(
      appBar: AppBar(title: Text(tr.calendarTitle)),
      body: entriesAsync.when(
        loading: () => const SingleChildScrollView(child: SkeletonList()),
        error: (e, _) => ErrorRetry(
          message: tr.commonCouldntLoadData,
          details: '$e',
          onRetry: () => ref.invalidate(monthlyTransactionsProvider(
              (year: _month.year, month: _month.month))),
        ),
        data: (entries) {
          final days = _byDay(entries, base);
          final bills = _billsByDay();
          final spent = days.values.fold(0.0, (t, d) => t + d.spent);
          final income = days.values.fold(0.0, (t, d) => t + d.income);
          final selectedDay = days[_selected.day];
          final selectedBills = bills[_selected.day] ?? const [];
          final canAdd = !_selected.isAfter(_today);
          String f(double v) => formatAmount(v, currency: base);
          return RefreshIndicator(
            onRefresh: () async {
              final key = (year: _month.year, month: _month.month);
              await _loadBills();
              if (isFutureMonth) return;
              ref.invalidate(monthlyTransactionsProvider(key));
              await ref.read(monthlyTransactionsProvider(key).future);
            },
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _MonthHeader(
                month: _month,
                canGoForward: !_atLastMonth,
                onPrevious: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
              ),
              if (!isFutureMonth)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    tr.txMonthSpent(f(spent), f(income)),
                    style:
                        TextStyle(fontSize: 13, color: AppColors.ts(context)),
                  ),
                )
              else
                const SizedBox(height: 12),
              _MonthGrid(
                month: _month,
                today: _today,
                selected: _selected,
                days: days,
                bills: bills,
                onTap: (d) {
                  hapticLight();
                  setState(() => _selected = d);
                },
                onDoubleTap: (d) {
                  setState(() => _selected = d);
                  _addOn(d);
                },
              ),
              const SizedBox(height: Spacing.lg),
              _DayCard(
                day: _selected,
                today: _today,
                total: (selectedDay?.income ?? 0) - (selectedDay?.spent ?? 0),
                currency: base,
                emptyText: _selected.isAfter(_today)
                    ? tr.calendarFutureDay
                    : tr.calendarNothing,
                rows: [
                  for (final e in selectedDay?.entries ??
                      const <TransactionEntry>[])
                    TxTile(entry: e, categoryMap: categoryMap),
                  for (final b in selectedBills)
                    _BillRow(
                      bill: b.bill,
                      amount: b.amount,
                      category: categoryMap[b.bill.categoryId],
                      daysUntil: calendarDaysBetween(_today, _selected),
                    ),
                ],
              ),
              if (canAdd) ...[
                const SizedBox(height: Spacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _addOn(_selected),
                    icon: const Icon(AppIcons.plus, size: 18),
                    label: Text(_selected == _today
                        ? tr.calendarAddToday
                        : tr.calendarAddOn),
                  ),
                ),
              ],
            ],
          ),
          );
        },
      ),
    );
  }

  /// Day of month → what it cost and brought in (base currency; lines with
  /// no real rate are left out, as in Activity) and its transactions,
  /// newest first.
  Map<int, _Day> _byDay(List<TransactionEntry> entries, String base) {
    final out = <int, _Day>{};
    for (final e in entries) {
      final local = e.tx.createdAt.toLocal();
      if (local.year != _month.year || local.month != _month.month) continue;
      final day = out.putIfAbsent(local.day, () => _Day());
      day.entries.add(e);
      double amount = 0;
      if (e.lines.isNotEmpty) {
        for (final l in e.lines) {
          if (!isRealRate(l.currency, base, l.exchangeRateToBase)) continue;
          amount += l.amount * l.exchangeRateToBase;
        }
      } else if (isRealRate(e.tx.currency, base, e.tx.exchangeRateToBase)) {
        amount = e.tx.amount * e.tx.exchangeRateToBase;
      }
      if (e.tx.type == 'expense') day.spent += amount;
      if (e.tx.type == 'income') day.income += amount;
    }
    for (final d in out.values) {
      d.entries.sort((a, b) => b.tx.createdAt.compareTo(a.tx.createdAt));
    }
    return out;
  }
}

class _Day {
  double spent = 0;
  double income = 0;
  final entries = <TransactionEntry>[];
}

/// A short amount for a cell: 26, 1.2K, 2.3M (the user's decimal mark).
String _short(double v) {
  String one(double x) {
    final s = x >= 100 ? x.round().toString() : x.toStringAsFixed(1);
    return (s.endsWith('.0') ? s.substring(0, s.length - 2) : s)
        .replaceAll('.', decimalSeparatorChar);
  }

  if (v >= 1e9) return '${one(v / 1e9)}B';
  if (v >= 1e6) return '${one(v / 1e6)}M';
  if (v >= 1e4) return '${one(v / 1e3)}K';
  return formatForDisplay(v.roundToDouble());
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  const _MonthHeader({
    required this.month,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(
            capitalizedFirst(DateFormat.yMMMM().format(month)),
            style: TextStyle(
              fontFamily: TypographyTokens.displayFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.tp(context),
            ),
          ),
        ),
      ),
      IconButton(
        onPressed: onPrevious,
        icon: const Icon(AppIcons.caretLeft, size: 20),
      ),
      IconButton(
        onPressed: canGoForward ? onNext : null,
        icon: const Icon(AppIcons.caretRight, size: 20),
      ),
    ]);
  }
}

/// Seven columns starting on the locale's first weekday. A past day shows
/// what it cost (or "+income" on a day with income only); today and later
/// show the bills due, in the bills' blue. Today has an accent ring; the
/// selected day is filled.
class _MonthGrid extends ConsumerWidget {
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final Map<int, _Day> days;
  final Map<int, List<({RecurringTransaction bill, double amount})>> bills;
  final ValueChanged<DateTime> onTap;
  final ValueChanged<DateTime> onDoubleTap;
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.days,
    required this.bills,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstWeekday =
        MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = Sunday
    final lead =
        (DateTime(month.year, month.month).weekday % 7 - firstWeekday) % 7;
    final count = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((lead + count) / 7).ceil();
    final weekdayNames = DateFormat.E().dateSymbols.NARROWWEEKDAYS;
    final incomeColor = ref.watch(txColorsProvider).income;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: AppColors.card(context),
      child: Column(children: [
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(
                  weekdayNames[(firstWeekday + i) % 7],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.th(context),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Row(children: [
            for (var c = 0; c < 7; c++)
              Expanded(child: _cell(context, r * 7 + c - lead + 1, count, incomeColor)),
          ]),
      ]),
    );
  }

  Widget _cell(
      BuildContext context, int day, int count, Color incomeColor) {
    if (day < 1 || day > count) return const SizedBox(height: 56);
    final date = DateTime(month.year, month.month, day);
    final isToday = date == today;
    final isSelected = date == selected;
    final isFuture = date.isAfter(today);
    final d = days[day];
    final due = bills[day];
    final dueTotal = due == null
        ? 0.0
        : due.fold(0.0, (t, b) => b.bill.type == 'income' ? t : t + b.amount);

    String? label;
    Color? labelColor;
    if (d != null && d.spent >= 0.005) {
      label = _short(d.spent);
      labelColor = AppColors.ts(context);
    } else if (d != null && d.income >= 0.005) {
      label = '+${_short(d.income)}';
      labelColor = incomeColor;
    } else if (due != null) {
      // Bills can be in other currencies: the amount only when one bill.
      label = due.length == 1 && dueTotal > 0
          ? _short(dueTotal)
          : '•' * due.length.clamp(1, 3);
      labelColor = AppColors.billUpcoming;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isSelected ? AppColors.accentLight : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          side: isToday && !isSelected
              ? BorderSide(color: AppColors.accentText(context), width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTap(date),
          onDoubleTap: isFuture ? null : () => onDoubleTap(date),
          child: SizedBox(
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: isFuture && due == null
                        ? AppColors.th(context)
                        : AppColors.tp(context),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 14,
                  child: label == null
                      ? null
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                              color: labelColor,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A card like Activity's day cards: a header, then rows split by hairlines.
class _Card extends StatelessWidget {
  final Widget header;
  final List<Widget> rows;
  const _Card({required this.header, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.card(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: AppColors.bd(context)),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// The selected day: name, date, day net, then its transactions (or a
/// quiet line when nothing happened).
class _DayCard extends StatelessWidget {
  final DateTime day;
  final DateTime today;
  final double total;
  final String currency;
  final String emptyText;
  final List<Widget> rows;
  const _DayCard({
    required this.day,
    required this.today,
    required this.total,
    required this.currency,
    required this.emptyText,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final diff = calendarDaysBetween(day, today);
    final name = diff == 0
        ? tr.commonToday
        : diff == 1
            ? tr.commonYesterday
            : capitalizedFirst(DateFormat.EEEE().format(day));
    return _Card(
      header: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              name,
              style: TextStyle(
                fontFamily: TypographyTokens.displayFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formatDate(day),
                style: TextStyle(fontSize: 12.5, color: AppColors.ts(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (total.abs() >= 0.005)
              Text(
                total > 0
                    ? bidiSafeAmount('+${formatAmount(total, currency: currency)}')
                    : formatAmount(total, currency: currency),
                style: TextStyle(
                  fontFamily: TypographyTokens.displayFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ts(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
      rows: rows.isEmpty
          ? [
              // A quiet row in the card's row slot, not an empty state:
              // the day card stays the same shape.
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 14),
                child: Row(children: [
                  Icon(AppIcons.calendarBlank,
                      size: 18, color: AppColors.th(context)),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      emptyText,
                      style: TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: AppColors.ts(context)),
                    ),
                  ),
                ]),
              ),
            ]
          : rows,
    );
  }
}

/// A bill due on the selected day; tapping it opens Upcoming bills, where
/// it can be paid or skipped.
class _BillRow extends ConsumerWidget {
  final RecurringTransaction bill;
  final double amount;
  final Category? category;
  final int daysUntil;
  const _BillRow({
    required this.bill,
    required this.amount,
    required this.daysUntil,
    this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final isIncome = bill.type == 'income';
    final title = bill.title.isNotEmpty
        ? bill.title
        : category?.name ?? tr.subUntitled;
    return InkWell(
      onTap: () => context.push('/upcoming-bills'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          CategoryIcon(
            categoryName: category?.name ?? title,
            emoji: category?.icon,
            color: category != null
                ? AppColors.fromHex(category!.colorHex)
                : AppColors.accent,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  daysUntil <= 0
                      ? tr.upcomingDueToday
                      : daysUntil == 1
                          ? tr.upcomingDueTomorrow
                          : tr.upcomingDueInDays(daysUntil),
                  style: TextStyle(fontSize: 12.5, color: AppColors.billUpcoming),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isIncome
                ? bidiSafeAmount('+${formatAmount(amount, currency: bill.currency)}')
                : formatAmount(amount, currency: bill.currency),
            style: TextStyle(
              fontFamily: TypographyTokens.displayFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isIncome
                  ? ref.watch(txColorsProvider).income
                  : AppColors.tp(context),
            ),
          ),
        ]),
      ),
    );
  }
}
