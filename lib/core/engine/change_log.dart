import 'package:drift/drift.dart';

import '../database/app_database.dart';

enum ChangeKind { added, edited, deleted }

/// One entry of the change history.
class ChangeEvent {
  final ChangeKind kind;
  final Transaction tx; // the live row (added/edited) or the deleted one
  final DateTime at;
  const ChangeEvent(this.kind, this.tx, this.at);
}

/// The change history from transaction rows alone (no log table): a row's
/// `lastModified` is when it was saved, or when it was deleted. An edit
/// saves a new row and deletes the old one within moments, so a deleted
/// row and a live row of the same type within [pairWindow] read as one
/// "edited". Newest first.
List<ChangeEvent> buildChangeLog(List<Transaction> rows,
    {Duration pairWindow = const Duration(seconds: 10)}) {
  final live = rows.where((t) => !t.deleted).toList();
  final deleted = rows.where((t) => t.deleted).toList();
  final edited = <String>{};
  final pairedDeleted = <String>{};
  for (final d in deleted) {
    Transaction? best;
    var bestGap = pairWindow;
    for (final a in live) {
      if (edited.contains(a.id) || a.type != d.type) continue;
      final gap = a.lastModified.difference(d.lastModified).abs();
      if (gap <= bestGap) {
        best = a;
        bestGap = gap;
      }
    }
    if (best != null) {
      edited.add(best.id);
      pairedDeleted.add(d.id);
    }
  }
  final out = <ChangeEvent>[
    for (final a in live)
      ChangeEvent(edited.contains(a.id) ? ChangeKind.edited : ChangeKind.added,
          a, a.lastModified),
    for (final d in deleted)
      if (!pairedDeleted.contains(d.id))
        ChangeEvent(ChangeKind.deleted, d, d.lastModified),
  ]..sort((a, b) => b.at.compareTo(a.at));
  return out;
}

/// The newest [limit] posted or deleted rows as a change history, with
/// each row's lines (planned payments aren't history yet).
Future<({List<ChangeEvent> events, Map<String, List<TransactionLine>> lines})>
    loadChangeLog(AppDatabase db, String householdId, {int limit = 300}) async {
  final rows = await (db.select(db.transactions)
        ..where((t) =>
            t.householdId.equals(householdId) &
            (t.status.isNull() | t.deleted.equals(true)))
        ..orderBy([(t) => OrderingTerm.desc(t.lastModified)])
        ..limit(limit))
      .get();
  final ids = rows.map((t) => t.id).toList();
  final lines = ids.isEmpty
      ? const <TransactionLine>[]
      : await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.isIn(ids)))
          .get();
  final byTx = <String, List<TransactionLine>>{};
  for (final l in lines) {
    byTx.putIfAbsent(l.transactionId, () => []).add(l);
  }
  return (events: buildChangeLog(rows), lines: byTx);
}
