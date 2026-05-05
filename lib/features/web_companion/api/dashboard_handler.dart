import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';

import '../../../core/engine/balance_calculator.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_serializers.dart';
import '_validation.dart';

Handler dashboardHandler(Ref ref) {
  return (Request request) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      final household = await (db.select(db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();

      final accounts = await (db.select(db.accounts)
            ..where((a) =>
                a.householdId.equals(householdId) & a.archived.equals(false))
            ..orderBy([(a) => OrderingTerm.asc(a.name)]))
          .get();

      final txs = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) & t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(10))
          .get();

      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catMap = {for (final c in categories) c.id: c};
      final acctMap = {for (final a in accounts) a.id: a};

      final allocs = await (db.select(db.allocations)
            ..where((a) =>
                a.householdId.equals(householdId) & a.archived.equals(false))
            ..orderBy([(a) => OrderingTerm.asc(a.name)]))
          .get();

      final calculator = BalanceCalculator(db);
      final accountBalances = await calculator.allAccountBalances(householdId);
      final allocBalances =
          await calculator.allAllocationBalancesByCurrency(householdId);
      final unallocated = await calculator.unallocatedByCurrency(householdId);

      return ok({
        'household': {
          'id': household?.id,
          'name': household?.name ?? '',
          'baseCurrency': household?.baseCurrency ?? 'USD',
          'periodStartDay': household?.periodStartDay ?? 1,
        },
        'accounts': accounts
            .map((a) => accountToJson(a, accountBalances[a.id] ?? 0.0))
            .toList(),
        'envelopes': allocs
            .map((a) => allocationToJson(a, allocBalances[a.id] ?? {}))
            .toList(),
        'unallocated': unallocated,
        'recentTransactions':
            txs.map((t) => txToJson(t, catMap, acctMap)).toList(),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}
