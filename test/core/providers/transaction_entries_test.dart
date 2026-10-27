import 'dart:async';

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/core/providers/transactions_provider.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The history reuses the lines of rows that didn't change between saves;
/// what changed must still show as it is now.
void main() {
  late AppDatabase db;
  late ProviderContainer c;
  late List<List<TransactionEntry>> emitted;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    c.read(currentHouseholdIdProvider.notifier).set('h');
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'h', name: 'Home', createdByDeviceId: 't'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'bank', householdId: 'h', name: 'Bank', type: 'bank',
        currency: 'USD', initialBalance: const Value(100), deviceId: 't'));
    emitted = [];
    c.listen(transactionEntriesProvider, (_, next) {
      if (next.hasValue) emitted.add(next.value!);
    });
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<List<TransactionEntry>> after(Future<void> Function() change) async {
    final n = emitted.length;
    await change();
    for (var i = 0; i < 100 && emitted.length == n; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    // Let a burst of writes settle into its last emission.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return emitted.last;
  }

  test('new, edited and deleted rows show as they are now; balances follow',
      () async {
    final e = AllocationEngine(db);
    late String coffee;
    var list = await after(() async {
      coffee = await e.recordTransaction(
          householdId: 'h', accountId: 'bank', type: 'expense',
          lines: const [TxLine(amount: 4, currency: 'USD')],
          baseCurrency: 'USD', note: 'Coffee');
    });
    expect(list.single.lines.single.amount, 4);

    list = await after(() => e.recordTransaction(
        householdId: 'h', accountId: 'bank', type: 'expense',
        lines: const [TxLine(amount: 10, currency: 'USD')],
        baseCurrency: 'USD', note: 'Lunch',
        date: DateTime.now().add(const Duration(minutes: 1))));
    expect([for (final x in list) x.tx.note], ['Lunch', 'Coffee']);
    expect(list.first.accountBalanceAfter, 86);

    // Edited in place: new lines (the row changed with them).
    list = await after(() => e.recordTransaction(
        editing: coffee, householdId: 'h', accountId: 'bank',
        type: 'expense',
        lines: const [
          TxLine(amount: 3, currency: 'USD'),
          TxLine(amount: 2, currency: 'USD'),
        ],
        baseCurrency: 'USD', note: 'Coffee and cake'));
    final edited = list.singleWhere((x) => x.tx.id == coffee);
    expect([for (final l in edited.lines) l.amount]..sort(), [2.0, 3.0]);
    expect(list.first.accountBalanceAfter, 85);

    list = await after(() => e.deleteTransaction(coffee));
    expect([for (final x in list) x.tx.note], ['Lunch']);
    expect(list.single.accountBalanceAfter, 90);
  });
}
