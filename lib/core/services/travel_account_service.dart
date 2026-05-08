import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../shared/utils/format_number.dart';
import '../database/app_database.dart';
import '../engine/balance_calculator.dart';

/// Checks travel accounts and auto-archives any with zero balance.
/// Call after transaction mutations that might affect travel accounts.
/// Returns true if any account was archived.
class TravelAccountService {
  static Future<bool> checkAndAutoArchive(AppDatabase db, String householdId) async {
    try {
      // Find active travel accounts
      final travelAccounts = await (db.select(db.accounts)
            ..where((a) => a.householdId.equals(householdId))
            ..where((a) => a.isTravel.equals(true))
            ..where((a) => a.archived.equals(false)))
          .get();

      if (travelAccounts.isEmpty) return false;

      final calculator = BalanceCalculator(db);
      final balances = await calculator.allAccountBalances(householdId);
      bool archived = false;

      for (final acc in travelAccounts) {
        final balance = balances[acc.id] ?? 0.0;
        // Currency-aware threshold: 0.5 for JPY (0 decimals), 0.005 for USD (2), 0.0005 for KWD (3)
        final decimals = currencyDecimals(acc.currency);
        final threshold = 0.5 / pow(10, decimals);
        if (balance.abs() < threshold) {
          await (db.update(db.accounts)
                ..where((a) => a.id.equals(acc.id)))
              .write(AccountsCompanion(
            archived: const Value(true),
            lastModified: Value(DateTime.now()),
          ));
          debugPrint('[Travel] Auto-archived "${acc.name}" (balance: $balance)');
          archived = true;
        }
      }
      return archived;
    } catch (e) {
      debugPrint('[Travel] Error checking auto-archive: $e');
      return false;
    }
  }
}
