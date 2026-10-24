import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/providers/member_names_provider.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late AllocationEngine engine;
  const me = 'dev-me';
  const other = 'dev-sara';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DeviceIdentity.debugSet(me);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = AllocationEngine(db);
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'hh', name: 'Home', createdByDeviceId: 'd'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acct',
        householdId: 'hh',
        name: 'Cash',
        type: 'cash',
        currency: 'USD',
        deviceId: 'd'));
  });

  tearDown(() async {
    DeviceIdentity.debugSet('local');
    await db.close();
  });

  Future<String> spend({String deviceId = 'local'}) =>
      engine.recordTransaction(
        householdId: 'hh',
        accountId: 'acct',
        type: 'expense',
        lines: const [TxLine(amount: 5, currency: 'USD')],
        baseCurrency: 'USD',
        deviceId: deviceId,
      );

  test('new transactions carry this device; the web keeps its own', () async {
    final mine = await db.transactionsDao.getById(await spend());
    final web = await db.transactionsDao.getById(await spend(deviceId: 'web'));
    expect(mine!.deviceId, me);
    expect(web!.deviceId, 'web');
  });

  test('a single-user budget never asks', () async {
    await spend();
    expect(await HouseholdMembers.shouldAsk(db, 'hh'), isFalse);
  });

  test('asks once another device added entries, then not after naming',
      () async {
    await spend(deviceId: other);
    expect(await HouseholdMembers.shouldAsk(db, 'hh'), isTrue);
    await HouseholdMembers.setMyName(db, 'hh', ' Samer ');
    expect(await HouseholdMembers.shouldAsk(db, 'hh'), isFalse);
    expect(await HouseholdMembers.myName(db, 'hh'), 'Samer');
  });

  test('a device that joined from the cloud asks', () async {
    await HouseholdMembers.markJoined();
    expect(await HouseholdMembers.shouldAsk(db, 'hh'), isTrue);
  });

  test('"Just me" holds until someone new names themselves', () async {
    await HouseholdMembers.markJoined();
    await HouseholdMembers.skip(db, 'hh');
    expect(await HouseholdMembers.shouldAsk(db, 'hh'), isFalse);
    await db.into(db.users).insert(UsersCompanion.insert(
        id: other, householdId: 'hh', name: 'Sara', deviceId: other));
    expect(await HouseholdMembers.shouldAsk(db, 'hh'), isTrue);
  });

  test('names show only when someone else is named', () {
    expect(memberNameFor({me: 'Samer'}, me), isNull);
    expect(memberNameFor({me: 'Samer', other: 'Sara'}, me), 'Samer');
    expect(memberNameFor({other: 'Sara'}, other), 'Sara');
    expect(memberNameFor({me: 'Samer', other: 'Sara'}, 'local'), isNull);
  });
}
