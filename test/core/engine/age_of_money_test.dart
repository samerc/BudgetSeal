import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/age_of_money.dart';

void main() {
  late AppDatabase db;
  var n = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'hh', name: 'H', createdByDeviceId: 'd'));
  });
  tearDown(() async => db.close());

  Future<void> tx(String type, double amount, DateTime date) =>
      db.into(db.transactions).insert(TransactionsCompanion.insert(
            id: 't${n++}',
            householdId: 'hh',
            type: type,
            accountId: 'acc',
            amount: amount,
            currency: 'USD',
            createdBy: 'test',
            deviceId: 'd',
            createdAt: Value(date),
          ));

  test('recent expenses spend recent money once old income is used up',
      () async {
    // Jan income fully spent in Jan; Jun income spent in Jun.
    await tx('income', 100, DateTime(2026, 1, 1));
    await tx('expense', 100, DateTime(2026, 1, 11));
    await tx('income', 100, DateTime(2026, 6, 1));
    await tx('expense', 100, DateTime(2026, 6, 21));

    // Average of the two expenses: 10 days and 20 days → 15. The old
    // version matched the June expense against January income (~170 days).
    expect(await calculateAgeOfMoney(db, 'hh'), 15);
  });

  test('null without expenses', () async {
    await tx('income', 100, DateTime(2026, 1, 1));
    expect(await calculateAgeOfMoney(db, 'hh'), isNull);
  });
}
