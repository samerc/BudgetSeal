import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// Provides all non-archived objectives for the current household.
final objectivesProvider =
    FutureProvider<List<Objective>>((ref) async {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return [];

  return (db.select(db.objectives)
        ..where((o) =>
            o.householdId.equals(householdId) & o.archived.equals(false))
        ..orderBy([(o) => OrderingTerm.asc(o.name)]))
      .get();
});

/// Provides a single objective by ID.
final objectiveByIdProvider =
    FutureProvider.family<Objective?, String>((ref, id) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.objectives)..where((o) => o.id.equals(id)))
      .getSingleOrNull();
});
