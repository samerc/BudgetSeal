import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/fx/fx_service.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:budgetseal/core/sync/log_sync.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sync/log_sync_test.dart' show MemoryStore;

Future<AppDatabase> _phone(String id) async {
  DeviceIdentity.debugSet(id);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.customSelect('SELECT 1').get();
  addTearDown(db.close);
  return db;
}

Future<void> _seed(AppDatabase db) async {
  await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: 'h', name: 'Home', createdByDeviceId: 'a'));
  for (final (id, cur) in [('usd', 'USD'), ('lbp', 'LBP')]) {
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: id, householdId: 'h', name: id, type: 'cash', currency: cur,
        deviceId: 'a'));
  }
  // A fetched market rate.
  await db.into(db.fxRates).insert(FxRatesCompanion.insert(
      id: 'api', fromCurrency: 'USD', toCurrency: 'LBP', rate: 89500,
      source: const Value('api'),
      fetchedAt: Value(DateTime.now().subtract(const Duration(minutes: 5)))));
}

Future<void> _exchange(AppDatabase db, double rate) =>
    AllocationEngine(db).recordTransfer(
        householdId: 'h', fromAccountId: 'usd', toAccountId: 'lbp',
        amount: 100, currency: 'USD', exchangeRateToBase: rate,
        createdBy: 'u', deviceId: 'local', rateGot: true);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(() => DeviceIdentity.debugSet('local'));

  test('an exchange remembers the rate got; live stays the default',
      () async {
    final db = await _phone('a');
    await _seed(db);
    await _exchange(db, 90000);
    expect((await rateGot(db, 'USD', 'LBP'))!.rate, 90000);
    expect(await rateSource(db, 'USD', 'LBP'), RateSource.live);
    // The newer "got" row doesn't pass for a fetched one.
    expect(await latestCachedRate(db, 'USD', 'LBP'), 89500);
    expect(await FxService(db).getRateWithCache('USD', 'LBP'), 89500);
  });

  test('"last rate I got" is used in both directions once chosen; a fixed '
      'rate wins over it', () async {
    final db = await _phone('a');
    await _seed(db);
    await _exchange(db, 90000);
    await _exchange(db, 91000); // only the latest is kept
    await setRateSource(db, 'h', 'LBP', 'USD', RateSource.got);
    expect(await rateSource(db, 'USD', 'LBP'), RateSource.got);
    expect(await latestCachedRate(db, 'USD', 'LBP'), 91000);
    expect(await latestCachedRate(db, 'LBP', 'USD'), closeTo(1 / 91000, 1e-12));
    expect(await FxService(db).getRateWithCache('USD', 'LBP'), 91000);
    expect(
        await FxService(db).getRateWithCache('USD', 'LBP', liveOnly: true),
        89500);

    await FxService(db).saveManualRate('USD', 'LBP', 88000);
    expect(await rateSource(db, 'USD', 'LBP'), RateSource.fixed);
    expect(await latestCachedRate(db, 'USD', 'LBP'), 88000);
    await FxService(db).clearManualRate('USD', 'LBP');
    expect(await latestCachedRate(db, 'USD', 'LBP'), 91000);

    await setRateSource(db, 'h', 'USD', 'LBP', RateSource.live);
    expect(await latestCachedRate(db, 'USD', 'LBP'), 89500);
  });

  test('the choice and the rate got reach the other phone', () async {
    final store = MemoryStore();
    final a = await _phone('a');
    await _seed(a);
    await LogSync(a).sync(store);
    final b = await _phone('b');
    await LogSync(b).replaceFrom(store);

    await _exchange(a, 90500);
    await setRateSource(a, 'h', 'USD', 'LBP', RateSource.got);
    await LogSync(a).sync(store);
    await LogSync(b).sync(store);
    expect(await rateSource(b, 'USD', 'LBP'), RateSource.got);
    expect(await latestCachedRate(b, 'USD', 'LBP'), 90500);
  });
}
