import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/forecast.dart';
import 'package:budgetseal/core/engine/sinking_fund.dart' show FundPayment;
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 10, 27, 15);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'h', name: 'Home', createdByDeviceId: 't'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'bank', householdId: 'h', name: 'Bank', type: 'bank',
        currency: 'USD', deviceId: 't'));
  });
  tearDown(() => db.close());

  Future<List<RecurringTransaction>> recurring(
      List<(String id, String type, double amount, DateTime next)> items,
      {bool enabled = true, DateTime? endDate}) async {
    for (final (id, type, amount, next) in items) {
      await db.into(db.recurringTransactions).insert(
          RecurringTransactionsCompanion.insert(
              id: id, householdId: 'h', type: type, amount: amount,
              currency: 'USD', accountId: 'bank', frequency: 'monthly',
              nextDueDate: next, title: Value(id), enabled: Value(enabled),
              endDate: Value(endDate)));
    }
    return db.select(db.recurringTransactions).get();
  }

  test('the timeline, its lowest point, and safe to spend until payday',
      () async {
    final f = buildForecast(
      now: now,
      cash: {'USD': 1000},
      recurring: await recurring([
        ('Rent', 'expense', 500, DateTime(2026, 11, 1)),
        ('Salary', 'income', 2000, DateTime(2026, 11, 25)),
      ]),
    )['USD']!;
    expect(f.daily.first, 1000);
    expect(f.daily[5], 500); // Nov 1
    expect(f.daily[29], 2500); // Nov 25
    expect((f.lowest, f.lowestOn), (500.0, DateTime(2026, 11, 1)));
    expect(f.nextIncome!.date, DateTime(2026, 11, 25));
    expect((f.dueBefore, f.daysLeft), (500.0, 29));
    expect(f.safeToSpend, closeTo(500 / 29, 1e-9));
    // Monthly, up to Jan 25 (90 days): rent Dec 1 and Jan 1, salary Dec 25
    // and Jan 25.
    expect([for (final e in f.events) e.title],
        ['Rent', 'Salary', 'Rent', 'Salary', 'Rent', 'Salary']);
  });

  test('an overdue bill counts today; paused and ended ones not', () async {
    final items = await recurring([
      ('Late', 'expense', 40, DateTime(2026, 10, 20)),
    ]);
    items.addAll(await recurring([('Paused', 'expense', 99, DateTime(2026, 11, 2))],
        enabled: false));
    items.addAll(await recurring([('Ended', 'expense', 77, DateTime(2026, 11, 3))],
        endDate: DateTime(2026, 10, 1)));
    final f = buildForecast(now: now, cash: {'USD': 100}, recurring: {
      for (final r in await db.select(db.recurringTransactions).get()) r.id: r
    }.values.toList())['USD']!;
    expect(f.events.first.date, DateTime(2026, 10, 27));
    expect(f.daily.first, 60);
    expect(f.events.where((e) => e.title != 'Late'), isEmpty);
  });

  test('no scheduled income: an estimate from the last three months, on '
      'its usual day', () {
    final f = buildForecast(
      now: now,
      cash: {'USD': 300},
      pastIncome: [
        PastIncome(DateTime(2026, 8, 1), 1500, 'USD'),
        PastIncome(DateTime(2026, 9, 1), 1500, 'USD'),
        PastIncome(DateTime(2026, 10, 1), 1500, 'USD'),
        PastIncome(DateTime(2026, 10, 12), 60, 'USD'), // a refund
      ],
    )['USD']!;
    expect(f.hasEstimate, isTrue);
    expect(f.nextIncome!.kind, ForecastKind.estimate);
    expect(f.nextIncome!.date, DateTime(2026, 11, 1));
    expect(f.nextIncome!.amount, closeTo(1520, 1e-9));
  });

  test('currencies stay apart: a planned payment split over two', () {
    final out = buildForecast(
      now: now,
      cash: {'USD': 500, 'LBP': 9000000},
      planned: [
        PlannedPart(DateTime(2026, 11, 5), 'School', 'expense', 300, 'USD'),
        PlannedPart(DateTime(2026, 11, 5), 'School', 'expense', 4500000, 'LBP'),
      ],
    );
    expect(out['USD']!.daily.last, 200);
    expect(out['LBP']!.daily.last, 4500000);
  });

  test('sinking funds: what they keep for later is held back, a payment '
      'before payday counts once', () async {
    final f = buildForecast(
      now: now,
      cash: {'USD': 2000},
      recurring: await recurring([
        ('Salary', 'income', 2000, DateTime(2026, 11, 25)),
      ]),
      planned: [
        PlannedPart(DateTime(2026, 11, 10), 'Insurance', 'expense', 400, 'USD'),
      ],
      funds: [
        ForecastFund({'USD': 600}, {'USD': 100}, [
          FundPayment(
              title: 'Insurance',
              date: DateTime(2026, 11, 10),
              amounts: const {'USD': 400}),
        ]),
      ],
    )['USD']!;
    expect(f.dueBefore, 400);
    expect(f.reserved, 300); // 600 − 400 paid before payday, + 100 to put in
    expect(f.safeToSpend, closeTo((2000 - 400 - 300) / 29, 1e-9));
  });

  test('savings goals are not safe to spend; each currency its own',
      () async {
    final f = buildForecast(
      now: now,
      cash: {'USD': 2000, 'EUR': 500},
      recurring: await recurring([
        ('Salary', 'income', 2000, DateTime(2026, 11, 25)),
      ]),
      savings: {'USD': 1200, 'EUR': -50},
    );
    expect(f['USD']!.saved, 1200);
    expect(f['USD']!.safeToSpend, closeTo((2000 - 1200) / 29, 1e-9));
    // A negative savings balance never adds money.
    expect(f['EUR']!.saved, 0);
  });

  test('falling short: safe to spend is 0 and says by how much', () async {
    final f = buildForecast(
      now: now,
      cash: {'USD': 100},
      recurring: await recurring([
        ('Rent', 'expense', 300, DateTime(2026, 11, 1)),
        ('Salary', 'income', 2000, DateTime(2026, 11, 25)),
      ]),
    )['USD']!;
    expect((f.safeToSpend, f.short), (0.0, 200.0));
    expect(f.lowest, -200);
  });
}
