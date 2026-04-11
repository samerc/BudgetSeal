import 'package:drift/drift.dart';
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
            t.householdId.equals(householdId) & t.archived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();
});

class AccountWithBalance {
  final Account account;
  final double balance;
  const AccountWithBalance({required this.account, required this.balance});
}

final accountsWithBalanceProvider =
    StreamProvider<List<AccountWithBalance>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) {
    yield [];
    return;
  }

  final calculator = BalanceCalculator(db);
  final accountStream = (db.select(db.accounts)
        ..where((t) =>
            t.householdId.equals(householdId) & t.archived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();

  await for (final accounts in accountStream) {
    final result = <AccountWithBalance>[];
    for (final acc in accounts) {
      final balance = await calculator.accountBalance(acc.id);
      result.add(AccountWithBalance(account: acc, balance: balance));
    }
    yield result;
  }
});
