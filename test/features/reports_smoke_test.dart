import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/features/reports/time/budget_report.dart';
import 'package:budgetseal/features/reports/time/list_reports.dart';
import 'package:budgetseal/features/reports/time/money_report.dart';
import 'package:budgetseal/features/reports/time/places_report.dart';
import 'package:budgetseal/features/reports/time/reports_home.dart';
import 'package:budgetseal/features/reports/time/spending_report.dart';
import 'package:budgetseal/features/reports/time/year_report.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every time report builds on a small phone with large text: no layout
/// overflow, no exception. Data: one envelope (funded, then overspent),
/// titled expenses, income and a subscription.
void main() {
  const hh = 'hh';
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    container.read(currentHouseholdIdProvider.notifier).set(hh);
    final engine = AllocationEngine(db);
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: hh, name: 'Home', createdByDeviceId: 't'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'acc', householdId: hh, name: 'Bank', type: 'checking',
        currency: 'USD', deviceId: 't'));
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: 'food', householdId: hh, name: 'Food & drink', categoryId: 'cat',
        targetAmount: const Value(100), targetCurrency: const Value('USD'),
        deviceId: 't'));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat', householdId: hh, name: 'Food & drink',
        allocationId: const Value('food')));
    await engine.fundAllocation(
        allocationId: 'food', amount: 100, currency: 'USD', deviceId: 't');
    final now = DateTime.now();
    for (final (i, title, amount) in [
      (0, 'Carrefour', 60.0),
      (1, 'Carrefour', 25.5),
      (2, 'Coffee', 4.5),
      (40, 'Carrefour', 70.0),
    ]) {
      await engine.recordTransaction(
        householdId: hh,
        accountId: 'acc',
        type: 'expense',
        lines: [TxLine(amount: amount, currency: 'USD', categoryId: 'cat')],
        baseCurrency: 'USD',
        note: title,
        date: now.subtract(Duration(days: i)),
      );
    }
    await engine.recordTransaction(
      householdId: hh,
      accountId: 'acc',
      type: 'income',
      lines: [const TxLine(amount: 1200, currency: 'USD')],
      baseCurrency: 'USD',
      note: 'Salary',
      date: now.subtract(const Duration(days: 3)),
    );
    await db.into(db.recurringTransactions).insert(
        RecurringTransactionsCompanion.insert(
            id: 'r1', householdId: hh, type: 'expense', amount: 15.99,
            currency: 'USD', accountId: 'acc', frequency: 'monthly',
            nextDueDate: now.add(const Duration(days: 5)),
            title: const Value('Netflix')));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  final reports = <String, Widget>{
    'home': const Scaffold(body: ReportsHome()),
    'budget': const BudgetReport(),
    'spending': const SpendingReport(),
    'money': const MoneyReport(),
    'places': const PlacesReport(),
    'biggest': const BiggestReport(),
    'accounts': const AccountsReport(),
    'currencies': const CurrenciesReport(),
    'subscriptions': const SubscriptionsReport(),
    'year': const YearReport(),
  };

  for (final locale in const [Locale('en'), Locale('ar')])
  for (final MapEntry(key: name, value: page) in reports.entries) {
    testWidgets('$name builds at 360 dp, 115 % text ($locale)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.15)),
            child: child!,
          ),
          home: page,
        ),
      ));
      // Let the database streams and futures settle.
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: '$name still loading');
      // Unmount so stream timers stop before the test ends.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
    });
  }
}
