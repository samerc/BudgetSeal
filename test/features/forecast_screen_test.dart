import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/features/forecast/forecast_screen.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The forecast and its Home card build on a small phone with large text,
/// in English and Arabic, with a rent and a salary coming up.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    container.read(currentHouseholdIdProvider.notifier).set('hh');
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'hh', name: 'Home', createdByDeviceId: 't'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'bank', householdId: 'hh', name: 'Bank', type: 'bank',
        currency: 'USD', initialBalance: const Value(900), deviceId: 't'));
    final now = DateTime.now();
    for (final (id, type, amount, days) in [
      ('Rent', 'expense', 700.0, 4),
      ('Salary', 'income', 2000.0, 20),
    ]) {
      await db.into(db.recurringTransactions).insert(
          RecurringTransactionsCompanion.insert(
              id: id, householdId: 'hh', type: type, amount: amount,
              currency: 'USD', accountId: 'bank', frequency: 'monthly',
              nextDueDate: now.add(Duration(days: days)), title: Value(id)));
    }
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final (name, page) in [
      ('screen', const ForecastScreen()),
      ('card', const Scaffold(body: ForecastCard())),
    ]) {
      testWidgets('$name builds at 360 dp, 115 % text ($locale)',
          (tester) async {
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
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 100)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        if (locale.languageCode == 'en') {
          expect(find.textContaining('Safe to spend today'), findsOneWidget);
          if (name == 'screen') {
            // The list of what's coming is below the chart.
            await tester.drag(find.byType(ListView), const Offset(0, -700));
            await tester.pump();
            expect(find.text('Rent'), findsWidgets);
            expect(find.text('Salary'), findsWidgets);
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
      });
    }
  }
}
