import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/engine/base_currency_change.dart';
import 'package:budgetseal/shared/utils/format_number.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Switching the base from USD to EUR at 1 USD = 0.9 EUR converts what is
/// stored relative to the base, and leaves account balances alone.
void main() {
  late AppDatabase db;
  late AllocationEngine engine;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = AllocationEngine(db);
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'hh', name: 'Home', createdByDeviceId: 'd'));
    for (final (id, cur) in [('usd', 'USD'), ('eur', 'EUR'), ('lbp', 'LBP')]) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id,
          householdId: 'hh',
          name: id,
          type: 'cash',
          currency: cur,
          deviceId: 'd'));
    }
  });

  tearDown(() => db.close());

  Future<String> spend(String account, double amount, String cur, double rate) =>
      engine.recordTransaction(
        householdId: 'hh',
        accountId: account,
        type: 'expense',
        lines: [
          TxLine(
              amount: amount,
              currency: cur,
              accountId: account,
              exchangeRateToBase: rate),
        ],
        baseCurrency: 'USD',
      );

  Future<(Transaction, TransactionLine)> row(String id) async {
    final tx = await db.transactionsDao.getById(id);
    final line = await (db.select(db.transactionLines)
          ..where((l) => l.transactionId.equals(id)))
        .getSingle();
    return (tx!, line);
  }

  test('converts totals and rates, keeps balances', () async {
    final inUsd = await spend('usd', 10, 'USD', 1.0);
    final inEur = await spend('eur', 20, 'EUR', 1.1);
    final inLbp = await spend('lbp', 90000, 'LBP', 1 / 90000);
    final noRate = await spend('lbp', 50000, 'LBP', 1.0);
    final transfer = await engine.recordTransfer(
        householdId: 'hh',
        fromAccountId: 'usd',
        toAccountId: 'eur',
        amount: 100,
        currency: 'USD',
        exchangeRateToBase: 0.92,
        createdBy: 'user',
        deviceId: 'd');
    final balances = BalanceCalculator(db);
    final before = await balances.allAccountBalances('hh');

    await changeBaseCurrency(db, 'hh', 'USD', 'EUR', 0.9);

    expect((await balances.allAccountBalances('hh')), before);
    final hh = await db.select(db.households).getSingle();
    expect(hh.baseCurrency, 'EUR');

    var (tx, line) = await row(inUsd);
    expect(line.exchangeRateToBase, 0.9);
    expect(tx.amount, closeTo(9, 1e-9));
    expect(tx.currency, 'EUR');

    (tx, line) = await row(inEur);
    expect(line.exchangeRateToBase, 1.0);
    expect((tx.amount, tx.currency), (20, 'EUR'));

    (tx, line) = await row(inLbp);
    expect(line.exchangeRateToBase, closeTo(0.9 / 90000, 1e-12));
    expect(tx.amount, closeTo(0.9, 1e-9));

    (tx, line) = await row(noRate);
    expect(isRealRate(line.currency, 'EUR', line.exchangeRateToBase), isFalse);
    expect(tx.amount, 0);

    final t = await db.transactionsDao.getById(transfer);
    expect((t!.amount, t.currency, t.exchangeRateToBase), (100, 'USD', 0.92));
  });

  test('a rate landing on 1.0 is kept as a real rate', () {
    final r = convertedRateToBase('GBP', 1.25, 'USD', 'EUR', 0.8);
    expect(isRealRate('GBP', 'EUR', r), isTrue);
    expect(r, closeTo(1.0, 0.0012));
  });
}
