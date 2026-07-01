import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';
import 'household_provider.dart';

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return Stream.value([]);

  return (db.select(db.categories)
        ..where((c) =>
            c.householdId.equals(householdId) &
            c.archived.equals(false) &
            c.deleted.equals(false))
        ..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .watch();
});
