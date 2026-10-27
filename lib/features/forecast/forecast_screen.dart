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

/// The line under "safe to spend": until when.
String _untilLine(S tr, CurrencyForecast f) {
  final next = f.nextIncome;
  if (next == null) return tr.forecastNoIncome;
  return next.kind == ForecastKind.estimate
      ? tr.forecastUntilEst(formatDate(next.date))
      : tr.forecastUntil(formatDate(next.date));
}

/// Home: "Safe to spend today" in the base currency, the lowest point
/// ahead; opens the forecast (roadmap #4).
class ForecastCard extends ConsumerWidget {
  const ForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency;
    final f = ref.watch(forecastProvider).value?[base];
    if (f == null || (f.events.isEmpty && f.start == 0)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tappable(
        onTap: () => context.push('/forecast'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppColors.card(context),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr.forecastSafeToday,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.ts(context))),
                  Text(
                    formatAmount(f.safeToSpend, currency: f.currency),
                    style: TextStyle(
                      fontFamily: TypographyTokens.displayFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: f.short > 0 ? AppColors.overspent : null,
                    ),
                  ),
                  Text(
                    f.short > 0
                        ? tr.forecastShort(
                            formatAmount(f.short, currency: f.currency))
                        : _untilLine(tr, f),
                    maxLines: 2,
                    style:
                        TextStyle(fontSize: 12.5, color: AppColors.ts(context)),
                  ),
                  if (f.lowest < f.start)
                    Text(
                      tr.forecastLowest(
                          formatAmount(f.lowest, currency: f.currency),
                          formatDate(f.lowestOn)),
                      style: TextStyle(
                          fontSize: 12.5,
                          color: f.lowest < 0
                              ? AppColors.overspent
                              : AppColors.ts(context)),
                    ),
                ],
              ),
            ),
            Icon(AppIcons.caretRight, size: 18, color: AppColors.th(context)),
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
                    for (final (label, value) in [
                      (tr.forecastCashNow, money(f.start)),
                      (tr.forecastDue, money(-f.dueBefore)),
                      if (f.reserved > 0.005)
                        (tr.forecastReserved, money(-f.reserved)),
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
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

/// The balance over the next 90 days: one line (the title names it, so no
/// legend), the lowest point marked and labelled, a zero line only when it
/// goes below zero, month labels; touch shows the day's balance.
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
    final i = (local.dx / width * (n - 1)).round().clamp(0, n - 1);
    if (i != _touched) setState(() => _touched = i);
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final f = widget.forecast;
    final i = _touched;
    final day = f.today.add(Duration(days: i ?? 0));
    final tooltip = i == null
        ? tr.forecastLowest(formatAmount(f.lowest, currency: f.currency),
            formatDate(f.lowestOn))
        : '${formatDate(day)} · ${formatAmount(f.daily[i], currency: f.currency)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(tooltip,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: (i == null ? f.lowest : f.daily[i]) < 0
                    ? AppColors.overspent
                    : AppColors.tp(context),
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
                  daily: f.daily,
                  today: f.today,
                  lowestIndex: f.lowestOn.difference(f.today).inDays,
                  touched: i,
                  line: AppColors.accent,
                  low: f.lowest < 0 ? AppColors.overspent : AppColors.accent,
                  grid: AppColors.bd(context),
                  label: AppColors.th(context),
                  surface: AppColors.sf(context),
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
  final List<double> daily;
  final DateTime today;
  final int lowestIndex;
  final int? touched;
  final Color line, low, grid, label, surface;

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
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelsH = 18.0;
    final h = size.height - labelsH;
    // The data's own range (a balance line, not bars: the dips are the
    // point), with room around it.
    var lo = daily.reduce((a, b) => a < b ? a : b);
    var hi = daily.reduce((a, b) => a > b ? a : b);
    final span = hi - lo;
    final pad = span == 0 ? (hi.abs() * 0.1 + 1) : span * 0.15;
    lo -= pad;
    hi += pad;
    double x(int i) => i / (daily.length - 1) * size.width;
    double y(double v) => h - (v - lo) / (hi - lo) * h;

    // Recessive axes: the zero line when the balance gets there, month
    // starts.
    final axis = Paint()
      ..color = grid
      ..strokeWidth = 1;
    if (lo < 0 && hi > 0) {
      canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)), axis);
    }
    final faint = Paint()
      ..color = grid.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    // Month starts.
    final text = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < daily.length; i++) {
      final d = today.add(Duration(days: i));
      if (d.day != 1) continue;
      canvas.drawLine(Offset(x(i), 0), Offset(x(i), h), faint);
      text
        ..text = TextSpan(
            text: formatMonth(d, short: true),
            style: TextStyle(fontSize: 11, color: label))
        ..layout();
      text.paint(canvas, Offset(x(i) + 3, h + 3));
    }

    // The balance line (2px).
    final path = Path()..moveTo(x(0), y(daily[0]));
    for (var i = 1; i < daily.length; i++) {
      // Steps: a balance changes on the day, not in between.
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
      canvas.drawLine(Offset(tp.dx, 0), Offset(tp.dx, h),
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
