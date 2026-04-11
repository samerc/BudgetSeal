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
}
