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

  /// Watch all entries for an allocation, newest first.
  Stream<List<AllocationLedgerData>> watchByAllocation(String allocationId) =>
      (select(allocationLedger)
            ..where((t) => t.allocationId.equals(allocationId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

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

  /// Get all ledger entries for a household across all allocations.
  /// Use getAllBalances() instead when you only need sums.
  Future<List<AllocationLedgerData>> getAllForHousehold(
      List<String> allocationIds) async {
    return (select(allocationLedger)
          ..where((t) => t.allocationId.isIn(allocationIds)))
        .get();
  }

  /// Delete all ledger entries linked to a given transaction.
  Future<int> deleteByTransactionId(String txId) {
    return (delete(allocationLedger)
          ..where((t) => t.sourceTransactionId.equals(txId)))
        .go();
  }
}
