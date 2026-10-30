// Unhappy-path tests: planned payments, bills & subscriptions, the bill
// splitter, receipt OCR and the forecast — a user who doesn't know what
// they're doing (wrong data, steps out of order, backing out halfway, huge
// numbers). Each test says what SHOULD happen; a failing one is a candidate
// bug (see the comment above it).
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/engine/forecast.dart';
import 'package:budgetseal/core/engine/planned_engine.dart';
import 'package:budgetseal/core/engine/recurring_engine.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/features/forecast/forecast_screen.dart';
import 'package:budgetseal/features/planned/plan_payment_screen.dart';
import 'package:budgetseal/shared/theme/app_icons.dart';
import 'package:budgetseal/features/recurring/recurring_screen.dart';
import 'package:budgetseal/features/recurring/upcoming_bills_screen.dart';
import 'package:budgetseal/features/transactions/bill_splitter_screen.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:budgetseal/shared/utils/ocr_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const hh = 'hh';

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

Future<AppDatabase> _seed({bool accounts = true}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: hh, name: 'Home', createdByDeviceId: 't'));
  if (accounts) {
    for (final (id, bal) in [('bank', 1000.0), ('old', 0.0)]) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id, householdId: hh, name: id == 'bank' ? 'Bank' : 'Old card',
          type: 'bank', currency: 'USD', initialBalance: Value(bal),
          deviceId: 't'));
    }
  }
  await db.into(db.allocations).insert(AllocationsCompanion.insert(
      id: 'env', householdId: hh, name: 'Bills', categoryId: 'cat',
      deviceId: 't'));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: 'cat', householdId: hh, name: 'Bills',
      allocationId: const Value('env')));
  return db;
}

