// Unhappy-path tests for the add/edit transaction forms, the calculator
// sheet and the AllocationEngine calls behind them: a user who types
// garbage, does steps out of order, double-taps, backs out halfway or edits
// something that was deleted meanwhile.
//
// Every test asserts what SHOULD happen. A failing test is a candidate bug.

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/features/transactions/add_transaction_screen.dart';
import 'package:budgetseal/features/transactions/quick_add_screen.dart';
import 'package:budgetseal/features/transactions/widgets/delete_with_undo.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:budgetseal/shared/theme/app_icons.dart';
import 'package:budgetseal/shared/utils/format_number.dart';
import 'package:budgetseal/shared/utils/search_match.dart';
import 'package:budgetseal/shared/widgets/calculator_amount_field.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const hh = 'hh';

/// Household (base USD), accounts, one envelope linked to "food" with $200.
Future<void> seed(AppDatabase db) async {
  await db.into(db.households).insert(
      HouseholdsCompanion.insert(id: hh, name: 'Home', createdByDeviceId: 't'));
  for (final (id, name, cur, bal) in [
    ('bank', 'Bank', 'USD', 1000.0),
    ('cash', 'Cash', 'USD', 100.0),
    ('lbp', 'Lira', 'LBP', 50000000.0),
    ('lbp2', 'Lira bank', 'LBP', 0.0),
  ]) {
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: id,
        householdId: hh,
        name: name,
        type: 'cash',
        currency: cur,
        initialBalance: Value(bal),
        deviceId: 't'));
  }
  await db.into(db.allocations).insert(AllocationsCompanion.insert(
      id: 'env-food',
      householdId: hh,
      name: 'Food',
      categoryId: 'food',
      deviceId: 't'));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: 'food',
      householdId: hh,
      name: 'Food',
      transactionType: const Value('expense'),
      allocationId: const Value('env-food')));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: 'salary',
      householdId: hh,
      name: 'Salary',
      transactionType: const Value('income')));
  await AllocationEngine(db).fundAllocation(
      allocationId: 'env-food', amount: 200, currency: 'USD', deviceId: 't');
}

/// Sum(accounts) = Unallocated + Sum(envelopes), and Unallocated is what
/// it should be ([expectedUnallocated], per currency).
Future<void> expectBalanced(AppDatabase db,
    {Map<String, double>? expectedUnallocated,
    Map<String, double>? expectedAccounts,
    Map<String, double>? expectedFood}) async {
  final calc = BalanceCalculator(db);
  final accts = await calc.allAccountBalances(hh);
  final env = await calc.allAllocationBalancesByCurrency(hh);
  final unalloc = await calc.unallocatedByCurrency(hh);
  final accounts = await db.select(db.accounts).get();
  final byCur = <String, double>{};
  for (final a in accounts) {
    byCur[a.currency] = (byCur[a.currency] ?? 0) + (accts[a.id] ?? 0);
  }
  final envByCur = <String, double>{};
  for (final m in env.values) {
    m.forEach((c, v) => envByCur[c] = (envByCur[c] ?? 0) + v);
  }
  for (final c in {...byCur.keys, ...envByCur.keys}) {
    expect((byCur[c] ?? 0), closeTo((unalloc[c] ?? 0) + (envByCur[c] ?? 0), 0.005),
        reason: 'invariant broken in $c');
  }
  expectedUnallocated?.forEach((c, v) =>
      expect(unalloc[c] ?? 0, closeTo(v, 0.005), reason: 'unallocated $c'));
  expectedAccounts?.forEach((id, v) =>
      expect(accts[id] ?? 0, closeTo(v, 0.005), reason: 'account $id'));
  expectedFood?.forEach((c, v) => expect(env['env-food']?[c] ?? 0,
      closeTo(v, 0.005), reason: 'food envelope $c'));
}

Future<List<Transaction>> liveTxs(AppDatabase db) =>
    (db.select(db.transactions)..where((t) => t.deleted.equals(false))).get();

