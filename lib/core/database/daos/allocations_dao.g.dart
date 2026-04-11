// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allocations_dao.dart';

// ignore_for_file: type=lint
mixin _$AllocationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $HouseholdsTable get households => attachedDatabase.households;
  $AllocationsTable get allocations => attachedDatabase.allocations;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CategoriesTable get categories => attachedDatabase.categories;
  AllocationsDaoManager get managers => AllocationsDaoManager(this);
}

class AllocationsDaoManager {
  final _$AllocationsDaoMixin _db;
  AllocationsDaoManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db.attachedDatabase, _db.households);
  $$AllocationsTableTableManager get allocations =>
      $$AllocationsTableTableManager(_db.attachedDatabase, _db.allocations);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
}
