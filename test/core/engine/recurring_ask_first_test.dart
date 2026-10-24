import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/recurring_engine.dart';

void main() {
  late AppDatabase db;
  late RecurringEngine recurring;
  late String billId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recurring = RecurringEngine(db);
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'hh', name: 'Home', createdByDeviceId: 'd'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acct',
        householdId: 'hh',
        name: 'Cash',
        type: 'cash',
        currency: 'USD',
        deviceId: 'd'));
    final now = DateTime.now();
    billId = await recurring.create(
      householdId: 'hh',
      type: 'expense',
      title: 'Electricity',
      amount: 40,
      currency: 'USD',
      accountId: 'acct',
      frequency: 'monthly',
      startDate: DateTime(now.year, now.month, now.day - 3),
      askFirst: true,
      remindDays: 0,
    );
  });

  tearDown(() => db.close());

  Future<List<Transaction>> posted() => (db.select(db.transactions)
        ..where((t) => t.deleted.equals(false)))
      .get();

  test('an ask-first bill is not posted on its own', () async {
    expect(await recurring.processRecurring(), 0);
    expect(await posted(), isEmpty);
    final rec = await (db.select(db.recurringTransactions)
          ..where((r) => r.id.equals(billId)))
        .getSingle();
    expect(rec.remindDays, 0);
    expect(rec.nextDueDate.isBefore(DateTime.now()), isTrue,
        reason: 'stays due until confirmed');
  });

  test('confirming posts the entered amount and moves the date on', () async {
    final before = (await (db.select(db.recurringTransactions)
              ..where((r) => r.id.equals(billId)))
            .getSingle())
        .nextDueDate;
    await recurring.postNow(billId, amount: 52.5);
    final txs = await posted();
    expect(txs, hasLength(1));
    final lines = await db.select(db.transactionLines).get();
    expect(lines.single.amount, 52.5);
    final rec = await (db.select(db.recurringTransactions)
          ..where((r) => r.id.equals(billId)))
        .getSingle();
    expect(rec.nextDueDate.isAfter(before), isTrue);
    expect(rec.amount, 40, reason: 'the usual amount stays');
  });

  test('turning ask-first off lets the engine post it', () async {
    await recurring.setBillOptions(billId, askFirst: false, remindDays: null);
    expect(await recurring.processRecurring(), 1);
  });
}
