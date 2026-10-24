import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/ledger_dao.dart';
import '../../../core/engine/balance_calculator.dart';
import '../../../core/engine/period_engine.dart';
import '../../../core/engine/sinking_fund.dart';
import '../../../core/providers/seal_provider.dart' show isEnvelopeSealed;
import '../../../core/providers/sinking_fund_provider.dart';
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
  final funded =
      await LedgerDao(db).fundedInPeriod(householdId, period.start, period.end);
  final base = household?.baseCurrency ?? 'USD';

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

  // Sinking funds: schedule and plan, as on the phone's fund screen.
  final sinking = allocs.where((a) => a.type == 'sinking').toList();
  final funds = sinking.isEmpty
      ? const <String, SinkingFund>{}
      : await loadSinkingFunds(db,
          householdId: householdId,
          funds: {for (final a in sinking) a: allocBalances[a.id] ?? const {}},
          liveAllocations: allocs,
          categories: cats,
          startDay: household?.periodStartDay ?? 1);

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
        .map((a) => {
              ...allocationToJson(
                a,
                allocBalances[a.id] ?? const {},
                spentByCurrency: spent[a.id] ?? const {},
                colorHex:
                    colorByAlloc[a.id] ?? catById[a.categoryId]?.colorHex,
              ),
              // Fully funded: the app's wax seal.
              'sealed': isEnvelopeSealed(
                  a, allocBalances[a.id] ?? const {}, funded[a.id], base),
              if (funds[a.id] case final f?)
                'fund': fundToJson(f,
                    cats.where((c) => c.allocationId == a.id).firstOrNull?.id),
            })
        .toList(),
    'unallocated': unallocated,
  };
}

Map<String, dynamic> _payment(FundPayment p) => {
      'title': p.title,
      'date': p.date.toIso8601String(),
      'amounts': p.amounts,
      'paid': p.paid,
      'planId': p.planId,
      'recurringId': p.recurringId,
    };

/// A sinking fund for the Web Companion: what this month takes (by its
/// catch-up setting), how far behind, the monthly plan, the payments (paid
/// in the past year, then ahead) and the "Copy from last year" candidates.
Map<String, dynamic> fundToJson(SinkingFund f, String? categoryId) {
  final plan = f.plan;
  final next = plan.next;
  final topUpSteps = plan.steps(BehindMode.topUp);
  return {
    'categoryId': categoryId,
    'mode': f.allocation.behindMode ?? 'ask',
    'mustChoose': f.mustChoose,
    'behind': plan.behind,
    'thisMonth': f.thisPeriod,
    'spreadNow': plan.remaining(BehindMode.spread),
    'topUpNow': plan.remaining(BehindMode.topUp),
    'steady': topUpSteps.length > 1 ? topUpSteps[1].amounts : const {},
    if (next != null)
      'next': {
        ..._payment(next),
        'saved': savedToward(next, f.balances),
      },
    'steps': [
      for (final s in plan.steps(
          f.mode == BehindMode.topUp ? BehindMode.topUp : BehindMode.spread))
        {
          'from': s.from.toIso8601String(),
          'to': s.to.toIso8601String(),
          'amounts': s.amounts,
        },
    ],
    'payments': [
      for (final p in f.paid.reversed) _payment(p),
      for (final p in plan.upcoming) _payment(p),
    ],
    'copy': [
      for (final c in copyFromLastYear(f.history))
        {..._payment(c.payment), 'alreadyPlanned': c.alreadyPlanned,
          'accountIds': c.payment.accountIds},
    ],
  };
}
