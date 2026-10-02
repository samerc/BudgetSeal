import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../l10n/s_lookup.dart';
import '../database/app_database.dart';
import '../database/daos/allocations_dao.dart';
import '../database/daos/ledger_dao.dart';

/// The budget period containing [now]: from day [startDay] of a month to the
/// same day of the next, clamped to short months (31 → Feb 28/29).
({DateTime start, DateTime end}) budgetPeriodFor(int startDay,
    [DateTime? now]) {
  DateTime clampedStart(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, startDay.clamp(1, daysInMonth));
  }

  now ??= DateTime.now();
  var start = clampedStart(now.year, now.month);
  if (now.isBefore(start)) start = clampedStart(now.year, now.month - 1);
  final end = clampedStart(start.year, start.month + 1);
  return (start: start, end: end);
}

enum LeftoverResolution { toUnallocated, toOtherAllocation, keep }

class FundingSuggestion {
  final String allocationId;
  final String allocationName;
  final Map<String, double> amountByCurrency;

  const FundingSuggestion({
    required this.allocationId,
    required this.allocationName,
    required this.amountByCurrency,
  });
}

/// Manages financial period transitions.
///
/// Period definition: start day N → period runs day N to day N-1 of next month.
/// e.g. start day 25 → period is 25th to 24th of next month.
class PeriodEngine {
  final LedgerDao _ledgerDao;
  final AllocationsDao _allocationsDao;
  final _uuid = const Uuid();

  PeriodEngine(AppDatabase db)
      : _ledgerDao = LedgerDao(db),
        _allocationsDao = AllocationsDao(db);

  /// Returns true if today >= periodStartDay and a new period should begin.
  bool isNewPeriodDue(int periodStartDay, DateTime? lastPeriodStarted) {
    final now = DateTime.now();
    final todayDay = now.day;

    if (lastPeriodStarted == null) return true;

    // Determine if we've crossed into a new period cycle
    final lastPeriodMonth = lastPeriodStarted.month;
    final lastPeriodYear = lastPeriodStarted.year;
    final currentMonth = now.month;
    final currentYear = now.year;

    if (currentYear > lastPeriodYear) return true;
    if (currentYear == lastPeriodYear && currentMonth > lastPeriodMonth) {
      return todayDay >= periodStartDay;
    }
    return false;
  }

  /// Generate funding suggestions based on last period's funding amounts.
  Future<List<FundingSuggestion>> generateFundingSuggestions(
      String householdId) async {
    final allocs = await _allocationsDao.watchAll(householdId).first;
    final periodicAllocs = allocs
        .where((awc) => awc.allocation.periodicity != 'permanent')
        .toList();
    if (periodicAllocs.isEmpty) return [];

    // Batch-fetch all balances in one query
    final allBalances = await _ledgerDao.getAllBalances(
        periodicAllocs.map((a) => a.allocation.id).toList());

    final suggestions = <FundingSuggestion>[];
    for (final awc in periodicAllocs) {
      final ledger = allBalances[awc.allocation.id] ?? {};
      final fundingAmounts = <String, double>{};

      // Use current balance as funding suggestion baseline
      for (final entry in ledger.entries) {
        if (entry.value > 0) {
          fundingAmounts[entry.key] = entry.value;
        }
      }

      suggestions.add(FundingSuggestion(
        allocationId: awc.allocation.id,
        allocationName: awc.allocation.name,
        amountByCurrency: fundingAmounts,
      ));
    }
    return suggestions;
  }

  /// Resolve leftover balance for a periodic allocation at period end.
  Future<void> resolveLeftover({
    required String allocationId,
    required String currency,
    required double leftoverAmount,
    required LeftoverResolution resolution,
    required String deviceId,
    String? targetAllocationId,
  }) async {
    if (leftoverAmount.abs() < 0.005) return;

    // An overspent envelope (negative leftover): Ready to assign covers it,
    // or the debt carries into the new period.
    if (leftoverAmount < 0) {
      await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
        id: _uuid.v4(),
        allocationId: allocationId,
        entryType: resolution == LeftoverResolution.toUnallocated
            ? 'funding'
            : 'carry_forward',
        amount: resolution == LeftoverResolution.toUnallocated
            ? -leftoverAmount
            : 0,
        currency: currency,
        note: Value(resolution == LeftoverResolution.toUnallocated
            ? currentS().enginePeriodCovered
            : currentS().engineCarryForward),
        deviceId: deviceId,
      ));
      return;
    }

    switch (resolution) {
      case LeftoverResolution.toUnallocated:
        // Debit from allocation → returns to Unallocated pool automatically
        await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
          id: _uuid.v4(),
          allocationId: allocationId,
          entryType: 'period_reset',
          amount: -leftoverAmount,
          currency: currency,
          note: Value(currentS().enginePeriodReturned),
          deviceId: deviceId,
        ));

      case LeftoverResolution.toOtherAllocation:
        if (targetAllocationId == null) return;
        // Debit source
        await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
          id: _uuid.v4(),
          allocationId: allocationId,
          entryType: 'period_reset',
          amount: -leftoverAmount,
          currency: currency,
          note: Value(currentS().enginePeriodOut),
          deviceId: deviceId,
        ));
        // Credit target
        await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
          id: _uuid.v4(),
          allocationId: targetAllocationId,
          entryType: 'funding',
          amount: leftoverAmount,
          currency: currency,
          note: Value(currentS().enginePeriodReceived),
          deviceId: deviceId,
        ));

      case LeftoverResolution.keep:
        // Write carry_forward entry for audit trail
        await _ledgerDao.appendEntry(AllocationLedgerCompanion.insert(
          id: _uuid.v4(),
          allocationId: allocationId,
          entryType: 'carry_forward',
          amount: 0, // balance unchanged, just a marker
          currency: currency,
          note: Value(currentS().engineCarryForward),
          deviceId: deviceId,
        ));
    }
  }
}
