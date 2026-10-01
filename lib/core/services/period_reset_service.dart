import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/s_lookup.dart';
import 'package:drift/drift.dart' show InsertMode, Value;

import '../database/app_database.dart';
import '../database/daos/ledger_dao.dart';
import '../engine/period_engine.dart' show budgetPeriodFor;

const _lastResetKey = 'period_last_reset';

/// Handles automatic period resets for envelopes.
///
/// On app launch, checks if the current period has changed since the last
/// reset. For envelopes with `autoReset = true` and `periodicity = 'periodic'`,
/// automatically resolves leftovers (return to unallocated or roll over).
class PeriodResetService {
  /// Check if a period reset is needed and perform auto-resets.
  /// Returns the number of envelopes still needing manual review.
  static Future<int> checkAndAutoReset(AppDatabase db, String householdId,
      int periodStartDay) async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString(_lastResetKey);
    final now = DateTime.now();

    // Determine current period start (clamped: day 31 → Feb 28/29)
    final currentPeriodStart = budgetPeriodFor(periodStartDay, now).start;

    // First run on this install (new user, reinstall, cleared data): there is
    // no "previous period" here to close — resetting now would empty
    // envelopes mid-period. Just remember the period.
    if (lastResetStr == null) {
      await prefs.setString(
          _lastResetKey, currentPeriodStart.toIso8601String());
      return _countPendingManual(db, householdId);
    }

    // Check if we already reset for this period
    final lastReset = DateTime.tryParse(lastResetStr);
    if (lastReset != null && !lastReset.isBefore(currentPeriodStart)) {
      // Already reset for this period — just count pending manual ones
      return _countPendingManual(db, householdId);
    }

    // New period — perform auto-resets
    final ledgerDao = LedgerDao(db);
    final allocs = await (db.select(db.allocations)
          ..where((a) => a.householdId.equals(householdId))
          ..where((a) => a.archived.equals(false))
          ..where((a) => a.deleted.equals(false))
          ..where((a) => a.periodicity.equals('periodic')))
        .get();

    // Batch-fetch all balances in one query instead of per-allocation
    final allocIds = allocs.map((a) => a.id).toList();
    final allBalances = await ledgerDao.getAllBalances(allocIds);

    int autoResetCount = 0;
    for (final alloc in allocs) {
      if (!alloc.autoReset) continue; // manual — skip

      final balances = allBalances[alloc.id] ?? {};
      for (final entry in balances.entries) {
        final balance = entry.value;
        if (balance.abs() < 0.01) continue;

        if (alloc.rollover) {
          // Rollover — do nothing, balance carries forward
          debugPrint('[PeriodReset] Rolling over ${entry.key} balance');
        } else {
          // Return leftover to unallocated
          if (balance > 0) {
            // Deterministic id: if another synced device (or a re-run)
            // already reset this envelope for this period, the row exists
            // and the insert is ignored instead of resetting twice.
            final day = currentPeriodStart.toIso8601String().substring(0, 10);
            await db.into(db.allocationLedger).insert(
                AllocationLedgerCompanion.insert(
              id: 'reset:${alloc.id}:$day:${entry.key}',
              allocationId: alloc.id,
              entryType: 'period_reset',
              amount: -balance,
              currency: entry.key,
              note: Value(currentS().engineAutoReset),
              deviceId: 'period-reset',
            ), mode: InsertMode.insertOrIgnore);
            debugPrint('[PeriodReset] Reset ${entry.key} balance to unallocated');
          }
        }
      }
      autoResetCount++;
    }

    // Mark this period as reset
    await prefs.setString(_lastResetKey, currentPeriodStart.toIso8601String());

    debugPrint('[PeriodReset] Auto-reset $autoResetCount envelopes');

    return _countPendingManual(db, householdId);
  }

  /// Count periodic envelopes with manual reset that have non-zero balances.
  static Future<int> _countPendingManual(
      AppDatabase db, String householdId) async {
    final ledgerDao = LedgerDao(db);
    final allocs = await (db.select(db.allocations)
          ..where((a) => a.householdId.equals(householdId))
          ..where((a) => a.archived.equals(false))
          ..where((a) => a.deleted.equals(false))
          ..where((a) => a.periodicity.equals('periodic'))
          ..where((a) => a.autoReset.equals(false)))
        .get();

    if (allocs.isEmpty) return 0;
    final allBalances = await ledgerDao.getAllBalances(
        allocs.map((a) => a.id).toList());

    int pending = 0;
    for (final alloc in allocs) {
      final balances = allBalances[alloc.id] ?? {};
      if (balances.values.any((v) => v.abs() > 0.01)) pending++;
    }
    return pending;
  }

  /// Get the list of envelope IDs that need manual reset.
  static Future<List<String>> getPendingManualIds(
      AppDatabase db, String householdId) async {
    final ledgerDao = LedgerDao(db);
    final allocs = await (db.select(db.allocations)
          ..where((a) => a.householdId.equals(householdId))
          ..where((a) => a.archived.equals(false))
          ..where((a) => a.deleted.equals(false))
          ..where((a) => a.periodicity.equals('periodic'))
          ..where((a) => a.autoReset.equals(false)))
        .get();

    if (allocs.isEmpty) return [];
    final allBalances = await ledgerDao.getAllBalances(
        allocs.map((a) => a.id).toList());

    return [
      for (final alloc in allocs)
        if ((allBalances[alloc.id] ?? {}).values.any((v) => v.abs() > 0.01))
          alloc.id,
    ];
  }
}
