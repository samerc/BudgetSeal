import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/format_number.dart';

/// Daily spending data for the heatmap.
class DaySpending {
  final DateTime date;
  final double income;
  final double expense;

  const DaySpending({
    required this.date,
    this.income = 0,
    this.expense = 0,
  });

  double get net => income - expense;
}

/// A GitHub-style heatmap showing daily spending intensity.
///
/// Green = net positive (income > expense), red = net negative,
/// gray = no activity. Scrolls horizontally, newest on the right.
class SpendingHeatmap extends StatelessWidget {
  final List<DaySpending> data;
  final String baseCurrency;
  final double cellSize;
  final double cellSpacing;

  const SpendingHeatmap({
    super.key,
    required this.data,
    this.baseCurrency = 'USD',
    this.cellSize = 13,
    this.cellSpacing = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(S.of(context).heatmapNoData,
              style: TextStyle(color: AppColors.th(context), fontSize: 12)),
        ),
      );
    }

    // Build lookup map
    final lookup = <String, DaySpending>{};
    double maxExpense = 0;
    double maxIncome = 0;
    for (final d in data) {
      final key = '${d.date.year}-${d.date.month}-${d.date.day}';
      lookup[key] = d;
      if (d.expense > maxExpense) maxExpense = d.expense;
      if (d.income > maxIncome) maxIncome = d.income;
    }

    // Date range: from first data point to today
    final today = DateTime.now();
    final firstDate = data
        .map((d) => d.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    // Calculate weeks
    final startOfWeek = firstDate.subtract(
        Duration(days: firstDate.weekday % 7)); // align to Sunday
    final totalDays = today.difference(startOfWeek).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    final gridHeight = 7 * (cellSize + cellSpacing) + 20; // +20 for month labels

    // Collect month labels
    final monthLabels = <int, String>{};
    for (int w = 0; w < totalWeeks; w++) {
      final weekStart = startOfWeek.add(Duration(days: w * 7));
      if (weekStart.day <= 7) {
        monthLabels[w] = DateFormat.MMM().format(weekStart);
      }
    }

    return SizedBox(
      height: gridHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // newest on the right, scroll left for history
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(totalWeeks, (weekIdx) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month label
                SizedBox(
                  height: 16,
                  width: cellSize + cellSpacing,
                  child: monthLabels.containsKey(weekIdx)
                      ? Text(monthLabels[weekIdx]!,
                          style: TextStyle(
                              fontSize: 9, color: AppColors.th(context)))
                      : null,
                ),
                const SizedBox(height: 4),
                // 7 days (Sun–Sat)
                ...List.generate(7, (dayIdx) {
                  final date =
                      startOfWeek.add(Duration(days: weekIdx * 7 + dayIdx));
                  if (date.isAfter(today)) {
                    return SizedBox(
                      width: cellSize + cellSpacing,
                      height: cellSize + cellSpacing,
                    );
                  }
                  final key = '${date.year}-${date.month}-${date.day}';
                  final day = lookup[key];

                  final color = _cellColor(
                    context, day, maxExpense, maxIncome);
                  final tip = _tooltipText(context, date, day);

                  return Padding(
                    padding: EdgeInsets.all(cellSpacing / 2),
                    child: Semantics(
                      label: tip,
                      child: Tooltip(
                        message: tip,
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ),
      ),
    );
  }

  Color _cellColor(
      BuildContext context, DaySpending? day, double maxExp, double maxInc) {
    if (day == null) {
      return AppColors.sfv(context);
    }

    final net = day.net;
    if (net.abs() < 0.01) {
      return AppColors.sfv(context);
    }

    if (net < 0) {
      // Expense day — red shades
      final intensity = maxExp > 0
          ? (day.expense / maxExp).clamp(0.0, 1.0)
          : 0.5;
      final alpha = 0.15 + intensity * 0.65; // 0.15 to 0.8
      return AppColors.overspent.withValues(alpha: alpha);
    } else {
      // Income day — green shades
      final intensity = maxInc > 0
          ? (day.income / maxInc).clamp(0.0, 1.0)
          : 0.5;
      final alpha = 0.15 + intensity * 0.65;
      return AppColors.healthy.withValues(alpha: alpha);
    }
  }

  String _tooltipText(BuildContext context, DateTime date, DaySpending? day) {
    final dateStr = DateFormat.MMMd().format(date);
    if (day == null) return '$dateStr\n${S.of(context).heatmapNoActivity}';
    final parts = <String>[dateStr];
    if (day.income > 0) {
      parts.add('+${formatAmount(day.income, currency: baseCurrency)}');
    }
    if (day.expense > 0) {
      parts.add('-${formatAmount(day.expense, currency: baseCurrency)}');
    }
    return parts.join('\n');
  }
}
