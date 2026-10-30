import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/note_text.dart';
import '../engine/forecast.dart';
import 'accounts_provider.dart';
import 'allocations_provider.dart';
import 'database_provider.dart';
import 'household_provider.dart';
import 'sinking_fund_provider.dart';

/// The 90-day forecast per currency (roadmap #4), from what's in the
/// accounts, recurring bills and incomes, planned payments, sinking funds
/// and — for the income estimate — the last three months' incomes.
final forecastProvider =
    FutureProvider<Map<String, CurrencyForecast>>((ref) async {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return const {};

  final cash = <String, double>{};
  for (final a in await ref.watch(accountsWithBalanceProvider.future)) {
    if (a.account.archived) continue;
    cash[a.account.currency] = (cash[a.account.currency] ?? 0) + a.balance;
  }

  final recurring = await (db.select(db.recurringTransactions)
        ..where((r) =>
            r.householdId.equals(householdId) & r.deleted.equals(false)))
      .get();

  final planned = <PlannedPart>[];
  for (final r in await db.customSelect(
    'SELECT t.created_at AS at, t.note, t.type, l.amount, l.currency '
    'FROM transactions t JOIN transaction_lines l ON l.transaction_id = t.id '
    "WHERE t.household_id = ? AND t.deleted = 0 AND t.status = 'planned' "
    "AND t.type <> 'transfer'",
    variables: [Variable.withString(householdId)],
  ).get()) {
    planned.add(PlannedPart(
      DateTime.fromMillisecondsSinceEpoch(r.read<int>('at') * 1000),
      visibleNote(r.read<String>('note')).split(' — ').first.trim(),
      r.read<String>('type'),
      r.read<double>('amount'),
      r.read<String>('currency'),
    ));
  }

  final funds = [
    for (final f in (await ref.watch(sinkingFundsProvider.future)).values)
      ForecastFund(f.balances, f.thisPeriod, f.plan.upcoming),
  ];

  // Savings envelopes' money has a goal: not safe to spend.
  final savings = <String, double>{};
  for (final a in await ref.watch(allocationsProvider.future)) {
    final env = a.data.allocation;
    if (env.type != 'saving' || env.archived) continue;
    a.balanceByCurrency.forEach((c, v) {
      if (v > 0) savings[c] = (savings[c] ?? 0) + v;
    });
  }

  final since = DateTime.now().subtract(const Duration(days: 92));
  final pastIncome = [
    for (final r in await db.customSelect(
      'SELECT t.created_at AS at, l.amount, l.currency '
      'FROM transactions t JOIN transaction_lines l ON l.transaction_id = t.id '
      "WHERE t.household_id = ? AND t.deleted = 0 AND t.status IS NULL "
      "AND t.type = 'income' AND t.created_at >= ?",
      variables: [
        Variable.withString(householdId),
        Variable<DateTime>(since),
      ],
    ).get())
      PastIncome(DateTime.fromMillisecondsSinceEpoch(r.read<int>('at') * 1000),
          r.read<double>('amount'), r.read<String>('currency')),
  ];

  return buildForecast(
    now: DateTime.now(),
    cash: cash,
    recurring: recurring,
    planned: planned,
    funds: funds,
    savings: savings,
    pastIncome: pastIncome,
  );
});
