import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/engine/planned_engine.dart';
import 'package:budgetseal/core/providers/sinking_fund_provider.dart';

/// A sinking fund's schedule comes from planned expenses (one part per
/// currency) and yearly bills in its category; posting a plan pays it from
/// the fund.
void main() {
  late AppDatabase db;
  const hh = 'hh';
  // Real dates: the engine dates funding rows with the clock.
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: hh, name: 'Home', createdByDeviceId: 't'));
    for (final (id, cur) in [('bank', 'USD'), ('lira', 'LBP')]) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id, householdId: hh, name: id, type: 'cash',
          currency: cur, deviceId: 't'));
    }
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: 'school', householdId: hh, name: 'School', categoryId: 'edu',
        type: const Value('sinking'), periodicity: const Value('permanent'),
        createdAt: Value(month), deviceId: 't'));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'edu', householdId: hh, name: 'Education',
        allocationId: const Value('school')));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'food', householdId: hh, name: 'Food'));
  });

  tearDown(() => db.close());

  Future<Map<String, SinkingFund>> load() async {
    final allocs = await db.select(db.allocations).get();
    final cats = await db.select(db.categories).get();
    return loadSinkingFunds(db,
        householdId: hh,
        funds: {
          for (final a in allocs)
            a: await BalanceCalculator(db).allocationBalanceByCurrency(a.id),
        },
        liveAllocations: allocs,
        categories: cats,
        startDay: 1,
        now: now);
  }

  test('plans in two currencies and yearly bills make the schedule', () async {
    await PlannedEngine(db).save(
      householdId: hh,
      type: 'expense',
      accountId: 'bank',
      amount: 1500,
      currency: 'USD',
      categoryId: 'edu',
      note: '2nd installment',
      date: DateTime(month.year, month.month + 2, 5),
      createdBy: 't',
      deviceId: 't',
      parts: const [
        PlanPart(amount: 1500, currency: 'USD', accountId: 'bank'),
        PlanPart(amount: 45000000, currency: 'LBP', accountId: 'lira'),
      ],
    );
    // Another category's plan is not the fund's.
    await PlannedEngine(db).save(
      householdId: hh,
      type: 'expense',
      accountId: 'bank',
      amount: 80,
      currency: 'USD',
      categoryId: 'food',
      date: DateTime(month.year, month.month + 1, 1),
      createdBy: 't',
      deviceId: 't',
    );
    await db.into(db.recurringTransactions).insert(
        RecurringTransactionsCompanion.insert(
            id: 'books',
            householdId: hh,
            type: 'expense',
            title: const Value('Books'),
            amount: 300,
            currency: 'USD',
            accountId: 'bank',
            categoryId: const Value('edu'),
            frequency: 'yearly',
            nextDueDate: DateTime(month.year, month.month + 10, 1)));

    final fund = (await load())['school']!;
    expect(fund.plan.upcoming.map((p) => p.title), ['2nd installment', 'Books']);
    expect(fund.plan.upcoming.first.amounts,
        {'USD': 1500, 'LBP': 45000000});
    expect(fund.thisPeriod, {'USD': 500, 'LBP': 15000000});

    await AllocationEngine(db).fundAllocation(
        allocationId: 'school', amount: 500, currency: 'USD', deviceId: 't');
    final after = (await load())['school']!;
    expect(after.thisPeriod, {'LBP': 15000000});
  });

  test('a posted plan is paid from the fund', () async {
    final id = await PlannedEngine(db).save(
      householdId: hh,
      type: 'expense',
      accountId: 'bank',
      amount: 200,
      currency: 'USD',
      categoryId: 'edu',
      note: 'Trip',
      date: month,
      createdBy: 't',
      deviceId: 't',
    );
    await PlannedEngine(db).post(id,
        baseCurrency: 'USD',
        rate: (_, __) async => null,
        createdBy: 't',
        deviceId: 't',
        now: now);
    final fund = (await load())['school']!;
    expect(fund.plan.upcoming, isEmpty);
    expect(fund.paid.single.title, 'Trip');
    expect(fund.paid.single.amounts, {'USD': 200});
    expect(fund.balances['USD'], closeTo(-200, 0.001));
  });
}
