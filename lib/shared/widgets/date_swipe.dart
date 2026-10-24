import 'package:flutter/material.dart';

import '../utils/haptics.dart';

/// Swipe sideways on [child] to move [date] a day: towards the reading
/// direction's end = the next day (left in LTR, right in RTL), the other way
/// = the day before. Taps still reach [child]. A swipe past [lastDate] does
/// nothing.
class DateSwipe extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final DateTime? lastDate;
  final Widget child;

  const DateSwipe({
    super.key,
    required this.date,
    required this.onChanged,
    required this.child,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < 200) return;
        final forward = rtl ? v > 0 : v < 0;
        final next = DateTime(date.year, date.month,
            date.day + (forward ? 1 : -1), date.hour, date.minute);
        final last = lastDate;
        if (last != null &&
            DateTime(next.year, next.month, next.day)
                .isAfter(DateTime(last.year, last.month, last.day))) {
          return;
        }
        hapticSelection();
        onChanged(next);
      },
      child: child,
    );
  }
}
