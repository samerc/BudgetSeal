import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'fx_provider.dart';
import 'live_fx_provider.dart';

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
  Future<double> getRateWithCache(String from, String to) async {
    if (from == to) return 1.0;

    // Check cache
    final cached = await (_db.select(_db.fxRates)
          ..where((t) =>
              t.fromCurrency.equals(from) & t.toCurrency.equals(to))
          ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
          ..limit(1))
        .getSingleOrNull();

    if (cached != null &&
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
}
