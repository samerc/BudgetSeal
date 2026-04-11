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

  /// Compute balance per currency for a given allocation.
  /// Returns `Map<currency, netAmount>` where positive = credit.
  Future<Map<String, double>> getBalanceByCurrency(String allocationId) async {
    final entries = await (select(allocationLedger)
          ..where((t) => t.allocationId.equals(allocationId)))
        .get();

    final Map<String, double> balances = {};
    for (final e in entries) {
      balances[e.currency] = (balances[e.currency] ?? 0.0) + e.amount;
    }
    return balances;
  }

  /// Get all ledger entries for a household across all allocations.
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
