import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/ledger_dao.dart';
import '../../../core/engine/balance_calculator.dart';
import '../../../core/engine/period_engine.dart';
import '_serializers.dart';

/// Envelopes (in the Budget tab's order), Ready to assign per currency and
/// the current budget period — shared by the dashboard and envelopes routes.
Future<Map<String, dynamic>> budgetSnapshot(
    AppDatabase db, String householdId) async {
  final household = await (db.select(db.households)
        ..where((h) => h.id.equals(householdId)))
      .getSingleOrNull();

  final allocs = await (db.select(db.allocations)
        ..where((a) =>
            a.householdId.equals(householdId) &
            a.archived.equals(false) &
            a.deleted.equals(false))
        // Same order as the Budget tab: manual order first, then by name.
        ..orderBy([
          (a) => OrderingTerm.asc(a.sortOrder.isNull()),
          (a) => OrderingTerm.asc(a.sortOrder),
          (a) => OrderingTerm.asc(a.name),
        ]))
      .get();

  final accounts = await (db.select(db.accounts)
        ..where((a) =>
            a.householdId.equals(householdId) &
            a.archived.equals(false) &
            a.deleted.equals(false))
        ..orderBy([(a) => OrderingTerm.asc(a.name)]))
      .get();

  // Envelope color: its linked category (top-level first), like the app.
  final cats = await (db.select(db.categories)
        ..where((c) =>
            c.householdId.equals(householdId) & c.deleted.equals(false)))
      .get();
  final colorByAlloc = <String, String>{};
  for (final c in cats.where((c) => c.allocationId != null)) {
    if (c.parentId == null || !colorByAlloc.containsKey(c.allocationId)) {
      colorByAlloc[c.allocationId!] = c.colorHex;
    }
  }
  final catById = {for (final c in cats) c.id: c};

  final calculator = BalanceCalculator(db);
  final accountBalances = await calculator.allAccountBalances(householdId);
  final allocBalances =
      await calculator.allAllocationBalancesByCurrency(householdId);

  final period = budgetPeriodFor(household?.periodStartDay ?? 1);
  final spent = await LedgerDao(db)
      .watchSpendingInPeriod(householdId, period.start, period.end)
      .first;

  // Unallocated = account totals − envelope totals, per currency.
  final unallocated = <String, double>{};
  for (final acc in accounts) {
    unallocated[acc.currency] =
        (unallocated[acc.currency] ?? 0) + (accountBalances[acc.id] ?? 0);
  }
  for (final byCur in allocBalances.values) {
    for (final e in byCur.entries) {
      unallocated[e.key] = (unallocated[e.key] ?? 0) - e.value;
    }
  }

  return {
    'household': {
      'id': household?.id,
      'name': household?.name ?? '',
      'baseCurrency': household?.baseCurrency ?? 'USD',
      'periodStartDay': household?.periodStartDay ?? 1,
    },
    'period': {
      'start': period.start.toIso8601String(),
      'end': period.end.toIso8601String(),
    },
    'accounts': accounts
        .map((a) => accountToJson(a, accountBalances[a.id] ?? 0))
        .toList(),
    'envelopes': allocs
        .map((a) => allocationToJson(
              a,
              allocBalances[a.id] ?? const {},
              spentByCurrency: spent[a.id] ?? const {},
              colorHex: colorByAlloc[a.id] ?? catById[a.categoryId]?.colorHex,
            ))
        .toList(),
    'unallocated': unallocated,
  };
}
