import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/features/transactions/pay_with_change_screen.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pay with change builds on a small phone with large text, picks a cash
/// account in the base currency and one in another for the change, and
/// shows the rate it will use.
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
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: hh, name: 'Home', createdByDeviceId: 't'));
    for (final (id, name, type, cur) in [
      ('bank', 'Bank', 'checking', 'USD'),
      ('usd', 'Dollars', 'cash', 'USD'),
      ('lbp', 'Lira cash', 'cash', 'LBP'),
    ]) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id, householdId: hh, name: name, type: type, currency: cur,
          deviceId: 't'));
    }
    await db.into(db.fxRates).insert(FxRatesCompanion.insert(
        id: 'fx', fromCurrency: 'USD', toCurrency: 'LBP', rate: 89500,
        source: const Value('manual')));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('builds at 360 dp, 115 % text ($locale)', (tester) async {
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
          home: const PayWithChangeScreen(initialTitle: 'Groceries'),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Dollars'), findsOneWidget);
      expect(find.text('Lira cash'), findsOneWidget);
      expect(find.textContaining('89'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
    });
  }
}
