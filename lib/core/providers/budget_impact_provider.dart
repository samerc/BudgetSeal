import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// What an expense did to its envelope: the envelope's balance (in the
/// spent currency) right after it, shown on Activity rows as
/// "Food & drink · $142.80 left" / "over by $8.00".
class EnvelopeImpact {
  final String allocationId;
  final String name;
  final String currency;

  /// Balance right after this transaction.
  final double balanceAfter;

  /// The envelope's balance now, in the same currency (a Cover pill only
  /// makes sense while it is still below zero).
  final double balanceNow;

  /// Envelopes this transaction spent from (split lines can hit several).
  final int envelopeCount;

  /// The envelope's most recent spending — the one row that offers Cover,
  /// so an overspent envelope doesn't put a button on every row.
  final bool isLatest;

  const EnvelopeImpact({
    required this.allocationId,
    required this.name,
    required this.currency,
    required this.balanceAfter,
    required this.balanceNow,
    this.envelopeCount = 1,
    this.isLatest = false,
  });

  bool get overspent => balanceAfter < -0.005;
  bool get stillOverspent => balanceNow < -0.005;
}

/// Transaction id → [EnvelopeImpact], for every posted expense that spent
/// from an envelope. One pass over the household's ledger: rows are
/// replayed per envelope and currency in time order — a spending row at its
/// transaction's date, funding/moves/resets at the time they were made.
final txEnvelopeImpactProvider =
    StreamProvider<Map<String, EnvelopeImpact>>((ref) {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return const Stream.empty();
  return envelopeImpactQuery(db, householdId).watchSingle();
});

/// The same replay as [txEnvelopeImpactProvider], as a query (watch it, or
/// `.getSingle()` once — the Web Companion's transaction list).
Selectable<Map<String, EnvelopeImpact>> envelopeImpactQuery(
        AppDatabase db, String householdId) =>
    _LedgerReplay(db.customSelect(
      'SELECT l.id AS id, l.allocation_id AS alloc, '
      'l.source_transaction_id AS tx, l.entry_type AS type, '
      'l.amount AS amount, l.currency AS currency, '
      'l.created_at AS lc, t.created_at AS tc, a.name AS name '
      'FROM allocation_ledger l '
      'INNER JOIN allocations a ON a.id = l.allocation_id '
      'LEFT JOIN transactions t ON t.id = l.source_transaction_id '
      'WHERE a.household_id = ? '
      'AND (l.source_transaction_id IS NULL OR t.id IS NULL OR t.deleted = 0)',
      variables: [Variable.withString(householdId)],
      readsFrom: {db.allocationLedger, db.allocations, db.transactions},
    ));

/// Wraps the ledger query and folds all its rows into one map.
class _LedgerReplay extends Selectable<Map<String, EnvelopeImpact>> {
  final Selectable<QueryRow> rows;
  _LedgerReplay(this.rows);

  @override
  Future<List<Map<String, EnvelopeImpact>>> get() async =>
      [_replay(await rows.get())];

  @override
  Stream<List<Map<String, EnvelopeImpact>>> watch() =>
      rows.watch().map((r) => [_replay(r)]);
}

Map<String, EnvelopeImpact> _replay(List<QueryRow> rows) {
  final items = [
    for (final r in rows)
      (
        id: r.data['id'] as String,
        alloc: r.data['alloc'] as String,
        tx: r.data['tx'] as String?,
        spend: r.data['type'] == 'consumption',
        amount: (r.data['amount'] as num).toDouble(),
        currency: r.data['currency'] as String,
        name: r.data['name'] as String,
        time: (r.data['type'] == 'consumption' && r.data['tc'] != null
            ? r.data['tc']
            : r.data['lc']) as int,
      ),
  ]..sort((a, b) {
      final t = a.time.compareTo(b.time);
      if (t != 0) return t;
      final x = (a.tx ?? '').compareTo(b.tx ?? '');
      return x != 0 ? x : a.id.compareTo(b.id);
    });

  final running = <String, double>{};
  final after =
      <String, ({String alloc, String name, String ccy, double bal})>{};
  final envelopes = <String, Set<String>>{};
  final latest = <String, String>{}; // alloc|currency → last spending tx
  for (final i in items) {
    final key = '${i.alloc}|${i.currency}';
    final bal = (running[key] ?? 0) + i.amount;
    running[key] = bal;
    if (!i.spend || i.tx == null) continue;
    latest[key] = i.tx!;
    final seen = envelopes.putIfAbsent(i.tx!, () => {});
    // A split keeps the first envelope it spent from.
    if (seen.isEmpty || seen.first == i.alloc) {
      after[i.tx!] = (alloc: i.alloc, name: i.name, ccy: i.currency, bal: bal);
    }
    seen.add(i.alloc);
  }
  return {
    for (final e in after.entries)
      e.key: EnvelopeImpact(
        allocationId: e.value.alloc,
        name: e.value.name,
        currency: e.value.ccy,
        balanceAfter: e.value.bal,
        balanceNow: running['${e.value.alloc}|${e.value.ccy}'] ?? 0,
        envelopeCount: envelopes[e.key]!.length,
        isLatest: latest['${e.value.alloc}|${e.value.ccy}'] == e.key,
      ),
  };
}
