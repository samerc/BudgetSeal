import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A bill paid at the rate on the receipt (90,000) must be recorded at that
/// rate, not at the app's saved one (89,500).
void main() {
  late AppDatabase db;
  late AllocationEngine engine;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = AllocationEngine(db);
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'hh', name: 'Home', createdByDeviceId: 'd'));
    for (final (id, cur) in [('usd', 'USD'), ('lbp', 'LBP')]) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id,
          householdId: 'hh',
          name: id,
          type: 'cash',
          currency: cur,
          deviceId: 'd'));
    }
    await db.into(db.fxRates).insert(FxRatesCompanion.insert(
        id: 'r1',
        fromCurrency: 'USD',
        toCurrency: 'LBP',
        rate: 89500,
        fetchedAt: Value(DateTime.now())));
  });

  tearDown(() => db.close());

  Future<(Transaction, List<TransactionLine>)> pay(String account) async {
    final id = await engine.recordTransaction(
      householdId: 'hh',
      accountId: account,
      type: 'expense',
      lines: [
        TxLine(
            amount: 4850000,
            currency: 'LBP',
            accountId: account,
            exchangeRateToBase: 1 / 90000),
      ],
      baseCurrency: 'USD',
    );
    final tx = await db.transactionsDao.getById(id);
    final lines = await (db.select(db.transactionLines)
          ..where((l) => l.transactionId.equals(id)))
        .get();
    return (tx!, lines);
  }

  test('from an LBP account: the line keeps the bill rate', () async {
    final (tx, lines) = await pay('lbp');
    expect(lines.single.amount, 4850000);
    expect(1 / lines.single.exchangeRateToBase, closeTo(90000, 0.01));
    expect(tx.amount, closeTo(53.89, 0.01));
  });

  test('from a USD account: converted at the bill rate', () async {
    final (tx, lines) = await pay('usd');
    expect(lines.single.currency, 'USD');
    expect(lines.single.amount, closeTo(53.89, 0.005));
    expect(tx.amount, closeTo(53.89, 0.005));
  });
}
