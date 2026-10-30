import 'package:budgetseal/core/capture/bank_alerts.dart';
import 'package:budgetseal/core/capture/capture_rules.dart';
import 'package:budgetseal/core/capture/share_intake.dart';
import 'package:budgetseal/core/capture/text_reader.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/fx/fx_service.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/features/capture/review_screen.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _text = 'Card ending 4455: purchase of USD 18.40 at ABC Verdun. '
    'Balance USD 1,220.00';

AlertItem _alert(String id) => AlertItem(
    id: id, app: 'com.bank', appName: 'My Bank', title: 'My Bank',
    text: _text, at: DateTime(2026, 10, 27, 9, 30));

void main() {
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'h', name: 'Home', createdByDeviceId: 't'));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'card', householdId: 'h', name: 'Card', type: 'card',
        currency: 'USD', deviceId: 't'));
    await db.into(db.categories).insert(
        CategoriesCompanion.insert(id: 'food', householdId: 'h', name: 'Food'));
  });
  tearDown(() => db.close());

  test('an alert opens the form dated when it arrived, tied to the alert',
      () async {
    final args = await alertFormArgs(_alert('a1'),
        db: db, householdId: 'h', baseCurrency: 'USD');
    expect(args['editDate'], DateTime(2026, 10, 27, 9, 30));
    expect(args['editNote'], 'ABC Verdun');
    final line = (args['editLines'] as List).single as Map;
    expect((line['amount'], line['accountId']), (18.4, 'card'));
    final capture = args['capture'] as Map;
    expect((capture['alertId'], capture['app'], capture['shop']),
        ('a1', 'com.bank', 'ABC Verdun'));
  });

  test('saving it: the alert leaves the inbox and the shop becomes a rule',
      () async {
    await BankAlerts.restore(_alert('a1'));
    await BankAlerts.restore(_alert('a2'));
    final args = await alertFormArgs(_alert('a1'),
        db: db, householdId: 'h', baseCurrency: 'USD');
    await captureSaved(db,
        householdId: 'h',
        capture: (args['capture'] as Map).cast<String, dynamic>(),
        amount: 18.4,
        categoryId: 'food',
        accountId: 'card');
    expect([for (final i in await BankAlerts.inbox()) i.id], ['a2']);
    expect((await findCaptureRule(db, 'h', 'abc verdun'))?.categoryId, 'food');
    // The reader's amount was right: nothing learned for the bank.
    expect(await BankAlerts.amountIndex('com.bank'), 0);
  });

  test('a fixed amount teaches which number is the payment for that bank',
      () async {
    // Say this bank puts the balance first: the user saved 1,220.
    await BankAlerts.learnAmount('com.bank', _text, 1220);
    expect(await BankAlerts.amountIndex('com.bank'), 1);
    expect(readCapturedText(_text, amountIndex: 1).amount, 1220);
    final args = await alertFormArgs(_alert('a3'),
        db: db, householdId: 'h', baseCurrency: 'USD');
    expect(((args['editLines'] as List).single as Map)['amount'], 1220.0);
    // Other banks keep the first amount.
    expect(await BankAlerts.amountIndex('com.other'), 0);
  });

  test('dismiss and undo', () async {
    await BankAlerts.restore(_alert('a1'));
    await BankAlerts.remove('a1');
    expect(await BankAlerts.inbox(), isEmpty);
    await BankAlerts.restore(_alert('a1'));
    await BankAlerts.restore(_alert('a1'));
    expect(await BankAlerts.inbox(), hasLength(1));
  });

  group('swipe right: added as read', () {
    Future<String?> save(String id) => saveAlertAsRead(_alert(id),
        db: db,
        engine: AllocationEngine(db),
        fx: FxService(db),
        householdId: 'h',
        baseCurrency: 'USD');

    test('a shop with no category yet needs the form: nothing is saved',
        () async {
      await BankAlerts.restore(_alert('a1'));
      expect(await save('a1'), isNull);
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await BankAlerts.inbox(), hasLength(1));
    });

    test('a known shop is saved as the form would start it, and leaves',
        () async {
      await learnCaptureRule(db,
          householdId: 'h', shop: 'ABC Verdun', categoryId: 'food', accountId: null);
      await BankAlerts.restore(_alert('a1'));
      await BankAlerts.restore(_alert('a2'));
      final txId = await save('a1');
      expect(txId, isNotNull);
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txId!)))
          .getSingle();
      expect((tx.type, tx.note, tx.createdAt),
          ('expense', 'ABC Verdun', DateTime(2026, 10, 27, 9, 30)));
      final line = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.equals(txId!)))
          .getSingle();
      expect((line.amount, line.categoryId, line.accountId),
          (18.4, 'food', 'card'));
      expect([for (final i in await BankAlerts.inbox()) i.id], ['a2']);
    });
  });

  testWidgets('To review, one at a time: Skip says so, and Undo brings it back',
      (tester) async {
    await tester.runAsync(() async {
      await BankAlerts.restore(_alert('a1'));
    });
    final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    container.read(currentHouseholdIdProvider.notifier).set('h');
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const ReviewScreen(),
      ),
    ));
    await settle();
    expect(find.text('ABC Verdun'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await settle();
    expect(find.text('Dismissed'), findsOneWidget);
    expect(find.text('ABC Verdun'), findsNothing);
    await tester.tap(find.text('Undo'));
    await settle();
    expect(find.text('ABC Verdun'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
