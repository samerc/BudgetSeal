// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_dao.dart';

// ignore_for_file: type=lint
mixin _$TransactionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $HouseholdsTable get households => attachedDatabase.households;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $AllocationsTable get allocations => attachedDatabase.allocations;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  TransactionsDaoManager get managers => TransactionsDaoManager(this);
}

class TransactionsDaoManager {
  final _$TransactionsDaoMixin _db;
  TransactionsDaoManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db.attachedDatabase, _db.households);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$AllocationsTableTableManager get allocations =>
      $$AllocationsTableTableManager(_db.attachedDatabase, _db.allocations);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}
