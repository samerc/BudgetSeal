import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/daos/ledger_dao.dart';
import '../engine/period_engine.dart' show budgetPeriodFor;
import 'allocations_provider.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// Ids of envelopes that are fully funded ("sealed"): a target is set, the
/// envelope isn't below zero, and
/// - spending envelopes: what was put in this period reaches the target
///   (spending from it afterwards keeps the seal, overspending breaks it);
/// - flexible envelopes: the balance reaches the target.
/// Amounts in the envelope's target currency. Recomputed whenever the
/// envelopes or their ledger change.
final sealedEnvelopesProvider = FutureProvider<Set<String>>((ref) async {
  final allocations = await ref.watch(allocationsProvider.future);
  final household = ref.watch(householdProvider).value;
  if (household == null) return const {};
  final period = budgetPeriodFor(household.periodStartDay);
  final funded = await LedgerDao(ref.read(databaseProvider))
      .fundedInPeriod(household.id, period.start, period.end);

  return {
    for (final a in allocations)
      if (isEnvelopeSealed(a.data.allocation, a.balanceByCurrency,
          funded[a.data.allocation.id], household.baseCurrency))
        a.data.allocation.id,
  };
});

/// The seal rule, shared with the Web Companion: [funded] is what went into
/// the envelope this period (`LedgerDao.fundedInPeriod`) by currency.
bool isEnvelopeSealed(Allocation alloc, Map<String, double> balances,
    Map<String, double>? funded, String baseCurrency) {
  final target = alloc.targetAmount ?? 0;
  if (target <= 0) return false;
  final cur = alloc.targetCurrency ?? baseCurrency;
  if ((balances[cur] ?? 0) < -0.005) return false;
  final have = alloc.type == 'spending'
      ? (funded?[cur] ?? 0)
      : (balances[cur] ?? 0);
  return have >= target - 0.005;
}
