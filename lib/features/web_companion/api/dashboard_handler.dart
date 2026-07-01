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
                a.householdId.equals(householdId) &
                a.archived.equals(false) &
                a.deleted.equals(false))
            ..orderBy([(a) => OrderingTerm.asc(a.name)]))
          .get();

      final txs = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) & t.deleted.equals(false) & t.status.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(10))
          .get();

      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catMap = {for (final c in categories) c.id: c};
      final acctMap = {for (final a in accounts) a.id: a};

      // Batch-fetch first line per recent tx so the dashboard shows the
      // native currency/amount (tx.amount/currency is always base currency).
      final txIds = txs.map((t) => t.id).toList();
      final allLines = txIds.isNotEmpty
          ? await (db.select(db.transactionLines)
                ..where((l) => l.transactionId.isIn(txIds)))
              .get()
          : [];
      final firstLineMap = {};
      for (final l in allLines) {
        firstLineMap.putIfAbsent(l.transactionId, () => l);
      }

      final allocs = await (db.select(db.allocations)
            ..where((a) =>
                a.householdId.equals(householdId) &
                a.archived.equals(false) &
                a.deleted.equals(false))
            ..orderBy([(a) => OrderingTerm.asc(a.name)]))
          .get();

      final calculator = BalanceCalculator(db);
      final accountBalances = await calculator.allAccountBalances(householdId);
      final allocBalances =
          await calculator.allAllocationBalancesByCurrency(householdId);

      // Compute unallocated from already-fetched data instead of
      // calling unallocatedByCurrency() which re-queries both.
      final accountTotals = <String, double>{};
      for (final acc in accounts) {
        final bal = accountBalances[acc.id] ?? 0;
        accountTotals[acc.currency] =
            (accountTotals[acc.currency] ?? 0.0) + bal;
      }
      final allocTotals = <String, double>{};
      for (final allocEntry in allocBalances.values) {
        for (final entry in allocEntry.entries) {
          allocTotals[entry.key] =
              (allocTotals[entry.key] ?? 0.0) + entry.value;
        }
      }
      final unallocated = <String, double>{};
      final allCurrencies = {...accountTotals.keys, ...allocTotals.keys};
      for (final currency in allCurrencies) {
        unallocated[currency] =
            (accountTotals[currency] ?? 0.0) - (allocTotals[currency] ?? 0.0);
      }

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
        'recentTransactions': txs.map((t) {
          final json = txToJson(t, catMap, acctMap);
          final line = firstLineMap[t.id];
          if (line != null) {
            json['lineCurrency'] = line.currency;
            json['lineAmount'] = line.amount;
            json['lineExchangeRate'] = line.exchangeRateToBase;
          }
          return json;
        }).toList(),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}
