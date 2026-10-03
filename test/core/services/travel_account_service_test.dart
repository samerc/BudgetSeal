import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/services/travel_account_service.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'hh', name: 'Home', createdByDeviceId: 't'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'bank', householdId: 'hh', name: 'Bank', type: 'bank',
        currency: 'USD', deviceId: 'x', initialBalance: const Value(1000)));
  });

  tearDown(() => db.close());

  Future<double> balance(String id) =>
      BalanceCalculator(db).accountBalance(id);

  Future<String> exchange({String? walletId, double amount = 100,
          double received = 90}) =>
      TravelAccountService.exchange(db,
          householdId: 'hh',
          fromAccountId: 'bank',
          fromCurrency: 'USD',
          amount: amount,
          toCurrency: 'EUR',
          received: received,
          walletId: walletId,
          newWalletName: 'Travel - EUR',
          note: 'Travel exchange → EUR');

  Future<void> spendAll(String walletId) async {
    await AllocationEngine(db).recordTransaction(
        householdId: 'hh', accountId: walletId, type: 'expense',
        lines: [TxLine(amount: await balance(walletId), currency: 'EUR')],
        baseCurrency: 'USD');
    await TravelAccountService.checkAndAutoArchive(db, 'hh');
  }

  test('exchange creates a wallet holding what was received', () async {
    final wallet = await exchange();
    expect(await balance(wallet), closeTo(90, 1e-9));
    expect(await balance('bank'), closeTo(900, 1e-9));
    final acc = await (db.select(db.accounts)
          ..where((a) => a.id.equals(wallet)))
        .getSingle();
    expect(acc.isTravel, isTrue);
    expect(acc.currency, 'EUR');
  });

  test('more cash mid-trip goes into the open wallet', () async {
    final first = await exchange();
    final open = await TravelAccountService.activeWallet(db, 'hh', 'EUR');
    expect(open?.id, first);
    await exchange(walletId: open!.id, amount: 50, received: 45);
    expect(await balance(first), closeTo(135, 1e-9));
    expect(
        await (db.select(db.accounts)..where((a) => a.isTravel.equals(true)))
            .get(),
        hasLength(1));
  });

  test('a third trip after "Create new" still finds a wallet to reactivate',
      () async {
    await spendAll(await exchange()); // trip 1, archived at zero
    await spendAll(await exchange()); // trip 2: "Create new", archived too
    final archived =
        await TravelAccountService.archivedWallet(db, 'hh', 'EUR');
    expect(archived, isNotNull); // used to throw: two archived EUR wallets
    final third = await exchange(walletId: archived!.id);
    expect(third, archived.id);
    expect(await balance(third), closeTo(90, 1e-9));
  });

  test('convert back empties and archives the wallet', () async {
    final wallet = await exchange();
    await TravelAccountService.convertBack(db,
        householdId: 'hh', walletId: wallet, expectedBalance: 90,
        toAccountId: 'bank', received: 95, note: 'back');
    expect(await balance(wallet), closeTo(0, 1e-9));
    expect(await balance('bank'), closeTo(995, 1e-9));
    final acc = await (db.select(db.accounts)
          ..where((a) => a.id.equals(wallet)))
        .getSingle();
    expect(acc.archived, isTrue);
  });

  test('convert back refuses a balance that changed, and changes nothing',
      () async {
    final wallet = await exchange();
    // Spent 10 elsewhere (another device, the browser) after the sheet opened.
    await AllocationEngine(db).recordTransaction(
        householdId: 'hh', accountId: wallet, type: 'expense',
        lines: [TxLine(amount: 10, currency: 'EUR')], baseCurrency: 'USD');

    await expectLater(
        TravelAccountService.convertBack(db,
            householdId: 'hh', walletId: wallet, expectedBalance: 90,
            toAccountId: 'bank', received: 95, note: 'back'),
        throwsA(isA<TravelBalanceChangedException>()));
    expect(await balance(wallet), closeTo(80, 1e-9));
    expect(await balance('bank'), closeTo(900, 1e-9));
    final acc = await (db.select(db.accounts)
          ..where((a) => a.id.equals(wallet)))
        .getSingle();
    expect(acc.archived, isFalse);
  });

  test('zero is half a unit of the last decimal', () {
    expect(TravelAccountService.zeroThreshold('USD'), closeTo(0.005, 1e-12));
    expect(TravelAccountService.zeroThreshold('JPY'), 0.5);
    expect(TravelAccountService.zeroThreshold('KWD'), closeTo(0.0005, 1e-12));
  });
}
