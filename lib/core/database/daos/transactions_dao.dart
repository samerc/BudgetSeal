import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transactions_table.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Stream<List<Transaction>> watchByHousehold(String householdId, {int limit = 50}) =>
      (select(transactions)
            ..where((t) => t.householdId.equals(householdId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  Future<Transaction?> getById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> insert(TransactionsCompanion entry) async {
    await into(transactions).insert(entry);
    return entry.id.value;
  }

  /// Fetch transactions for a specific month, filtered at the SQL level.
  /// Returns oldest-first for running-balance computation.
  Stream<List<Transaction>> watchByMonth(
    String householdId,
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (select(transactions)
          ..where((t) =>
              t.householdId.equals(householdId) &
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Fetch all transactions up to (but not including) a given month,
  /// oldest-first. Used to compute running balances before the target month.
  Future<List<Transaction>> getBeforeMonth(
    String householdId,
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    return (select(transactions)
          ..where((t) =>
              t.householdId.equals(householdId) &
              t.createdAt.isSmallerThanValue(start))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Fetch the most recent N transactions for a household.
  Stream<List<Transaction>> watchRecent(String householdId, {int limit = 10}) =>
      (select(transactions)
            ..where((t) => t.householdId.equals(householdId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();
}
