import '../database/daos/ledger_dao.dart';

/// How an envelope did in one budget period.
enum EnvelopeOutcome {
  /// Ended the period at or above zero.
  held,

  /// Ended the period below zero.
  over,

  /// Nothing put in, nothing spent, nothing in it.
  idle,
}

/// One envelope's period, in one currency.
class EnvelopePeriodStat {
  final double funded;
  final double spent;

  /// Balance at the end of the period, before the next period's reset.
  final double endBalance;

  const EnvelopePeriodStat({
    required this.funded,
    required this.spent,
    required this.endBalance,
  });

  EnvelopeOutcome get outcome {
    if (endBalance < -0.005) return EnvelopeOutcome.over;
    if (funded.abs() < 0.005 && spent.abs() < 0.005 && endBalance.abs() < 0.005) {
      return EnvelopeOutcome.idle;
    }
    return EnvelopeOutcome.held;
  }
}

/// Every envelope's funding, spending and closing balance for the period
/// [start, end) in [currency] (envelopes in other currencies are left
/// out: currencies never mix). Keyed by allocation id.
Future<Map<String, EnvelopePeriodStat>> envelopePeriodStats(
  LedgerDao dao, {
  required String householdId,
  required DateTime start,
  required DateTime end,
  required String currency,
}) async {
  final funded = await dao.fundedInPeriod(householdId, start, end);
  final spent =
      await dao.watchSpendingInPeriod(householdId, start, end).first;
  final closing = await dao.balancesAt(householdId, end);
  final ids = {...funded.keys, ...spent.keys, ...closing.keys};
  return {
    for (final id in ids)
      if (funded[id]?.containsKey(currency) == true ||
          spent[id]?.containsKey(currency) == true ||
          closing[id]?.containsKey(currency) == true)
        id: EnvelopePeriodStat(
          funded: funded[id]?[currency] ?? 0,
          spent: spent[id]?[currency] ?? 0,
          endBalance: closing[id]?[currency] ?? 0,
        ),
  };
}
