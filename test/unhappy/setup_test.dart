// Unhappy-path tests for first run and setup order: a user who doesn't know
// what they're doing — empty names, steps out of order, double taps,
// deleting things that hold money, starting over.
//
// Each test asserts what SHOULD happen. A failing test is a candidate bug.
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/features/accounts/account_detail_screen.dart';
import 'package:budgetseal/features/allocations/allocation_detail_screen.dart';
import 'package:budgetseal/features/categories/categories_screen.dart';
import 'package:budgetseal/features/onboarding/onboarding_screen.dart';
import 'package:budgetseal/features/settings/settings_screen.dart';
import 'package:budgetseal/features/transactions/add_transaction_screen.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:budgetseal/shared/widgets/currency_picker_field.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

late AppDatabase db;
late ProviderContainer container;

/// A fresh, empty app (no household) — the very first run.
Future<void> freshApp() async {
  SharedPreferences.setMockInitialValues({});
  db = AppDatabase.forTesting(NativeDatabase.memory());
  container =
      ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
}

/// A household 'hh' in USD, nothing else.
Future<void> emptyBudget() async {
  await freshApp();
  container.read(currentHouseholdIdProvider.notifier).set('hh');
  await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: 'hh', name: 'Home', createdByDeviceId: 't'));
}

Future<void> addAccount(String id,
    {String currency = 'USD', double opening = 0, String? name}) =>
    db.into(db.accounts).insert(AccountsCompanion.insert(
        id: id, householdId: 'hh', name: name ?? id, type: 'cash',
        currency: currency, initialBalance: Value(opening), deviceId: 't'));

Future<void> addEnvelope(String id, {String? name}) =>
    db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: id, householdId: 'hh', name: name ?? id, categoryId: id,
        deviceId: 't'));

Future<void> addCategory(String id,
    {String? name, String? parentId, String? allocationId}) =>
    db.into(db.categories).insert(CategoriesCompanion.insert(
        id: id, householdId: 'hh', name: name ?? id,
        parentId: Value(parentId), allocationId: Value(allocationId),
        transactionType: const Value('expense')));

/// Per currency: accounts, envelopes, unallocated.
Future<Map<String, ({double accounts, double envelopes, double ready})>>
    money() async {
  final calc = BalanceCalculator(db);
  final accounts = await (db.select(db.accounts)
        ..where((a) => a.archived.equals(false) & a.deleted.equals(false)))
      .get();
  final bal = await calc.allAccountBalances('hh');
  final acc = <String, double>{};
  for (final a in accounts) {
    acc[a.currency] = (acc[a.currency] ?? 0) + (bal[a.id] ?? 0);
  }
  final env = <String, double>{};
  for (final m in (await calc.allAllocationBalancesByCurrency('hh')).values) {
    for (final e in m.entries) {
      env[e.key] = (env[e.key] ?? 0) + e.value;
    }
  }
  final ready = await calc.unallocatedByCurrency('hh');
  return {
    for (final c in {...acc.keys, ...env.keys, ...ready.keys})
      c: (
        accounts: acc[c] ?? 0,
        envelopes: env[c] ?? 0,
        ready: ready[c] ?? 0
      ),
  };
}

Future<void> expectInvariant() async {
  for (final e in (await money()).entries) {
    expect(e.value.accounts, closeTo(e.value.ready + e.value.envelopes, 0.001),
        reason: 'invariant broken for ${e.key}');
  }
}

/// Lets drift streams and futures run (they need real async).
Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps [page] pushed over a stub home, so `context.pop()` works.
Future<GoRouter> pumpPage(WidgetTester tester, Widget page,
    {Locale? locale}) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // The test font draws every glyph as a full square, so rows overflow
  // that fit on a phone: note overflows, don't fail on them.
  _origOnError ??= FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exceptionAsString().contains('overflowed')) {
      overflows.add(d.exceptionAsString());
      return;
    }
    _origOnError?.call(d);
  };
  addTearDown(_restoreOnError);
  final router = GoRouter(initialLocation: '/', routes: [
    GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('HOME'))),
    GoRoute(path: '/page', builder: (_, __) => page),
    GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen()),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
    ),
  ));
  await tester.pump();
  router.push('/page');
  await settle(tester);
  return router;
}

