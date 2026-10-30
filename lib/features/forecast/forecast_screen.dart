import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:go_router/go_router.dart';

import '../../core/engine/forecast.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/forecast_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/tappable.dart';
import '../reports/time/report_widgets.dart' show axisAmount, niceMax;

/// The line under "safe to spend": until when.
String _untilLine(S tr, CurrencyForecast f) {
  final next = f.nextIncome;
  if (next == null) return tr.forecastNoIncome;
  return next.kind == ForecastKind.estimate
      ? tr.forecastUntilEst(formatDate(next.date))
      : tr.forecastUntil(formatDate(next.date));
}

/// Home's line under the amount: "a day until Nov 1".
String _perDayLine(S tr, CurrencyForecast f) {
  final next = f.nextIncome;
  if (next == null) return tr.forecastADay30;
  // Non-breaking: "Nov 1" never splits across lines in the half-width box.
  final date = formatDateNoYear(next.date).replaceAll(' ', ' ');
  return next.kind == ForecastKind.estimate
      ? tr.forecastADayUntilEst(date)
      : tr.forecastADayUntil(date);
}

/// Whether Home has a forecast to show for the base currency.
bool hasHomeForecast(WidgetRef ref) {
  final base = ref.watch(householdProvider).value?.baseCurrency;
  final f = ref.watch(forecastProvider).value?[base];
  return f != null && !(f.events.isEmpty && f.start == 0);
}

/// Home: "Safe to spend today" (per day, base currency) until the next
/// income; opens the forecast (roadmap #4). [compact]: the half-width box
/// beside Upcoming bills.
class ForecastCard extends ConsumerWidget {
  final bool compact;
  const ForecastCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency;
    final f = ref.watch(forecastProvider).value?[base];
    if (f == null || (f.events.isEmpty && f.start == 0)) {
      return const SizedBox.shrink();
    }
    final amount = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        formatAmount(f.safeToSpend, currency: f.currency),
        style: TextStyle(
          fontFamily: TypographyTokens.displayFamily,
          fontSize: compact ? TypographyTokens.amountDisplaySize : 24,
          fontWeight: FontWeight.w800,
          color: f.short > 0 ? AppColors.overspent : null,
        ),
      ),
    );
    final sub = Text(
      f.short > 0
          ? tr.forecastShort(formatAmount(f.short, currency: f.currency))
          : _perDayLine(tr, f),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
          fontSize: TypographyTokens.amountSmallSize,
          color: AppColors.ts(context)),
    );
    final label = Text(compact ? tr.forecastSafeShort : tr.forecastSafeToday,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: TypographyTokens.cardTitleSize,
            fontWeight: TypographyTokens.cardTitleWeight,
            color: AppColors.tp(context)));
    return DecoratedBox(
      decoration: AppColors.card(context),
      child: Tappable(
        onTap: () => context.push('/forecast'),
        borderRadius: CardTokens.borderRadius,
        color: AppColors.sf(context),
        child: Padding(
          padding: CardTokens.padding,
          child: compact
              // Same rhythm as the Upcoming box beside it.
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    const SizedBox(height: 8),
                    amount,
                    const SizedBox(height: 2),
                    sub,
                  ],
                )
              : Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [label, amount, sub],
                    ),
                  ),
                  Icon(AppIcons.caretRight,
                      size: 18, color: AppColors.th(context)),
                ]),
        ),
      ),
    );
  }
}

