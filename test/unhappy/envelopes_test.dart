// Unhappy-path tests for envelopes and money moves: a user who over-assigns,
// moves money in circles, skips months, deletes envelopes that hold money,
// and sets odd goals / sinking fund schedules / trips.
//
// Every test asserts what SHOULD happen. A failing test is a candidate bug —
// see the comment above each one marked "BUG?".
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/database/daos/allocations_dao.dart';
import 'package:budgetseal/core/database/daos/ledger_dao.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/engine/period_engine.dart';
import 'package:budgetseal/core/engine/sinking_fund.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/core/providers/seal_provider.dart';
import 'package:budgetseal/core/services/period_reset_service.dart';
import 'package:budgetseal/core/services/travel_account_service.dart';
import 'package:budgetseal/features/objectives/objective_detail_screen.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const hh = 'hh';
const base = 'USD';

late AppDatabase db;
late AllocationEngine engine;
late BalanceCalculator calc;

Future<void> _account(String id, String currency, double initial,
    {bool travel = false}) =>
    db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id,
          householdId: hh,
          name: id,
          type: 'bank',
          currency: currency,
          initialBalance: Value(initial),
          isTravel: Value(travel),
          deviceId: 'd',
        ));

Future<void> _envelope(String id,
    {String type = 'spending',
    String periodicity = 'periodic',
    double? target,
    String currency = base,
    bool autoReset = true,
    bool rollover = false,
    DateTime? createdAt}) async {
  await db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: id,
        householdId: hh,
        name: id,
        categoryId: id,
        type: Value(type),
        periodicity: Value(periodicity),
        targetAmount: Value(target),
        targetCurrency: Value(currency),
        autoReset: Value(autoReset),
        rollover: Value(rollover),
        createdAt: Value(createdAt ?? DateTime(2025, 1, 1)),
        deviceId: 'd',
      ));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat-$id',
        householdId: hh,
        name: 'cat-$id',
        transactionType: const Value('expense'),
        allocationId: Value(id),
      ));
}

var _seq = 0;

Future<void> _ledger(String env, String type, double amount,
        {String currency = base, DateTime? at, String? id}) =>
    db.into(db.allocationLedger).insert(AllocationLedgerCompanion.insert(
          id: id ?? 'l-${_seq++}-$env-$type',
          allocationId: env,
          entryType: type,
          amount: amount,
          currency: currency,
          createdAt: Value(at ?? DateTime.now()),
          deviceId: 'd',
        ));

Future<String> _spend(String env, double amount,
    {String account = 'usd', String currency = base, DateTime? date}) =>
    engine.recordTransaction(
      householdId: hh,
      accountId: account,
      type: 'expense',
      lines: [
        TxLine(
            amount: amount,
            currency: currency,
            categoryId: 'cat-$env',
            exchangeRateToBase: 1.0),
      ],
      baseCurrency: base,
      date: date ?? DateTime.now(),
    );

Future<Map<String, double>> _rta() => calc.unallocatedByCurrency(hh);

Future<Map<String, double>> _env(String id) async =>
    (await calc.allAllocationBalancesByCurrency(hh))[id] ?? {};

/// accounts = Ready to assign + envelopes, per currency, AND the envelope
/// side is the real ledger (not the archived/deleted-filtered view).
Future<void> _expectInvariant() async {
  final accts = await calc.allAccountBalances(hh);
  final accounts = await (db.select(db.accounts)
        ..where((a) => a.archived.equals(false) & a.deleted.equals(false)))
      .get();
  final byCur = <String, double>{};
  for (final a in accounts) {
    byCur[a.currency] = (byCur[a.currency] ?? 0) + (accts[a.id] ?? 0);
  }
  final envs = await calc.allAllocationBalancesByCurrency(hh);
  final envByCur = <String, double>{};
  for (final m in envs.values) {
    m.forEach((c, v) => envByCur[c] = (envByCur[c] ?? 0) + v);
  }
  final rta = await _rta();
  for (final c in {...byCur.keys, ...envByCur.keys, ...rta.keys}) {
    expect((byCur[c] ?? 0),
        closeTo((rta[c] ?? 0) + (envByCur[c] ?? 0), 0.0001),
        reason: 'invariant broken in $c');
  }
}

