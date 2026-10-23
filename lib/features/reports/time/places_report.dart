import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/providers/household_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/widgets/empty_state.dart';
import 'report_period.dart';
import 'report_widgets.dart';
import 'reports_home.dart';

/// Places (expense titles) where the money goes most, then when it goes:
/// by weekday, the busiest time of day, days without spending.
class PlacesReport extends ConsumerWidget {
  const PlacesReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final period = ref.watch(reportPeriodProvider);
    final t = ref.watch(reportTotalsProvider).value?.now;
    String money(double v) => formatAmount(v, currency: base);
    final ts = AppColors.ts(context);

    if (t == null) {
      return ReportScaffold(title: tr.rptPlaces, children: const [
        Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator())),
      ]);
    }
    if (t.payments == 0) {
      return ReportScaffold(title: tr.rptPlaces, children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: EmptyState(icon: AppIcons.mapPin, title: tr.rptNothingInPeriod),
        ),
      ]);
    }

    final places = t.places.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final topPlaces = places.take(10).toList();
    final maxPlace = topPlaces.isEmpty ? 1.0 : topPlaces.first.total;

    // Weekdays: average spent per occurrence of that weekday so far.
    final days = elapsedDays(period.start, period.end);
    final occurrences = List<int>.filled(7, 0);
    for (var i = 0; i < days; i++) {
      occurrences[period.start.add(Duration(days: i)).weekday - 1]++;
    }
    final perDay = [
      for (var i = 0; i < 7; i++)
        occurrences[i] == 0 ? 0.0 : t.weekdaySpent[i] / occurrences[i],
    ];
    var top = 0;
    for (var i = 1; i < 7; i++) {
      if (perDay[i] > perDay[top]) top = i;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    // 2024-01-01 is a Monday.
    String dayName(int i, {bool short = false}) =>
        (short ? DateFormat.E(locale) : DateFormat.EEEE(locale))
            .format(DateTime(2024, 1, 1 + i));
    final maxDay = perDay.fold(0.0, (m, v) => v > m ? v : m);

    // Busiest three hours.
    var bestHour = 0, bestCount = -1;
    for (var h = 0; h <= 21; h++) {
      final c = t.hourCount[h] + t.hourCount[h + 1] + t.hourCount[h + 2];
      if (c > bestCount) {
        bestCount = c;
        bestHour = h;
      }
    }
    final share = (bestCount / t.payments * 100).round();
    final from = TimeOfDay(hour: bestHour, minute: 0).format(context);
    final to = TimeOfDay(hour: (bestHour + 3) % 24, minute: 0).format(context);

    // No-spend days and the longest run of them.
    var run = 0, longest = 0;
    for (var i = 0; i < days; i++) {
      final d = period.start.add(Duration(days: i));
      if (t.spendDays.contains(DateTime(d.year, d.month, d.day))) {
        run = 0;
      } else {
        run++;
        if (run > longest) longest = run;
      }
    }
    final noSpend = days - t.spendDays.length;

    Widget tile(String label, String value, String sub) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: AppColors.card(context, radius: RadiusTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: ts)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(value,
                      style: const TextStyle(
                          fontFamily: TypographyTokens.displayFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                ),
                Text(sub, style: TextStyle(fontSize: 12, color: ts)),
              ],
            ),
          ),
        );

    return ReportScaffold(
      title: tr.rptPlaces,
      children: [
        ReportSection(tr.rptWhereMost, note: tr.rptByTitle),
        if (topPlaces.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text(tr.rptNoPlaces, style: TextStyle(color: ts)),
          )
        else
          ReportCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(children: [
              for (var i = 0; i < topPlaces.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppColors.bd(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(topPlaces[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                        Text(money(topPlaces[i].total),
                            style: const TextStyle(
                                fontFamily: TypographyTokens.displayFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 6,
                          child: Stack(children: [
                            Container(color: AppColors.sfv(context)),
                            FractionallySizedBox(
                              widthFactor:
                                  (topPlaces[i].total / maxPlace).clamp(0.02, 1.0),
                              alignment: AlignmentDirectional.centerStart,
                              child: Container(color: AppColors.accentBright),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          tr.rptVisits(topPlaces[i].count,
                              money(topPlaces[i].total / topPlaces[i].count)),
                          style: TextStyle(fontSize: 12, color: ts)),
                    ],
                  ),
                ),
              ],
            ]),
          ),
        ReportSection(tr.rptWhenSpend),
        ReportCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportHeadline(tr.rptDayCostsMost(dayName(top)),
                  sub: tr.rptDayAverage(money(perDay[top]), dayName(top))),
              const SizedBox(height: 14),
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(axisAmount(perDay[i]),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: ts)),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: maxDay <= 0
                                    ? 2
                                    : (perDay[i] / maxDay * 100).clamp(2, 100),
                                decoration: BoxDecoration(
                                  color: i == top
                                      ? AppColors.accentText(context)
                                      : AppColors.th(context)
                                          .withValues(alpha: 0.45),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(dayName(i, short: true),
                                  maxLines: 1,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: ts)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            tile(tr.rptBusiestTime, '$from – $to', tr.rptShareOfPayments(share)),
            const SizedBox(width: 8),
            tile(tr.rptNoSpendDays, tr.rptNofM(noSpend, days),
                tr.rptLongestRun(longest)),
          ]),
        ),
      ],
    );
  }
}
