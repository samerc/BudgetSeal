import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/change_log.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:budgetseal/core/sync/log_sync.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/sync/log_sync_test.dart' show MemoryStore;

Transaction _tx(String id, DateTime at, {bool deleted = false, String type = 'expense'}) =>
    Transaction(
      id: id,
      householdId: 'hh',
      type: type,
      accountId: 'a',
      amount: 10,
      currency: 'USD',
      exchangeRateToBase: 1,
      note: '',
      createdBy: 'user',
      deviceId: 'local',
      createdAt: at,
      lastModified: at,
      deleted: deleted,
    );

void main() {
  final t0 = DateTime(2026, 10, 24, 12);

  test('an edit (new row + old deleted moments later) reads as one edit', () {
    final log = buildChangeLog([
      _tx('new', t0),
      _tx('old', t0.add(const Duration(seconds: 1)), deleted: true),
      _tx('other', t0.subtract(const Duration(hours: 2))),
    ]);
    expect(log.map((e) => (e.tx.id, e.kind)).toList(), [
      ('new', ChangeKind.edited),
      ('other', ChangeKind.added),
    ]);
  });

  test('a delete on its own stays a delete; types must match to pair', () {
    final log = buildChangeLog([
      _tx('inc', t0, type: 'income'),
      _tx('gone', t0.add(const Duration(seconds: 2)), deleted: true),
      _tx('late', t0.add(const Duration(minutes: 5)), deleted: true),
    ]);
    expect(log.map((e) => (e.tx.id, e.kind)).toList(), [
      ('late', ChangeKind.deleted),
      ('gone', ChangeKind.deleted),
      ('inc', ChangeKind.added),
    ]);
  });

  group('from the operation log', opLogTests);
}

// ── From the operation log ───────────────────────────────────────────────────

Future<AppDatabase> _phone(String id) async {
  DeviceIdentity.debugSet(id);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.customSelect('SELECT 1').get();
  addTearDown(db.close);
  return db;
}

Future<void> _household(AppDatabase db) async {
  await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: 'h', name: 'Home', createdByDeviceId: 'a'));
  for (final id in ['bank', 'cash']) {
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: id, householdId: 'h', name: id, type: 'bank', currency: 'USD',
        deviceId: 'a'));
  }
  for (final id in ['food', 'home']) {
    await db.into(db.categories).insert(
        CategoriesCompanion.insert(id: id, householdId: 'h', name: id));
  }
}

// Longer than one tick of the system clock (about 15 ms on Windows).
Future<void> _later() => Future<void>.delayed(const Duration(milliseconds: 20));

void opLogTests() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(() => DeviceIdentity.debugSet('local'));

  test('every save is one entry; an edit says what changed', () async {
    final db = await _phone('phone-a');
    await _household(db);
    final engine = AllocationEngine(db);
    final id = await engine.recordTransaction(
      householdId: 'h', accountId: 'bank', type: 'expense',
      lines: const [TxLine(amount: 10, currency: 'USD', categoryId: 'food')],
      baseCurrency: 'USD', note: 'Lunch');
    await _later();
    await engine.recordTransaction(
      editing: id, householdId: 'h', accountId: 'cash', type: 'expense',
      lines: const [TxLine(amount: 12, currency: 'USD', categoryId: 'home')],
      baseCurrency: 'USD', note: 'Lunch out');
    await _later();
    await (db.update(db.transactions)..where((t) => t.id.equals(id)))
        .write(const TransactionsCompanion(deleted: Value(true)));
    await _later();
    await (db.update(db.transactions)..where((t) => t.id.equals(id)))
        .write(const TransactionsCompanion(deleted: Value(false)));

    final log = await loadChangeLog(db, 'h');
    expect(log.map((e) => e.kind), [
      ChangeKind.restored,
      ChangeKind.deleted,
      ChangeKind.edited,
      ChangeKind.added,
    ]);
    expect(log.every((e) => e.tx.id == id && e.by == 'phone-a'), isTrue);
    expect(log.last.amounts, {'USD': 10});
    final edit = log[2];
    expect(edit.amounts, {'USD': 12});
    expect({for (final c in edit.changes) c.field: '${c.from} → ${c.to}'}, {
      'amount': '{USD: 10.0} → {USD: 12.0}',
      'category': '[food] → [home]',
      'account': '[bank] → [cash]',
      'note': 'Lunch → Lunch out',
    });
    expect(edit.replacedBy, isNull);
  });

  test('the same field edited on two phones: the earlier edit is marked '
      'replaced, a later edit made after seeing it is not', () async {
    final store = MemoryStore();
    final a = await _phone('phone-a');
    await _household(a);
    final id = await AllocationEngine(a).recordTransaction(
      householdId: 'h', accountId: 'bank', type: 'expense',
      lines: const [TxLine(amount: 10, currency: 'USD', categoryId: 'food')],
      baseCurrency: 'USD', note: 'Lunch');
    await LogSync(a).sync(store);
    final b = await _phone('phone-b');
    await LogSync(b).replaceFrom(store);

    Future<void> note(AppDatabase db, String text) =>
        (db.update(db.transactions)..where((t) => t.id.equals(id)))
            .write(TransactionsCompanion(note: Value(text)));
    // Offline: A, then B, rename it.
    await note(a, 'Lunch (A)');
    await _later();
    await note(b, 'Lunch (B)');
    await LogSync(a).sync(store);
    await LogSync(b).sync(store);
    await LogSync(a).sync(store);
    // Then A, having seen B's, renames it again.
    await _later();
    await note(a, 'Team lunch');
    await LogSync(a).sync(store);
    await LogSync(b).sync(store);

    for (final db in [a, b]) {
      final edits = [
        for (final e in await loadChangeLog(db, 'h'))
          if (e.kind == ChangeKind.edited)
            (e.changes.single.to, e.by, e.replacedBy),
      ];
      expect(edits, [
        ('Team lunch', 'phone-a', null),
        ('Lunch (B)', 'phone-b', null),
        ('Lunch (A)', 'phone-a', 'phone-b'),
      ]);
    }
  });

  test('rows from before the log keep the old reading', () async {
    final db = await _phone('phone-a');
    await _household(db);
    final t0 = DateTime(2026, 9, 1, 12);
    // Written with the log muted, as if before it existed.
    await db.customStatement('UPDATE sync_clock SET applying = 1');
    for (final (id, at, deleted) in [
      ('new', t0, false),
      ('old', t0.add(const Duration(seconds: 2)), true),
    ]) {
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: id, householdId: 'h', type: 'expense', accountId: 'bank',
          amount: 5, currency: 'USD', createdBy: 'u', deviceId: 'phone-a',
          lastModified: Value(at), deleted: Value(deleted)));
    }
    await db.customStatement('UPDATE sync_clock SET applying = 0');
    await AllocationEngine(db).recordTransaction(
      householdId: 'h', accountId: 'bank', type: 'expense',
      lines: const [TxLine(amount: 1, currency: 'USD', categoryId: 'food')],
      baseCurrency: 'USD');

    final log = await loadChangeLog(db, 'h');
    expect(log.map((e) => (e.tx.id == 'new' ? 'new' : 'today', e.kind)), [
      ('today', ChangeKind.added),
      ('new', ChangeKind.edited),
    ]);
  });
}
