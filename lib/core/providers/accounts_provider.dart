import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../engine/balance_calculator.dart';
import 'database_provider.dart';
import 'household_provider.dart';

final accountsProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return Stream.value([]);

  return (db.select(db.accounts)
        ..where((t) =>
            t.householdId.equals(householdId) &
            t.archived.equals(false) &
            t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();
});

class AccountWithBalance {
  final Account account;
  final double balance;
  const AccountWithBalance({required this.account, required this.balance});
}

final accountsWithBalanceProvider =
    StreamProvider<List<AccountWithBalance>>((ref) {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return Stream.value(const []);

  final calculator = BalanceCalculator(db);
  final controller = StreamController<List<AccountWithBalance>>();
  List<Account>? cachedAccounts;
  var latest = 0;

  Future<void> recompute() async {
    final accounts = cachedAccounts;
    if (accounts == null) return;
    final seq = ++latest;
    // Batch: compute ALL account balances in ~7 queries total
    final balances = await calculator.allAccountBalances(householdId);
    // A newer recompute started meanwhile — let it emit instead.
    if (seq != latest || controller.isClosed) return;
    controller.add([
      for (final acc in accounts)
        AccountWithBalance(account: acc, balance: balances[acc.id] ?? 0),
    ]);
  }

  void run() => recompute().catchError(
      (Object e) => debugPrint('[accountsWithBalance] recompute error: $e'));

  final accountSub = (db.select(db.accounts)
        ..where((t) =>
            t.householdId.equals(householdId) &
            t.archived.equals(false) &
            t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch()
      .listen((accounts) {
    cachedAccounts = accounts;
    run();
  });
  // Balances move with every transaction write, not only account edits.
  final txSub = db
      .tableUpdates(TableUpdateQuery.onAllTables(
          [db.transactions, db.transactionLines]))
      .listen((_) => run());

  ref.onDispose(() {
    accountSub.cancel();
    txSub.cancel();
    controller.close();
  });
  return controller.stream;
});
