import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fx/fx_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/calculator_amount_field.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/settings_row.dart';
import '../../shared/widgets/skeleton_loader.dart';

typedef _Rate = ({double rate, DateTime at});

class _RateRow {
  final String currency;
  final RateSource source;
  // 1 base = rate currency, from each source.
  final _Rate? live;
  final _Rate? got;
  final _Rate? fixed;
  const _RateRow(this.currency, this.source, this.live, this.got, this.fixed);

  /// What new transactions use: the chosen source, else live.
  _Rate? get used => switch (source) {
        RateSource.fixed => fixed,
        RateSource.got => got ?? live,
        RateSource.live => live,
      };
}

/// Rates for every currency the budget uses (accounts, recurring items,
/// rates set or got), with refresh and a rate source per currency: live,
/// the last rate the user got, or their fixed rate.
class ExchangeRatesScreen extends ConsumerStatefulWidget {
  const ExchangeRatesScreen({super.key});

  @override
  ConsumerState<ExchangeRatesScreen> createState() =>
      _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends ConsumerState<ExchangeRatesScreen> {
  List<_RateRow> _rows = [];
  bool _loading = false;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _base =>
      ref.read(householdProvider).value?.baseCurrency ?? 'USD';

  /// Currencies the budget actually uses, base excluded.
  Future<List<String>> _currencies() async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    final set = <String>{};
    if (householdId != null) {
      final accts = await (db.select(db.accounts)
            ..where((a) =>
                a.householdId.equals(householdId) & a.deleted.equals(false)))
          .get();
      set.addAll(accts.map((a) => a.currency));
      final recs = await (db.select(db.recurringTransactions)
            ..where((r) =>
                r.householdId.equals(householdId) & r.deleted.equals(false)))
          .get();
      set.addAll(recs.map((r) => r.currency));
    }
    final own = await (db.select(db.fxRates)
          ..where((t) => t.source.isIn(['manual', 'got'])))
        .get();
    for (final m in own) {
      set
        ..add(m.fromCurrency)
        ..add(m.toCurrency);
    }
    set.remove(_base);
    return set.toList()..sort();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() => _loading = true);
    try {
      final base = _base;
      final db = ref.read(databaseProvider);
      final fx = ref.read(fxServiceProvider);
      final rows = <_RateRow>[];
      for (final c in await _currencies()) {
        try {
          await fx.getRateWithCache(base, c,
              forceRefresh: refresh, liveOnly: true);
        } catch (e) {
          debugPrint('[ExchangeRates] No live rate for $c: $e');
        }
        rows.add(_RateRow(
          c,
          await rateSource(db, base, c),
          await latestFetchedRate(db, base, c),
          await rateGot(db, base, c),
          await _fixed(c),
        ));
      }
      if (mounted) {
        setState(() {
          _rows = rows;
          _loading = false;
          _loadedOnce = true;
        });
      }
    } catch (e) {
      debugPrint('[ExchangeRates] Error loading: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadedOnce = true;
        });
      }
    }
  }

  Future<_Rate?> _fixed(String c) async {
    final db = ref.read(databaseProvider);
    final base = _base;
    final rate = await manualRate(db, base, c);
    if (rate == null) return null;
    final row = await (db.select(db.fxRates)
          ..where((t) =>
              t.source.equals('manual') &
              ((t.fromCurrency.equals(base) & t.toCurrency.equals(c)) |
                  (t.fromCurrency.equals(c) & t.toCurrency.equals(base))))
          ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
          ..limit(1))
        .getSingleOrNull();
    return (rate: rate, at: row?.fetchedAt ?? DateTime.now());
  }

  String _formatRate(double rate) {
    if (rate >= 1000) return formatNumber(rate, decimals: 0);
    if (rate >= 100) return formatNumber(rate, decimals: 1);
    if (rate >= 1) return formatNumber(rate, decimals: 2);
    return formatNumber(rate, decimals: 6);
  }

  /// Choose the currency's rate source; "fixed" then asks for the rate
  /// with the calculator (the dialog closes first — a sheet opened from a
  /// dialog crashes).
  Future<void> _editRate(_RateRow row) async {
    final tr = S.of(context);
    final base = _base;
    String line(_Rate r) =>
        '1 $base = ${_formatRate(r.rate)} ${row.currency} · '
        '${formatDateSmart(r.at.toLocal())}';
    final choice = await showDialog<RateSource>(
      context: context,
      builder: (dCtx) {
        Widget option(RateSource source, String title, String sub,
                {bool enabled = true}) =>
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: enabled,
              onTap: () => Navigator.pop(dCtx, source),
              leading: Icon(
                row.source == source
                    ? AppIcons.radioButtonFill
                    : AppIcons.circle,
                color: row.source == source
                    ? AppColors.accent
                    : AppColors.th(dCtx),
              ),
              title: Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: Text(sub,
                  style: TextStyle(fontSize: 12.5, color: AppColors.ts(dCtx))),
            );
        return AlertDialog(
          title: Text(tr.fxSetRateTitle(row.currency)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                option(RateSource.live, tr.fxSourceLive,
                    row.live == null ? tr.fxNoRateFor(row.currency) : line(row.live!)),
                option(RateSource.got, tr.fxSourceGot,
                    row.got == null ? tr.fxSourceGotNone : line(row.got!)),
                option(RateSource.fixed, tr.fxSourceFixed,
                    row.fixed == null ? tr.fxSourceFixedNone : line(row.fixed!)),
                const SizedBox(height: 8),
                Text(tr.fxSourceHint,
                    style: TextStyle(fontSize: 12, color: AppColors.ts(dCtx))),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              style: DialogButtons.outlined,
              onPressed: () => Navigator.pop(dCtx),
              child: Text(tr.commonCancel),
            ),
          ],
        );
      },
    );
    if (choice == null || !mounted) return;
    final db = ref.read(databaseProvider);
    final fx = ref.read(fxServiceProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    try {
      if (choice == RateSource.fixed) {
        final start = (row.fixed ?? row.used)?.rate ?? 0;
        // Shown the way round that reads as a number above 1.
        final inverted = start > 0 && start < 1;
        final typed = await showCalculatorSheet(
            context, inverted ? 1 / start : start,
            title: inverted
                ? tr.fxRateSheet(row.currency, base)
                : tr.fxRateSheet(base, row.currency));
        if (typed == null || typed <= 0) return;
        await fx.saveManualRate(
            base, row.currency, inverted ? 1 / typed : typed);
      } else {
        await fx.clearManualRate(base, row.currency);
        await setRateSource(db, householdId, base, row.currency, choice);
      }
      await _load();
    } catch (e) {
      debugPrint('[ExchangeRates] Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr.commonSomethingWentWrong),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final baseCurrency =
        ref.watch(householdProvider).value?.baseCurrency ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.fxTitle),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.arrowClockwise),
            tooltip: tr.fxRefreshTooltip,
            onPressed: _loading ? null : () => _load(refresh: true),
          ),
        ],
      ),
      body: !_loadedOnce
          ? const SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 8),
              child: SkeletonList())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: CardTokens.borderRadius,
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.currencyCircleDollar,
                          size: 20, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr.fxBaseLabel(baseCurrency),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      if (_loading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.accent),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr.fxCacheInfo,
                  style: TextStyle(fontSize: 12, color: AppColors.ts(context)),
                ),
                const SizedBox(height: 16),
                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: EmptyState(
                      icon: AppIcons.currencyCircleDollar,
                      title: tr.fxNoCurrencies,
                    ),
                  ),
                for (final row in _rows)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: Spacing.sm),
                    padding: EdgeInsets.zero,
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: CardTokens.borderRadius),
                        onTap: () => _editRate(row),
                        leading: Container(
                          width: SettingsRowStyle.iconSize,
                          height: SettingsRowStyle.iconSize,
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              row.currency,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          row.used != null
                              ? '1 $baseCurrency = ${_formatRate(row.used!.rate)} ${row.currency}'
                              : tr.fxNoRateFor(row.currency),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            switch (row.source) {
                              RateSource.fixed => tr.fxManualTag,
                              RateSource.got when row.got != null =>
                                tr.fxGotTag,
                              _ => tr.fxLiveTag,
                            },
                            if (row.used != null)
                              formatDateSmart(row.used!.at.toLocal()),
                          ].join(' · '),
                          style: TextStyle(
                              fontSize: 12,
                              color: row.source != RateSource.live
                                  ? AppColors.accent
                                  : AppColors.ts(context)),
                        ),
                        trailing: Icon(AppIcons.pencilSimple,
                            size: 18, color: AppColors.th(context)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
