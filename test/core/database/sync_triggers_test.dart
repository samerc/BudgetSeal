import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/sync/sync_engine.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every update to a synced row must move its `last_modified`, or the merge
/// (newer row wins) never sends it to the other device.
void main() {
  late AppDatabase db;
  final old = DateTime(2020, 1, 1);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await seed(db, old);
  });

  tearDown(() => db.close());

  test('every table with last_modified has the trigger', () async {
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'")
        .map((r) => r.data['name'] as String)
        .get();
    final withStamp = <String>[];
    for (final t in tables) {
      final cols = await db.customSelect('PRAGMA table_info($t)').get();
      if (cols.any((c) => c.data['name'] == 'last_modified')) withStamp.add(t);
    }
    final triggers = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
        .map((r) => r.data['name'] as String)
        .get();
    expect(withStamp, isNotEmpty);
    for (final t in withStamp) {
      expect(triggers, contains('bump_last_modified_$t'), reason: t);
    }
  });

  test('an update that forgets the stamp gets one', () async {
    final before = DateTime.now().subtract(const Duration(seconds: 1));
    // Raw SQL, as the subscription pause did.
    await db.customStatement(
        "UPDATE accounts SET name = 'Renamed' WHERE id = 'acc'");
    final acc = await db.select(db.accounts).getSingle();
    expect(acc.name, 'Renamed');
    expect(acc.lastModified.isAfter(before), isTrue);
  });

  test('an update that sets its own stamp keeps it', () async {
    final mine = DateTime(2021, 6, 1);
    await (db.update(db.accounts)..where((a) => a.id.equals('acc')))
        .write(AccountsCompanion(
            name: const Value('Mine'), lastModified: Value(mine)));
    expect((await db.select(db.accounts).getSingle()).lastModified, mine);
  });

  test('note search escapes _ and % (subscription and goal names)',
      () async {
    for (final note in ['Spotify_Family', 'SpotifyXFamily', '50% off']) {
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: note, householdId: 'hh', type: 'expense', accountId: 'acc',
          amount: 1, currency: 'USD', createdBy: 'u', deviceId: 'x',
          note: Value(note)));
    }
    // Same escaping as subscription_detail_screen / objective_detail_screen.
    String pattern(String name) => '%${name.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%';
    Future<List<String>> find(String name) => db
        .customSelect(
            "SELECT note FROM transactions WHERE note LIKE ? ESCAPE '\\'",
            variables: [Variable.withString(pattern(name))])
        .map((r) => r.data['note'] as String)
        .get();
    expect(await find('Spotify_Family'), ['Spotify_Family']);
    expect(await find('50% off'), ['50% off']);

    final drift = await (db.select(db.transactions)
          ..where((t) =>
              t.note.like(pattern('Spotify_Family'), escapeChar: r'\')))
        .get();
    expect(drift.map((t) => t.note), ['Spotify_Family']);
  });

  test('pausing a subscription reaches the other device', () async {
    final other = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(other.close);
    await seed(other, old);

    await db.customStatement(
        "UPDATE recurring_transactions SET enabled = 0 WHERE id = 'sub'");
    await SyncEngine(other).mergeFromJson(await SyncEngine(db).exportToJson());

    expect((await other.select(other.recurringTransactions).getSingle()).enabled,
        isFalse);
  });
}

Future<void> seed(AppDatabase db, DateTime stamp) async {
  await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: 'hh', name: 'Home', createdByDeviceId: 't',
      lastModified: Value(stamp)));
  await db.into(db.accounts).insert(AccountsCompanion.insert(
      id: 'acc', householdId: 'hh', name: 'Bank', type: 'bank',
      currency: 'USD', deviceId: 'x', lastModified: Value(stamp)));
  await db.into(db.recurringTransactions).insert(
      RecurringTransactionsCompanion.insert(
          id: 'sub', householdId: 'hh', type: 'expense', amount: 10,
          currency: 'USD', accountId: 'acc', frequency: 'monthly',
          nextDueDate: DateTime(2026, 12, 1),
          isSubscription: const Value(true),
          lastModified: Value(stamp)));
}
