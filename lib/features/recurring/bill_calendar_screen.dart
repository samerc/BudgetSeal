import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';

class BillCalendarScreen extends ConsumerStatefulWidget {
  const BillCalendarScreen({super.key});

  @override
  ConsumerState<BillCalendarScreen> createState() =>
      _BillCalendarScreenState();
}

class _BillCalendarScreenState extends ConsumerState<BillCalendarScreen> {
  List<RecurringTransaction> _items = [];
  DateTime _viewMonth = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;
      final engine = ref.read(recurringEngineProvider);
      final items = await engine.getAll(householdId);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      debugPrint('[BillCalendar] Error loading: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<RecurringTransaction> _itemsForDay(int day) {
    final checkDate =
        DateTime(_viewMonth.year, _viewMonth.month, day);
    return _items.where((r) {
      if (!r.enabled) return false;
      final due = r.nextDueDate;

      // Monthly: same day of month.
      if (r.frequency == 'monthly' && due.day == day) {
        return true;
      }

      // Weekly: check if this date falls on the same weekday
      // with correct interval from the start date.
      if (r.frequency == 'weekly') {
        if (checkDate.weekday == due.weekday) {
          final diff = checkDate.difference(due).inDays;
          if (diff >= 0 && diff % (7 * r.interval) == 0) {
            return true;
          }
        }
        return false;
      }

      // Daily: every N days from start.
      if (r.frequency == 'daily') {
        final diff = checkDate.difference(due).inDays;
        if (diff >= 0 && diff % r.interval == 0) {
          return true;
        }
        return false;
      }

      // Yearly: same month and day.
      if (r.frequency == 'yearly' &&
          due.month == _viewMonth.month &&
          due.day == day) {
        return true;
      }

      // Exact date match.
      if (due.year == _viewMonth.year &&
          due.month == _viewMonth.month &&
          due.day == day) {
        return true;
      }
      return false;
    }).toList();
  }

  void _showDayDetail(
      BuildContext context, int day, List<RecurringTransaction> items) {
    final date = DateTime(_viewMonth.year, _viewMonth.month, day);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.th(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('EEEE, MMMM d').format(date),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${items.length} ${items.length == 1 ? 'bill' : 'bills'} due',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.ts(context),
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((r) {
              final isIncome = r.type == 'income';
              final color = isIncome ? AppColors.healthy : AppColors.overspent;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.sfv(context),
                  borderRadius: BorderRadius.circular(CardTokens.radius),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(Icons.repeat_rounded, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title.isNotEmpty ? r.title : r.note,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tp(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _frequencyLabel(r.frequency, r.interval),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.ts(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatSignedAmount(r.amount,
                          currency: r.currency, type: r.type),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _frequencyLabel(String freq, int interval) {
    if (interval == 1) {
      return switch (freq) {
        'daily' => 'Daily',
        'weekly' => 'Weekly',
        'monthly' => 'Monthly',
        'yearly' => 'Yearly',
        _ => freq,
      };
    }
    return 'Every $interval $freq';
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_viewMonth.year, _viewMonth.month, 1).weekday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setState(() => _viewMonth =
                DateTime(_viewMonth.year, _viewMonth.month - 1)),
          ),
          Center(
            child: Text(
              DateFormat('MMM yyyy').format(_viewMonth),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => setState(() => _viewMonth =
                DateTime(_viewMonth.year, _viewMonth.month + 1)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Weekday headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map((d) => Expanded(
                              child: Center(
                                child: Text(d,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ts(context))),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 4),
                // Calendar grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: daysInMonth + firstWeekday - 1,
                    itemBuilder: (_, index) {
                      final day = index - firstWeekday + 2;
                      if (day < 1) return const SizedBox.shrink();

                      final dayItems = _itemsForDay(day);
                      final isToday = DateTime.now().day == day &&
                          DateTime.now().month == _viewMonth.month &&
                          DateTime.now().year == _viewMonth.year;

                      return GestureDetector(
                        onTap: dayItems.isNotEmpty
                            ? () => _showDayDetail(context, day, dayItems)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : dayItems.isNotEmpty
                                    ? AppColors.sf(context)
                                    : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: AppColors.accent)
                                : null,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isToday
                                      ? AppColors.accent
                                      : AppColors.tp(context),
                                ),
                              ),
                              ...dayItems.take(2).map((r) => Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 1),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: r.type == 'income'
                                          ? AppColors.healthy
                                              .withValues(alpha: 0.15)
                                          : AppColors.overspent
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      r.title.isNotEmpty
                                          ? r.title
                                          : formatAmount(r.amount),
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: r.type == 'income'
                                            ? AppColors.healthy
                                            : AppColors.overspent,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                              if (dayItems.length > 2)
                                Text('+${dayItems.length - 2}',
                                    style: TextStyle(
                                        fontSize: 8,
                                        color: AppColors.th(context))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Upcoming bills list
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UPCOMING',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.ts(context))),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _items.where((r) => r.enabled).isEmpty
                            ? Center(
                                child: Text('No upcoming bills',
                                    style: TextStyle(
                                        color: AppColors.th(context))))
                            : ListView(
                                children: _items
                                    .where((r) => r.enabled)
                                    .take(5)
                                    .map((r) => ListTile(
                                          dense: true,
                                          leading: Icon(
                                            r.type == 'income'
                                                ? Icons
                                                    .arrow_downward_rounded
                                                : Icons
                                                    .arrow_upward_rounded,
                                            size: 16,
                                            color: r.type == 'income'
                                                ? AppColors.healthy
                                                : AppColors.overspent,
                                          ),
                                          title: Text(r.title,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                          subtitle: Text(
                                            DateFormat('MMM d')
                                                .format(r.nextDueDate),
                                            style: TextStyle(
                                                fontSize: 10,
                                                color:
                                                    AppColors.th(context)),
                                          ),
                                          trailing: Text(
                                            formatAmount(r.amount,
                                                currency: r.currency),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: r.type == 'income'
                                                  ? AppColors.healthy
                                                  : AppColors.overspent,
                                            ),
                                          ),
                                        ))
                                    .toList(),
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
