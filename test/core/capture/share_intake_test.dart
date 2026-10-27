import 'package:budgetseal/core/capture/share_intake.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'last_used_account': 'card'});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'h', name: 'Home', createdByDeviceId: 't'));
    for (final (id, cur) in [
      ('cash', 'USD'),
      ('card', 'USD'),
      ('lira', 'LBP'),
    ]) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id, householdId: 'h', name: id, type: 'cash', currency: cur,
          deviceId: 't'));
    }
  });
  tearDown(() => db.close());

  test('a shared bank message opens the form filled in, on the last account '
      'used when its currency fits', () async {
    final extra = await shareFormArgs(
      const SharedItem(
          'Purchase of USD 18.40 at ABC Verdun with card ending 4455', []),
      db: db,
      householdId: 'h',
      baseCurrency: 'USD',
    );
    expect(extra!['editType'], 'expense');
    expect(extra['editNote'], 'ABC Verdun');
    final line = (extra['editLines'] as List).single as Map;
    expect((line['amount'], line['currency'], line['accountId']),
        (18.4, 'USD', 'card'));
  });

  test('in another currency: an account in that currency', () async {
    final extra = await shareFormArgs(
      const SharedItem('Paid LBP 450,000 at Bakery', []),
      db: db,
      householdId: 'h',
      baseCurrency: 'USD',
    );
    final line = (extra!['editLines'] as List).single as Map;
    expect((line['amount'], line['currency'], line['accountId']),
        (450000.0, 'LBP', 'lira'));
  });

  test('nothing shared: nothing to open', () async {
    expect(
        await shareFormArgs(const SharedItem('  ', []),
            db: db, householdId: 'h', baseCurrency: 'USD'),
        isNull);
  });
}
