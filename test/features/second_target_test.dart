import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/core/providers/seal_provider.dart';
import 'package:budgetseal/features/allocations/funding_screen.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:budgetseal/shared/widgets/envelope_row.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An envelope with a target in two currencies (Groceries $100 +
/// LBP 2,000,000): sealed only when both are met, each shown on its own,
/// each funded in its own currency.
Allocation _groceries({String type = 'spending'}) => Allocation(
      id: 'g', householdId: 'hh', name: 'Groceries', categoryId: 'c',
      type: type, periodicity: 'periodic', rollover: false,
      targetAmount: 100, targetCurrency: 'USD',
      secondTargetAmount: 2000000, secondTargetCurrency: 'LBP',
      autoReset: true, archived: false, deviceId: 't',
      createdAt: DateTime(2026), lastModified: DateTime(2026), deleted: false,
      isPrivate: false);

void main() {
  test('sealed only when both targets are met', () {
    final g = _groceries();
    expect(isEnvelopeSealed(g, {'USD': 100}, {'USD': 100}, 'USD'), isFalse);
    expect(
        isEnvelopeSealed(g, {'USD': 100, 'LBP': 2000000},
            {'USD': 100, 'LBP': 2000000}, 'USD'),
        isTrue);
    expect(
        isEnvelopeSealed(g, {'USD': 100, 'LBP': -10},
            {'USD': 100, 'LBP': 2000000}, 'USD'),
        isFalse);
  });

  testWidgets('the Budget row shows both currencies', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: EnvelopeRow(
          name: 'Groceries',
          type: 'spending',
          balanceByCurrency: const {'USD': 60, 'LBP': 600000},
          baseCurrency: 'USD',
          targetAmount: 100,
          targetCurrency: 'USD',
          secondTargetAmount: 2000000,
          secondTargetCurrency: 'LBP',
          spent: 40,
          secondSpent: 1400000,
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('2,000,000'), findsOneWidget);
    expect(find.textContaining('1,400,000'), findsOneWidget);
  });

  group('funding', () {
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
      for (final (id, cur) in [('usd', 'USD'), ('lbp', 'LBP')]) {
        await db.into(db.accounts).insert(AccountsCompanion.insert(
            id: id, householdId: 'hh', name: id, type: 'cash', currency: cur,
            initialBalance: Value(cur == 'USD' ? 500 : 5000000),
            deviceId: 't'));
      }
      await db.into(db.allocations).insert(_groceries().toCompanion(true));
      await AllocationEngine(db).fundAllocation(
          allocationId: 'g', amount: 20, currency: 'USD', deviceId: 't');
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    testWidgets('a row per currency, each with what it still needs',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: const FundingScreen(),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Groceries'), findsNWidgets(2));
      expect(find.textContaining('2,000,000'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
    });
  });
}
