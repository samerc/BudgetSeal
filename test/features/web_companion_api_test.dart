import 'dart:convert';

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/features/web_companion/api/categories_handler.dart';
import 'package:budgetseal/features/web_companion/api/dashboard_handler.dart';
import 'package:budgetseal/features/web_companion/api/envelopes_handler.dart';
import 'package:budgetseal/features/web_companion/api/recurring_handler.dart';
import 'package:budgetseal/features/web_companion/api/subscriptions_handler.dart';
import 'package:budgetseal/features/web_companion/api/transactions_handler.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

/// Hands the handlers a live Ref, like the server does.
final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late Ref ref;
  const hh = 'hh1';

  Future<Map<String, dynamic>> call(Handler h, String method,
      {Map<String, dynamic>? body, String? id, String query = ''}) async {
    final res = await h(Request(
      method,
      Uri.parse('http://localhost/api/x$query'),
      body: body == null ? null : jsonEncode(body),
      context: {
        if (id != null) 'shelf_router/params': {'id': id},
      },
    ));
    final text = await res.readAsString();
    final json = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    return {'status': res.statusCode, ...(json as Map<String, dynamic>)};
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    container.read(currentHouseholdIdProvider.notifier).set(hh);
    ref = container.read(_refProvider);

    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: hh, name: 'Home', createdByDeviceId: 't'));
    for (final (id, cur) in [('usd', 'USD'), ('usd2', 'USD'), ('lbp', 'LBP')]) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id,
          householdId: hh,
          name: id,
          type: 'bank',
          currency: cur,
          deviceId: 't'));
    }
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'food', householdId: hh, name: 'Food'));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'pay',
        householdId: hh,
        name: 'Salary',
        transactionType: const Value('income')));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<Map<String, double>> balances() =>
      BalanceCalculator(db).allAccountBalances(hh);

  test('create, then change an expense into income on edit', () async {
    final created = await call(createTransactionHandler(ref), 'POST', body: {
      'type': 'expense',
      'accountId': 'usd',
      'amount': 20,
      'currency': 'USD',
      'categoryId': 'food',
      'date': '2026-09-03',
    });
    expect(created['status'], 201);
    expect((await balances())['usd'], -20);

    final edited = await call(updateTransactionHandler(ref), 'PUT',
        id: created['id'] as String,
        body: {'type': 'income', 'amount': 20, 'categoryId': 'pay'});
    expect(edited['status'], 200);
    expect((await balances())['usd'], 20);

    final tx = await db.transactionsDao.getById(edited['id'] as String);
    expect(tx!.type, 'income');
    // The calendar day is kept (time of day too).
    expect(tx.createdAt.toLocal().day, 3);
  });

  test('a transfer between currencies credits the amount received',
      () async {
    final res = await call(createTransactionHandler(ref), 'POST', body: {
      'type': 'transfer',
      'accountId': 'usd',
      'destinationAccountId': 'lbp',
      'amount': 100,
      'exchangeRateToBase': 89500,
    });
    expect(res['status'], 201);
    final b = await balances();
    expect(b['usd'], -100);
    expect(b['lbp'], 8950000);

    // Without the received amount it is refused, not credited 1:1.
    final bad = await call(createTransactionHandler(ref), 'POST', body: {
      'type': 'transfer',
      'accountId': 'usd',
      'destinationAccountId': 'lbp',
      'amount': 100,
    });
    expect(bad['status'], 400);
  });

  test('editing keeps a goal payment tag but hides it from the browser',
      () async {
    final created = await call(createTransactionHandler(ref), 'POST', body: {
      'type': 'expense',
      'accountId': 'usd',
      'amount': 50,
      'note': 'Car loan',
    });
    final id = created['id'] as String;
    await (db.update(db.transactions)..where((t) => t.id.equals(id)))
        .write(const TransactionsCompanion(note: Value('Car loan [obj:g1|50]')));

    final got = await call(getTransactionHandler(ref), 'GET', id: id);
    expect(got['note'], 'Car loan');

    final edited = await call(updateTransactionHandler(ref), 'PUT',
        id: id, body: {'note': 'Car loan payment'});
    final tx = await db.transactionsDao.getById(edited['id'] as String);
    expect(tx!.note, 'Car loan payment [obj:g1|50]');

    // Clearing the note clears it (and still keeps the tag).
    final cleared = await call(updateTransactionHandler(ref), 'PUT',
        id: edited['id'] as String, body: {'note': ''});
    final tx2 = await db.transactionsDao.getById(cleared['id'] as String);
    expect(tx2!.note.trim(), '[obj:g1|50]');
  });

  test('list pages report hasMore and give split rows their category',
      () async {
    for (var i = 0; i < 3; i++) {
      await call(createTransactionHandler(ref), 'POST', body: {
        'type': 'expense',
        'accountId': 'usd',
        'amount': 1 + i,
        'categoryId': 'food',
      });
    }
    final page1 =
        await call(listTransactionsHandler(ref), 'GET', query: '?limit=2');
    expect(page1['hasMore'], true);
    expect((page1['items'] as List).length, 2);
    expect((page1['items'] as List).first['categoryName'], 'Food');
    final page2 = await call(listTransactionsHandler(ref), 'GET',
        query: '?limit=2&page=2');
    expect(page2['hasMore'], false);
  });

  test('subscriptions: delete works and deleted ones are not listed',
      () async {
    final created = await call(createSubscriptionHandler(ref), 'POST', body: {
      'title': 'Music',
      'accountId': 'usd',
      'amount': 9.99,
      'startDate': '2026-10-15',
    });
    expect(created['status'], 201);
    final del = await call(deleteSubscriptionHandler(ref), 'DELETE',
        id: created['id'] as String);
    expect(del['status'], 200);
    final list = await call(listSubscriptionsHandler(ref), 'GET');
    expect(list['items'], isEmpty);
  });

  test('subscription price change goes to the price history', () async {
    final created = await call(createSubscriptionHandler(ref), 'POST', body: {
      'title': 'Video',
      'accountId': 'usd',
      'amount': 10,
      'startDate': '2026-10-15',
    });
    await call(updateSubscriptionHandler(ref), 'PUT',
        id: created['id'] as String, body: {'amount': 12});
    final r = await (db.select(db.recurringTransactions)
          ..where((x) => x.id.equals(created['id'] as String)))
        .getSingle();
    expect(r.amount, 12);
    expect(jsonDecode(r.priceHistory!) as List, hasLength(1));
  });

  test('recurring transfers need a destination and get one', () async {
    final bad = await call(createRecurringHandler(ref), 'POST', body: {
      'type': 'transfer',
      'accountId': 'usd',
      'amount': 100,
      'frequency': 'monthly',
      'startDate': '2026-10-01',
    });
    expect(bad['status'], 400);
    final ok = await call(createRecurringHandler(ref), 'POST', body: {
      'type': 'transfer',
      'accountId': 'usd',
      'destinationAccountId': 'usd2',
      'amount': 100,
      'frequency': 'monthly',
      'startDate': '2026-10-01',
    });
    expect(ok['status'], 201);
    final edit = await call(updateRecurringHandler(ref), 'PUT',
        id: ok['id'] as String, body: {'nextDueDate': '2026-10-31'});
    expect(edit['status'], 200);
    final r = await (db.select(db.recurringTransactions)
          ..where((x) => x.id.equals(ok['id'] as String)))
        .getSingle();
    expect(r.destinationAccountId, 'usd2');
    expect(r.anchorDay, 31);
  });

  test('a category can move under a parent, not under itself or a child',
      () async {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'snacks', householdId: hh, name: 'Snacks'));
    final moved = await call(updateCategoryHandler(ref), 'PUT',
        id: 'snacks', body: {'parentId': 'food'});
    expect(moved['status'], 200);
    final self = await call(updateCategoryHandler(ref), 'PUT',
        id: 'food', body: {'parentId': 'food'});
    expect(self['status'], 400);
    // Food now has a child, so it can't become a subcategory.
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'misc', householdId: hh, name: 'Misc'));
    final nested = await call(updateCategoryHandler(ref), 'PUT',
        id: 'food', body: {'parentId': 'misc'});
    expect(nested['status'], 400);
  });

  test('dashboard reports Ready to assign per currency', () async {
    await call(createTransactionHandler(ref), 'POST', body: {
      'type': 'income',
      'accountId': 'usd',
      'amount': 500,
      'categoryId': 'pay',
    });
    final d = await call(dashboardHandler(ref), 'GET');
    expect(d['status'], 200);
    expect((d['unallocated'] as Map)['USD'], 500);
    expect(d['period'], isNotNull);
  });

  test('money moves between envelopes and Ready to assign', () async {
    await call(createTransactionHandler(ref), 'POST', body: {
      'type': 'income',
      'accountId': 'usd',
      'amount': 500,
      'categoryId': 'pay',
    });
    for (final (id, archived) in [('a', false), ('b', false), ('old', true)]) {
      await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: id,
          householdId: hh,
          name: id,
          categoryId: 'food',
          archived: Value(archived),
          deviceId: 't'));
    }
    Future<Map<String, dynamic>> move(Map<String, dynamic> body) =>
        call(moveEnvelopeMoneyHandler(ref), 'POST',
            body: {'currency': 'USD', ...body});

    expect((await move({'toId': 'a', 'amount': 100}))['status'], 200);
    expect((await move({'fromId': 'a', 'toId': 'b', 'amount': 30}))['status'],
        200);
    // An envelope can't give more than it holds.
    expect((await move({'fromId': 'a', 'toId': 'b', 'amount': 200}))['status'],
        400);
    expect((await move({'fromId': 'b', 'amount': 10}))['status'], 200);
    expect((await move({'fromId': 'a', 'toId': 'a', 'amount': 1}))['status'],
        400);
    expect((await move({'toId': 'old', 'amount': 1}))['status'], 404);
    expect((await move({'toId': 'nope', 'amount': 1}))['status'], 404);

    final list = await call(listEnvelopesHandler(ref), 'GET');
    final byId = {
      for (final e in list['items'] as List) e['id']: e['balanceByCurrency']
    };
    expect(byId['a']['USD'], 70);
    expect(byId['b']['USD'], 20);
    expect((list['unallocated'] as Map)['USD'], 410);
  });
}