void main() {
  // ════════════════════════════════════════════════════════════════════
  // parseLooseAmount / search amounts (typed or pasted text)
  // ════════════════════════════════════════════════════════════════════
  group('parseLooseAmount with what users type or paste', () {
    test('US grouping', () => expect(parseLooseAmount('1,234.56'), 1234.56));
    test('European grouping',
        () => expect(parseLooseAmount('1.234,56'), 1234.56));
    test('currency symbol', () => expect(parseLooseAmount(r'$12'), 12));
    test('blank is no amount', () => expect(parseLooseAmount(' '), isNull));
    test('leading zeros', () => expect(parseLooseAmount('00012'), 12));
    test('Arabic-Indic digits (an Arabic keyboard) are read', () {
      expect(parseLooseAmount('١٢٣'), 123);
      expect(parseLooseAmount('١٢٫٥'), 12.5); // Arabic decimal separator
    });
    test('Persian digits are read',
        () => expect(parseLooseAmount('۱۲۳'), 123));
    test('"1..2" is not silently read as 12', () {
      expect(parseLooseAmount('1..2'), isNot(12));
    });
  });

  group('Activity search amount terms', () {
    test('">1,000" means more than a thousand (as parseLooseAmount reads it)',
        () {
      final q = SearchQuery.parse('>1,000');
      expect(q.amounts, hasLength(1));
      expect(q.amounts.single.value, 1000);
    });
    test('">1,000,000" is an amount condition, not a word', () {
      final q = SearchQuery.parse('>1,000,000');
      expect(q.words, isEmpty);
      expect(q.amounts.single.value, 1000000);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Engine: edits, type changes, deleted rows
  // ════════════════════════════════════════════════════════════════════
  group('engine', () {
    late AppDatabase db;
    late AllocationEngine engine;
    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      engine = AllocationEngine(db);
      await seed(db);
    });
    tearDown(() => db.close());

    Future<String> spend(double amount, {String account = 'bank'}) async =>
        engine.recordTransaction(
          householdId: hh,
          accountId: account,
          type: 'expense',
          lines: [
            TxLine(
                amount: amount,
                currency: 'USD',
                categoryId: 'food',
                accountId: account)
          ],
          baseCurrency: 'USD',
          note: 'Lunch',
        );

    test('editing a transaction that was deleted meanwhile fails and does '
        'not bring it back or move money', () async {
      final id = await spend(30);
      await engine.deleteTransaction(id);
      await expectLater(
        engine.recordTransaction(
          householdId: hh,
          accountId: 'bank',
          type: 'expense',
          lines: const [
            TxLine(
                amount: 50,
                currency: 'USD',
                categoryId: 'food',
                accountId: 'bank')
          ],
          baseCurrency: 'USD',
          editing: id,
        ),
        throwsA(anything),
      );
      expect(await liveTxs(db), isEmpty);
      await expectBalanced(db,
          expectedAccounts: {'bank': 1000}, expectedFood: {'USD': 200});
    });

    test('editing a deleted transaction into a transfer fails and does not '
        'bring it back', () async {
      final id = await spend(30);
      await engine.deleteTransaction(id);
      await expectLater(
        engine.recordTransfer(
            householdId: hh,
            fromAccountId: 'bank',
            toAccountId: 'cash',
            amount: 30,
            currency: 'USD',
            exchangeRateToBase: 1,
            createdBy: 'user',
            deviceId: 'local',
            editing: id),
        throwsA(anything),
      );
      expect(await liveTxs(db), isEmpty);
      await expectBalanced(db, expectedAccounts: {'bank': 1000, 'cash': 100});
    });

    test('expense → transfer → income → expense keeps one transaction and '
        'the right balances at each step', () async {
      final id = await spend(40);
      await expectBalanced(db,
          expectedAccounts: {'bank': 960}, expectedFood: {'USD': 160});

      await engine.recordTransfer(
          householdId: hh,
          fromAccountId: 'bank',
          toAccountId: 'cash',
          amount: 40,
          currency: 'USD',
          exchangeRateToBase: 1,
          createdBy: 'user',
          deviceId: 'local',
          editing: id);
      await expectBalanced(db,
          expectedAccounts: {'bank': 960, 'cash': 140},
          expectedFood: {'USD': 200},
          expectedUnallocated: {'USD': 900});

      await engine.recordTransaction(
          householdId: hh,
          accountId: 'bank',
          type: 'income',
          lines: const [
            TxLine(
                amount: 40,
                currency: 'USD',
                categoryId: 'salary',
                accountId: 'bank')
          ],
          baseCurrency: 'USD',
          editing: id);
      await expectBalanced(db,
          expectedAccounts: {'bank': 1040, 'cash': 100},
          expectedFood: {'USD': 200},
          expectedUnallocated: {'USD': 940});
      final tx = (await liveTxs(db)).single;
      expect(tx.destinationAccountId, isNull);
      expect(tx.destinationAmount, isNull);

      await engine.recordTransaction(
          householdId: hh,
          accountId: 'bank',
          type: 'expense',
          lines: const [
            TxLine(
                amount: 40,
                currency: 'USD',
                categoryId: 'food',
                accountId: 'bank')
          ],
          baseCurrency: 'USD',
          editing: id);
      await expectBalanced(db,
          expectedAccounts: {'bank': 960, 'cash': 100},
          expectedFood: {'USD': 160});
      expect(await liveTxs(db), hasLength(1));
      final ledger = await db.select(db.allocationLedger).get();
      expect(ledger.where((l) => l.entryType == 'consumption'), hasLength(1));
    });

    test('a split with a zero line saves only the real money', () async {
      await engine.recordTransaction(
          householdId: hh,
          accountId: 'bank',
          type: 'expense',
          lines: const [
            TxLine(
                amount: 25,
                currency: 'USD',
                categoryId: 'food',
                accountId: 'bank'),
            TxLine(amount: 0, currency: 'USD', accountId: 'bank'),
          ],
          baseCurrency: 'USD');
      await expectBalanced(db,
          expectedAccounts: {'bank': 975}, expectedFood: {'USD': 175});
    });

    test('a date 50 years ahead or in 1970 keeps balances right', () async {
      await engine.recordTransaction(
          householdId: hh,
          accountId: 'bank',
          type: 'expense',
          lines: const [
            TxLine(
                amount: 10,
                currency: 'USD',
                categoryId: 'food',
                accountId: 'bank')
          ],
          baseCurrency: 'USD',
          date: DateTime(2076, 1, 1));
      await engine.recordTransaction(
          householdId: hh,
          accountId: 'bank',
          type: 'expense',
          lines: const [
            TxLine(
                amount: 10,
                currency: 'USD',
                categoryId: 'food',
                accountId: 'bank')
          ],
          baseCurrency: 'USD',
          date: DateTime(1970, 1, 1));
      await expectBalanced(db,
          expectedAccounts: {'bank': 980}, expectedFood: {'USD': 180});
    });

    test('a 1.5 billion LBP purchase (≈ \$17k: a car) can be recorded',
        () async {
      await db.into(db.fxRates).insert(FxRatesCompanion.insert(
          id: 'fx', fromCurrency: 'USD', toCurrency: 'LBP', rate: 89500,
          source: const Value('manual')));
      await engine.recordTransaction(
          householdId: hh,
          accountId: 'lbp',
          type: 'expense',
          lines: const [
            TxLine(
                amount: 1500000000,
                currency: 'LBP',
                accountId: 'lbp',
                exchangeRateToBase: 1 / 89500)
          ],
          baseCurrency: 'USD');
      await expectBalanced(db, expectedAccounts: {'lbp': 50000000 - 1500000000});
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Widgets
  // ════════════════════════════════════════════════════════════════════
  group('screens', () {
    late AppDatabase db;
    late ProviderContainer container;
    final overflows = <String>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container =
          ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
      container.read(currentHouseholdIdProvider.notifier).set(hh);
      await seed(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> settle(WidgetTester tester, [int rounds = 8]) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> open(WidgetTester tester, Widget screen) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final old = FlutterError.onError;
      // The test font (Ahem: every glyph 1 em wide) overflows rows that
      // fit with real fonts; layout overflows are noted, not failures.
      FlutterError.onError = (d) {
        if ('${d.exception}'.contains('overflowed')) {
          overflows.add('${d.exception}');
          return;
        }
        old!(d);
      };
      addTearDown(() => FlutterError.onError = old);
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/add'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(path: '/add', builder: (_, __) => screen),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      ));
      await settle(tester, 3);
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(tester.takeException(), isNull);
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
    }

    Future<T> q<T>(WidgetTester tester, Future<T> Function() f) async =>
        (await tester.runAsync(f)) as T;

    // ── Calculator sheet ──────────────────────────────────────────────
    Future<void> openCalc(WidgetTester tester, double initial,
        void Function(double?) onResult) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  onResult(await showCalculatorSheet(context, initial)),
              child: const Text('calc'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('calc'));
      await tester.pumpAndSettle();
    }

    Future<void> keys(WidgetTester tester, String seq) async {
      for (final k in seq.split('')) {
        await tester.tap(k == '⌫'
            ? find.byIcon(AppIcons.backspace).last
            : find.text(k).last);
        await tester.pump();
      }
    }

    testWidgets('calculator: one backspace after "12+5" leaves "12+", not '
        'nothing', (tester) async {
      double? result = -1;
      await openCalc(tester, 0, (v) => result = v);
      await keys(tester, '12+5');
      await keys(tester, '⌫');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, 12);
    });

    testWidgets('calculator: "5+" then Done gives 5', (tester) async {
      double? result = -1;
      await openCalc(tester, 0, (v) => result = v);
      await keys(tester, '5+');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, 5);
    });

    testWidgets('calculator: "1..2" gives 1.2 (second dot ignored)',
        (tester) async {
      double? result = -1;
      await openCalc(tester, 0, (v) => result = v);
      await keys(tester, '1..2');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, 1.2);
    });

    testWidgets('calculator: "00012" gives 12', (tester) async {
      double? result = -1;
      await openCalc(tester, 0, (v) => result = v);
      await keys(tester, '00012');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, 12);
    });

    testWidgets('calculator: Done is disabled at 0 and after "5-9" (negative)',
        (tester) async {
      double? result = -1;
      await openCalc(tester, 0, (v) => result = v);
      expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'))
              .onPressed,
          isNull);
      await keys(tester, '5-9');
      expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'))
              .onPressed,
          isNull);
      expect(result, -1);
    });

    testWidgets('calculator: a 3-decimal amount (KWD 1.125) + 1 is 2.125',
        (tester) async {
      double? result = -1;
      await openCalc(tester, 1.125, (v) => result = v);
      await keys(tester, '+1');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, closeTo(2.125, 1e-9));
    });

    testWidgets('calculator: a 16-digit number survives pressing +',
        (tester) async {
      double? result = -1;
      await openCalc(tester, 0, (v) => result = v);
      await keys(tester, '12345678901234567890+');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, closeTo(12345678901234567890.0, 1e6));
    });

    // ── One-screen add ────────────────────────────────────────────────
    Future<void> tapKeys(WidgetTester tester, String seq) async {
      for (final k in seq.split('')) {
        final f = k == '.' ? find.text('.') : find.text(k);
        await tester.tap(f.last, warnIfMissed: false);
        await tester.pump();
      }
    }

    Finder saveButton() => find.byType(FilledButton).last;

    testWidgets('quick add: Save at amount 0 does nothing', (tester) async {
      await open(tester, const QuickAddScreen());
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
      await tester.tap(saveButton(), warnIfMissed: false);
      await settle(tester);
      expect(await q(tester, () => liveTxs(db)), isEmpty);
      await finish(tester);
    });

    testWidgets('quick add: double-tapping Save records one expense',
        (tester) async {
      await open(tester, const QuickAddScreen());
      await tapKeys(tester, '25');
      await tester.tap(saveButton());
      await tester.tap(saveButton(), warnIfMissed: false);
      await settle(tester, 12);
      final txs = await q(tester, () => liveTxs(db));
      expect(txs, hasLength(1));
      await finish(tester);
    });

    testWidgets('quick add: "10÷3" saves a real money amount (3.33), not '
        '3.3333…', (tester) async {
      await open(tester, const QuickAddScreen());
      await tapKeys(tester, '10÷3');
      await tester.tap(saveButton());
      await settle(tester, 12);
      final lines = await q(tester, () => db.select(db.transactionLines).get());
      expect(lines, hasLength(1));
      expect(lines.single.amount, 3.33);
      await finish(tester);
    });

    testWidgets('quick add: "50÷0" is not saved as 50 without a word',
        (tester) async {
      await open(tester, const QuickAddScreen());
      await tapKeys(tester, '50÷0');
      // Either Save is off, or it doesn't claim the amount is $50.
      final btn = tester.widget<FilledButton>(saveButton());
      expect(btn.onPressed == null || find.textContaining(r'$50').evaluate().isEmpty,
          isTrue,
          reason: 'dividing by zero quietly becomes \$50');
      await finish(tester);
    });

    testWidgets('quick add: an LBP amount over 1 billion gets a clear '
        'message (or saves), not "Something went wrong"', (tester) async {
      await tester.runAsync(() => db.into(db.fxRates).insert(
          FxRatesCompanion.insert(
              id: 'fx', fromCurrency: 'USD', toCurrency: 'LBP', rate: 89500,
              source: const Value('manual'))));
      await open(
          tester,
          const QuickAddScreen(editLines: [
            {'amount': 1500000000.0, 'currency': 'LBP', 'accountId': 'lbp'}
          ]));
      await tester.tap(saveButton());
      await settle(tester, 12);
      final saved = (await q(tester, () => liveTxs(db))).isNotEmpty;
      expect(
          saved || find.text('Something went wrong').evaluate().isEmpty, isTrue,
          reason: 'LBP 1,500,000,000 (≈ \$17k) is refused with a generic error');
      await finish(tester);
    });

    testWidgets('quick add: a transfer to the same account is refused with a '
        'message', (tester) async {
      await open(
          tester,
          const QuickAddScreen(
            initialType: 'transfer',
            editFromAccountId: 'bank',
            editDestAccountId: 'bank',
            editLines: [
              {'amount': 20.0, 'currency': 'USD'}
            ],
          ));
      await tester.tap(saveButton());
      await settle(tester);
      expect(await q(tester, () => liveTxs(db)), isEmpty);
      expect(find.byType(SnackBar), findsOneWidget);
      await finish(tester);
    });

    testWidgets('quick add: a USD→LBP transfer with no rate is not saved 1:1',
        (tester) async {
      await open(
          tester,
          const QuickAddScreen(
            initialType: 'transfer',
            editFromAccountId: 'bank',
            editDestAccountId: 'lbp',
            editLines: [
              {'amount': 20.0, 'currency': 'USD'}
            ],
          ));
      await tester.tap(saveButton());
      await settle(tester);
      final txs = await q(tester, () => liveTxs(db));
      for (final t in txs) {
        expect(t.destinationAmount, isNot(closeTo(20, 0.01)),
            reason: '\$20 arrived as LBP 20');
      }
      await finish(tester);
    });

    testWidgets('quick add: editing a transaction deleted meanwhile does not '
        'bring it back and says why', (tester) async {
      final id = await q(tester, () async {
        final e = AllocationEngine(db);
        final id = await e.recordTransaction(
            householdId: hh,
            accountId: 'bank',
            type: 'expense',
            lines: const [
              TxLine(
                  amount: 30,
                  currency: 'USD',
                  categoryId: 'food',
                  accountId: 'bank')
            ],
            baseCurrency: 'USD');
        return id;
      });
      await open(
          tester,
          QuickAddScreen(
            editTransactionId: id,
            editLines: const [
              {
                'amount': 30.0,
                'currency': 'USD',
                'accountId': 'bank',
                'categoryId': 'food'
              }
            ],
          ));
      // Deleted on another screen / phone while the form is open.
      await tester.runAsync(() => AllocationEngine(db).deleteTransaction(id));
      await tapKeys(tester, '5');
      await tester.tap(saveButton());
      await settle(tester);
      expect(await q(tester, () => liveTxs(db)), isEmpty);
      await tester.runAsync(() => expectBalanced(db,
          expectedAccounts: {'bank': 1000}, expectedFood: {'USD': 200}));
      expect(find.byType(SnackBar), findsOneWidget);
      await finish(tester);
    });

    testWidgets('quick add: edit an expense, switch to Transfer, save — the '
        'envelope gets its money back', (tester) async {
      final id = await q(tester, () => AllocationEngine(db).recordTransaction(
          householdId: hh,
          accountId: 'bank',
          type: 'expense',
          lines: const [
            TxLine(
                amount: 30,
                currency: 'USD',
                categoryId: 'food',
                accountId: 'bank')
          ],
          baseCurrency: 'USD'));
      await open(
          tester,
          QuickAddScreen(
            editTransactionId: id,
            editLines: const [
              {
                'amount': 30.0,
                'currency': 'USD',
                'accountId': 'bank',
                'categoryId': 'food'
              }
            ],
          ));
      await tester.tap(find.text('Transfer').first);
      await settle(tester);
      await tester.tap(saveButton());
      await settle(tester, 12);
      final txs = await q(tester, () => liveTxs(db));
      expect(txs, hasLength(1));
      expect(txs.single.type, 'transfer');
      expect(txs.single.destinationAccountId, isNot('bank'));
      await tester.runAsync(() => expectBalanced(db,
          expectedAccounts: {'bank': 970}, expectedFood: {'USD': 200}));
      await finish(tester);
    });

    // ── Classic form ──────────────────────────────────────────────────
    Finder classicSave() => find.byType(FilledButton).last;

    testWidgets('classic: an LBP→LBP transfer (base USD) saves without a '
        '"rate not set" warning', (tester) async {
      await open(
          tester,
          const AddTransactionScreen(
            editType: 'transfer',
            editFromAccountId: 'lbp',
            editDestAccountId: 'lbp2',
            editLines: [
              {'amount': 1000000.0, 'currency': 'LBP', 'accountId': 'lbp'}
            ],
          ));
      await tester.tap(classicSave());
      await settle(tester);
      expect(find.text('Exchange rate not set'), findsNothing,
          reason: 'same-currency transfer asks for an exchange rate');
      await finish(tester);
    });

    testWidgets('classic: a USD→LBP transfer with no rate is not saved 1:1 '
        'without a warning', (tester) async {
      await open(
          tester,
          const AddTransactionScreen(
            editType: 'transfer',
            editFromAccountId: 'bank',
            editDestAccountId: 'lbp',
            editLines: [
              {'amount': 20.0, 'currency': 'USD', 'accountId': 'bank'}
            ],
          ));
      await tester.tap(classicSave());
      await settle(tester);
      final txs = await q(tester, () => liveTxs(db));
      for (final t in txs) {
        expect(t.destinationAmount, isNot(closeTo(20, 0.01)),
            reason: '\$20 arrived as LBP 20 with no warning');
      }
      await finish(tester);
    });

    testWidgets('classic: double-tapping Save records one expense',
        (tester) async {
      await open(
          tester,
          const AddTransactionScreen(
            editType: 'expense',
            editLines: [
              {
                'amount': 12.0,
                'currency': 'USD',
                'accountId': 'bank',
                'categoryId': 'food'
              }
            ],
          ));
      await tester.tap(classicSave());
      await tester.tap(classicSave(), warnIfMissed: false);
      await settle(tester, 12);
      expect(await q(tester, () => liveTxs(db)), hasLength(1));
      await finish(tester);
    });

    testWidgets('classic: a split whose second line is empty says which item',
        (tester) async {
      await open(
          tester,
          const AddTransactionScreen(
            editType: 'expense',
            editLines: [
              {
                'amount': 12.0,
                'currency': 'USD',
                'accountId': 'bank',
                'categoryId': 'food'
              },
              {'amount': 0.0, 'currency': 'USD', 'accountId': 'bank'},
            ],
          ));
      await tester.tap(classicSave());
      await settle(tester);
      expect(await q(tester, () => liveTxs(db)), isEmpty);
      expect(find.textContaining('2'), findsWidgets);
      await finish(tester);
    });

    // ── Delete with undo ──────────────────────────────────────────────
    testWidgets('delete A, delete B, Undo: B is back, A stays gone, '
        'balances right throughout', (tester) async {
      final ids = await q(tester, () async {
        final e = AllocationEngine(db);
        Future<String> s(double a) => e.recordTransaction(
            householdId: hh,
            accountId: 'bank',
            type: 'expense',
            lines: [
              TxLine(
                  amount: a,
                  currency: 'USD',
                  categoryId: 'food',
                  accountId: 'bank')
            ],
            baseCurrency: 'USD');
        return [await s(10), await s(20)];
      });
      late BuildContext ctx;
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox();
          })),
        ),
      ));
      await tester.runAsync(() => deleteTransactionsWithUndo(ctx, [ids[0]]));
      await tester.pump();
      await tester.runAsync(() => expectBalanced(db,
          expectedAccounts: {'bank': 980}, expectedFood: {'USD': 180}));
      await tester.runAsync(() => deleteTransactionsWithUndo(ctx, [ids[1]]));
      await settle(tester, 4);
      await tester.runAsync(() => expectBalanced(db,
          expectedAccounts: {'bank': 1000}, expectedFood: {'USD': 200}));
      await tester.tap(find.text('Undo').last);
      await settle(tester, 4);
      // Tapping Undo again (the action is gone or ignored).
      if (find.text('Undo').evaluate().isNotEmpty) {
        await tester.tap(find.text('Undo').last, warnIfMissed: false);
        await settle(tester, 4);
      }
      final live = await q(tester, () => liveTxs(db));
      expect(live.map((t) => t.id), [ids[1]]);
      await tester.runAsync(() => expectBalanced(db,
          expectedAccounts: {'bank': 980}, expectedFood: {'USD': 180}));
      await tester.pump(const Duration(seconds: 6));
      await settle(tester, 4);
      expect((await q(tester, () => liveTxs(db))).map((t) => t.id), [ids[1]]);
      await finish(tester);
    });
  });
}
