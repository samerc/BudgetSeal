import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/daos/allocations_dao.dart';
import '../database/daos/ledger_dao.dart';
import '../engine/balance_calculator.dart';
import 'database_provider.dart';
import 'household_provider.dart';

class AllocationWithBalance {
  final AllocationWithCategory data;
  final Map<String, double> balanceByCurrency;

  const AllocationWithBalance({
    required this.data,
    required this.balanceByCurrency,
  });

  double get totalInBase {
    // Simplified: sum amounts (proper FX conversion done in UI layer)
    return balanceByCurrency.values.fold(0.0, (a, b) => a + b);
  }
}

final allocationsProvider =
    StreamProvider<List<AllocationWithBalance>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    yield [];
    return;
  }

  final dao = AllocationsDao(db);
  final ledgerDao = LedgerDao(db);

  await for (final list in dao.watchAll(householdId)) {
    final result = <AllocationWithBalance>[];
    for (final awc in list) {
      final balances = await ledgerDao.getBalanceByCurrency(awc.allocation.id);
      result.add(AllocationWithBalance(data: awc, balanceByCurrency: balances));
    }
    yield result;
  }
});

final unallocatedProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return {};
  // Watch allocations so we recompute when funding changes.
  ref.watch(allocationsProvider);
  return BalanceCalculator(db).unallocatedByCurrency(householdId);
});
