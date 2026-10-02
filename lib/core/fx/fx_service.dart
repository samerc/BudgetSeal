import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'fx_provider.dart';
import 'live_fx_provider.dart';

/// Latest cached rate [from] → [to] (direct, or the inverse of [to] →
/// [from]), whatever its age, or null if none was ever fetched. Offline and
/// instant — for work that must not wait on the network (app start).
Future<double?> latestCachedRate(AppDatabase db, String from, String to) async {
  if (from == to) return 1.0;
  final manual = await manualRate(db, from, to);
  if (manual != null) return manual;
  Future<FxRate?> latest(String a, String b) => (db.select(db.fxRates)
        ..where((t) => t.fromCurrency.equals(a) & t.toCurrency.equals(b))
        ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
        ..limit(1))
      .getSingleOrNull();
  final direct = await latest(from, to);
  if (direct != null && direct.rate > 0) return direct.rate;
  final inverse = await latest(to, from);
  if (inverse != null && inverse.rate > 0) return 1 / inverse.rate;
  return null;
}

/// The user's own rate [from] → [to] (set in Settings › Exchange rates, in
/// either direction), or null. A manual rate wins over live ones until the
/// user clears it — for currencies whose market rate differs from the
/// official one.
Future<double?> manualRate(AppDatabase db, String from, String to) async {
  final row = await (db.select(db.fxRates)
        ..where((t) =>
            t.source.equals('manual') &
            ((t.fromCurrency.equals(from) & t.toCurrency.equals(to)) |
                (t.fromCurrency.equals(to) & t.toCurrency.equals(from))))
        ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
        ..limit(1))
      .getSingleOrNull();
  if (row == null || row.rate <= 0) return null;
  return row.fromCurrency == from ? row.rate : 1 / row.rate;
}

/// FX rate service with caching to the local fx_rates table.
/// Automatically falls back to cached rate if provider is unavailable.
class FxService {
  final AppDatabase _db;
  FxProvider _provider;
  final _uuid = const Uuid();

  /// Cache TTL: 1 hour
  static const _cacheTtl = Duration(hours: 1);

  FxService(this._db) : _provider = LiveFxProvider();

  /// Swap the underlying provider (e.g. switch to a live API impl).
  void setProvider(FxProvider provider) => _provider = provider;

  /// Get exchange rate from [from] to [to], using cache when fresh.
  Future<double> getRateWithCache(String from, String to,
      {bool forceRefresh = false}) async {
    if (from == to) return 1.0;
    final manual = await manualRate(_db, from, to);
    if (manual != null) return manual;

    // Check cache
    final cached = await (_db.select(_db.fxRates)
          ..where((t) =>
              t.fromCurrency.equals(from) & t.toCurrency.equals(to))
          ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
          ..limit(1))
        .getSingleOrNull();

    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
      return cached.rate;
    }

    // Fetch from provider
    try {
      final rate = await _provider.getRate(from, to);
      await _db.into(_db.fxRates).insertOnConflictUpdate(
            FxRatesCompanion.insert(
              id: _uuid.v4(),
              fromCurrency: from,
              toCurrency: to,
              rate: rate,
              source: Value(_provider.isLive ? 'api' : 'mock'),
            ),
          );
      return rate;
    } catch (e) {
      debugPrint('FX rate fetch failed for $from->$to: $e');
      // Return cached rate even if stale
      if (cached != null) return cached.rate;
      rethrow;
    }
  }

  /// Store the user's own rate (1 [from] = [rate] [to]), replacing any
  /// earlier manual rate for the pair.
  Future<void> saveManualRate(String from, String to, double rate) async {
    await clearManualRate(from, to);
    await _db.into(_db.fxRates).insert(FxRatesCompanion.insert(
          id: _uuid.v4(),
          fromCurrency: from,
          toCurrency: to,
          rate: rate,
          source: const Value('manual'),
        ));
  }

  /// Go back to live rates for the pair (either direction).
  Future<void> clearManualRate(String a, String b) =>
      (_db.delete(_db.fxRates)
            ..where((t) =>
                t.source.equals('manual') &
                ((t.fromCurrency.equals(a) & t.toCurrency.equals(b)) |
                    (t.fromCurrency.equals(b) & t.toCurrency.equals(a)))))
          .go();
}

/// Rate [currency] → [base] for a line saved without a user-entered rate:
/// live (or fresh cache), else any cached rate, else 1.0 (the "No rate"
/// warning then shows and reports skip the line, as before).
Future<double> rateToBaseOrOne(
    FxService fx, AppDatabase db, String currency, String base) async {
  if (currency == base) return 1.0;
  try {
    final r = await fx.getRateWithCache(currency, base);
    if (r > 0) return r;
  } catch (_) {}
  return await latestCachedRate(db, currency, base) ?? 1.0;
}
