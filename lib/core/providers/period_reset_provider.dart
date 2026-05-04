import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/period_reset_service.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// IDs of envelopes needing manual period reset.
final pendingResetProvider = FutureProvider<List<String>>((ref) async {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return [];
  return PeriodResetService.getPendingManualIds(db, householdId);
});

/// Run auto-resets on app launch. Returns count of pending manual ones.
final periodResetCheckProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final household = ref.watch(householdProvider).value;
  if (household == null) return 0;
  return PeriodResetService.checkAndAutoReset(
      db, household.id, household.periodStartDay);
});
