import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
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
    // Only meaningful if single currency — returns sum of all balances.
    // For multi-currency envelopes, use balanceByCurrency[currency] directly.
    return balanceByCurrency.values.fold(0.0, (a, b) => a + b);
  }
}

final allocationsProvider =
    StreamProvider<List<AllocationWithBalance>>((ref) {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return const Stream.empty();

  final dao = AllocationsDao(db);
  final ledgerDao = LedgerDao(db);

  // Controller to merge both allocation and ledger change events
  final controller = StreamController<List<AllocationWithBalance>>();
  List<AllocationWithCategory>? cachedList;

  Future<void> recompute() async {
    final list = cachedList;
    if (list == null) return;

    final allocIds = list.map((awc) => awc.allocation.id).toList();
    List<AllocationLedgerData> allEntries = [];
    if (allocIds.isNotEmpty) {
      allEntries = await ledgerDao.getAllForHousehold(allocIds);
    }

    final balancesByAlloc = <String, Map<String, double>>{};
    for (final e in allEntries) {
      balancesByAlloc.putIfAbsent(e.allocationId, () => {});
      balancesByAlloc[e.allocationId]![e.currency] =
          (balancesByAlloc[e.allocationId]![e.currency] ?? 0) + e.amount;
    }

    if (!controller.isClosed) {
      controller.add([
        for (final awc in list)
          AllocationWithBalance(
            data: awc,
            balanceByCurrency: balancesByAlloc[awc.allocation.id] ?? {},
          ),
      ]);
    }
  }

  // Watch allocations table — re-compute when allocations change
  final allocSub = dao.watchAll(householdId).listen((list) {
    cachedList = list;
    recompute();
  });

  // Watch ledger table — re-compute when balances change
  final ledgerSub = db.select(db.allocationLedger).watch().listen((_) {
    recompute();
  });

  ref.onDispose(() {
    allocSub.cancel();
    ledgerSub.cancel();
    controller.close();
  });

  return controller.stream;
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
