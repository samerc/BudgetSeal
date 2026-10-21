import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/daos/ledger_dao.dart';
import '../engine/period_engine.dart' show budgetPeriodFor;
import 'allocations_provider.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// Ids of envelopes that are fully funded ("sealed"): a target is set and
/// - spending envelopes: what was put in this period reaches the target
///   (spending from it afterwards doesn't break the seal);
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

  final sealed = <String>{};
  for (final a in allocations) {
    final alloc = a.data.allocation;
    final target = alloc.targetAmount ?? 0;
    if (target <= 0) continue;
    final cur = alloc.targetCurrency ?? household.baseCurrency;
    final have = alloc.type == 'spending'
        ? (funded[alloc.id]?[cur] ?? 0)
        : (a.balanceByCurrency[cur] ?? 0);
    if (have >= target - 0.005) sealed.add(alloc.id);
  }
  return sealed;
});