Future<List<Transaction>> _posted(AppDatabase db) =>
    (db.select(db.transactions)
          ..where((t) => t.status.isNull() & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

Future<RecurringTransaction> _rec(AppDatabase db, String id) =>
    (db.select(db.recurringTransactions)..where((r) => r.id.equals(id)))
        .getSingle();

Future<double> _rta(AppDatabase db) async =>
    (await BalanceCalculator(db).unallocatedByCurrency(hh))['USD'] ?? 0;

Future<double> _env(AppDatabase db) async =>
    (await BalanceCalculator(db).allocationBalanceByCurrency('env'))['USD'] ??
    0;

/// Pumps [page] inside the app's providers, then lets the async loads run.
Future<void> _pump(WidgetTester tester, ProviderContainer container,
    Widget page, {double width = 360}) async {
  await tester.binding.setSurfaceSize(Size(width, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: page,
    ),
  ));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Types [digits] on the open calculator sheet and taps Done.
Future<void> _calc(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.text(d).last);
    await tester.pump();
  }
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 10)); // SnackBar/route timers
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)));
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Bills, subscriptions (RecurringEngine)
  // ═══════════════════════════════════════════════════════════════════════
  group('bills & subscriptions', () {
    late AppDatabase db;
    late RecurringEngine engine;
    setUp(() async {
      db = await _seed();
      engine = RecurringEngine(db);
    });
    tearDown(() => db.close());

    Future<String> bill({
      required DateTime start,
      DateTime? end,
      String frequency = 'monthly',
      String account = 'bank',
      double amount = 50,
      bool sub = false,
      String? priceHistory,
      bool askFirst = false,
      String title = 'Phone',
    }) =>
        engine.create(
            householdId: hh, type: 'expense', title: title, amount: amount,
            currency: 'USD', accountId: account, categoryId: 'cat',
            frequency: frequency, startDate: start, endDate: end,
            isSubscription: sub, priceHistory: priceHistory,
            askFirst: askFirst);

    // CANDIDATE BUG: a bill whose end date passes during catch-up stays
    // enabled with a due date after its end, so Upcoming bills keeps it as
    // "overdue" forever (Home's bill boxes and reminders filter it out;
    // _advance() switches such a bill off, processRecurring() doesn't).
    test('a bill whose end date has passed is switched off, not left due',
        () async {
      final t = _today();
      final id = await bill(
          start: DateTime(t.year, t.month - 3, 1),
          end: DateTime(t.year, t.month - 1, 15));
      await engine.processRecurring();
      expect(await _posted(db), hasLength(3)); // months -3, -2, -1
      final rec = await _rec(db, id);
      expect(rec.nextDueDate.isAfter(rec.endDate!), isTrue);
      expect(rec.enabled, isFalse,
          reason: 'ended bill should not stay enabled and due');
    });

    // CANDIDATE BUG: the add sheet lets the user pick an end date, then move
    // the start date after it (the start picker isn't bounded by the end).
    // Such a bill never posts but is due forever.
    test('end date before start date: never posts, and is not due forever',
        () async {
      final t = _today();
      final id = await bill(start: t, end: t.subtract(const Duration(days: 5)));
      expect(await engine.processRecurring(), 0);
      expect(await _posted(db), isEmpty);
      expect((await _rec(db, id)).enabled, isFalse,
          reason: 'a bill that has already ended should switch itself off');
    });

    // CANDIDATE BUG: Upcoming bills → Post now ignores the end date.
    test('Post now on a bill past its end date does not record a payment',
        () async {
      final t = _today();
      final id = await bill(start: t, end: t.subtract(const Duration(days: 5)));
      try {
        await engine.postNow(id);
      } catch (_) {/* refusing is fine */}
      expect(await _posted(db), isEmpty,
          reason: 'a cancelled/ended bill must not be paid again');
    });

    test('monthly on the 31st: Feb and 30-day months clamp, then come back',
        () async {
      final t = _today();
      // Jan 31 of this year, all occurrences until today posted.
      await bill(start: DateTime(t.year, 1, 31));
      await engine.processRecurring();
      final dates = (await _posted(db)).map((x) => x.createdAt).toList();
      for (final d in dates) {
        final last = DateTime(d.year, d.month + 1, 0).day;
        expect(d.day, last, reason: '$d should be the month end');
      }
      // One per month, no month twice or skipped.
      expect(dates.map((d) => d.month).toSet().length, dates.length);
    });

    // CANDIDATE BUG (by design, but harsh): the edit sheet lets "Next due"
    // go back to Jan 2020; the next launch silently records every missed
    // week — hundreds of expenses — with only "N recurring items posted".
    test('next due moved years back does not flood hundreds of payments',
        () async {
      final id = await bill(start: _today().add(const Duration(days: 3)),
          frequency: 'weekly');
      // What EditRecurringSheet._save writes (firstDate: DateTime(2020)).
      await (db.update(db.recurringTransactions)
            ..where((r) => r.id.equals(id)))
          .write(RecurringTransactionsCompanion(
              nextDueDate: Value(DateTime(2020, 1, 6)),
              anchorDay: const Value(6)));
      final n = await engine.processRecurring();
      expect(n, lessThanOrEqualTo(53),
          reason: 'posted $n weekly payments in one go');
    });

    test('Post now twice pays two occurrences, both kept apart', () async {
      final t = _today();
      final id = await bill(start: t.add(const Duration(days: 10)));
      await engine.postNow(id);
      await engine.postNow(id);
      final txs = await _posted(db);
      expect(txs.map((x) => x.id).toSet(), hasLength(2));
      final rec = await _rec(db, id);
      expect(rec.nextDueDate,
          advanceRecurringDate(
              advanceRecurringDate(t.add(const Duration(days: 10)),
                  'monthly', 1),
              'monthly', 1));
    });

    // CANDIDATE BUG: occurrence ids are fixed (rec:<id>:<date>) and
    // recordTransaction() returns early when that id exists — even when the
    // row is deleted. Delete a wrongly posted bill, set the due date back,
    // post it again: "Posted" is shown but nothing is recorded, and the due
    // date still moves on.
    test('re-posting an occurrence whose payment was deleted records it',
        () async {
      final t = _today();
      final due = t.add(const Duration(days: 2));
      final id = await bill(start: due);
      await engine.postNow(id);
      final first = (await _posted(db)).single;
      await AllocationEngine(db).deleteTransaction(first.id); // user deletes
      // Edit sheet: next due back to the same day.
      await (db.update(db.recurringTransactions)
            ..where((r) => r.id.equals(id)))
          .write(RecurringTransactionsCompanion(nextDueDate: Value(due)));
      await engine.postNow(id, amount: 55);
      final live = await _posted(db);
      expect(live, hasLength(1), reason: 'the payment was silently dropped');
      expect(live.single.amount, 55);
    });

    test('skip, then move the due date back (un-skip) → it posts', () async {
      final t = _today();
      final id = await bill(start: t.subtract(const Duration(days: 1)),
          askFirst: true); // so launch doesn't post it first
      await engine.skipNext(id);
      await (db.update(db.recurringTransactions)
            ..where((r) => r.id.equals(id)))
          .write(RecurringTransactionsCompanion(
              nextDueDate: Value(t.subtract(const Duration(days: 1))),
              askFirst: const Value(false)));
      expect(await engine.processRecurring(), 1);
      expect(await _posted(db), hasLength(1));
    });

    test('paid on another day: dated that day at noon, due date moves on',
        () async {
      final t = _today();
      final id = await bill(start: t.add(const Duration(days: 5)));
      final paid = t.subtract(const Duration(days: 3));
      await engine.postNow(id, on: paid);
      final tx = (await _posted(db)).single;
      expect(tx.createdAt, DateTime(paid.year, paid.month, paid.day, 12));
      expect((await _rec(db, id)).nextDueDate,
          advanceRecurringDate(t.add(const Duration(days: 5)), 'monthly', 1));
    });

    test('interval 0 (repeat every 0 …) does not loop forever', () {
      final d = DateTime(2026, 1, 31);
      expect(advanceRecurringDate(d, 'monthly', 0), DateTime(2026, 2, 28));
      expect(advanceRecurringDate(d, 'daily', 0), DateTime(2026, 2, 1));
      expect(advanceRecurringDate(d, 'weekly', -3), DateTime(2026, 2, 7));
    });

    // CANDIDATE BUG: a subscription whose price was changed from the Web
    // Companion has a priceHistory; the phone's edit sheet changes `amount`
    // only, and recurringAmountOn() lets the history win — so the new
    // price shown in the sheet is never charged.
    test('editing a subscription amount on the phone is what gets charged',
        () async {
      final t = _today();
      final id = await bill(
          start: t.add(const Duration(days: 4)),
          sub: true,
          amount: 12,
          priceHistory: jsonEncode([
            {'amount': 12, 'from': '${t.year - 1}-01-01'}
          ]));
      // EditRecurringSheet._save (recurring_screen.dart) writes this.
      await (db.update(db.recurringTransactions)
            ..where((r) => r.id.equals(id)))
          .write(const RecurringTransactionsCompanion(amount: Value(15)));
      await engine.postNow(id);
      expect((await _posted(db)).single.amount, 15);
    });

    // CANDIDATE BUG: deleting (or archiving) an account leaves its bills
    // running. The next launch posts them into the hidden account: the
    // envelope is debited but no visible account goes down, so Ready to
    // assign grows by the bill — money created.
    for (final how in ['deleted', 'archived']) {
      test('a bill on a $how account does not create Ready-to-assign money',
          () async {
        await AllocationEngine(db).fundAllocation(
            allocationId: 'env', amount: 200, currency: 'USD',
            deviceId: 't');
        await bill(
            start: _today().subtract(const Duration(days: 1)),
            account: 'old');
        await (db.update(db.accounts)..where((a) => a.id.equals('old'))).write(
            how == 'deleted'
                ? const AccountsCompanion(deleted: Value(true))
                : const AccountsCompanion(archived: Value(true)));
        final rtaBefore = await _rta(db);
        await engine.processRecurring();
        expect(await _rta(db), closeTo(rtaBefore, 0.001),
            reason: 'Ready to assign moved by '
                '${(await _rta(db)) - rtaBefore} '
                '(envelope now ${await _env(db)})');
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Bill screens (Upcoming bills, edit sheet)
  // ═══════════════════════════════════════════════════════════════════════
  group('bill screens', () {
    late AppDatabase db;
    late ProviderContainer container;
    setUp(() async {
      db = await _seed();
      container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      container.read(currentHouseholdIdProvider.notifier).set(hh);
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    // CANDIDATE BUG: see "switched off" above — Upcoming bills lists an
    // ended bill (its _load doesn't look at endDate).
    testWidgets('Upcoming bills does not list a bill that has ended',
        (tester) async {
      final t = _today();
      await tester.runAsync(() async {
        await RecurringEngine(db).create(
            householdId: hh, type: 'expense', title: 'Old gym', amount: 30,
            currency: 'USD', accountId: 'bank', categoryId: 'cat',
            frequency: 'monthly',
            startDate: DateTime(t.year, t.month - 3, 1),
            endDate: DateTime(t.year, t.month - 1, 15));
        await RecurringEngine(db).processRecurring();
      });
      await _pump(tester, container, const UpcomingBillsScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('Old gym'), findsNothing);
      await _unmount(tester);
    });

    Future<RecurringTransaction> seedBill(WidgetTester tester,
        {required DateTime next, DateTime? end}) async {
      late RecurringTransaction rec;
      await tester.runAsync(() async {
        final id = await RecurringEngine(db).create(
            householdId: hh, type: 'expense', title: 'Insurance',
            amount: 300, currency: 'USD', accountId: 'bank',
            categoryId: 'cat', frequency: 'yearly', startDate: next,
            endDate: end);
        rec = await _rec(db, id);
      });
      return rec;
    }

    Future<void> openSheet(WidgetTester tester, RecurringTransaction rec) =>
        _pump(tester, container,
            Scaffold(body: SingleChildScrollView(
                child: EditRecurringSheet(item: rec))));

    // CANDIDATE BUG (crash): the edit sheet's "Next due" picker is bounded
    // to 2020…2030 but opens on the bill's next due date. A yearly bill
    // skipped a few times (Upcoming bills → Skip) is due in 2031 → tapping
    // the date trips showDatePicker's initialDate <= lastDate assertion.
    testWidgets('edit sheet: tapping Next due on a bill due after 2030',
        (tester) async {
      final rec = await seedBill(tester, next: DateTime(2031, 3, 1));
      await openSheet(tester, rec);
      await tester.tap(find.textContaining('Next due'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });

    // CANDIDATE BUG (crash): a cancelled subscription (end date passed, so
    // its next due date is after the end) — Edit → tap "Ends …" opens the
    // picker with initialDate (end) before firstDate (next due).
    testWidgets('edit sheet: tapping Ends on a bill whose end is before next due',
        (tester) async {
      final t = _today();
      final rec = await seedBill(tester,
          next: t.add(const Duration(days: 40)),
          end: t.add(const Duration(days: 10)));
      await openSheet(tester, rec);
      await tester.tap(find.textContaining('Ends'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Planned payments
  // ═══════════════════════════════════════════════════════════════════════
  // CANDIDATE BUG (crash + wrong date): Plan payment → pick an exact date,
  // then change the YEAR with the arrows. Month chips reset the exact date,
  // the year arrows don't: the header says 2027 but the plan saves on the
  // old date, and tapping the exact date opens a picker whose initialDate
  // is outside [first, last] of the new month → assertion.
  group('plan payment screen', () {
    late AppDatabase db;
    late ProviderContainer container;
    setUp(() async {
      db = await _seed();
      container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      container.read(currentHouseholdIdProvider.notifier).set(hh);
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    testWidgets('exact date, then year arrow, then exact date again',
        (tester) async {
      // Wider than a phone: the test font overflows a row at 360 dp.
      await _pump(tester, container, const PlanPaymentScreen(), width: 600);
      final exact = find.textContaining('exact date', findRichText: true);
      await tester.ensureVisible(exact.first);
      await tester.tap(exact.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final next = find.byIcon(AppIcons.caretRight);
      await tester.ensureVisible(next.first);
      await tester.tap(next.first);
      await tester.pumpAndSettle();
      // The year arrow cleared the exact date, so the row is back to
      // "Pick exact date".
      await tester.tap(find
          .textContaining(RegExp('exact date', caseSensitive: false),
              findRichText: true)
          .first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });
  });

  group('planned payments', () {
    late AppDatabase db;
    setUp(() async => db = await _seed());
    tearDown(() => db.close());

    Future<String> plan({String account = 'bank', DateTime? date,
            double amount = 80}) =>
        PlannedEngine(db).save(
            householdId: hh, type: 'expense', accountId: account,
            amount: amount, currency: 'USD', categoryId: 'cat',
            note: 'School', date: date ?? _today(), createdBy: 'u',
            deviceId: 't');
    Future<String> post(String id) => PlannedEngine(db).post(id,
        baseCurrency: 'USD', rate: (a, b) async => null, createdBy: 'u',
        deviceId: 't');

    test('marking paid twice posts once', () async {
      final id = await plan();
      await post(id);
      await post(id);
      expect(await _posted(db), hasLength(1));
    });

    test('a plan whose posted payment was deleted cannot come back twice',
        () async {
      final id = await plan();
      final tx = await post(id);
      await AllocationEngine(db).deleteTransaction(tx);
      // The plan is gone; posting again neither throws nor re-creates.
      expect(await post(id), tx);
      expect(await _posted(db), isEmpty);
    });

    test('editing a plan in place keeps one plan and the new amount',
        () async {
      final id = await plan();
      await PlannedEngine(db).save(replaceId: id, householdId: hh,
          type: 'expense', accountId: 'bank', amount: 120, currency: 'USD',
          categoryId: 'cat', date: _today(), createdBy: 'u', deviceId: 't');
      await post(id);
      expect((await _posted(db)).single.amount, 120);
    });

    // CANDIDATE BUG: archive requires a zero balance, but planned payments
    // don't count — post one on the archived account and it vanishes from
    // every visible balance while the envelope is debited: Ready to assign
    // grows by the payment.
    test('posting a plan on an archived account does not create money',
        () async {
      await AllocationEngine(db).fundAllocation(
          allocationId: 'env', amount: 200, currency: 'USD', deviceId: 't');
      final id = await plan(account: 'old');
      await (db.update(db.accounts)..where((a) => a.id.equals('old')))
          .write(const AccountsCompanion(archived: Value(true)));
      final before = await _rta(db);
      try {
        await post(id);
      } catch (_) {/* refusing is fine */}
      expect(await _rta(db), closeTo(before, 0.001));
    });

    test('a plan years in the past posts on its own date, once', () async {
      final id = await plan(date: DateTime(2019, 6, 1));
      await post(id);
      expect((await _posted(db)).single.createdAt, DateTime(2019, 6, 1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Forecast / safe to spend
  // ═══════════════════════════════════════════════════════════════════════
  group('forecast', () {
    RecurringTransaction rec(String type, double amount, DateTime next,
            {String freq = 'monthly', DateTime? end, bool enabled = true}) =>
        RecurringTransaction(
          id: '$type$amount', householdId: hh, type: type, title: type,
          amount: amount, currency: 'USD', accountId: 'bank',
          note: '', frequency: freq, interval: 1, nextDueDate: next,
          anchorDay: next.day, endDate: end, enabled: enabled,
          lastModified: DateTime(2026), isSubscription: false,
          deleted: false, askFirst: false, createdAt: DateTime(2026),
        );

    final now = DateTime.now();
    final today = _today();

    test('no income at all: 30 days, cash ÷ 30, nothing NaN', () {
      final f = buildForecast(now: now, cash: {'USD': 300})['USD']!;
      expect(f.nextIncome, isNull);
      expect(f.daysLeft, 30);
      expect(f.safeToSpend, closeTo(10, 0.001));
      expect(f.daily.every((d) => d.isFinite), isTrue);
    });

    test('no accounts, no anything: empty forecast, no crash', () {
      expect(buildForecast(now: now, cash: const {}), isEmpty);
    });

    test('payday already passed (unconfirmed): next payday is next month',
        () {
      final f = buildForecast(now: now, cash: {'USD': 100}, recurring: [
        rec('income', 2000, today.subtract(const Duration(days: 5))),
      ])['USD']!;
      expect(f.nextIncome, isNotNull);
      expect(f.nextIncome!.date.isAfter(today), isTrue);
      expect(f.safeToSpend.isFinite, isTrue);
    });

    test('in debt: safe to spend is 0 and says by how much', () {
      final f = buildForecast(now: now, cash: {'USD': -500}, recurring: [
        rec('expense', 100, today.add(const Duration(days: 2))),
        rec('income', 1000, today.add(const Duration(days: 10))),
      ])['USD']!;
      expect(f.safeToSpend, 0);
      expect(f.short, closeTo(600, 0.001));
    });

    test('payday tomorrow: one day left, not zero', () {
      final f = buildForecast(now: now, cash: {'USD': 100}, recurring: [
        rec('income', 1000, today.add(const Duration(days: 1))),
      ])['USD']!;
      expect(f.daysLeft, 1);
      expect(f.safeToSpend, closeTo(100, 0.001));
    });

    test('huge numbers stay finite', () {
      final f = buildForecast(now: now, cash: {'LBP': 9e14}, recurring: [
        rec('expense', 8e14, today.add(const Duration(days: 3)))
          .copyWith(currency: 'LBP'),
      ])['LBP']!;
      expect(f.safeToSpend.isFinite, isTrue);
      expect(f.lowest.isFinite, isTrue);
    });

    test('ended or paused income is not counted as next payday', () {
      final f = buildForecast(now: now, cash: {'USD': 300}, recurring: [
        rec('income', 2000, today.add(const Duration(days: 3)),
            end: today.subtract(const Duration(days: 1))),
        rec('income', 999, today.add(const Duration(days: 4)),
            enabled: false),
      ])['USD']!;
      expect(f.nextIncome, isNull);
    });

  });

  group('forecast screen', () {
    late AppDatabase db;
    late ProviderContainer container;
    setUp(() async {
      db = await _seed(accounts: false);
      container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      container.read(currentHouseholdIdProvider.notifier).set(hh);
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    testWidgets('Forecast screen with no accounts at all builds',
        (tester) async {
      await _pump(tester, container, const ForecastScreen());
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Receipt OCR with garbage
  // ═══════════════════════════════════════════════════════════════════════
  group('receipt OCR garbage', () {
    OcrResult parse(List<String> texts) {
      final raw = <OcrRawLine>[];
      for (var i = 0; i < texts.length; i++) {
        raw.add(OcrRawLine(
            text: texts[i],
            rect: ui.Rect.fromLTWH(40, 40.0 + i * 40, texts[i].length * 14.0,
                28),
            angle: 0,
            height: 28));
      }
      return OcrService.parseLines(raw, imageWidth: 800, imageHeight: 1400);
    }

    void sane(OcrResult r) {
      for (final l in r.lines.where((l) => l.hasPrice)) {
        expect(l.parsedAmount!.isFinite, isTrue, reason: l.text);
        // A discount line is negative by design (OcrLineKind.discount).
        if (l.kind != OcrLineKind.discount) {
          expect(l.parsedAmount!, greaterThan(0), reason: l.text);
        }
        expect(l.parsedAmount!, lessThan(1e9), reason: l.text);
      }
    }

    test('no lines at all', () {
      final r = OcrService.parseLines(const [],
          imageWidth: 800, imageHeight: 1400);
      expect(r.lines, isEmpty);
    });

    test('symbols, emoji, empty strings', () {
      final r = parse(['', '   ', '###***', '😀😀', r'$$$', '.,.,', '----']);
      sane(r);
      expect(r.lines.where((l) => l.hasPrice), isEmpty);
    });

    test('barcode, phone, card number, date are not items', () {
      final r = parse([
        '5901234123457',
        'Tel 01 234 567',
        '**** **** **** 4242',
        '30/10/2026 21:45',
        'VAT No 123456789',
      ]);
      sane(r);
      expect(r.lines.where((l) => l.hasPrice).map((l) => l.text), isEmpty);
    });

    test('negative, zero and absurd prices', () {
      final r = parse([
        'Discount -5.00',
        'Water 0.00',
        'Bread 99999999999999.99',
        'Coffee 3.50',
      ]);
      sane(r);
    });

    test('a single line repeated 500 times does not hang', () {
      final r = parse(List.filled(500, 'Burger 12.50'));
      sane(r);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Bill splitter (the real screen)
  // ═══════════════════════════════════════════════════════════════════════
  group('bill splitter', () {
    late AppDatabase db;
    late ProviderContainer container;
    setUp(() async {
      db = await _seed();
      container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      container.read(currentHouseholdIdProvider.notifier).set(hh);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> addPerson(WidgetTester tester, String name) async {
      // Evenly: the "Add" pill; By item: the "+" chip.
      final pill = find.text('Add');
      await tester.ensureVisible(pill.first);
      await tester.tap(pill.first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, name);
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
    }

    Future<void> setTotal(WidgetTester tester, String digits) async {
      await tester.tap(find.text(r'$0.00').first);
      await tester.pumpAndSettle();
      await _calc(tester, digits);
    }

    testWidgets('100 split 3 ways adds back to exactly 100', (tester) async {
      await _pump(tester, container, const BillSplitterScreen());
      await setTotal(tester, '100');
      await addPerson(tester, 'Sam');
      await addPerson(tester, 'Alex');
      expect(tester.takeException(), isNull);
      expect(find.text(r'$33.34'), findsOneWidget);
      expect(find.text(r'$33.33'), findsNWidgets(2));
      await _unmount(tester);
    });

    testWidgets('no total: See totals is disabled', (tester) async {
      await _pump(tester, container, const BillSplitterScreen());
      await addPerson(tester, 'Sam');
      final btn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'See totals'));
      expect(btn.onPressed, isNull);
      await _unmount(tester);
    });

    testWidgets('50 people at 360 dp: no overflow, shares add up',
        (tester) async {
      await _pump(tester, container, const BillSplitterScreen());
      await setTotal(tester, '1000');
      for (var i = 1; i < 50; i++) {
        await addPerson(tester, 'P$i');
      }
      expect(tester.takeException(), isNull);
      expect(find.text(r'$20.00'), findsWidgets); // 1000 / 50
      await tester.drag(find.byType(ListView).first, const Offset(0, 20000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });

    // CANDIDATE BUG (confusing UX): with no account (none yet, or all
    // archived) Save opens an empty account picker and then does nothing —
    // no message, no hint to add an account.
    testWidgets('Save with no account at all explains why it can\'t',
        (tester) async {
      // Every account archived (or none made yet).
      await tester.runAsync(() => db.update(db.accounts)
          .write(const AccountsCompanion(archived: Value(true))));
      await _pump(tester, container, const BillSplitterScreen());
      await setTotal(tester, '60');
      await tester.tap(find.text('See totals'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Save'));
      await tester.pumpAndSettle();
      // Dismiss whatever sheet opened.
      await tester.tapAt(const Offset(180, 40));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(await tester.runAsync(() => _posted(db)), isEmpty);
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'nothing tells the user they need an account');
      await _unmount(tester);
    });

    // CANDIDATE BUG (money wrong): By item, Sam shares the pizza with Alex
    // and had the drink alone. Remove Sam → Undo: the drink comes back to
    // Sam, but the pizza stays Alex's alone (the Undo restores only items
    // that were Sam's alone; _removePerson removed Sam from every item).
    testWidgets('remove a person with items, then Undo, restores the split',
        (tester) async {
      await _pump(tester, container, const BillSplitterScreen());
      await tester.tap(find.text('By item'));
      await tester.pumpAndSettle();
      Future<void> item(String name, String price) async {
        await tester.tap(find.text('Add item').first);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, name);
        await tester.tap(find.text('Amount'));
        await tester.pumpAndSettle();
        await _calc(tester, price);
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
      }

      await item('Pizza', '30');
      await item('Drink', '10');
      Future<void> person(String name) async {
        await tester.tap(find.text('+').last);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, name);
        await tester.tap(find.widgetWithText(FilledButton, 'Add'));
        await tester.pumpAndSettle();
      }

      await person('Sam');
      await person('Alex');
      Future<void> paint(String who, List<String> items) async {
        await tester.tap(find.text(who).last);
        await tester.pumpAndSettle();
        for (final i in items) {
          await tester.tap(find.text(i));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(who).last); // stop painting
        await tester.pumpAndSettle();
      }

      // Me had nothing; Alex didn't have the drink.
      // Chips show initials ("Me" for the user).
      await paint('Me', ['Pizza', 'Drink']);
      await paint('A', ['Drink']);
      expect(find.text(r'$25.00'), findsOneWidget); // Sam: 15 + 10
      expect(find.text(r'$15.00'), findsOneWidget); // Alex: 15
      // Remove Sam (long press his chip → Remove), then Undo.
      await tester.longPress(find.text('S').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(r'$25.00'), findsOneWidget,
          reason: 'Sam should be back to 15 + 10');
      expect(find.text(r'$15.00'), findsOneWidget,
          reason: 'Alex should be back to half the pizza');
      await _unmount(tester);
    });
  });
}
