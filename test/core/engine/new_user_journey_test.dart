// End-to-end "new user journey" simulation.
//
// Reproduces what a brand-new user does after installing the app, driving the
// SAME money-flow code the screens use (AllocationEngine → allocation_ledger →
// BalanceCalculator). Editing a transaction reproduces the real screen flow:
// record the new transaction, then soft-delete the old one (see
// add_transaction_screen.dart). Every step asserts account balances, envelope
// balances, unallocated, and the core invariant:
//
//     Sum(account balances) == Unallocated + Sum(allocation balances)   (per currency)
//
// It deliberately feeds WRONG data (overspend, negative amounts, bad rates,
// unset foreign rates) and then corrects it, checking the numbers each time.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/database/daos/ledger_dao.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/engine/recurring_engine.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late AllocationEngine engine;
  late RecurringEngine recurring;
  late LedgerDao ledgerDao;
  late BalanceCalculator calc;
  const uuid = Uuid();

  // "Maya's" household + accounts + envelopes, created during onboarding.
  late String hh;
  late String checking, savings;
  late String groceriesEnv, diningEnv, rentEnv;
  late String groceriesCat, diningCat, rentCat;

  Future<String> makeAccount(String name, String currency) async {
    final id = uuid.v4();
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id,
          householdId: hh,
          name: name,
          type: 'bank',
          currency: currency,
          deviceId: 'device-A',
        ));
    return id;
  }

  /// Create an envelope + a category linked to it (as onboarding does).
  Future<(String env, String cat)> makeEnvelope(String name,
      {String? targetCurrency}) async {
    final envId = uuid.v4();
    final catId = uuid.v4();
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: envId,
          householdId: hh,
          name: name,
          categoryId: catId,
          targetCurrency: Value(targetCurrency),
          deviceId: 'device-A',
        ));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: catId,
          householdId: hh,
          name: name,
          allocationId: Value(envId),
          transactionType: const Value('expense'),
        ));
    return (envId, catId);
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = AllocationEngine(db);
    recurring = RecurringEngine(db);
    ledgerDao = LedgerDao(db);
    calc = BalanceCalculator(db);

    // ── Onboarding: create household (base USD) ──
    hh = uuid.v4();
    await db.into(db.households).insert(HouseholdsCompanion.insert(
          id: hh,
          name: "Maya's Budget",
          createdByDeviceId: 'device-A',
        ));

    // ── Accounts (all start at $0) ──
    checking = await makeAccount('Checking', 'USD');
    savings = await makeAccount('Savings', 'USD');
    await makeAccount('Cash', 'USD'); // third account, stays at $0

    // ── Envelopes + linked categories ──
    (groceriesEnv, groceriesCat) = await makeEnvelope('Groceries');
    (diningEnv, diningCat) = await makeEnvelope('Dining');
    (rentEnv, rentCat) = await makeEnvelope('Rent');

    // A plain income category (not linked to any envelope).
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: uuid.v4(),
          householdId: hh,
          name: 'Salary',
          transactionType: const Value('income'),
        ));
  });

  tearDown(() async => db.close());

  // ── helpers ────────────────────────────────────────────────────────────
  Future<double> envUsd(String envId) async =>
      (await ledgerDao.getBalanceByCurrency(envId))['USD'] ?? 0.0;

  Future<double> acctUsd(String acctId) async {
    final all = await calc.allAccountBalances(hh);
    return all[acctId] ?? 0.0;
  }

  Future<double> unallocUsd() async =>
      (await calc.unallocatedByCurrency(hh))['USD'] ?? 0.0;

  /// The core invariant, per USD (all accounts here are USD):
  /// Sum(accounts) == Unallocated + Sum(envelopes).
  Future<void> expectInvariant() async {
    final accts = await calc.allAccountBalances(hh);
    final acctTotal = accts.values.fold(0.0, (s, v) => s + v);
    final unalloc = await unallocUsd();
    final allocTotal = await envUsd(groceriesEnv) +
        await envUsd(diningEnv) +
        await envUsd(rentEnv);
    expect(unalloc + allocTotal, closeTo(acctTotal, 0.001),
        reason: 'Invariant broken: accounts=$acctTotal, '
            'unallocated=$unalloc, envelopes=$allocTotal');
  }

  Future<void> income(String acctId, double amount) async {
    await engine.recordIncome(
      householdId: hh,
      accountId: acctId,
      amount: amount,
      currency: 'USD',
      exchangeRateToBase: 1.0,
      createdBy: 'user',
      deviceId: 'device-A',
      note: 'income',
    );
  }

  Future<void> fund(String envId, double amount) async {
    await engine.fundAllocation(
      allocationId: envId,
      amount: amount,
      currency: 'USD',
      deviceId: 'device-A',
    );
  }

  /// An expense entered via the classic form (recordTransaction with one line).
  Future<String> spend(String acctId, String catId, double amount,
      {String note = ''}) async {
    return engine.recordTransaction(
      householdId: hh,
      accountId: acctId,
      type: 'expense',
      lines: [TxLine(amount: amount, currency: 'USD', categoryId: catId, accountId: acctId)],
      baseCurrency: 'USD',
      note: note,
      deviceId: 'device-A',
    );
  }

  test('full new-user journey keeps every balance and the invariant correct',
      () async {
    // 1) First paycheck lands in Checking.
    await income(checking, 3000);
    expect(await acctUsd(checking), closeTo(3000, 0.001));
    expect(await unallocUsd(), closeTo(3000, 0.001));
    await expectInvariant();

    // 2) Budget the month: fund the three envelopes ($1,800 total).
    await fund(groceriesEnv, 400);
    await fund(diningEnv, 200);
    await fund(rentEnv, 1200);
    expect(await unallocUsd(), closeTo(1200, 0.001));
    expect(await envUsd(groceriesEnv), closeTo(400, 0.001));
    await expectInvariant();

    // 3) A couple of real expenses.
    final grocTxId = await spend(checking, groceriesCat, 42.50, note: 'Weekly shop');
    await spend(checking, diningCat, 30, note: 'Lunch');
    expect(await acctUsd(checking), closeTo(2927.50, 0.001)); // 3000 - 42.50 - 30
    expect(await envUsd(groceriesEnv), closeTo(357.50, 0.001)); // 400 - 42.50
    expect(await envUsd(diningEnv), closeTo(170, 0.001)); // 200 - 30
    expect(await unallocUsd(), closeTo(1200, 0.001)); // unaffected by spending
    await expectInvariant();

    // 4) WRONG DATA: a fat-fingered $3,000 grocery expense. The envelope only
    //    has $357.50, so recordExpense reports the shortfall and creates nothing.
    final bad = await engine.recordExpense(
      householdId: hh,
      accountId: checking,
      allocationId: groceriesEnv,
      amount: 3000,
      currency: 'USD',
      exchangeRateToBase: 1.0,
      createdBy: 'user',
      deviceId: 'device-A',
      categoryId: groceriesCat,
    );
    expect(bad.txId, isNull, reason: 'Overspend should not create a transaction');
    expect(bad.overspend, isNotNull);
    expect(bad.overspend!.shortfall, closeTo(2642.50, 0.001)); // 3000 - 357.50
    // Nothing changed.
    expect(await acctUsd(checking), closeTo(2927.50, 0.001));
    expect(await envUsd(groceriesEnv), closeTo(357.50, 0.001));
    await expectInvariant();

    // 4b) CORRECTED DATA: the real amount was $85.
    final ok = await engine.recordExpense(
      householdId: hh,
      accountId: checking,
      allocationId: groceriesEnv,
      amount: 85,
      currency: 'USD',
      exchangeRateToBase: 1.0,
      createdBy: 'user',
      deviceId: 'device-A',
      categoryId: groceriesCat,
    );
    expect(ok.txId, isNotNull);
    expect(await acctUsd(checking), closeTo(2842.50, 0.001)); // 2927.50 - 85
    expect(await envUsd(groceriesEnv), closeTo(272.50, 0.001)); // 357.50 - 85
    await expectInvariant();

    // 5) EDIT a transaction (screen flow = record new, delete old).
    //    Maya realizes the $42.50 weekly shop was actually $52.50.
    final editedTxId = await spend(checking, groceriesCat, 52.50, note: 'Weekly shop');
    await engine.deleteTransaction(grocTxId);
    expect(await acctUsd(checking), closeTo(2832.50, 0.001)); // 2842.50 - 10 net
    expect(await envUsd(groceriesEnv), closeTo(262.50, 0.001)); // 272.50 - 10 net
    await expectInvariant();

    // 6) Transfer $500 Checking → Savings. Envelopes untouched.
    await engine.recordTransfer(
      householdId: hh,
      fromAccountId: checking,
      toAccountId: savings,
      amount: 500,
      currency: 'USD',
      exchangeRateToBase: 1.0,
      createdBy: 'user',
      deviceId: 'device-A',
    );
    expect(await acctUsd(checking), closeTo(2332.50, 0.001));
    expect(await acctUsd(savings), closeTo(500, 0.001));
    expect(await unallocUsd(), closeTo(1200, 0.001)); // transfers don't move budget
    await expectInvariant();

    // 7) Split transaction: $65 groceries $40 + dining $25 in one entry.
    final splitTxId = await engine.recordTransaction(
      householdId: hh,
      accountId: checking,
      type: 'expense',
      lines: [
        TxLine(amount: 40, currency: 'USD', categoryId: groceriesCat, accountId: checking),
        TxLine(amount: 25, currency: 'USD', categoryId: diningCat, accountId: checking),
      ],
      baseCurrency: 'USD',
      note: 'Groceries + takeout',
      deviceId: 'device-A',
    );
    expect(await acctUsd(checking), closeTo(2267.50, 0.001)); // 2332.50 - 65
    expect(await envUsd(groceriesEnv), closeTo(222.50, 0.001)); // 262.50 - 40
    expect(await envUsd(diningEnv), closeTo(145, 0.001)); // 170 - 25
    await expectInvariant();

    // 8) Delete the split — everything restores exactly.
    await engine.deleteTransaction(splitTxId);
    expect(await acctUsd(checking), closeTo(2332.50, 0.001));
    expect(await envUsd(groceriesEnv), closeTo(262.50, 0.001));
    expect(await envUsd(diningEnv), closeTo(170, 0.001));
    await expectInvariant();

    // 9) Withdraw $200 from Rent back to unallocated (over-funded it).
    await engine.withdrawFromAllocation(
      allocationId: rentEnv,
      amount: 200,
      currency: 'USD',
      deviceId: 'device-A',
    );
    expect(await envUsd(rentEnv), closeTo(1000, 0.001)); // 1200 - 200
    expect(await unallocUsd(), closeTo(1400, 0.001)); // 1200 + 200
    await expectInvariant();

    // 10) Overspend on purpose, covered from unallocated (force commit).
    //     Dining holds $170; spend $250 and auto-cover the $80 shortfall.
    final forced = await engine.forceCommitExpense(
      householdId: hh,
      accountId: checking,
      allocationId: diningEnv,
      amount: 250,
      currency: 'USD',
      exchangeRateToBase: 1.0,
      createdBy: 'user',
      deviceId: 'device-A',
      coverFromUnallocated: true,
    );
    expect(forced, isNotNull);
    expect(await envUsd(diningEnv), closeTo(0, 0.001)); // 170 + 80 cover - 250
    expect(await unallocUsd(), closeTo(1320, 0.001)); // 1400 - 80 cover
    expect(await acctUsd(checking), closeTo(2082.50, 0.001)); // 2332.50 - 250
    await expectInvariant();

    // Sanity: the deleted/edited transactions are soft-deleted, not resurrected.
    final deletedOld = await (db.select(db.transactions)
          ..where((t) => t.id.equals(grocTxId)))
        .getSingle();
    expect(deletedOld.deleted, isTrue);
    final liveEdit = await (db.select(db.transactions)
          ..where((t) => t.id.equals(editedTxId)))
        .getSingle();
    expect(liveEdit.deleted, isFalse);
  });

  group('wrong-data guards (validation)', () {
    test('negative line amount is rejected', () async {
      expect(
        () => engine.recordTransaction(
          householdId: hh,
          accountId: checking,
          type: 'expense',
          lines: [TxLine(amount: -5, currency: 'USD', categoryId: groceriesCat, accountId: checking)],
          baseCurrency: 'USD',
          deviceId: 'device-A',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('non-positive exchange rate is rejected', () async {
      expect(
        () => engine.recordTransaction(
          householdId: hh,
          accountId: checking,
          type: 'expense',
          lines: [TxLine(amount: 5, currency: 'EUR', categoryId: groceriesCat, accountId: checking, exchangeRateToBase: 0)],
          baseCurrency: 'USD',
          deviceId: 'device-A',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('absurdly large amount (> 1 billion) is rejected', () async {
      expect(
        () => engine.recordTransaction(
          householdId: hh,
          accountId: checking,
          type: 'expense',
          lines: [TxLine(amount: 2000000000, currency: 'USD', categoryId: groceriesCat, accountId: checking)],
          baseCurrency: 'USD',
          deviceId: 'device-A',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('zero-amount income leaves balances untouched', () async {
      await income(checking, 0);
      expect(await acctUsd(checking), closeTo(0, 0.001));
      expect(await unallocUsd(), closeTo(0, 0.001));
    });

    test('withdrawing more than an envelope holds throws', () async {
      await income(checking, 100);
      await fund(groceriesEnv, 50);
      expect(
        () => engine.withdrawFromAllocation(
          allocationId: groceriesEnv,
          amount: 80,
          currency: 'USD',
          deviceId: 'device-A',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('multi-currency envelope debits', () {
    test('foreign expense with a real rate converts into the envelope currency',
        () async {
      await income(checking, 1000);
      await fund(groceriesEnv, 500); // USD envelope

      // Spend €100 with a real rate of 1 EUR = 1.1 USD.
      await engine.recordTransaction(
        householdId: hh,
        accountId: checking,
        type: 'expense',
        lines: [
          TxLine(amount: 100, currency: 'EUR', categoryId: groceriesCat, accountId: checking, exchangeRateToBase: 1.1),
        ],
        baseCurrency: 'USD',
        deviceId: 'device-A',
      );

      // Envelope is debited 100 * 1.1 = 110 USD (single-currency envelope).
      expect(await envUsd(groceriesEnv), closeTo(390, 0.001)); // 500 - 110
      final eurBal = (await ledgerDao.getBalanceByCurrency(groceriesEnv))['EUR'];
      expect(eurBal ?? 0, closeTo(0, 0.001),
          reason: 'Envelope must not accumulate foreign currency');
    });

    test('foreign expense with NO real rate is skipped (no inflation)',
        () async {
      await income(checking, 1000);
      await fund(groceriesEnv, 500);

      // rate == 1.0 for a non-base currency means "rate not set" → skip.
      await engine.recordTransaction(
        householdId: hh,
        accountId: checking,
        type: 'expense',
        lines: [
          TxLine(amount: 100, currency: 'EUR', categoryId: groceriesCat, accountId: checking, exchangeRateToBase: 1.0),
        ],
        baseCurrency: 'USD',
        deviceId: 'device-A',
      );

      // Envelope untouched — the unconverted 100 was NOT deducted.
      expect(await envUsd(groceriesEnv), closeTo(500, 0.001));
    });
  });

  group('recurring transactions', () {
    DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

    test('a due monthly bill posts once and advances the due date', () async {
      await income(checking, 2000);
      await fund(rentEnv, 1200);
      final today = dayOnly(DateTime.now());

      final recId = await recurring.create(
        householdId: hh,
        type: 'expense',
        title: 'Rent',
        amount: 1200,
        currency: 'USD',
        accountId: checking,
        categoryId: rentCat,
        frequency: 'monthly',
        startDate: today,
        endDate: today, // ensures exactly one occurrence
      );

      final generated = await recurring.processRecurring();
      expect(generated, 1);

      // The bill posted as a real expense: account + envelope both debited.
      expect(await acctUsd(checking), closeTo(800, 0.001)); // 2000 - 1200
      expect(await envUsd(rentEnv), closeTo(0, 0.001)); // 1200 - 1200
      await expectInvariant();

      // Due date advanced to next month; a second run must NOT re-post.
      final rec = await (db.select(db.recurringTransactions)
            ..where((r) => r.id.equals(recId)))
          .getSingle();
      expect(rec.nextDueDate.isAfter(today), isTrue);

      final again = await recurring.processRecurring();
      expect(again, 0, reason: 'No duplicate posting on a second run');
      expect(await acctUsd(checking), closeTo(800, 0.001));
    });

    test('missed daily occurrences all post (catch-up)', () async {
      await income(checking, 100);
      await fund(groceriesEnv, 100);
      final today = dayOnly(DateTime.now());

      await recurring.create(
        householdId: hh,
        type: 'expense',
        title: 'Daily coffee',
        amount: 10,
        currency: 'USD',
        accountId: checking,
        categoryId: groceriesCat,
        frequency: 'daily',
        startDate: today.subtract(const Duration(days: 3)),
        endDate: today,
      );

      final generated = await recurring.processRecurring();
      expect(generated, 4); // days -3, -2, -1, 0
      expect(await acctUsd(checking), closeTo(60, 0.001)); // 100 - 4*10
      expect(await envUsd(groceriesEnv), closeTo(60, 0.001));
      await expectInvariant();
    });

    test('recurring income posts without touching any envelope', () async {
      final today = dayOnly(DateTime.now());
      await recurring.create(
        householdId: hh,
        type: 'income',
        title: 'Paycheck',
        amount: 500,
        currency: 'USD',
        accountId: checking,
        frequency: 'monthly',
        startDate: today,
        endDate: today,
      );
      final generated = await recurring.processRecurring();
      expect(generated, 1);
      expect(await acctUsd(checking), closeTo(500, 0.001));
      expect(await unallocUsd(), closeTo(500, 0.001));
      expect(await envUsd(groceriesEnv), closeTo(0, 0.001));
    });

    test('recurring transfer moves money between accounts, no ledger',
        () async {
      await income(checking, 1000);
      final today = dayOnly(DateTime.now());
      await recurring.create(
        householdId: hh,
        type: 'transfer',
        title: 'Auto-save',
        amount: 300,
        currency: 'USD',
        accountId: checking,
        destinationAccountId: savings,
        frequency: 'monthly',
        startDate: today,
        endDate: today,
      );
      final generated = await recurring.processRecurring();
      expect(generated, 1);
      expect(await acctUsd(checking), closeTo(700, 0.001));
      expect(await acctUsd(savings), closeTo(300, 0.001));
      await expectInvariant();
    });

    test('disabled and deleted recurring items never post', () async {
      await income(checking, 1000);
      await fund(groceriesEnv, 500);
      final today = dayOnly(DateTime.now());

      final disabledId = await recurring.create(
        householdId: hh, type: 'expense', title: 'Disabled', amount: 50,
        currency: 'USD', accountId: checking, categoryId: groceriesCat,
        frequency: 'monthly', startDate: today, endDate: today,
      );
      await recurring.toggleEnabled(disabledId, false);

      final deletedId = await recurring.create(
        householdId: hh, type: 'expense', title: 'Deleted', amount: 70,
        currency: 'USD', accountId: checking, categoryId: groceriesCat,
        frequency: 'monthly', startDate: today, endDate: today,
      );
      await recurring.delete(deletedId);

      final generated = await recurring.processRecurring();
      expect(generated, 0);
      expect(await acctUsd(checking), closeTo(1000, 0.001)); // untouched
      expect(await envUsd(groceriesEnv), closeTo(500, 0.001));
    });
  });

  group('planned payments', () {
    // Create a planned transaction (status='planned') as plan_payment_screen does.
    Future<String> createPlanned({
      required String type,
      required double amount,
      String? categoryId,
      String? destAccountId,
    }) async {
      final txId = uuid.v4();
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
            id: txId,
            householdId: hh,
            type: type,
            accountId: checking,
            destinationAccountId: Value(destAccountId),
            amount: amount,
            currency: 'USD',
            exchangeRateToBase: const Value(1.0),
            categoryId: Value(categoryId),
            createdBy: 'user',
            deviceId: 'device-A',
            status: const Value('planned'),
          ));
      await db.into(db.transactionLines).insert(TransactionLinesCompanion.insert(
            id: uuid.v4(),
            transactionId: txId,
            amount: amount,
            currency: 'USD',
            categoryId: Value(categoryId),
            accountId: Value(checking),
            exchangeRateToBase: const Value(1.0),
          ));
      return txId;
    }

    // Mirrors _postItemSilent: create the real tx, then soft-delete the planned one.
    Future<void> postPlanned(String plannedTxId) async {
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(plannedTxId)))
          .getSingle();
      if (tx.type == 'transfer') {
        await engine.recordTransfer(
          householdId: hh,
          fromAccountId: tx.accountId,
          toAccountId: tx.destinationAccountId ?? tx.accountId,
          amount: tx.amount,
          currency: tx.currency,
          exchangeRateToBase: tx.exchangeRateToBase,
          createdBy: 'user',
          deviceId: 'device-A',
          date: tx.createdAt,
        );
      } else {
        final planLines = await (db.select(db.transactionLines)
              ..where((l) => l.transactionId.equals(plannedTxId)))
            .get();
        final lines = planLines
            .map((l) => TxLine(
                  amount: l.amount,
                  currency: l.currency,
                  categoryId: l.categoryId,
                  accountId: l.accountId,
                  exchangeRateToBase: l.exchangeRateToBase,
                ))
            .toList();
        await engine.recordTransaction(
          householdId: hh,
          accountId: tx.accountId,
          type: tx.type,
          lines: lines,
          baseCurrency: 'USD',
          date: tx.createdAt,
        );
      }
      await engine.deleteTransaction(plannedTxId);
    }

    test('a planned expense does not affect balances until posted', () async {
      await income(checking, 1000);
      await fund(groceriesEnv, 300);

      final plannedId = await createPlanned(
          type: 'expense', amount: 120, categoryId: groceriesCat);

      // Planned items are excluded from every balance/report query.
      expect(await acctUsd(checking), closeTo(1000, 0.001));
      expect(await envUsd(groceriesEnv), closeTo(300, 0.001));
      await expectInvariant();

      // Post it (the "Post" swipe/button).
      await postPlanned(plannedId);

      expect(await acctUsd(checking), closeTo(880, 0.001)); // 1000 - 120
      expect(await envUsd(groceriesEnv), closeTo(180, 0.001)); // 300 - 120
      await expectInvariant();

      // The planned row is soft-deleted; a live posted expense now exists.
      final planned = await (db.select(db.transactions)
            ..where((t) => t.id.equals(plannedId)))
          .getSingle();
      expect(planned.deleted, isTrue);

      final live = await (db.select(db.transactions)
            ..where((t) => t.deleted.equals(false) & t.status.isNull()))
          .get();
      expect(live.where((t) => t.type == 'expense'), hasLength(1));
    });

    test('posting a planned transfer moves money between accounts', () async {
      await income(checking, 1000);
      final plannedId = await createPlanned(
          type: 'transfer', amount: 200, destAccountId: savings);

      // No effect while planned.
      expect(await acctUsd(checking), closeTo(1000, 0.001));
      expect(await acctUsd(savings), closeTo(0, 0.001));

      await postPlanned(plannedId);

      expect(await acctUsd(checking), closeTo(800, 0.001));
      expect(await acctUsd(savings), closeTo(200, 0.001));
      await expectInvariant();
    });
  });
}
