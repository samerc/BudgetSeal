import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/allocation_ledger_table.dart';

part 'ledger_dao.g.dart';

@DriftAccessor(tables: [AllocationLedger])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.db);

  /// Append a new entry. Ledger is immutable after insert.
  Future<void> appendEntry(AllocationLedgerCompanion entry) =>
      into(allocationLedger).insert(entry);

  /// Watch all entries for an allocation, newest first, each with the date
  /// to show: spending at its transaction's date (a purchase logged a day
  /// late is still yesterday's), other rows at their own time. Rows of
  /// deleted transactions are left out, as in the balance.
  Stream<List<({AllocationLedgerData entry, DateTime date})>> watchByAllocation(
      String allocationId) {
    final tx = db.transactions;
    final date = coalesce<DateTime>([
      tx.createdAt,
      allocationLedger.createdAt,
    ]);
    final q = select(allocationLedger).join([
      leftOuterJoin(tx, tx.id.equalsExp(allocationLedger.sourceTransactionId)),
    ])
      ..addColumns([date])
      ..where(allocationLedger.allocationId.equals(allocationId) &
          (tx.id.isNull() | tx.deleted.equals(false)))
      ..orderBy([OrderingTerm.desc(date)]);
    return q.watch().map((rows) => [
          for (final r in rows)
            (entry: r.readTable(allocationLedger), date: r.read(date)!),
        ]);
  }

  /// Compute balance per currency for a given allocation via SQL SUM.
  /// Returns `Map<currency, netAmount>` where positive = credit.
  Future<Map<String, double>> getBalanceByCurrency(String allocationId) async {
    // Exclude ledger entries whose source transaction has been (soft-)deleted.
    // Without this, deleting a transaction leaves its consumption in the
    // envelope balance — and across devices the balances diverge, because the
    // soft-deleted transaction propagates but the hard-deleted ledger rows do
    // not. Entries with no source transaction (manual funding, adjustments) or
    // an orphaned source are kept.
    final rows = await customSelect(
      'SELECT l.currency AS currency, SUM(l.amount) AS total '
      'FROM allocation_ledger l '
      'LEFT JOIN transactions t ON t.id = l.source_transaction_id '
      'WHERE l.allocation_id = ? '
      'AND (l.source_transaction_id IS NULL OR t.id IS NULL OR t.deleted = 0) '
      'GROUP BY l.currency',
      variables: [Variable.withString(allocationId)],
    ).get();

    final Map<String, double> balances = {};
    for (final row in rows) {
      final currency = row.data['currency'] as String;
      final total = (row.data['total'] as num?)?.toDouble() ?? 0.0;
      if (total.abs() > 0.001) balances[currency] = total;
    }
    return balances;
  }

  /// Get aggregated balances per allocation per currency for all allocations.
  /// Returns `Map<allocationId, Map<currency, netAmount>>`.
  /// Uses a single SQL query instead of loading raw entries.
  Future<Map<String, Map<String, double>>> getAllBalances(
      List<String> allocationIds) async {
    if (allocationIds.isEmpty) return {};

    // Same deleted-transaction exclusion as getBalanceByCurrency — keeps
    // envelope balances correct after a transaction delete and identical
    // across synced devices.
    final rows = await customSelect(
      'SELECT l.allocation_id AS allocation_id, l.currency AS currency, '
      'SUM(l.amount) AS total '
      'FROM allocation_ledger l '
      'LEFT JOIN transactions t ON t.id = l.source_transaction_id '
      'WHERE l.allocation_id IN (${allocationIds.map((_) => '?').join(', ')}) '
      'AND (l.source_transaction_id IS NULL OR t.id IS NULL OR t.deleted = 0) '
      'GROUP BY l.allocation_id, l.currency',
      variables: allocationIds.map((id) => Variable.withString(id)).toList(),
    ).get();

    final Map<String, Map<String, double>> result = {};
    for (final row in rows) {
      final allocId = row.data['allocation_id'] as String;
      final currency = row.data['currency'] as String;
      final total = (row.data['total'] as num?)?.toDouble() ?? 0.0;
      if (total.abs() > 0.001) {
        result.putIfAbsent(allocId, () => {})[currency] = total;
      }
    }
    return result;
  }

  /// Watch how much each envelope spent in [from, to), by transaction date.
  /// Returns `Map<allocationId, Map<currency, spent>>` with spent > 0
  /// (consumption net of refunds; funding and resets are not spending).
  Stream<Map<String, Map<String, double>>> watchSpendingInPeriod(
      String householdId, DateTime from, DateTime to) {
    return customSelect(
      'SELECT l.allocation_id AS allocation_id, l.currency AS currency, '
      'SUM(l.amount) AS total '
      'FROM allocation_ledger l '
      'INNER JOIN allocations a ON a.id = l.allocation_id '
      'INNER JOIN transactions t ON t.id = l.source_transaction_id '
      "WHERE a.household_id = ? AND l.entry_type = 'consumption' "
      'AND t.deleted = 0 AND t.created_at >= ? AND t.created_at < ? '
      'GROUP BY l.allocation_id, l.currency',
      variables: [
        Variable.withString(householdId),
        Variable.withInt(from.millisecondsSinceEpoch ~/ 1000),
        Variable.withInt(to.millisecondsSinceEpoch ~/ 1000),
      ],
      readsFrom: {allocationLedger, attachedDatabase.allocations,
          attachedDatabase.transactions},
    ).watch().map((rows) {
      final result = <String, Map<String, double>>{};
      for (final row in rows) {
        final spent = -((row.data['total'] as num?)?.toDouble() ?? 0.0);
        if (spent > 0.001) {
          result.putIfAbsent(row.data['allocation_id'] as String,
              () => {})[row.data['currency'] as String] = spent;
        }
      }
      return result;
    });
  }

  /// Money put into each envelope during [from, to) — funding and moves in
  /// (by ledger date): `Map<allocationId, Map<currency, funded>>`.
  Future<Map<String, Map<String, double>>> fundedInPeriod(
      String householdId, DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT l.allocation_id AS allocation_id, l.currency AS currency, '
      'SUM(l.amount) AS total '
      'FROM allocation_ledger l '
      'INNER JOIN allocations a ON a.id = l.allocation_id '
      "WHERE a.household_id = ? AND l.entry_type IN ('funding', 'transfer') "
      'AND l.amount > 0 AND l.created_at >= ? AND l.created_at < ? '
      'GROUP BY l.allocation_id, l.currency',
      variables: [
        Variable.withString(householdId),
        Variable.withInt(from.millisecondsSinceEpoch ~/ 1000),
        Variable.withInt(to.millisecondsSinceEpoch ~/ 1000),
      ],
      readsFrom: {allocationLedger, attachedDatabase.allocations},
    ).get();
    final result = <String, Map<String, double>>{};
    for (final row in rows) {
      final total = (row.data['total'] as num?)?.toDouble() ?? 0.0;
      if (total > 0.001) {
        result.putIfAbsent(row.data['allocation_id'] as String,
            () => {})[row.data['currency'] as String] = total;
      }
    }
    return result;
  }

  /// Each envelope's balance just before [at]: every row dated earlier
  /// (spending at its transaction's date, as in [watchByAllocation]), rows
  /// of deleted transactions left out. `Map<allocationId, Map<currency, balance>>`.
  Future<Map<String, Map<String, double>>> balancesAt(
      String householdId, DateTime at) async {
    final rows = await customSelect(
      'SELECT l.allocation_id AS allocation_id, l.currency AS currency, '
      'SUM(l.amount) AS total '
      'FROM allocation_ledger l '
      'INNER JOIN allocations a ON a.id = l.allocation_id '
      'LEFT JOIN transactions t ON t.id = l.source_transaction_id '
      'WHERE a.household_id = ? '
      'AND (l.source_transaction_id IS NULL OR t.id IS NULL OR t.deleted = 0) '
      'AND COALESCE(t.created_at, l.created_at) < ? '
      'GROUP BY l.allocation_id, l.currency',
      variables: [
        Variable.withString(householdId),
        Variable.withInt(at.millisecondsSinceEpoch ~/ 1000),
      ],
      readsFrom: {allocationLedger, attachedDatabase.allocations,
          attachedDatabase.transactions},
    ).get();
    final result = <String, Map<String, double>>{};
    for (final row in rows) {
      final total = (row.data['total'] as num?)?.toDouble() ?? 0.0;
      if (total.abs() > 0.001) {
        result.putIfAbsent(row.data['allocation_id'] as String,
            () => {})[row.data['currency'] as String] = total;
      }
    }
    return result;
  }

  /// What period resets since [from] took out of envelopes and returned to
  /// Ready to assign, per currency (positive amounts).
  Future<Map<String, double>> resetReturnedSince(
      String householdId, DateTime from) async {
    final rows = await customSelect(
      'SELECT l.currency AS currency, SUM(l.amount) AS total '
      'FROM allocation_ledger l '
      'INNER JOIN allocations a ON a.id = l.allocation_id '
      "WHERE a.household_id = ? AND l.entry_type = 'period_reset' "
      'AND l.created_at >= ? '
      'GROUP BY l.currency',
      variables: [
        Variable.withString(householdId),
        Variable.withInt(from.millisecondsSinceEpoch ~/ 1000),
      ],
      readsFrom: {allocationLedger, attachedDatabase.allocations},
    ).get();
    return {
      for (final row in rows)
        if (-((row.data['total'] as num?)?.toDouble() ?? 0) > 0.001)
          row.data['currency'] as String:
              -((row.data['total'] as num?)?.toDouble() ?? 0),
    };
  }

  /// Delete ledger entries whose source transaction is soft-deleted (balances
  /// already ignore them; this keeps the ledger and orphan counts clean).
  Future<int> deleteForDeletedTransactions() => customUpdate(
        'DELETE FROM allocation_ledger WHERE source_transaction_id IN '
        '(SELECT id FROM transactions WHERE deleted = 1)',
        updates: {allocationLedger},
        updateKind: UpdateKind.delete,
      );

  /// Delete all ledger entries linked to a given transaction.
  Future<int> deleteByTransactionId(String txId) {
    return (delete(allocationLedger)
          ..where((t) => t.sourceTransactionId.equals(txId)))
        .go();
  }
}
