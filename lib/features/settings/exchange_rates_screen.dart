import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _RateRow {
  final String currency;
  final double? rate; // 1 base = rate currency
  final bool manual;
  final DateTime? updated;
  const _RateRow(this.currency, this.rate, this.manual, this.updated);
}

/// Rates for every currency the budget uses (accounts, recurring items,
/// manual rates), with refresh and a manual override per currency.
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
    final manual = await (db.select(db.fxRates)
          ..where((t) => t.source.equals('manual')))
        .get();
    for (final m in manual) {
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
        final manual = await manualRate(db, base, c);
        double? rate = manual;
        if (rate == null) {
          try {
            rate = await fx.getRateWithCache(base, c, forceRefresh: refresh);
          } catch (e) {
            rate = await latestCachedRate(db, base, c);
          }
        }
        rows.add(_RateRow(c, rate, manual != null, await _updatedAt(c)));
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

  Future<DateTime?> _updatedAt(String c) async {
    final db = ref.read(databaseProvider);
    final base = _base;
    final row = await (db.select(db.fxRates)
          ..where((t) =>
              (t.fromCurrency.equals(base) & t.toCurrency.equals(c)) |
              (t.fromCurrency.equals(c) & t.toCurrency.equals(base)))
          ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.fetchedAt;
  }

  String _formatRate(double rate) {
    if (rate >= 1000) return formatNumber(rate, decimals: 0);
    if (rate >= 100) return formatNumber(rate, decimals: 1);
    if (rate >= 1) return formatNumber(rate, decimals: 2);
    return formatNumber(rate, decimals: 6);
  }

  Future<void> _editRate(_RateRow row) async {
    final tr = S.of(context);
    final base = _base;
    final ctrl = TextEditingController(
        text: row.rate != null ? formatRateForInput(row.rate!) : '');
    final result = await showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(tr.fxSetRateTitle(row.currency)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                prefixText: '1 $base = ',
                suffixText: row.currency,
              ),
            ),
            const SizedBox(height: 12),
            Text(tr.fxSetRateHint,
                style: TextStyle(fontSize: 12, color: AppColors.ts(dCtx))),
          ],
        ),
        actions: [
          if (row.manual)
            TextButton(
              onPressed: () => Navigator.pop(dCtx, 'clear'),
              child: Text(tr.fxUseLiveRate),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text(tr.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, 'save'),
            child: Text(tr.commonSave),
          ),
        ],
      ),
    );
    final text = ctrl.text;
    ctrl.dispose();
    if (result == null || !mounted) return;
    final fx = ref.read(fxServiceProvider);
    try {
      if (result == 'clear') {
        await fx.clearManualRate(base, row.currency);
      } else {
        final rate = parseLooseAmount(text);
        if (rate == null || rate <= 0) return;
        await fx.saveManualRate(base, row.currency, rate);
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: tr.fxRefreshTooltip,
            onPressed: _loading ? null : () => _load(refresh: true),
          ),
        ],
      ),
      body: !_loadedOnce
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(CardTokens.radius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.currency_exchange_rounded,
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
                    child: Text(
                      tr.fxNoCurrencies,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.ts(context)),
                    ),
                  ),
                for (final row in _rows)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sf(context),
                      borderRadius: BorderRadius.circular(CardTokens.radius),
                      boxShadow: AppColors.cardShadow(context),
                    ),
                    child: Material(
                      // Transparent Material so the ripple paints above the card fill.
                      type: MaterialType.transparency,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(CardTokens.radius)),
                        onTap: () => _editRate(row),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(10),
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
                          row.rate != null
                              ? '1 $baseCurrency = ${_formatRate(row.rate!)} ${row.currency}'
                              : tr.fxNoRateFor(row.currency),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            row.manual ? tr.fxManualTag : tr.fxLiveTag,
                            if (row.updated != null)
                              formatDateSmart(row.updated!.toLocal()),
                          ].join(' · '),
                          style: TextStyle(
                              fontSize: 12,
                              color: row.manual
                                  ? AppColors.accent
                                  : AppColors.ts(context)),
                        ),
                        trailing: Icon(Icons.edit_rounded,
                            size: 18, color: AppColors.th(context)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
