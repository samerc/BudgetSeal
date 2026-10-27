import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'fx_provider.dart';
import 'live_fx_provider.dart';

/// Where a currency pair's rate comes from: fetched live, the user's
/// fixed rate, or the rate they last actually got (a change payment or an
/// exchange between their accounts — in cash economies the street rate).
enum RateSource { live, fixed, got }

/// Fetched rates (not the user's own).
const _fetched = ['api', 'mock'];

String _pairKey(String a, String b) =>
    a.compareTo(b) < 0 ? '$a/$b' : '$b/$a';

/// The source chosen for the pair [a]/[b] (either direction): fixed when
/// the user set a rate, else what Settings › Exchange rates says (kept in
/// `households.settingsJson` → `rateSources`, so a shared budget agrees),
/// else live.
Future<RateSource> rateSource(AppDatabase db, String a, String b) async {
  if (await manualRate(db, a, b) != null) return RateSource.fixed;
  return await _chosenSource(db, a, b) ?? RateSource.live;
}

Future<RateSource?> _chosenSource(AppDatabase db, String a, String b) async {
  for (final h in await db.select(db.households).get()) {
    try {
      final m = jsonDecode(h.settingsJson) as Map<String, dynamic>;
      final v = (m['rateSources'] as Map<String, dynamic>?)?[_pairKey(a, b)];
      if (v == 'got') return RateSource.got;
      if (v == 'live') return RateSource.live;
    } catch (_) {}
  }
  return null;
}

/// Choose live or "last rate I got" for the pair (fixed is chosen by
/// setting a manual rate).
Future<void> setRateSource(
    AppDatabase db, String householdId, String a, String b, RateSource source) async {
  final h = await (db.select(db.households)
        ..where((x) => x.id.equals(householdId)))
      .getSingle();
  Map<String, dynamic> m;
  try {
    m = jsonDecode(h.settingsJson) as Map<String, dynamic>;
  } catch (_) {
    m = {};
  }
  final sources = {...?(m['rateSources'] as Map<String, dynamic>?)};
  if (source == RateSource.got) {
    sources[_pairKey(a, b)] = 'got';
  } else {
    sources.remove(_pairKey(a, b));
  }
  m['rateSources'] = sources;
  await (db.update(db.households)..where((x) => x.id.equals(householdId)))
      .write(HouseholdsCompanion(
          settingsJson: Value(jsonEncode(m)),
          lastModified: Value(DateTime.now())));
}

/// The rate [from] → [to] the user last actually got, with when, or null.
Future<({double rate, DateTime at})?> rateGot(
    AppDatabase db, String from, String to) async {
  final row = await (db.select(db.fxRates)
        ..where((t) =>
            t.source.equals('got') &
            ((t.fromCurrency.equals(from) & t.toCurrency.equals(to)) |
                (t.fromCurrency.equals(to) & t.toCurrency.equals(from))))
        ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
        ..limit(1))
      .getSingleOrNull();
  if (row == null || row.rate <= 0) return null;
  return (
    rate: row.fromCurrency == from ? row.rate : 1 / row.rate,
    at: row.fetchedAt,
  );
}

/// Remembers 1 [from] = [rate] [to] as the rate the user actually got
/// (one row per pair, the latest). Called when money really changed
/// currency: a transfer between accounts in two currencies, a payment
/// with change in another currency.
Future<void> noteRateGot(
    AppDatabase db, String from, String to, double rate) async {
  if (from == to || rate <= 0) return;
  await (db.delete(db.fxRates)
        ..where((t) =>
            t.source.equals('got') &
            ((t.fromCurrency.equals(from) & t.toCurrency.equals(to)) |
                (t.fromCurrency.equals(to) & t.toCurrency.equals(from)))))
      .go();
  await db.into(db.fxRates).insert(FxRatesCompanion.insert(
        id: const Uuid().v4(),
        fromCurrency: from,
        toCurrency: to,
        rate: rate,
        source: const Value('got'),
      ));
}

/// The rate the pair's chosen source gives without going online: fixed,
/// or the last one got (when chosen and known); null for live.
Future<double?> _ownRate(AppDatabase db, String from, String to) async {
  final manual = await manualRate(db, from, to);
  if (manual != null) return manual;
  if (await _chosenSource(db, from, to) == RateSource.got) {
    return (await rateGot(db, from, to))?.rate;
  }
  return null;
}

/// The latest fetched rate [from] → [to] (either direction), with when.
Future<({double rate, DateTime at})?> latestFetchedRate(
    AppDatabase db, String from, String to) async {
  final row = await (db.select(db.fxRates)
        ..where((t) =>
            t.source.isIn(_fetched) &
            ((t.fromCurrency.equals(from) & t.toCurrency.equals(to)) |
                (t.fromCurrency.equals(to) & t.toCurrency.equals(from))))
        ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
        ..limit(1))
      .getSingleOrNull();
  if (row == null || row.rate <= 0) return null;
  return (
    rate: row.fromCurrency == from ? row.rate : 1 / row.rate,
    at: row.fetchedAt,
  );
}

/// Latest rate [from] → [to] (direct, or the inverse of [to] → [from]),
/// whatever its age, or null if none is known: the pair's own rate (fixed,
/// or the last one got when chosen), else the latest fetched one. Offline
/// and instant — for work that must not wait on the network (app start).
Future<double?> latestCachedRate(AppDatabase db, String from, String to) async {
  if (from == to) return 1.0;
  final own = await _ownRate(db, from, to);
  if (own != null) return own;
  Future<FxRate?> latest(String a, String b) => (db.select(db.fxRates)
        ..where((t) =>
            t.fromCurrency.equals(a) &
            t.toCurrency.equals(b) &
            t.source.isIn(_fetched))
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

  /// Get exchange rate from [from] to [to], using cache when fresh: the
  /// pair's own rate when it has one (fixed, or the last one got), unless
  /// [liveOnly].
  Future<double> getRateWithCache(String from, String to,
      {bool forceRefresh = false, bool liveOnly = false}) async {
    if (from == to) return 1.0;
    final own = liveOnly ? null : await _ownRate(_db, from, to);
    if (own != null) return own;

    // Check cache
    final cached = await (_db.select(_db.fxRates)
          ..where((t) =>
              t.fromCurrency.equals(from) &
              t.toCurrency.equals(to) &
              t.source.isIn(_fetched))
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