void Function(FlutterErrorDetails)? _origOnError;
void _restoreOnError() {
  if (_origOnError != null) FlutterError.onError = _origOnError;
  _origOnError = null;
}

Future<void> unmount(WidgetTester tester) async {
  _restoreOnError();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)));
}

/// No exception other than a layout overflow (cosmetic, depends on the
/// test font) — those are noted, not counted as a crash.
final overflows = <String>[];
void noCrash(WidgetTester tester) {
  Object? e;
  while ((e = tester.takeException()) != null) {
    if ('$e'.contains('overflowed')) {
      overflows.add('$e');
      continue;
    }
    fail('exception: $e');
  }
}

Future<void> tearDownDb() async {
  container.dispose();
  await db.close();
}

void main() {
  // ───────────────────────────── Onboarding ─────────────────────────────
  group('onboarding', () {
    setUp(freshApp);
    tearDown(tearDownDb);

    Future<void> toSetup(WidgetTester tester) async {
      await pumpPage(tester, const OnboardingScreen());
      await tester.tap(find.text('Get started'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> tapCreate(WidgetTester tester) async {
      final btn = find.text('Create my budget');
      await tester.ensureVisible(btn);
      await tester.pump();
      await tester.tap(btn);
    }

    testWidgets('Create with no household name: error, nothing written',
        (tester) async {
      await toSetup(tester);
      // Leave household name empty; also blank the account name.
      await tester.enterText(find.widgetWithText(TextField, 'Account name'),
          '   ');
      await tapCreate(tester);
      await settle(tester);
      noCrash(tester);
      expect(find.text('Enter a household name'), findsOneWidget);
      expect(find.text('Enter an account name'), findsOneWidget);
      await tester.runAsync(() async {
        expect(await db.select(db.households).get(), isEmpty);
        expect(await db.select(db.accounts).get(), isEmpty);
      });
      await unmount(tester);
    });

    testWidgets('Arabic + emoji names, whitespace around them: saved trimmed',
        (tester) async {
      await toSetup(tester);
      await tester.enterText(
          find.widgetWithText(TextField, 'Household name'), '  بيت 🏠  ');
      await tester.enterText(
          find.widgetWithText(TextField, 'Account name'), ' محفظة 💵 ');
      await tapCreate(tester);
      await settle(tester, rounds: 10);
      noCrash(tester);
      await tester.runAsync(() async {
        final hh = await db.select(db.households).get();
        expect(hh.map((h) => h.name), ['بيت 🏠']);
        final acc = await db.select(db.accounts).get();
        expect(acc.map((a) => a.name), ['محفظة 💵']);
        // Suggested categories + an envelope per main group, all linked.
        final cats = await db.select(db.categories).get();
        expect(cats, isNotEmpty);
        final envs = await db.select(db.allocations).get();
        expect(envs, isNotEmpty);
        for (final e in envs) {
          expect(cats.where((c) => c.allocationId == e.id), isNotEmpty,
              reason: 'envelope ${e.name} has no category');
        }
      });
      expect(find.text("You're all set!"), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('double-tapping Create makes one household', (tester) async {
      await toSetup(tester);
      await tester.enterText(
          find.widgetWithText(TextField, 'Household name'), 'Home');
      await tapCreate(tester);
      await tester.pump(const Duration(milliseconds: 40));
      // Second tap a moment later (the button may already be disabled).
      await tester.tap(find.text('Create my budget'), warnIfMissed: false);
      await settle(tester, rounds: 10);
      noCrash(tester);
      await tester.runAsync(() async {
        expect(await db.select(db.households).get(), hasLength(1));
        expect(await db.select(db.accounts).get(), hasLength(1));
      });
      await unmount(tester);
    });

    testWidgets('suggested categories off: no envelopes are made either',
        (tester) async {
      await toSetup(tester);
      await tester.enterText(
          find.widgetWithText(TextField, 'Household name'), 'Home');
      final seed = find.text('Add suggested categories');
      await tester.ensureVisible(seed);
      await tester.tap(seed);
      await tester.pump();
      await tapCreate(tester);
      await settle(tester, rounds: 10);
      await tester.runAsync(() async {
        expect(await db.select(db.categories).get(), isEmpty);
        expect(await db.select(db.allocations).get(), isEmpty);
        expect(await db.select(db.accounts).get(), hasLength(1));
      });
      await unmount(tester);
    });

    testWidgets('back from setup to welcome and in again keeps typed name',
        (tester) async {
      await toSetup(tester);
      await tester.enterText(
          find.widgetWithText(TextField, 'Household name'), 'Home');
      await tester.tap(find.byType(BackButtonIcon));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Get started'), findsOneWidget);
      await tester.tap(find.text('Get started'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Home'), findsOneWidget);
      await tester.runAsync(() async {
        expect(await db.select(db.households).get(), isEmpty);
      });
      await unmount(tester);
    });
  });

  // ─────────────────────── Before setup is done ───────────────────────
  group('adding money before setup', () {
    setUp(emptyBudget);
    tearDown(tearDownDb);

    testWidgets('an expense with no accounts at all: asks for an account',
        (tester) async {
      await pumpPage(
          tester,
          const AddTransactionScreen(editType: 'expense', editLines: [
            {'amount': 25.0, 'currency': 'USD'},
          ]));
      noCrash(tester);
      await tester.tap(find.text('Add transaction'));
      await settle(tester);
      noCrash(tester);
      expect(find.text('Select an account for the transaction'),
          findsOneWidget);
      await tester.runAsync(() async {
        expect(await db.select(db.transactions).get(), isEmpty);
      });
      await unmount(tester);
    });

    testWidgets('an expense with an account but no categories or envelopes',
        (tester) async {
      await tester.runAsync(() => addAccount('cash', opening: 10));
      await pumpPage(
          tester,
          const AddTransactionScreen(editType: 'expense', editLines: [
            {'amount': 25.0, 'currency': 'USD', 'accountId': 'cash'},
          ]));
      await tester.tap(find.text('Add transaction'));
      await settle(tester);
      noCrash(tester);
      await tester.runAsync(() async {
        final txs = await db.select(db.transactions).get();
        expect(txs, hasLength(1));
        final m = await money();
        expect(m['USD']!.accounts, closeTo(-15, 0.001));
        await expectInvariant();
      });
      await unmount(tester);
    });

    test('assigning money with no income: Ready to assign goes negative, '
        'invariant holds', () async {
      await addEnvelope('food');
      await AllocationEngine(db).fundAllocation(
          allocationId: 'food', amount: 50, currency: 'USD', deviceId: 't');
      final m = await money();
      expect(m['USD']!.ready, closeTo(-50, 0.001));
      await expectInvariant();
    });

    test('taking back more than an envelope holds is refused, nothing written',
        () async {
      await addAccount('cash', opening: 100);
      await addEnvelope('food');
      final engine = AllocationEngine(db);
      await engine.fundAllocation(
          allocationId: 'food', amount: 30, currency: 'USD', deviceId: 't');
      await expectLater(
          engine.withdrawFromAllocation(
              allocationId: 'food', amount: 31, currency: 'USD'),
          throwsStateError);
      await expectLater(
          engine.moveMoney(
              fromAllocationId: 'food', amount: 1e12, currency: 'USD'),
          throwsStateError);
      expect(await db.select(db.allocationLedger).get(), hasLength(1));
      await expectInvariant();
    });

    test('a huge amount (over a billion) is refused by the engine', () async {
      await addAccount('cash');
      await expectLater(
          AllocationEngine(db).recordTransaction(
              householdId: 'hh', accountId: 'cash', type: 'income',
              baseCurrency: 'USD',
              lines: const [
                TxLine(amount: 1e13, currency: 'USD', accountId: 'cash')
              ]),
          throwsArgumentError);
      expect(await db.select(db.transactions).get(), isEmpty);
    });
  });

  // ─────────────────────── Deleting what holds money ───────────────────────
  group('deleting things that hold money', () {
    setUp(emptyBudget);
    tearDown(tearDownDb);

    Future<void> openMenu(WidgetTester tester, String item) async {
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(item).last);
      await settle(tester);
    }

    testWidgets(
        'deleting the only account (opening balance, money already assigned) '
        'must not leave envelopes holding money that no account has',
        (tester) async {
      await tester.runAsync(() async {
        await addAccount('cash', opening: 500, name: 'Wallet');
        await addEnvelope('food', name: 'Food');
        await AllocationEngine(db).fundAllocation(
            allocationId: 'food', amount: 300, currency: 'USD',
            deviceId: 't');
      });
      await pumpPage(tester, const AccountDetailScreen(accountId: 'cash'));
      await openMenu(tester, 'Delete permanently');
      final dialogText = tester
          .widgetList<Text>(find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(Text)))
          .map((t) => t.data ?? '')
          .join(' | ');
      final confirm = find.text('Delete permanently');
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm);
        await settle(tester);
      }
      noCrash(tester);
      await tester.runAsync(() async {
        final acc = await (db.select(db.accounts)
              ..where((a) => a.id.equals('cash')))
            .getSingle();
        final m = await money();
        await expectInvariant();
        // Either the delete is stopped, or Ready to assign doesn't go
        // negative.
        expect(acc.deleted == false || m['USD']!.ready >= 0, isTrue,
            reason: 'Account with \$500 deleted without a word about its '
                'balance; Ready to assign is now ${m['USD']!.ready} while '
                'Food still holds ${m['USD']!.envelopes}. Dialog said: '
                '$dialogText');
      });
      await unmount(tester);
    });

    testWidgets('deleting an account with transactions (spent from an '
        'envelope): no crash, transactions gone, envelope debit gone',
        (tester) async {
      await tester.runAsync(() async {
        await addAccount('cash', name: 'Wallet');
        await addAccount('bank', name: 'Bank', opening: 1000);
        await addEnvelope('food', name: 'Food');
        await addCategory('groc', name: 'Groceries', allocationId: 'food');
        final e = AllocationEngine(db);
        await e.recordTransaction(
            householdId: 'hh', accountId: 'cash', type: 'income',
            baseCurrency: 'USD',
            lines: const [
              TxLine(amount: 100, currency: 'USD', accountId: 'cash')
            ]);
        await e.fundAllocation(
            allocationId: 'food', amount: 60, currency: 'USD', deviceId: 't');
        await e.recordTransaction(
            householdId: 'hh', accountId: 'cash', type: 'expense',
            baseCurrency: 'USD',
            lines: const [
              TxLine(amount: 40, currency: 'USD', accountId: 'cash',
                  categoryId: 'groc')
            ]);
        await e.recordTransfer(
            householdId: 'hh', fromAccountId: 'bank', toAccountId: 'cash',
            amount: 10, currency: 'USD', exchangeRateToBase: 1,
            createdBy: 't', deviceId: 't');
      });
      await pumpPage(tester, const AccountDetailScreen(accountId: 'cash'));
      await openMenu(tester, 'Delete permanently');
      await tester.tap(find.text('Delete with transactions'));
      await settle(tester);
      expect(find.textContaining('shared with other accounts'), findsOneWidget);
      await tester.tap(find.text('Delete permanently'));
      await settle(tester);
      noCrash(tester);
      expect(find.text('HOME'), findsOneWidget);
      await tester.runAsync(() async {
        final live = await (db.select(db.transactions)
              ..where((t) => t.deleted.equals(false)))
            .get();
        expect(live, isEmpty);
        final m = await money();
        expect(m['USD']!.accounts, closeTo(1000, 0.001));
        expect(m['USD']!.envelopes, closeTo(60, 0.001));
        await expectInvariant();
      });
      await unmount(tester);
    });

    testWidgets(
        "changing an account's currency after it has transactions must not "
        'turn dollars into euros', (tester) async {
      await tester.runAsync(() async {
        await addAccount('cash', name: 'Wallet', opening: 100);
        await AllocationEngine(db).recordTransaction(
            householdId: 'hh', accountId: 'cash', type: 'expense',
            baseCurrency: 'USD',
            lines: const [
              TxLine(amount: 30, currency: 'USD', accountId: 'cash')
            ]);
      });
      await pumpPage(tester, const AccountDetailScreen(accountId: 'cash'));
      await tester.tap(find.text('Account settings'));
      await settle(tester);
      final picker =
          tester.widget<CurrencyPickerField>(find.byType(CurrencyPickerField));
      picker.onChanged('EUR');
      await tester.pump();
      final save = find.text('Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await settle(tester);
      noCrash(tester);
      await tester.runAsync(() async {
        final m = await money();
        expect(m['USD']?.accounts ?? 0, closeTo(70, 0.001),
            reason: 'the \$70 left in the account became '
                '${m['EUR']?.accounts} EUR');
        final lines = await db.select(db.transactionLines).get();
        final acc = await (db.select(db.accounts)
              ..where((a) => a.id.equals('cash')))
            .getSingle();
        expect(lines.every((l) => l.currency == acc.currency), isTrue,
            reason: 'account is ${acc.currency} but its lines are '
                '${lines.map((l) => l.currency).toSet()}');
      });
      await unmount(tester);
    });

    testWidgets('renaming an envelope to an empty name tells the user why',
        (tester) async {
      await tester.runAsync(() => addEnvelope('food', name: 'Food'));
      await pumpPage(
          tester, const AllocationDetailScreen(allocationId: 'food'));
      await openMenu(tester, 'Edit settings');
      final name = find.widgetWithText(TextField, 'Food');
      expect(name, findsOneWidget);
      await tester.enterText(name, '   ');
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await settle(tester);
      noCrash(tester);
      await tester.runAsync(() async {
        final a = await (db.select(db.allocations)
              ..where((a) => a.id.equals('food')))
            .getSingle();
        expect(a.name, 'Food');
      });
      final feedback = find.byType(SnackBar).evaluate().isNotEmpty ||
          tester
              .widgetList<TextField>(find.byType(TextField))
              .any((t) => t.decoration?.errorText != null);
      expect(feedback, isTrue,
          reason: 'Save changes with an empty name does nothing at all');
      await unmount(tester);
    });

    testWidgets('deleting an envelope that holds money returns it to Ready '
        'to assign', (tester) async {
      await tester.runAsync(() async {
        await addAccount('cash', opening: 200);
        await addEnvelope('food', name: 'Food');
        await AllocationEngine(db).fundAllocation(
            allocationId: 'food', amount: 80, currency: 'USD', deviceId: 't');
      });
      await pumpPage(
          tester, const AllocationDetailScreen(allocationId: 'food'));
      await openMenu(tester, 'Delete');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);
      noCrash(tester);
      await tester.runAsync(() async {
        final m = await money();
        expect(m['USD']!.ready, closeTo(200, 0.001));
        expect(m['USD']!.envelopes, closeTo(0, 0.001));
        await expectInvariant();
      });
      await unmount(tester);
    });
  });

  // ─────────────────────────── Categories ───────────────────────────
  group('categories', () {
    setUp(emptyBudget);
    tearDown(tearDownDb);

    Future<void> seedCats(WidgetTester tester) => tester.runAsync(() async {
          await addCategory('food', name: 'Food');
          await addCategory('groc', name: 'Groceries', parentId: 'food');
          await addCategory('trans', name: 'Transport');
        });

    testWidgets('deleting a group keeps its subcategories reachable',
        (tester) async {
      await seedCats(tester);
      await pumpPage(tester, const CategoriesScreen());
      expect(find.text('Groceries'), findsOneWidget);
      await tester.longPress(find.text('Food'));
      await settle(tester);
      await tester.tap(find.text('Delete').last);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);
      noCrash(tester);
      final groc = await tester.runAsync(() => (db.select(db.categories)
            ..where((c) => c.id.equals('groc')))
          .getSingle());
      expect(find.text('Groceries'), findsOneWidget,
          reason: 'Groceries (deleted=${groc!.deleted}, its parent '
              '${groc.parentId} is deleted) is no longer listed, so it '
              "can't be edited or deleted");
      await unmount(tester);
    });

    testWidgets('making a group a subcategory of another group keeps its '
        'subcategories listed', (tester) async {
      await seedCats(tester);
      await pumpPage(tester, const CategoriesScreen());
      await tester.longPress(find.text('Food'));
      await settle(tester);
      await tester.tap(find.text('Edit'));
      await settle(tester);
      await tester.tap(find.text('None').first);
      await settle(tester);
      await tester.tap(find.text('Transport').last);
      await settle(tester);
      final save = find.text('Save');
      await tester.ensureVisible(save.last);
      await tester.tap(save.last);
      await settle(tester);
      noCrash(tester);
      final food = await tester.runAsync(() => (db.select(db.categories)
            ..where((c) => c.id.equals('food')))
          .getSingle());
      expect(food!.parentId, 'trans');
      expect(find.text('Groceries'), findsOneWidget,
          reason: 'Food became a subcategory of Transport; its own '
              'subcategory Groceries is now a grandchild and is not shown');
      await unmount(tester);
    });

    testWidgets('a category with an empty name is refused with a message',
        (tester) async {
      await seedCats(tester);
      await pumpPage(tester, const CategoriesScreen());
      await tester.longPress(find.text('Transport'));
      await settle(tester);
      await tester.tap(find.text('Edit'));
      await settle(tester);
      await tester.enterText(
          find.widgetWithText(TextField, 'Transport'), '   ');
      final save = find.text('Save');
      await tester.ensureVisible(save.last);
      await tester.tap(save.last);
      await settle(tester);
      expect(find.text('Enter a category name'), findsOneWidget);
      final t = await tester.runAsync(() => (db.select(db.categories)
            ..where((c) => c.id.equals('trans')))
          .getSingle());
      expect(t!.name, 'Transport');
      await unmount(tester);
    });
  });

  // ─────────────────────────── Start over ───────────────────────────
  group('reset everything', () {
    setUp(emptyBudget);
    tearDown(tearDownDb);

    testWidgets('Reset everything, then onboarding again: only the new budget',
        (tester) async {
      await tester.runAsync(() async {
        await addAccount('cash', opening: 100, name: 'Old wallet');
        await addEnvelope('food', name: 'Old food');
        await AllocationEngine(db).fundAllocation(
            allocationId: 'food', amount: 50, currency: 'USD', deviceId: 't');
        // Sync bookkeeping from the old budget.
        await db.customStatement(
            "INSERT OR REPLACE INTO sync_files (name, version) VALUES ('log-x-00000.json', 'v1')");
        await db.customStatement(
            "INSERT OR REPLACE INTO sync_meta (key, value) VALUES ('snapshot_entries', '9999')");
      });
      final router = await pumpPage(tester, const SettingsDetailScreen());
      noCrash(tester);
      final reset = find.text('Reset everything', findRichText: true);
      await tester.scrollUntilVisible(reset, 400,
          scrollable: find.byType(Scrollable).first, maxScrolls: 200);
      await tester.tap(reset);
      await settle(tester);
      await tester.tap(find.text('Delete everything'));
      await settle(tester, rounds: 10);
      noCrash(tester);
      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/onboarding');
      expect(container.read(currentHouseholdIdProvider), isNull);
      await tester.runAsync(() async {
        for (final t in ['households', 'accounts', 'allocations',
            'allocation_ledger', 'transactions', 'categories']) {
          final n = (await db.customSelect('SELECT COUNT(*) AS n FROM $t')
                  .getSingle())
              .read<int>('n');
          expect(n, 0, reason: '$t not emptied');
        }
      });
      // Start again.
      await tester.tap(find.text('Get started'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.enterText(
          find.widgetWithText(TextField, 'Household name'), 'New home');
      final create = find.ancestor(
          of: find.text('Create my budget'),
          matching: find.byType(FilledButton));
      await tester.ensureVisible(create);
      await tester.pump();
      tester.widget<FilledButton>(create).onPressed!();
      await settle(tester, rounds: 10);
      noCrash(tester);
      await tester.runAsync(() async {
        final hh = await db.select(db.households).get();
        expect(hh.map((h) => h.name), ['New home']);
        expect(container.read(currentHouseholdIdProvider), hh.single.id);
        final acc = await db.select(db.accounts).get();
        expect(acc, hasLength(1));
        final calc = BalanceCalculator(db);
        final ready = await calc.unallocatedByCurrency(hh.single.id);
        expect(ready.values.every((v) => v.abs() < 0.001), isTrue,
            reason: 'new budget starts with $ready');
        // The old budget's sync bookkeeping should be gone too, or a sync
        // set up for the new budget believes it already read/wrote files.
        final files = await db.customSelect('SELECT * FROM sync_files').get();
        final meta = await db.customSelect('SELECT * FROM sync_meta').get();
        expect(files.length + meta.length, 0,
            reason: 'sync_files: ${files.map((r) => r.data)}, '
                'sync_meta: ${meta.map((r) => r.data)} survived the reset');
      });
      await unmount(tester);
    });
  });
}
