import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/ledger_dao.dart';
import '../../../core/engine/budget_history.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/date_format_provider.dart';
import '../../../core/providers/family_provider.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/providers/report_stats_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/widgets/seal_mark.dart';
import 'report_period.dart';

/// This year (January to now) and how each month's envelopes did.
final _yearProvider = FutureProvider<
    ({
      ReportPeriod period,
      PeriodTotals totals,
      Map<DateTime, Map<String, EnvelopePeriodStat>> envelopes,
    })?>((ref) async {
  final household = ref.watch(householdProvider).value;
  final entries = await ref.watch(transactionEntriesProvider.future);
  ref.watch(visibleAllocationsProvider);
  if (household == null) return null;
  final startDay = ref.watch(reportsStartDayProvider);
  final now = reportBucketFor(DateTime.now(), startDay);
  final period = ReportPeriod(
      [for (var m = 1; m <= now.month; m++) DateTime(now.year, m, 1)],
      startDay);
  final dao = LedgerDao(ref.read(databaseProvider));
  return (
    period: period,
    totals: periodTotals(entries, period, household.baseCurrency),
    envelopes: {
      for (final b in period.buckets)
        b: await envelopePeriodStats(dao,
            householdId: household.id,
            start: period.range(b).start,
            end: period.range(b).end,
            currency: household.baseCurrency),
    },
  );
});

/// The year in review: a dark card with the seal, what was kept, months
/// sealed, the most reliable envelope, the biggest category, the favourite
/// place, the best month and no-spend days. Shareable as an image.
class YearReport extends ConsumerStatefulWidget {
  const YearReport({super.key});

  @override
  ConsumerState<YearReport> createState() => _YearReportState();
}

class _YearReportState extends ConsumerState<YearReport> {
  final _shot = GlobalKey();

  // The card is dark in every theme (it's made to be shared).
  static const _bg = Color(0xFF121318);
  static const _card = Color(0xFF1C1D24);
  static const _text = Color(0xFFF2EEE6);
  static const _muted = Color(0xFFB8B2A7);

