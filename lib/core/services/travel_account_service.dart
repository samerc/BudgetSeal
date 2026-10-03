import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';

import '../../shared/utils/format_number.dart';
import '../database/app_database.dart';
import '../engine/allocation_engine.dart';
import '../engine/balance_calculator.dart';

/// Convert back was asked for an amount that is no longer the wallet's
/// balance (it changed after the sheet opened: a sync, a web edit).
class TravelBalanceChangedException implements Exception {
  final double balance;
  const TravelBalanceChangedException(this.balance);

  @override
  String toString() => 'TravelBalanceChangedException: now $balance';
}

/// Checks travel accounts and auto-archives any with zero balance.
/// Call after transaction mutations that might affect travel accounts.
/// Returns true if any account was archived.
class TravelAccountService {
  /// Below half a unit of the currency's last decimal a balance is zero
  /// (0.005 for USD, 0.5 for JPY, 0.0005 for KWD).
  static double zeroThreshold(String currency) =>
      0.5 / pow(10, currencyDecimals(currency));

  /// The travel wallet to use for [currency]: the active one (a top-up
  /// mid-trip), else null. Newest first if there are several.
  static Future<Account?> activeWallet(
          AppDatabase db, String householdId, String currency) =>
      _wallet(db, householdId, currency, archived: false);

  /// The most recent archived wallet in [currency], offered for
  /// reactivation. (There can be several: "Create new" leaves the old one.)
  static Future<Account?> archivedWallet(
          AppDatabase db, String householdId, String currency) =>
      _wallet(db, householdId, currency, archived: true);

  static Future<Account?> _wallet(
          AppDatabase db, String householdId, String currency,
          {required bool archived}) =>
      (db.select(db.accounts)
            ..where((a) =>
                a.householdId.equals(householdId) &
                a.isTravel.equals(true) &
                a.currency.equals(currency) &
                a.archived.equals(archived) &
                // A deleted wallet must not come back via "Reactivate".
                a.deleted.equals(false))
            ..orderBy([(a) => OrderingTerm.desc(a.lastModified)])
            ..limit(1))
          .getSingleOrNull();

  /// Exchange [amount] from [fromAccountId] into a travel wallet holding
  /// [received] of [toCurrency]: into [walletId] (an active wallet, or an
  /// archived one that is unarchived), or a new wallet named [newWalletName].
  /// One db transaction. Returns the wallet id.
  static Future<String> exchange(
    AppDatabase db, {
    required String householdId,
    required String fromAccountId,
    required String fromCurrency,
    required double amount,
    required String toCurrency,
    required double received,
    String? walletId,
    required String newWalletName,
    required String note,
  }) async {
    if (amount <= 0 || received <= 0) {
      throw ArgumentError('amounts must be positive');
    }
    return db.transaction(() async {
      final now = DateTime.now();
      final String id;
      if (walletId != null) {
        id = walletId;
        await (db.update(db.accounts)..where((a) => a.id.equals(id)))
            .write(AccountsCompanion(
                archived: const Value(false), lastModified: Value(now)));
      } else {
        id = const Uuid().v4();
        await db.into(db.accounts).insert(AccountsCompanion.insert(
              id: id,
              householdId: householdId,
              name: newWalletName,
              type: 'wallet',
              currency: toCurrency,
              deviceId: 'local',
              isTravel: const Value(true),
              decimalPlaces: Value(currencyDecimals(toCurrency)),
            ));
      }
      await AllocationEngine(db).recordTransfer(
        householdId: householdId,
        fromAccountId: fromAccountId,
        toAccountId: id,
        amount: amount,
        currency: fromCurrency,
        // Source → destination, as every transfer stores it.
        exchangeRateToBase: received / amount,
        createdBy: 'local',
        deviceId: 'local',
        note: note,
        date: now,
      );
      return id;
    });
  }

  /// Convert back & close: move the wallet's whole balance to
  /// [toAccountId] ([received] in that account's currency) and archive the
  /// wallet, in one db transaction. The balance is read inside it; if it is
  /// no longer [expectedBalance] nothing happens and
  /// [TravelBalanceChangedException] is thrown (the rate the user typed was
  /// for the old amount) — archiving a wallet with money left would drop that
  /// money out of every balance.
  static Future<void> convertBack(
    AppDatabase db, {
    required String householdId,
    required String walletId,
    required double expectedBalance,
    required String toAccountId,
    required double received,
    required String note,
  }) async {
    if (received <= 0) throw ArgumentError('received must be positive');
    await db.transaction(() async {
      final wallet = await (db.select(db.accounts)
            ..where((a) => a.id.equals(walletId)))
          .getSingle();
      final balance = await BalanceCalculator(db).accountBalance(walletId);
      if ((balance - expectedBalance).abs() >= zeroThreshold(wallet.currency) ||
          balance <= 0) {
        throw TravelBalanceChangedException(balance);
      }
      await AllocationEngine(db).recordTransfer(
        householdId: householdId,
        fromAccountId: walletId,
        toAccountId: toAccountId,
        amount: balance,
        currency: wallet.currency,
        exchangeRateToBase: received / balance,
        createdBy: 'local',
        deviceId: 'local',
        note: note,
        date: DateTime.now(),
      );
      await (db.update(db.accounts)..where((a) => a.id.equals(walletId)))
          .write(AccountsCompanion(
              archived: const Value(true), lastModified: Value(DateTime.now())));
    });
  }

  static Future<bool> checkAndAutoArchive(AppDatabase db, String householdId) async {
    try {
      // Find active travel accounts
      final travelAccounts = await (db.select(db.accounts)
            ..where((a) => a.householdId.equals(householdId))
            ..where((a) => a.isTravel.equals(true))
            ..where((a) => a.archived.equals(false))
            ..where((a) => a.deleted.equals(false)))
          .get();

      if (travelAccounts.isEmpty) return false;

      final calculator = BalanceCalculator(db);
      final balances = await calculator.allAccountBalances(householdId);
      bool archived = false;

      for (final acc in travelAccounts) {
        final balance = balances[acc.id] ?? 0.0;
        if (balance.abs() < zeroThreshold(acc.currency)) {
          await (db.update(db.accounts)
                ..where((a) => a.id.equals(acc.id)))
              .write(AccountsCompanion(
            archived: const Value(true),
            lastModified: Value(DateTime.now()),
          ));
          debugPrint('[Travel] Auto-archived travel wallet');
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
