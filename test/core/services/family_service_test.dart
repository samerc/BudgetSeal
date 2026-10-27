import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/database/daos/ledger_dao.dart';
import 'package:budgetseal/core/services/family_service.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:budgetseal/core/sync/log_sync.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sync/log_sync_test.dart' show MemoryStore;

Future<AppDatabase> _phone(String id, {bool seed = true}) async {
  DeviceIdentity.debugSet(id);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.customSelect('SELECT 1').get();
  addTearDown(db.close);
  if (seed) {
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'h', name: 'Home', createdByDeviceId: 't'));
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: 'kid-fun', householdId: 'h', name: 'Fun', categoryId: 'c',
        deviceId: 't', ownerDeviceId: const Value('kid')));
  }
  return db;
}

Future<double> _funded(AppDatabase db) async =>
    (await LedgerDao(db).getBalanceByCurrency('kid-fun'))['USD'] ?? 0;

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(() => DeviceIdentity.debugSet('local'));

  test('a request: approving funds the envelope once; deciding twice does '
      'nothing', () async {
    final db = await _phone('kid');
    final id = await FamilyService(db).ask(
        householdId: 'h', allocationId: 'kid-fun', amount: 20,
        currency: 'USD', note: 'School trip');
    DeviceIdentity.debugSet('mom');
    expect(await FamilyService(db).approve(id), isTrue);
    expect(await FamilyService(db).approve(id), isFalse);
    expect(await FamilyService(db).decline(id), isFalse);
    expect(await _funded(db), 20);
    final r = await db.select(db.moneyRequests).getSingle();
    expect((r.status, r.decidedBy, r.fromDeviceId), ('approved', 'mom', 'kid'));
  });

  test('declined: nothing moves', () async {
    final db = await _phone('kid');
    final id = await FamilyService(db).ask(
        householdId: 'h', allocationId: 'kid-fun', amount: 20, currency: 'USD');
    expect(await FamilyService(db).decline(id), isTrue);
    expect(await _funded(db), 0);
  });

  test('two grown-ups approve the same request before syncing: funded once',
      () async {
    final store = MemoryStore();
    final mom = await _phone('mom');
    final id = await FamilyService(mom).ask(
        householdId: 'h', allocationId: 'kid-fun', amount: 20, currency: 'USD');
    await LogSync(mom).sync(store);
    final dad = await _phone('dad', seed: false);
    await LogSync(dad).replaceFrom(store);

    DeviceIdentity.debugSet('mom');
    await FamilyService(mom).approve(id);
    DeviceIdentity.debugSet('dad');
    await FamilyService(dad).approve(id);
    DeviceIdentity.debugSet('mom');
    await LogSync(mom).sync(store);
    DeviceIdentity.debugSet('dad');
    await LogSync(dad).sync(store);
    DeviceIdentity.debugSet('mom');
    await LogSync(mom).sync(store);
    expect(await _funded(mom), 20);
    expect(await _funded(dad), 20);
  });

  test('the review: each grown-up confirms once', () async {
    final db = await _phone('mom');
    final start = DateTime(2026, 10, 1);
    await FamilyService(db).confirmReview('h', start);
    await FamilyService(db).confirmReview('h', start);
    DeviceIdentity.debugSet('dad');
    await FamilyService(db).confirmReview('h', start);
    expect(await FamilyService(db).reviewedBy('h', start), {'mom', 'dad'});
    expect(await FamilyService(db).reviewedBy('h', DateTime(2026, 9, 1)),
        isEmpty);
  });
}
