import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Cashew-style budget bar: a thick pill that fills with a pastel of [color],
/// an optional "today" marker showing how far through the period we are, and
/// an optional percentage label inside the fill.
///
/// [progress] is unclamped — values above 1.0 draw the full bar in the
/// overspent color.
class BudgetProgress extends StatelessWidget {
  const BudgetProgress({
    super.key,
    required this.progress,
    required this.color,
    this.height = 12,
    this.todayFraction,
    this.showPercent = false,
    this.overspent = false,
  });

  final double progress;
  final Color color;
  final double height;

  /// 0..1 position of "today" within the period (null hides the marker).
  final double? todayFraction;

  /// Draw "NN%" inside the fill (only legible from ~16px height).
  final bool showPercent;

  /// Force the overspent styling (e.g. negative balance).
  final bool overspent;

  @override
  Widget build(BuildContext context) {
    final isOver = overspent || progress > 1.0;
    final fillColor = isOver
        ? AppColors.overspent
        : AppColors.pastel(context, color, light: 0.15, dark: 0.1);
    final trackColor =
        AppColors.pastel(context, color, light: 0.8, dark: 0.72);
    final target = isOver ? 1.0 : progress.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height);

    return SizedBox(
      height: todayFraction != null ? height + 8 : height,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          alignment: AlignmentDirectional.centerStart,
          children: [
            // Track
            Container(
              height: height,
              decoration: BoxDecoration(color: trackColor, borderRadius: radius),
            ),
            // Fill — grows from 0 on first build, eases between values after.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOutCubicEmphasized,
              builder: (context, v, _) => Container(
                width: w * v,
                height: height,
                decoration:
                    BoxDecoration(color: fillColor, borderRadius: radius),
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: showPercent && v > 0.18
                    ? Text(
                        '${(progress * 100).round()}%',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: height * 0.62,
                          fontWeight: FontWeight.w800,
                          color: isOver
                              ? Colors.white
                              : AppColors.pastel(context, color,
                                  light: 0.55, dark: 0.75, inverse: true),
                        ),
                      )
                    : null,
              ),
            ),
            // Today marker
            if (todayFraction != null)
              PositionedDirectional(
                start: (w * todayFraction!.clamp(0.0, 1.0) - 1.5)
                    .clamp(0.0, w - 3),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.tp(context).withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  /// The budget period containing today for a household whose periods start
  /// on [startDay] (1–31, clamped to the month's length, e.g. 31 → Feb 28).
  static ({DateTime start, DateTime end}) currentPeriod(int startDay) {
    DateTime clampedStart(int year, int month) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, startDay.clamp(1, daysInMonth));
    }

    final now = DateTime.now();
    var start = clampedStart(now.year, now.month);
    if (now.isBefore(start)) start = clampedStart(now.year, now.month - 1);
    final end = clampedStart(start.year, start.month + 1);
    return (start: start, end: end);
  }

  /// How far through [start, end) "now" is, or null if outside/unknown.
  static double? fractionOfPeriod(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return null;
    final f = DateTime.now().difference(start).inSeconds / total;
    if (f < 0 || f > 1) return null;
    return f;
  }
}
