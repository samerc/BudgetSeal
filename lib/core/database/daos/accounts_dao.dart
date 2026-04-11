import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts_table.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase> with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Stream<List<Account>> watchAll(String householdId) =>
      (select(accounts)
            ..where((t) => t.householdId.equals(householdId) & t.archived.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<Account?> getById(String id) =>
      (select(accounts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> upsert(AccountsCompanion entry) async {
    await into(accounts).insertOnConflictUpdate(entry);
    return entry.id.value;
  }

  Future<void> archive(String id) => (update(accounts)..where((t) => t.id.equals(id)))
      .write(const AccountsCompanion(archived: Value(true)));
}