Future<void> _setUpDb() async {
  SharedPreferences.setMockInitialValues({});
  db = AppDatabase.forTesting(NativeDatabase.memory());
  engine = AllocationEngine(db);
  calc = BalanceCalculator(db);
  await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: hh, name: 'Home', createdByDeviceId: 'd'));
  await _account('usd', 'USD', 1000);
  await _account('eur', 'EUR', 500);
  await db.into(db.fxRates).insert(FxRatesCompanion.insert(
      id: 'fx-eur', fromCurrency: 'EUR', toCurrency: base, rate: 1.1));
  await db.into(db.fxRates).insert(FxRatesCompanion.insert(
      id: 'fx-jpy', fromCurrency: 'JPY', toCurrency: base, rate: 0.0067));
}

void main() {
  setUp(_setUpDb);
  tearDown(() => db.close());

  // ───────────────────────────── Assigning ─────────────────────────────
  group('assigning money', () {
    test('assigning more than Ready to assign: RTA goes negative, no money '
        'created', () async {
      await _envelope('food', target: 100);
      await engine.fundAllocation(
          allocationId: 'food', amount: 1500, currency: base, deviceId: 'd');
      expect((await _rta())[base], closeTo(-500, 0.001));
      expect((await _env('food'))[base], closeTo(1500, 0.001));
      await _expectInvariant();
    });

    test('assigning a currency the user has no account in', () async {
      await _envelope('food');
      await engine.fundAllocation(
          allocationId: 'food', amount: 10, currency: 'GBP', deviceId: 'd');
      expect((await _rta())['GBP'], closeTo(-10, 0.001));
      await _expectInvariant();
    });

    // fundAllocation has no upper bound (recordTransaction caps at 1
    // billion; the calculator sheet has no cap either). A fat-fingered
    // quadrillion must not swallow the cent already in the envelope.
    test('a huge fund then withdraw leaves small amounts intact', () async {
      await _envelope('food');
      await engine.fundAllocation(
          allocationId: 'food', amount: 0.01, currency: base, deviceId: 'd');
      await engine.fundAllocation(
          allocationId: 'food', amount: 9e15, currency: base, deviceId: 'd');
      await engine.withdrawFromAllocation(
          allocationId: 'food', amount: 9e15, currency: base);
      expect((await _env('food'))[base] ?? 0, closeTo(0.01, 0.0001));
      await _expectInvariant();
    });
  });

  // ───────────────────────────── Moving ─────────────────────────────
  group('moving money', () {
    setUp(() async {
      await _envelope('food', target: 200);
      await _envelope('fun', target: 50);
      await _envelope('trip', currency: 'EUR', type: 'flexible');
      await engine.fundAllocation(
          allocationId: 'food', amount: 100, currency: base, deviceId: 'd');
    });

    test('move to the same envelope does nothing', () async {
      await engine.moveMoney(
          fromAllocationId: 'food',
          toAllocationId: 'food',
          amount: 50,
          currency: base);
      expect((await _env('food'))[base], closeTo(100, 0.001));
      await _expectInvariant();
    });

    test('move more than the envelope holds is refused, nothing written',
        () async {
      final before = await db.select(db.allocationLedger).get();
      await expectLater(
          engine.moveMoney(
              fromAllocationId: 'food',
              toAllocationId: 'fun',
              amount: 100.02,
              currency: base),
          throwsStateError);
      expect((await db.select(db.allocationLedger).get()).length,
          before.length);
      await _expectInvariant();
    });

    test('move zero or negative is a no-op', () async {
      await engine.moveMoney(
          fromAllocationId: 'food',
          toAllocationId: 'fun',
          amount: -40,
          currency: base);
      await engine.moveMoney(
          fromAllocationId: 'food',
          toAllocationId: 'fun',
          amount: 0,
          currency: base);
      expect((await _env('food'))[base], closeTo(100, 0.001));
      expect((await _env('fun'))[base] ?? 0, 0);
    });

    test('move money in a currency the envelope does not hold', () async {
      await expectLater(
          engine.moveMoney(
              fromAllocationId: 'food',
              toAllocationId: 'trip',
              amount: 10,
              currency: 'EUR'),
          throwsStateError);
    });

    test('move USD into a EUR envelope keeps each currency balanced',
        () async {
      await engine.moveMoney(
          fromAllocationId: 'food',
          toAllocationId: 'trip',
          amount: 60,
          currency: base);
      expect((await _env('trip'))[base], closeTo(60, 0.001));
      expect((await _env('trip'))['EUR'] ?? 0, 0);
      await _expectInvariant();
    });

    test('withdraw more than held is refused', () async {
      await expectLater(
          engine.withdrawFromAllocation(
              allocationId: 'food', amount: 101, currency: base),
          throwsStateError);
      await _expectInvariant();
    });

    test('overspent envelope then Cover from another', () async {
      await _spend('fun', 80);
      expect((await _env('fun'))[base], closeTo(-80, 0.001));
      await engine.moveMoney(
          fromAllocationId: 'food',
          toAllocationId: 'fun',
          amount: 80,
          currency: base);
      expect((await _env('fun'))[base] ?? 0, closeTo(0, 0.001));
      await _expectInvariant();
    });
  });

  // ───────────────────────────── Seals ─────────────────────────────
  group('seals', () {
    // BUG? A spending envelope funded to its target and then emptied again
    // (money moved out, or withdrawn back to Ready to assign) keeps the
    // "Fully funded" seal while it holds nothing: fundedInPeriod sums only
    // positive funding/transfer rows and ignores what left.
    test('funded then emptied is not sealed', () async {
      await _envelope('food', target: 100);
      await _envelope('fun');
      await engine.fundAllocation(
          allocationId: 'food', amount: 100, currency: base, deviceId: 'd');
      await engine.moveMoney(
          fromAllocationId: 'food',
          toAllocationId: 'fun',
          amount: 100,
          currency: base);
      final period = budgetPeriodFor(1);
      final funded =
          await LedgerDao(db).fundedInPeriod(hh, period.start, period.end);
      final alloc = await AllocationsDao(db).getById('food');
      final bal = await _env('food');
      expect(bal[base] ?? 0, 0);
      expect(isEnvelopeSealed(alloc!, bal, funded['food'], base), isFalse,
          reason: 'an empty envelope shows the Fully funded seal');
    });

    test('funded then withdrawn to Ready to assign is not sealed', () async {
      await _envelope('food', target: 100);
      await engine.fundAllocation(
          allocationId: 'food', amount: 100, currency: base, deviceId: 'd');
      await engine.withdrawFromAllocation(
          allocationId: 'food', amount: 100, currency: base);
      final period = budgetPeriodFor(1);
      final funded =
          await LedgerDao(db).fundedInPeriod(hh, period.start, period.end);
      final alloc = await AllocationsDao(db).getById('food');
      expect(
          isEnvelopeSealed(alloc!, await _env('food'), funded['food'], base),
          isFalse);
    });

    test('overspent envelope loses the seal; target 0 never seals', () async {
      await _envelope('food', target: 100);
      await _envelope('zero', target: 0);
      await engine.fundAllocation(
          allocationId: 'food', amount: 100, currency: base, deviceId: 'd');
      await _spend('food', 150);
      final period = budgetPeriodFor(1);
      final funded =
          await LedgerDao(db).fundedInPeriod(hh, period.start, period.end);
      expect(
          isEnvelopeSealed((await AllocationsDao(db).getById('food'))!,
              await _env('food'), funded['food'], base),
          isFalse);
      expect(
          isEnvelopeSealed((await AllocationsDao(db).getById('zero'))!,
              await _env('zero'), funded['zero'], base),
          isFalse);
    });
  });

  // ───────────────────────────── Period reset ─────────────────────────────
  group('period reset', () {
    final period = budgetPeriodFor(1);
    final prevStart = DateTime(period.start.year, period.start.month - 1, 1);

    Future<int> reset({DateTime? lastReset}) async {
      SharedPreferences.setMockInitialValues({
        'period_last_reset': (lastReset ?? prevStart).toIso8601String(),
      });
      return PeriodResetService.checkAndAutoReset(db, hh, 1);
    }

    test('leftover returned, overspent carried; money balanced', () async {
      await _envelope('food', target: 100);
      await _envelope('fun', target: 100);
      await _ledger('food', 'funding', 100,
          at: prevStart.add(const Duration(days: 1)));
      await _ledger('fun', 'funding', 50,
          at: prevStart.add(const Duration(days: 1)));
      await _spend('fun', 80, date: prevStart.add(const Duration(days: 3)));
      final rtaBefore = (await _rta())[base]!;
      await reset();
      expect((await _env('food'))[base] ?? 0, closeTo(0, 0.001));
      expect((await _rta())[base], closeTo(rtaBefore + 100, 0.001));
      // Overspending is not auto-covered (it stays as "Over by" debt).
      expect((await _env('fun'))[base], closeTo(-30, 0.001));
      await _expectInvariant();
    });

    test('run twice in the same period (and from a second phone): '
        'resets once', () async {
      await _envelope('food');
      await _ledger('food', 'funding', 100,
          at: prevStart.add(const Duration(days: 1)));
      await reset();
      // Second phone: its own prefs still say last period.
      await reset();
      expect((await _env('food'))[base] ?? 0, closeTo(0, 0.001));
      final resets = await (db.select(db.allocationLedger)
            ..where((l) => l.entryType.equals('period_reset')))
          .get();
      expect(resets, hasLength(1));
      await _expectInvariant();
    });

    test('skipped months: one reset, nothing negative', () async {
      await _envelope('food');
      await _ledger('food', 'funding', 100,
          at: DateTime(prevStart.year, prevStart.month - 3, 5));
      await reset(
          lastReset: DateTime(prevStart.year, prevStart.month - 3, 1));
      expect((await _env('food'))[base] ?? 0, closeTo(0, 0.001));
      await _expectInvariant();
    });

    test('rollover envelope keeps its money; non-base currency reset per '
        'currency', () async {
      await _envelope('save', rollover: true);
      await _envelope('trip', currency: 'EUR');
      await _ledger('save', 'funding', 70,
          at: prevStart.add(const Duration(days: 1)));
      await _ledger('trip', 'funding', 40,
          currency: 'EUR', at: prevStart.add(const Duration(days: 1)));
      await _ledger('trip', 'funding', 5,
          at: prevStart.add(const Duration(days: 1)));
      await reset();
      expect((await _env('save'))[base], closeTo(70, 0.001));
      expect((await _env('trip'))['EUR'] ?? 0, closeTo(0, 0.001));
      expect((await _env('trip'))[base] ?? 0, closeTo(0, 0.001));
      await _expectInvariant();
    });

    // BUG? The reset sweeps the envelope's balance at the moment it runs,
    // not the leftover at the period start. It runs once per launch
    // (periodResetCheckProvider, dashboard), so if the app was only resumed
    // across the month boundary and the user budgeted the new month, the
    // next cold start empties that fresh funding back to Ready to assign.
    test('funding done in the new period before the reset ran is kept',
        () async {
      await _envelope('food', target: 200);
      // October: funded 100, spent 100 — nothing left over.
      await _ledger('food', 'funding', 100,
          at: prevStart.add(const Duration(days: 1)));
      await _spend('food', 100, date: prevStart.add(const Duration(days: 2)));
      // New period (app still running from last month): budget 200.
      await _ledger('food', 'funding', 200,
          at: period.start.add(const Duration(minutes: 1)));
      await reset(); // next cold start
      expect((await _env('food'))[base], closeTo(200, 0.001),
          reason: 'the new month\'s budget was swept to Ready to assign');
    });

    test('pending manual review: overspent and positive both listed',
        () async {
      await _envelope('food', autoReset: false);
      await _envelope('fun', autoReset: false);
      await _ledger('food', 'funding', 100,
          at: prevStart.add(const Duration(days: 1)));
      await _spend('fun', 30, date: prevStart.add(const Duration(days: 1)));
      final pending = await PeriodResetService.getPendingManualIds(db, hh, 1);
      expect(pending.toSet(), {'food', 'fun'});
    });

    test('review: cover overspent from RTA, then nothing pending', () async {
      await _envelope('fun', autoReset: false);
      await _spend('fun', 30, date: prevStart.add(const Duration(days: 1)));
      await PeriodEngine(db).resolveLeftover(
          allocationId: 'fun',
          currency: base,
          leftoverAmount: -30,
          resolution: LeftoverResolution.toUnallocated,
          deviceId: 'd');
      expect((await _env('fun'))[base] ?? 0, closeTo(0, 0.001));
      expect(await PeriodResetService.getPendingManualIds(db, hh, 1), isEmpty);
      await _expectInvariant();
    });

    // BUG? On the Review screen (period_transition_screen.dart) the user can
    // pick "Move to another envelope" and tap Done without choosing one —
    // the button isn't disabled for that case. resolveLeftover then returns
    // silently: nothing moves, no review marker is written, yet the screen
    // says "New period ready". The envelope stays pending.
    test('"Move to" with no envelope chosen must not silently do nothing',
        () async {
      await _envelope('food', autoReset: false);
      await _ledger('food', 'funding', 100,
          at: prevStart.add(const Duration(days: 1)));
      Object? error;
      try {
        await PeriodEngine(db).resolveLeftover(
            allocationId: 'food',
            currency: base,
            leftoverAmount: 100,
            resolution: LeftoverResolution.toOtherAllocation,
            deviceId: 'd');
      } catch (e) {
        error = e;
      }
      final stillPending =
          (await PeriodResetService.getPendingManualIds(db, hh, 1))
              .contains('food');
      expect(error != null || !stillPending, isTrue,
          reason: 'no error and the envelope is still pending after '
              '"done"');
    });
  });

  // ─────────────────────── Archive / delete ───────────────────────
  group('archive and delete', () {
    test('archiving an envelope with money: money back in RTA, balanced',
        () async {
      await _envelope('food');
      await engine.fundAllocation(
          allocationId: 'food', amount: 300, currency: base, deviceId: 'd');
      await AllocationsDao(db).archive('food');
      expect((await _rta())[base], closeTo(1000, 0.001));
      await _expectInvariant();
      // Re-assign that money, then unarchive: RTA dips below zero.
      await _envelope('rent');
      await engine.fundAllocation(
          allocationId: 'rent', amount: 1000, currency: base, deviceId: 'd');
      await AllocationsDao(db).unarchive('food');
      expect((await _rta())[base], closeTo(-300, 0.001));
      await _expectInvariant();
    });

    test('spending into an archived envelope category stays unbudgeted',
        () async {
      await _envelope('food');
      await AllocationsDao(db).archive('food');
      await _spend('food', 40);
      final rows = await (db.select(db.allocationLedger)
            ..where((l) => l.allocationId.equals('food')))
          .get();
      expect(rows, isEmpty);
      await _expectInvariant();
    });

    test('deleting an overspent envelope keeps money balanced', () async {
      await _envelope('fun');
      await _spend('fun', 80);
      await (db.update(db.allocations)..where((a) => a.id.equals('fun')))
          .write(const AllocationsCompanion(deleted: Value(true)));
      expect((await _rta())[base], closeTo(920, 0.001));
      await _expectInvariant();
    });
  });

  // ─────────────────────── Envelope in another currency ───────────────────────
  group('envelope in another currency', () {
    test('EUR envelope spent from a USD account: debt in USD, balanced',
        () async {
      await _envelope('trip', currency: 'EUR', type: 'flexible');
      await engine.fundAllocation(
          allocationId: 'trip', amount: 100, currency: 'EUR', deviceId: 'd');
      await _spend('trip', 50); // USD account
      final bal = await _env('trip');
      expect(bal['EUR'], closeTo(100, 0.001));
      expect(bal[base], closeTo(-50, 0.001));
      await _expectInvariant();
    });
  });

  // ───────────────────────────── Sinking funds ─────────────────────────────
  group('sinking fund schedules', () {
    final now = DateTime(2026, 10, 30, 12);
    void sane(FundPlan p) {
      for (final m in [p.spread, p.topUp, p.behind, p.remaining(BehindMode.ask)]) {
        for (final v in m.values) {
          expect(v.isFinite, isTrue);
          expect(v, greaterThanOrEqualTo(0));
        }
      }
    }

    test('no payments at all', () {
      final p = planSinkingFund(
          payments: const [],
          balanceAtStart: const {'USD': 50},
          funded: const {},
          anchor: DateTime(2026, 10, 1),
          balanceAtAnchor: const {},
          startDay: 1,
          now: now);
      sane(p);
      expect(p.spread, isEmpty);
    });

    test('overdue unpaid payment is due now; zero-amount payment ignored',
        () {
      final p = planSinkingFund(
          payments: [
            FundPayment(
                title: 'late', date: DateTime(2025, 1, 1), amounts: const {'USD': 600}),
            FundPayment(
                title: 'zero', date: DateTime(2027, 1, 1), amounts: const {'USD': 0}),
          ],
          balanceAtStart: const {'USD': 100},
          funded: const {},
          anchor: DateTime(2026, 10, 1),
          balanceAtAnchor: const {'USD': 100},
          startDay: 1,
          now: now);
      sane(p);
      expect(p.spread['USD'], closeTo(500, 0.001));
    });

    test('saved more than everything due: nothing to fund', () {
      final p = planSinkingFund(
          payments: [
            FundPayment(
                title: 'tax', date: DateTime(2027, 3, 1), amounts: const {'USD': 100}),
          ],
          balanceAtStart: const {'USD': 1000},
          funded: const {},
          anchor: DateTime(2026, 10, 1),
          balanceAtAnchor: const {'USD': 1000},
          startDay: 1,
          now: now);
      sane(p);
      expect(p.spread['USD'] ?? 0, 0);
    });

    test('overspent fund, start day 31, payment 40 years out', () {
      final p = planSinkingFund(
          payments: [
            FundPayment(
                title: 'far', date: DateTime(2066, 2, 29), amounts: const {'LBP': 1e9}),
            FundPayment(
                title: 'today', date: now, amounts: const {'USD': 10}),
          ],
          balanceAtStart: const {'USD': -50},
          funded: const {},
          anchor: DateTime(2025, 10, 31),
          balanceAtAnchor: const {'USD': -50},
          startDay: 31,
          now: now);
      sane(p);
      expect(p.spread['USD'], closeTo(60, 0.001));
    });

    test('bill end date before its next date: no occurrences', () {
      expect(
          fundBillDates(
              frequency: 'yearly',
              interval: 1,
              next: DateTime(2027, 1, 1),
              endDate: DateTime(2026, 1, 1),
              until: DateTime(2030, 1, 1)),
          isEmpty);
    });

    test('copy from last year: Feb 29 lands on Feb 28', () {
      final out = copyFromLastYear([
        FundPayment(
            title: 'leap', date: DateTime(2028, 2, 29), amounts: const {'USD': 5}),
      ], now: DateTime(2028, 3, 1));
      expect(out.single.payment.date, DateTime(2029, 2, 28));
    });
  });

  // ───────────────────────────── Travel ─────────────────────────────
  group('travel wallets', () {
    test('exchange with nothing received is refused', () async {
      await expectLater(
          TravelAccountService.exchange(db,
              householdId: hh,
              fromAccountId: 'usd',
              fromCurrency: 'USD',
              amount: 100,
              toCurrency: 'JPY',
              received: 0,
              newWalletName: 'Japan',
              note: ''),
          throwsArgumentError);
    });

    test('end the trip before it starts: money back, wallet closed', () async {
      final w = await TravelAccountService.exchange(db,
          householdId: hh,
          fromAccountId: 'usd',
          fromCurrency: 'USD',
          amount: 100,
          toCurrency: 'JPY',
          received: 15000,
          newWalletName: 'Japan',
          note: '');
      await TravelAccountService.convertBack(db,
          householdId: hh,
          walletId: w,
          expectedBalance: 15000,
          toAccountId: 'usd',
          received: 100,
          note: '');
      final accts = await calc.allAccountBalances(hh);
      expect(accts['usd'], closeTo(1000, 0.001));
      expect(accts.containsKey(w), isFalse); // archived
      await _expectInvariant();
    });

    test('convert back with a stale balance does nothing', () async {
      final w = await TravelAccountService.exchange(db,
          householdId: hh,
          fromAccountId: 'usd',
          fromCurrency: 'USD',
          amount: 100,
          toCurrency: 'JPY',
          received: 15000,
          newWalletName: 'Japan',
          note: '');
      await expectLater(
          TravelAccountService.convertBack(db,
              householdId: hh,
              walletId: w,
              expectedBalance: 14000,
              toAccountId: 'usd',
              received: 100,
              note: ''),
          throwsA(isA<TravelBalanceChangedException>()));
      expect((await calc.allAccountBalances(hh))[w], closeTo(15000, 0.01));
    });

    // BUG? Closing a trip archives the wallet, but an envelope funded with
    // the wallet's yen keeps them: the envelope shows ¥ it can never spend
    // and Ready to assign in JPY goes negative (with no JPY account left).
    test('closing a trip leaves no envelope holding the trip currency',
        () async {
      await _envelope('japan', type: 'flexible');
      final w = await TravelAccountService.exchange(db,
          householdId: hh,
          fromAccountId: 'usd',
          fromCurrency: 'USD',
          amount: 100,
          toCurrency: 'JPY',
          received: 15000,
          newWalletName: 'Japan',
          note: '');
      await engine.fundAllocation(
          allocationId: 'japan', amount: 5000, currency: 'JPY', deviceId: 'd');
      await TravelAccountService.convertBack(db,
          householdId: hh,
          walletId: w,
          expectedBalance: 15000,
          toAccountId: 'usd',
          received: 100,
          note: '');
      await _expectInvariant();
      expect((await _rta())['JPY'] ?? 0, greaterThanOrEqualTo(-0.5),
          reason: 'JPY Ready to assign is negative with no JPY account');
    });
  });

  // ───────────────────────────── Goals & loans ─────────────────────────────
  group('goals and loans', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
      container.read(currentHouseholdIdProvider.notifier).set(hh);
    });
    tearDown(() => container.dispose());

    Future<void> goal(String id, String name,
            {double target = 1000, DateTime? end, String type = 'goal'}) =>
        db.into(db.objectives).insert(ObjectivesCompanion.insert(
              id: id,
              householdId: hh,
              name: name,
              type: type,
              targetCurrency: base,
              deviceId: 'd',
              targetAmount: Value(target),
              endDate: Value(end),
              direction: Value(type == 'loan' ? 'borrowed' : null),
            ));

    Future<void> pump(WidgetTester tester, String id) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(initialLocation: '/', routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold()),
        GoRoute(
            path: '/o',
            builder: (_, __) => ObjectiveDetailScreen(objectiveId: id)),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      ));
      router.push('/o');
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // BUG (data loss): a goal with no tagged payments yet falls back to
    // "every transaction whose note contains the goal's name". Deleting the
    // goal then offers "Delete everything" and soft-deletes those unrelated
    // transactions (a "Car" goal takes "Car wash" and "Carrefour" with it).
    testWidgets('deleting a new goal never deletes unrelated transactions',
        (tester) async {
      late String carWash;
      await tester.runAsync(() async {
        await _envelope('misc');
        carWash = await engine.recordTransaction(
          householdId: hh,
          accountId: 'usd',
          type: 'expense',
          lines: const [TxLine(amount: 25, currency: base, categoryId: 'cat-misc')],
          baseCurrency: base,
          note: 'Car wash',
        );
        await goal('o1', 'Car');
      });
      await pump(tester, 'o1');
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await settle(tester);
      await tester.tap(find.text('Delete').last);
      await settle(tester);
      final all = find.text('Delete everything');
      if (all.evaluate().isNotEmpty) {
        await tester.tap(all);
      } else {
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      }
      await settle(tester);

      final tx = await tester.runAsync(() => (db.select(db.transactions)
            ..where((t) => t.id.equals(carWash)))
          .getSingle());
      expect(tx!.deleted, isFalse,
          reason: '"Car wash" was deleted together with the "Car" goal');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
    });

    testWidgets('goal with target 0, past due date, overpaid loan: no crash',
        (tester) async {
      await tester.runAsync(() async {
        await goal('o2', 'Zero', target: 0, end: DateTime(2020, 1, 1));
        await goal('o3', 'Loan', target: 100, type: 'loan',
            end: DateTime.now());
        await db.into(db.transactions).insert(TransactionsCompanion.insert(
              id: 'pay',
              householdId: hh,
              accountId: 'usd',
              type: 'expense',
              amount: 500,
              currency: base,
              createdBy: 'd',
              deviceId: 'd',
              note: const Value('Loan payment — Loan [obj:o3|500.0]'),
            ));
      });
      await pump(tester, 'o2');
      expect(tester.takeException(), isNull);
      await pump(tester, 'o3');
      expect(tester.takeException(), isNull);
      // Overpaid: progress is recomputed from the tagged payment.
      final o3 = await tester.runAsync(() => (db.select(db.objectives)
            ..where((o) => o.id.equals('o3')))
          .getSingle());
      expect(o3!.currentAmount, closeTo(500, 0.001));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
    });
  });
}
