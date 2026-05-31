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
            ..where((t) => t.householdId.equals(householdId) & t.deleted.equals(false) & t.status.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  Future<Transaction?> getById(String id) => (select(transactions)
        ..where((t) => t.id.equals(id) & t.deleted.equals(false)))
      .getSingleOrNull();

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
              t.deleted.equals(false) &
              t.status.isNull() &
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
              t.deleted.equals(false) &
              t.status.isNull() &
              t.createdAt.isSmallerThanValue(start))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Fetch the most recent N transactions for a household.
  Stream<List<Transaction>> watchRecent(String householdId, {int limit = 10}) =>
      (select(transactions)
            ..where((t) => t.householdId.equals(householdId) & t.deleted.equals(false) & t.status.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  /// Compute per-account running balance totals for all transactions before
  /// a given date using SQL aggregation. Returns `Map<accountId, balance>`
  /// starting from each account's initial balance.
  ///
  /// This replaces loading all prior transactions into memory.
  Future<Map<String, double>> getRunningBalancesBeforeDate(
    String householdId,
    DateTime before,
  ) async {
    final db = attachedDatabase;
    // Start with initial balances
    final accounts = await (db.select(db.accounts)
          ..where((a) => a.householdId.equals(householdId)))
        .get();
    final running = <String, double>{
      for (final a in accounts) a.id: a.initialBalance,
    };

    final beforeMs = before.millisecondsSinceEpoch ~/ 1000;

    // Income/expense via transaction_lines (per-line accounts)
    final lineResults = await db.customSelect(
      '''SELECT tl.account_id, t.type, SUM(tl.amount) as total
         FROM transaction_lines tl
         INNER JOIN transactions t ON t.id = tl.transaction_id
         WHERE t.household_id = ? AND t.deleted = 0 AND t.status IS NULL
           AND t.created_at < ? AND t.type IN ('income', 'expense')
           AND tl.account_id IS NOT NULL
         GROUP BY tl.account_id, t.type''',
      variables: [Variable.withString(householdId), Variable.withInt(beforeMs)],
    ).get();

    final perLineAccounts = <String>{};
    for (final row in lineResults) {
      final acctId = row.data['account_id'] as String;
      final type = row.data['type'] as String;
      final total = (row.data['total'] as num).toDouble();
      perLineAccounts.add(acctId);
      if (type == 'income') {
        running[acctId] = (running[acctId] ?? 0) + total;
      } else {
        running[acctId] = (running[acctId] ?? 0) - total;
      }
    }

    // Income/expense via header-level (no per-line account)
    // We need to exclude transactions that already have per-line accounts
    final headerResults = await db.customSelect(
      '''SELECT t.account_id, t.type, SUM(t.amount) as total
         FROM transactions t
         WHERE t.household_id = ? AND t.deleted = 0 AND t.status IS NULL
           AND t.created_at < ? AND t.type IN ('income', 'expense')
           AND t.id NOT IN (
             SELECT DISTINCT transaction_id FROM transaction_lines
             WHERE account_id IS NOT NULL
           )
         GROUP BY t.account_id, t.type''',
      variables: [Variable.withString(householdId), Variable.withInt(beforeMs)],
    ).get();

    for (final row in headerResults) {
      final acctId = row.data['account_id'] as String;
      final type = row.data['type'] as String;
      final total = (row.data['total'] as num).toDouble();
      if (type == 'income') {
        running[acctId] = (running[acctId] ?? 0) + total;
      } else {
        running[acctId] = (running[acctId] ?? 0) - total;
      }
    }

    // Outgoing transfers
    final outResults = await db.customSelect(
      '''SELECT account_id, SUM(amount) as total
         FROM transactions
         WHERE household_id = ? AND deleted = 0 AND status IS NULL
           AND created_at < ? AND type = 'transfer'
         GROUP BY account_id''',
      variables: [Variable.withString(householdId), Variable.withInt(beforeMs)],
    ).get();

    for (final row in outResults) {
      final acctId = row.data['account_id'] as String;
      final total = (row.data['total'] as num).toDouble();
      running[acctId] = (running[acctId] ?? 0) - total;
    }

    // Incoming transfers
    final inResults = await db.customSelect(
      '''SELECT destination_account_id, SUM(amount * exchange_rate_to_base) as total
         FROM transactions
         WHERE household_id = ? AND deleted = 0 AND status IS NULL
           AND created_at < ? AND type = 'transfer'
           AND destination_account_id IS NOT NULL
         GROUP BY destination_account_id''',
      variables: [Variable.withString(householdId), Variable.withInt(beforeMs)],
    ).get();

    for (final row in inResults) {
      final acctId = row.data['destination_account_id'] as String;
      final total = (row.data['total'] as num).toDouble();
      running[acctId] = (running[acctId] ?? 0) + total;
    }

    return running;
  }
}
