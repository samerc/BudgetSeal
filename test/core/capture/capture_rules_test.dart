import 'package:budgetseal/core/capture/capture_rules.dart';
import 'package:budgetseal/core/capture/share_intake.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:budgetseal/core/sync/log_sync.dart';
import 'package:budgetseal/features/settings/rules_screen.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sync/log_sync_test.dart' show MemoryStore;

Future<AppDatabase> _phone(String id) async {
  DeviceIdentity.debugSet(id);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.customSelect('SELECT 1').get();
  addTearDown(db.close);
  await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: 'h', name: 'Home', createdByDeviceId: 't'));
  for (final (id, cur) in [('cash', 'USD'), ('visa', 'USD')]) {
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: id,
        householdId: 'h',
        name: id,
        type: 'cash',
        currency: cur,
        deviceId: 't'));
  }
  for (final id in ['food', 'fuel']) {
    await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(id: id, householdId: 'h', name: id));
  }
  return db;
}

Future<void> _userRule(AppDatabase db, String match,
        {String? category, String? account, String? title}) =>
    db.into(db.captureRules).insert(CaptureRulesCompanion.insert(
        id: match,
        householdId: 'h',
        match: match,
        categoryId: Value(category),
        accountId: Value(account),
        title: Value(title)));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() => DeviceIdentity.debugSet('local'));

  test('the longest rule found in the text wins, whatever the case', () async {
    final db = await _phone('a');
    await _userRule(db, 'spinneys', category: 'food');
    await _userRule(db, 'Spinneys Achrafieh', category: 'fuel');
    expect((await findCaptureRule(db, 'h', 'SPINNEYS ACHRAFIEH 27/10'))!.match,
        'Spinneys Achrafieh');
    expect(
        (await findCaptureRule(db, 'h', 'spinneys dbayeh'))!.match, 'spinneys');
    expect(await findCaptureRule(db, 'h', 'Carrefour'), isNull);
  });

  test(
      'learning: a new shop becomes a learned rule; a learned rule follows '
      'the latest choice; a rule the user made is only counted', () async {
    final db = await _phone('a');
    await learnCaptureRule(db,
        householdId: 'h',
        shop: ' ABC  Verdun ',
        categoryId: 'food',
        accountId: 'cash');
    var r = (await db.select(db.captureRules).get()).single;
    expect((r.match, r.categoryId, r.learned, r.uses),
        ('abc verdun', 'food', true, 1));
    await learnCaptureRule(db,
        householdId: 'h',
        shop: 'abc verdun',
        categoryId: 'fuel',
        accountId: 'visa');
    r = (await db.select(db.captureRules).get()).single;
    expect((r.categoryId, r.accountId, r.uses), ('fuel', 'visa', 2));

    await _userRule(db, 'total', category: 'fuel');
    await learnCaptureRule(db,
        householdId: 'h', shop: 'Total', categoryId: 'food', accountId: null);
    final user = await (db.select(db.captureRules)
          ..where((x) => x.id.equals('total')))
        .getSingle();
    expect((user.categoryId, user.uses), ('fuel', 1));
    // No category: nothing to learn.
    await learnCaptureRule(db,
        householdId: 'h', shop: 'Somewhere', categoryId: null, accountId: null);
    expect(await db.select(db.captureRules).get(), hasLength(2));
  });

  test('a shared payment gets the rule: category, account and title', () async {
    final db = await _phone('a');
    await _userRule(db, 'spinneys',
        category: 'food', account: 'visa', title: 'Spinneys');
    final extra = await shareFormArgs(
        const SharedItem('Purchase of USD 32.10 at SPINNEYS ACHRAFIEH', []),
        db: db,
        householdId: 'h',
        baseCurrency: 'USD');
    expect(extra!['editNote'], 'Spinneys');
    expect(extra['captureShop'], 'SPINNEYS ACHRAFIEH');
    final line = (extra['editLines'] as List).single as Map;
    expect((line['categoryId'], line['accountId']), ('food', 'visa'));
  });

  test('rules reach the other phone', () async {
    final store = MemoryStore();
    final a = await _phone('phone-a');
    await LogSync(a).sync(store);
    DeviceIdentity.debugSet('phone-b');
    final b = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(b.close);
    await LogSync(b).replaceFrom(store);
    await learnCaptureRule(a,
        householdId: 'h',
        shop: 'ABC Verdun',
        categoryId: 'food',
        accountId: null);
    await LogSync(a).sync(store);
    await LogSync(b).sync(store);
    expect((await findCaptureRule(b, 'h', 'abc verdun'))?.categoryId, 'food');
  });

  group('screen', () {
    late AppDatabase db;
    setUp(() async {
      db = await _phone('a');
      await _userRule(db, 'spinneys', category: 'food', title: 'Spinneys');
    });

    testWidgets('the Rules screen lists them', (tester) async {
      final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      addTearDown(container.dispose);
      container.read(currentHouseholdIdProvider.notifier).set('h');
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: const RulesScreen(),
        ),
      ));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.text('“spinneys”'), findsOneWidget);
      expect(find.textContaining('Spinneys · food'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      // The list's database stream closes on a timer.
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
    });
  });
}
