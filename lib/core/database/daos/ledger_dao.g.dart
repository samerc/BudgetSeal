// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_dao.dart';

// ignore_for_file: type=lint
mixin _$LedgerDaoMixin on DatabaseAccessor<AppDatabase> {
  $HouseholdsTable get households => attachedDatabase.households;
  $AllocationsTable get allocations => attachedDatabase.allocations;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $AllocationLedgerTable get allocationLedger =>
      attachedDatabase.allocationLedger;
  LedgerDaoManager get managers => LedgerDaoManager(this);
}

class LedgerDaoManager {
  final _$LedgerDaoMixin _db;
  LedgerDaoManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db.attachedDatabase, _db.households);
  $$AllocationsTableTableManager get allocations =>
      $$AllocationsTableTableManager(_db.attachedDatabase, _db.allocations);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
  $$AllocationLedgerTableTableManager get allocationLedger =>
      $$AllocationLedgerTableTableManager(
          _db.attachedDatabase, _db.allocationLedger);
}
