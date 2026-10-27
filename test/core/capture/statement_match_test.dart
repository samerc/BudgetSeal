import 'package:budgetseal/core/capture/statement_match.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/planned_engine.dart';
import 'package:budgetseal/shared/utils/ocr_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/painting.dart' show Rect;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rows read from a bank list: name, then a signed amount at the end; '
      'dates, balances and totals left out', () {
    OcrLine line(String t) => OcrLine(text: t, boundingBox: Rect.zero);
    final rows = statementRows(OcrResult(
      lines: [
        for (final t in [
          'Transactions',
          '27 Oct',
          'WATER DELIVERY  -18.00',
          'CARREFOUR −82.40',
          'SALARY ACME  +2,500.00',
          'Spinneys 1 350 000 LBP',
          'Available balance 1,220.00',
          'Total -100.40',
        ])
          line(t),
      ],
      imageWidth: 720,
      imageHeight: 1000,
      rawText: '',
    ));
    expect([for (final r in rows) '${r.name}|${r.amount}|${r.income}'], [
      'WATER DELIVERY|18.0|false',
      'CARREFOUR|82.4|false',
      'SALARY ACME|2500.0|true',
      'Spinneys|1350000.0|false',
    ]);
  });

  test('each row matches one recorded movement of the same amount and '
      'direction, the closest title first; the rest is missing', () {
    final now = DateTime(2026, 10, 27);
    final booked = [
      BookedItem('a', 'Coffee', 4.5, date: now),
      BookedItem('b', 'Spinneys', 18.4, date: now),
      BookedItem('c', 'ABC Verdun', 18.4,
          date: now.subtract(const Duration(days: 1))),
      BookedItem('d', 'Salary', 18.4, income: true, date: now),
    ];
    final m = matchStatement(const [
      StatementRow('ABC VERDUN BEIRUT', 18.4),
      StatementRow('STARBUCKS', 4.5),
      StatementRow('SPINNEYS', 18.4),
      StatementRow('SPINNEYS', 18.4), // a second one: not recorded
      StatementRow('NETFLIX', 15.99),
    ], booked);
    expect([for (final (r, b) in m.matched) '${r.name}→${b.id}'],
        ['ABC VERDUN BEIRUT→c', 'STARBUCKS→a', 'SPINNEYS→b']);
    expect([for (final r in m.missing) r.name], ['SPINNEYS', 'NETFLIX']);
  });

  test('what was recorded on an account: its lines, transfers out and in; '
      'not deleted, planned, or older ones', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'h', name: 'Home', createdByDeviceId: 't'));
    for (final (id, cur) in [('card', 'USD'), ('cash', 'USD'), ('lbp', 'LBP')]) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id, householdId: 'h', name: id, type: 'bank', currency: cur,
          deviceId: 't'));
    }
    final e = AllocationEngine(db);
    final now = DateTime.now();
    await e.recordTransaction(
        householdId: 'h', accountId: 'card', type: 'expense',
        lines: const [TxLine(amount: 18.4, currency: 'USD')],
        baseCurrency: 'USD', note: 'Spinneys', date: now);
    // A split over two accounts: only its card part.
    await e.recordTransaction(
        householdId: 'h', accountId: 'card', type: 'expense',
        lines: const [
          TxLine(amount: 10, currency: 'USD', accountId: 'card'),
          TxLine(amount: 5, currency: 'USD', accountId: 'cash'),
        ],
        baseCurrency: 'USD', note: 'Dinner', date: now);
    await e.recordTransfer(
        householdId: 'h', fromAccountId: 'card', toAccountId: 'lbp',
        amount: 100, currency: 'USD', exchangeRateToBase: 89500,
        createdBy: 'u', deviceId: 'local', date: now);
    await e.recordTransfer(
        householdId: 'h', fromAccountId: 'cash', toAccountId: 'card',
        amount: 50, currency: 'USD', exchangeRateToBase: 1,
        createdBy: 'u', deviceId: 'local', date: now);
    final gone = await e.recordTransaction(
        householdId: 'h', accountId: 'card', type: 'expense',
        lines: const [TxLine(amount: 7, currency: 'USD')],
        baseCurrency: 'USD', date: now);
    await e.deleteTransaction(gone);
    await e.recordTransaction(
        householdId: 'h', accountId: 'card', type: 'expense',
        lines: const [TxLine(amount: 99, currency: 'USD')],
        baseCurrency: 'USD', date: now.subtract(const Duration(days: 200)));
    await PlannedEngine(db).save(
        householdId: 'h', type: 'expense', accountId: 'card', amount: 30,
        currency: 'USD', date: now, createdBy: 'u', deviceId: 'local');

    final booked = await bookedOnAccount(
        db, 'card', now.subtract(const Duration(days: 90)));
    expect(
        {for (final b in booked) '${b.title}:${b.amount}:${b.income}'},
        {'Spinneys:18.4:false', 'Dinner:10.0:false', ':100.0:false',
         ':50.0:true'});
  });
}
