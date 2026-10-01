import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/daos/allocations_dao.dart';
import '../database/daos/ledger_dao.dart';
import '../engine/balance_calculator.dart';
import '../engine/period_engine.dart';
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
  var latest = 0;

  Future<void> recompute() async {
    final list = cachedList;
    if (list == null) return;
    final seq = ++latest;

    final allocIds = list.map((awc) => awc.allocation.id).toList();
    final balancesByAlloc = allocIds.isNotEmpty
        ? await ledgerDao.getAllBalances(allocIds)
        : <String, Map<String, double>>{};

    // Skip if a newer recompute started meanwhile (it will emit).
    if (seq == latest && !controller.isClosed) {
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
    recompute().catchError(
        (e) => debugPrint('[allocationsProvider] recompute error: $e'));
  });

  // Recompute on every ledger write, and on transaction writes: balances
  // exclude ledger rows of soft-deleted transactions, and Unallocated (which
  // re-runs when this emits) depends on account balances. tableUpdates fires
  // on each write — a watched MAX(rowid) missed deletes and soft-deletes.
  final ledgerSub = db
      .tableUpdates(TableUpdateQuery.onAllTables(
          [db.allocationLedger, db.transactions, db.transactionLines]))
      .listen((_) {
    recompute().catchError(
        (e) => debugPrint('[allocationsProvider] recompute error: $e'));
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

/// What each envelope spent in the current budget period, by transaction
/// date: `Map<allocationId, Map<currency, spent>>`. Re-evaluated when the
/// period start day changes; reopening the app picks up a new period.
final periodSpendingProvider =
    StreamProvider<Map<String, Map<String, double>>>((ref) {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return const Stream.empty();
  final startDay = ref.watch(
      householdProvider.select((h) => h.value?.periodStartDay ?? 1));
  final period = budgetPeriodFor(startDay);
  return LedgerDao(db)
      .watchSpendingInPeriod(householdId, period.start, period.end);
});
