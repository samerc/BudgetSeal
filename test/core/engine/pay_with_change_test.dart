import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/fx/fx_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'h', name: 'Home', createdByDeviceId: 'a'));
    for (final (id, cur) in [('usd', 'USD'), ('lbp', 'LBP')]) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id, householdId: 'h', name: id, type: 'cash', currency: cur,
          initialBalance: const Value(100), deviceId: 'a'));
    }
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: 'env', householdId: 'h', name: 'Food', categoryId: 'food',
        deviceId: 'a'));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'food', householdId: 'h', name: 'Food',
        allocationId: const Value('env')));
  });
  tearDown(() => db.close());

  test(r'$20 for an LBP 1,350,000 bill, LBP 440,000 change at 89,500',
      () async {
    final r = await AllocationEngine(db).recordPaymentWithChange(
      householdId: 'h', payAccountId: 'usd', paid: 20,
      changeAccountId: 'lbp', change: 440000, rate: 89500,
      baseCurrency: 'USD', categoryId: 'food', note: 'Groceries');

    expect(r.spent, 15.08);
    final balances = await BalanceCalculator(db).allAccountBalances('h');
    expect(balances['usd'], closeTo(80, 1e-9));
    expect(balances['lbp'], closeTo(100 + 440000, 1e-6));
    final envelopes =
        await BalanceCalculator(db).allAllocationBalancesByCurrency('h');
    expect(envelopes['env'], {'USD': closeTo(-15.08, 1e-9)});

    final txs = await db.select(db.transactions).get();
    final expense = txs.singleWhere((t) => t.id == r.expenseId);
    final exchange = txs.singleWhere((t) => t.id == r.exchangeId);
    expect((exchange.amount, exchange.destinationAmount), (4.92, 440000.0));
    // Saved together: Related transactions pairs them.
    expect(exchange.createdAt, expense.createdAt);
    expect(exchange.note, expense.note);
    expect((await rateGot(db, 'USD', 'LBP'))!.rate, 89500);
  });

  test('no change is a plain expense; change worth it all is refused',
      () async {
    final engine = AllocationEngine(db);
    final r = await engine.recordPaymentWithChange(
      householdId: 'h', payAccountId: 'usd', paid: 20,
      changeAccountId: 'lbp', change: 0, rate: 89500, baseCurrency: 'USD');
    expect((r.spent, r.exchangeId), (20.0, null));
    expect(
        () => engine.recordPaymentWithChange(
            householdId: 'h', payAccountId: 'usd', paid: 20,
            changeAccountId: 'lbp', change: 1790000, rate: 89500,
            baseCurrency: 'USD'),
        throwsArgumentError);
  });
}
