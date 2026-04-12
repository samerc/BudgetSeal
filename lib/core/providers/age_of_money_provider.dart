import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/age_of_money.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// Provides the Age of Money metric (average days between earning and
/// spending) for the current household. Returns `null` when there is
/// not enough transaction data to compute a meaningful value.
final ageOfMoneyProvider = FutureProvider<int?>((ref) async {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return null;
  return calculateAgeOfMoney(db, householdId);
});