  Future<void> _share() async {
    final tr = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary =
          _shot.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('no image');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/budgetseal_year.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      debugPrint('[YearReport] Share failed: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(tr.commonSomethingWentWrong),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final base = ref.watch(householdProvider).value?.baseCurrency ?? 'USD';
    final data = ref.watch(_yearProvider);
    final year = DateTime.now().year;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        actions: [
          IconButton(
            tooltip: tr.rptShareImage,
            icon: const Icon(AppIcons.shareNetwork),
            onPressed: data.value == null ? null : _share,
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
            child: Text(tr.commonCouldntLoadData,
                style: const TextStyle(color: _muted))),
        data: (d) => d == null
            ? const SizedBox.shrink()
            : ListView(
                padding: EdgeInsets.fromLTRB(
                    16, 0, 16, 24 + MediaQuery.viewPaddingOf(context).bottom),
                children: [
                  RepaintBoundary(
                    key: _shot,
                    child: ColoredBox(
                      color: _bg,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _content(context, tr, d, base, year),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _share,
                    icon: const Icon(AppIcons.shareNetwork, size: 18),
                    label: Text(tr.rptShareImage),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _content(
      BuildContext context,
      S tr,
      ({
        ReportPeriod period,
        PeriodTotals totals,
        Map<DateTime, Map<String, EnvelopePeriodStat>> envelopes,
      }) d,
      String base,
      int year) {
    final t = d.totals;
    String money(double v) => formatAmount(v, currency: base);
    final cats = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final names = {
      for (final a in ref.watch(visibleAllocationsProvider).value ?? const [])
        a.data.allocation.id: a.data.allocation.name,
    };

    // Months where envelopes were used and none went over.
    var sealedMonths = 0, activeMonths = 0;
    final heldCount = <String, int>{};
    for (final m in d.envelopes.values) {
      final used =
          m.values.where((s) => s.outcome != EnvelopeOutcome.idle).toList();
      if (used.isEmpty) continue;
      activeMonths++;
      if (used.every((s) => s.outcome == EnvelopeOutcome.held)) sealedMonths++;
      m.forEach((id, s) {
        if (s.outcome == EnvelopeOutcome.held) {
          heldCount[id] = (heldCount[id] ?? 0) + 1;
        }
      });
    }
    final reliable = (heldCount.entries.where((e) => names.containsKey(e.key))
            .toList()
          ..sort((a, b) => b.value != a.value
              ? b.value.compareTo(a.value)
              : names[a.key]!.compareTo(names[b.key]!)))
        .firstOrNull;

    // Biggest category (subcategories count toward their parent).
    final byTop = <String?, double>{};
    t.byCategory.forEach((id, v) {
      final c = cats[id];
      final k = c?.parentId != null && cats.containsKey(c!.parentId)
          ? c.parentId
          : id;
      byTop[k] = (byTop[k] ?? 0) + v;
    });
    final topCat = (byTop.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .firstOrNull;
    final place = (t.places.values.toList()
          ..sort((a, b) => b.count.compareTo(a.count)))
        .firstOrNull;
    DateTime? bestMonth;
    var bestKept = double.negativeInfinity;
    for (final b in d.period.buckets) {
      final k = (t.incomeByBucket[b] ?? 0) - (t.spentByBucket[b] ?? 0);
      if (k > bestKept) {
        bestKept = k;
        bestMonth = b;
      }
    }
    final days = elapsedDays(d.period.start, d.period.end);
    final noSpend = days - t.spendDays.length;
    final pct = t.income > 0.005 ? (t.kept / t.income * 100).round() : null;

    Widget box(String label, String value, String? sub) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(RadiusTokens.lg)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                // One line: IntrinsicHeight measures it unscaled.
                child: Text(value,
                    maxLines: 1,
                    style: const TextStyle(
                        fontFamily: TypographyTokens.displayFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _text)),
              ),
              if (sub != null)
                Text(sub,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          DatedSeal(top: '$year', size: 76),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr.rptYourYear('$year'),
                    style: const TextStyle(
                        fontFamily: TypographyTokens.displayFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _text)),
                Text(
                    tr.rptYearSpan(formatMonth(d.period.buckets.first),
                        formatMonth(d.period.buckets.last)),
                    style: const TextStyle(fontSize: 14, color: _muted)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(CardTokens.radius)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr.rptYouKept,
                  style: const TextStyle(fontSize: 13, color: _muted)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(money(t.kept),
                    style: TextStyle(
                        fontFamily: TypographyTokens.displayFamily,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentBright)),
              ),
              if (pct != null)
                Text(tr.rptOfEverything(pct),
                    style: const TextStyle(fontSize: 14, color: _text)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Two per row, each row as tall as its taller box.
        for (final pair in () {
          final boxes = [
            box(tr.rptMonthsSealed, tr.rptNofM(sealedMonths, activeMonths),
                tr.rptEveryHeld),
            box(tr.rptMostReliable, reliable == null ? '—' : names[reliable.key]!,
                reliable == null ? null : tr.rptHeldMonths(reliable.value)),
            box(
                tr.rptBiggestShare,
                topCat == null
                    ? '—'
                    : (cats[topCat.key]?.name ?? tr.rptUncategorized),
                topCat == null || t.spent <= 0
                    ? null
                    : '${money(topCat.value)} · ${(topCat.value / t.spent * 100).round()}%'),
            box(tr.rptFavouritePlace, place?.title ?? '—',
                place == null ? null : tr.rptVisits(place.count, money(place.total / place.count))),
            box(
                tr.rptBestMonth,
                bestMonth == null ? '—' : formatMonth(bestMonth),
                bestMonth == null ? null : tr.rptKeptValue(money(bestKept))),
            box(tr.rptNoSpendDays, '$noSpend', tr.rptOfDays(days)),
          ];
          return [
            for (var i = 0; i < boxes.length; i += 2) boxes.sublist(i, i + 2),
          ];
        }())
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: pair[0]),
                const SizedBox(width: 10),
                Expanded(child: pair[1]),
              ]),
            ),
          ),
      ],
    );
  }
}
