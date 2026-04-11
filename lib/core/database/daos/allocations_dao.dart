import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/allocations_table.dart';
import '../tables/categories_table.dart';

part 'allocations_dao.g.dart';

class AllocationWithCategory {
  final Allocation allocation;
  final Category? category;
  const AllocationWithCategory(this.allocation, this.category);
}

@DriftAccessor(tables: [Allocations, Categories])
class AllocationsDao extends DatabaseAccessor<AppDatabase>
    with _$AllocationsDaoMixin {
  AllocationsDao(super.db);

  Stream<List<AllocationWithCategory>> watchAll(String householdId) {
    final query = select(allocations).join([
      leftOuterJoin(
          categories, categories.id.equalsExp(allocations.categoryId)),
    ])
      ..where(allocations.householdId.equals(householdId) &
          allocations.archived.equals(false))
      ..orderBy([OrderingTerm.asc(allocations.name)]);

    return query.watch().map((rows) => rows
        .map((row) => AllocationWithCategory(
              row.readTable(allocations),
              row.readTableOrNull(categories),
            ))
        .toList());
  }

  Future<Allocation?> getById(String id) =>
      (select(allocations)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Get all categories linked to this envelope.
  Future<List<Category>> linkedCategories(String allocationId) =>
      (select(categories)
            ..where((c) => c.allocationId.equals(allocationId))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .get();

  /// Link a category to an envelope.
  Future<void> linkCategory(String categoryId, String allocationId) =>
      (update(categories)..where((c) => c.id.equals(categoryId)))
          .write(CategoriesCompanion(allocationId: Value(allocationId)));

  /// Unlink a category from its envelope.
  Future<void> unlinkCategory(String categoryId) =>
      (update(categories)..where((c) => c.id.equals(categoryId)))
          .write(const CategoriesCompanion(allocationId: Value(null)));

  Future<String> upsert(AllocationsCompanion entry) async {
    await into(allocations).insertOnConflictUpdate(entry);
    return entry.id.value;
  }

  Future<void> archive(String id) =>
      (update(allocations)..where((t) => t.id.equals(id)))
          .write(const AllocationsCompanion(archived: Value(true)));
}