/// The forecast (roadmap #4): per currency (never mixed), safe to spend
/// today and how it adds up, the 90-day balance line, and every upcoming
/// item (also the chart's table view).
class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});

  @override
  ConsumerState<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends ConsumerState<ForecastScreen> {
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final async = ref.watch(forecastProvider);
    final base = ref.watch(householdProvider).value?.baseCurrency;
    return Scaffold(
      appBar: AppBar(title: Text(tr.forecastTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: tr.commonSomethingWentWrong,
          details: '$e',
          onRetry: () => ref.invalidate(forecastProvider),
        ),
        data: (all) {
          final currencies = all.keys.toList()
            ..sort((a, b) => a == base
                ? -1
                : b == base
                    ? 1
                    : a.compareTo(b));
          if (currencies.isEmpty) {
            return Center(
                child: EmptyState(icon: AppIcons.chartLineUp, title: tr.forecastEmpty));
          }
          final cur = currencies.contains(_currency) ? _currency! : currencies.first;
          final f = all[cur]!;
          String money(double v) => formatAmount(v, currency: cur);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(tr.forecastIntro,
                  style:
                      TextStyle(fontSize: 13.5, color: AppColors.ts(context))),
              if (currencies.length > 1) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  for (final c in currencies)
                    ChoiceChip(
                      label: Text(c),
                      selected: c == cur,
                      onSelected: (_) => setState(() => _currency = c),
                    ),
                ]),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppColors.card(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.forecastSafeToday,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                    Text(tr.forecastPerDay(money(f.safeToSpend)),
                        style: TextStyle(
                          fontFamily: TypographyTokens.displayFamily,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: f.short > 0 ? AppColors.overspent : null,
                        )),
                    Text(_untilLine(tr, f),
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                    if (f.short > 0)
                      Text(tr.forecastShort(money(f.short)),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.overspent)),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: AppColors.bd(context)),
                    const SizedBox(height: 8),
                    for (final (label, value) in [
                      (tr.forecastCashNow, money(f.start)),
                      (tr.forecastDue, money(-f.dueBefore)),
                      if (f.reserved > 0.005)
                        (tr.forecastReserved, money(-f.reserved)),
                      if (f.saved > 0.005)
                        (tr.forecastSaved, money(-f.saved)),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Expanded(
                              child: Text(label,
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.ts(context)))),
                          Text(value,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    // The total, then the step to the number above: free
                    // money ÷ the days until the next income.
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Divider(height: 1, color: AppColors.bd(context)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(children: [
                        Expanded(
                            child: Text(tr.forecastFree,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700))),
                        Text(money(f.free),
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color:
                                    f.short > 0 ? AppColors.overspent : null)),
                      ]),
                    ),
                    if (f.short <= 0)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.pastel(context, AppColors.accent,
                              light: 0.85, dark: 0.78),
                          borderRadius: BorderRadius.circular(RadiusTokens.md),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(tr.forecastDividedBy(f.daysLeft),
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentText(context))),
                          ),
                          Text(tr.forecastPerDay(money(f.safeToSpend)),
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentText(context))),
                        ]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                decoration: AppColors.card(context),
                child: _ForecastChart(forecast: f),
              ),
              if (f.events.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(4, 20, 4, 8),
                  child: Text(tr.forecastUpcoming,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                Container(
                  decoration: AppColors.card(context),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final e in f.events)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(children: [
                          SizedBox(
                            width: 64,
                            // Short and localized ("Oct 27", "27 oct.").
                            child: Text(DateFormat.MMMd().format(e.date),
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.ts(context))),
                          ),
                          Expanded(
                            child: Text(
                              e.kind == ForecastKind.estimate
                                  ? tr.forecastEstimate
                                  : e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: e.kind == ForecastKind.estimate
                                    ? FontStyle.italic
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            formatSignedAmount(e.amount.abs(),
                                currency: cur,
                                type: e.isIncome ? 'income' : 'expense'),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ]),
                      ),
                  ]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Free money over the next 90 days (the balance less what sinking funds
/// and savings goals keep): one line under its title (no legend), the
/// lowest point marked and named, amount labels on the start, a zero line
/// when it goes below zero, month labels; touch shows the day's amount.
class _ForecastChart extends StatefulWidget {
  final CurrencyForecast forecast;
  const _ForecastChart({required this.forecast});

  @override
  State<_ForecastChart> createState() => _ForecastChartState();
}

class _ForecastChartState extends State<_ForecastChart> {
  int? _touched;

  void _touch(Offset local, double width) {
    final n = widget.forecast.daily.length;
    final plot = width - _ForecastPainter.axisW;
    final i = ((local.dx - _ForecastPainter.axisW) / plot * (n - 1))
        .round()
        .clamp(0, n - 1);
    if (i != _touched) setState(() => _touched = i);
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final f = widget.forecast;
    final values = f.freeDaily;
    var low = 0;
    for (var k = 1; k < values.length; k++) {
      if (values[k] < values[low]) low = k;
    }
    final i = _touched;
    final day = f.today.add(Duration(days: i ?? low));
    final shown = values[i ?? low];
    final caption = i == null
        ? tr.forecastLowest(formatAmount(shown, currency: f.currency),
            formatDateNoYear(day))
        : '${formatDateNoYear(day)} · ${formatAmount(shown, currency: f.currency)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(tr.forecastFreeMoney,
              style: const TextStyle(
                  fontSize: TypographyTokens.cardTitleSize,
                  fontWeight: FontWeight.w700)),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
          child: Text(caption,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: i == null ? FontWeight.w400 : FontWeight.w600,
                color: shown < 0 ? AppColors.overspent : AppColors.ts(context),
              )),
        ),
        LayoutBuilder(builder: (context, c) {
          return GestureDetector(
            onTapDown: (d) => _touch(d.localPosition, c.maxWidth),
            onHorizontalDragUpdate: (d) => _touch(d.localPosition, c.maxWidth),
            onHorizontalDragEnd: (_) => setState(() => _touched = null),
            child: Directionality(
              // Time runs left to right in every language.
              textDirection: TextDirection.ltr,
              child: CustomPaint(
                size: Size(c.maxWidth, 170),
                painter: _ForecastPainter(
                  daily: values,
                  today: f.today,
                  lowestIndex: low,
                  touched: i,
                  line: AppColors.accent,
                  low: values[low] < 0 ? AppColors.overspent : AppColors.accent,
                  grid: AppColors.bd(context),
                  label: AppColors.th(context),
                  surface: AppColors.sf(context),
                  // TextPainter doesn't inherit the app font.
                  textStyle: DefaultTextStyle.of(context).style,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ForecastPainter extends CustomPainter {
  /// Room for the amount labels on the start.
  static const axisW = 34.0;

  final List<double> daily;
  final DateTime today;
  final int lowestIndex;
  final int? touched;
  final Color line, low, grid, label, surface;
  final TextStyle textStyle;

  _ForecastPainter({
    required this.daily,
    required this.today,
    required this.lowestIndex,
    required this.touched,
    required this.line,
    required this.low,
    required this.grid,
    required this.label,
    required this.surface,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelsH = 18.0;
    const topPad = 6.0;
    final h = size.height - labelsH;
    // A value axis from zero (or the lowest point below it) to a round top,
    // so the amount labels are round numbers.
    final dataLo = daily.reduce((a, b) => a < b ? a : b);
    final dataHi = daily.reduce((a, b) => a > b ? a : b);
    final hi = niceMax(math.max(dataHi, 1));
    final lo = dataLo < 0 ? -niceMax(-dataLo) : 0.0;
    final plotW = size.width - axisW;
    double x(int i) => axisW + i / (daily.length - 1) * plotW;
    double y(double v) => topPad + (h - topPad) * (1 - (v - lo) / (hi - lo));

    final text = TextPainter(textDirection: TextDirection.ltr);
    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Amount labels and recessive gridlines: bottom, middle, top; zero
    // stronger when the line goes below it.
    for (final v in {lo, (lo + hi) / 2, hi, if (lo < 0) 0.0}) {
      canvas.drawLine(Offset(axisW, y(v)), Offset(size.width, y(v)),
          v == 0 && lo < 0 ? (Paint()..color = grid..strokeWidth = 1) : gridPaint);
      text
        ..text = TextSpan(
            text: axisAmount(v),
            style: textStyle.copyWith(fontSize: 10, color: label))
        ..layout();
      // End-aligned against the plot.
      text.paint(
          canvas, Offset(axisW - 5 - text.width, y(v) - text.height / 2));
    }

    // Month starts.
    for (var i = 0; i < daily.length; i++) {
      final d = today.add(Duration(days: i));
      if (d.day != 1) continue;
      text
        ..text = TextSpan(
            text: formatMonth(d, short: true),
            style: textStyle.copyWith(fontSize: 11, color: label))
        ..layout();
      text.paint(canvas, Offset(x(i) + 3, h + 3));
    }

    // The line (2px).
    final path = Path()..moveTo(x(0), y(daily[0]));
    for (var i = 1; i < daily.length; i++) {
      // Steps: money changes on the day, not in between.
      path
        ..lineTo(x(i), y(daily[i - 1]))
        ..lineTo(x(i), y(daily[i]));
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round);

    // The lowest point: an 8px marker with a surface ring.
    final lp = Offset(x(lowestIndex), y(daily[lowestIndex]));
    canvas.drawCircle(lp, 6, Paint()..color = surface);
    canvas.drawCircle(lp, 4, Paint()..color = low);

    // Touch: crosshair and point.
    if (touched != null) {
      final tp = Offset(x(touched!), y(daily[touched!]));
      canvas.drawLine(Offset(tp.dx, topPad), Offset(tp.dx, h),
          Paint()
            ..color = label
            ..strokeWidth = 1);
      canvas.drawCircle(tp, 6, Paint()..color = surface);
      canvas.drawCircle(tp, 4, Paint()..color = line);
    }
  }

  @override
  bool shouldRepaint(_ForecastPainter old) =>
      old.daily != daily || old.touched != touched || old.line != line;
}
