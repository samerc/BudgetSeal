import 'dart:convert';
import 'dart:math';

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/balance_calculator.dart';
import 'package:budgetseal/core/engine/base_currency_change.dart';
import 'package:budgetseal/core/sync/sync_engine.dart';
import 'package:budgetseal/shared/utils/format_number.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Model-based test of the money engine.
///
/// The app's own invariant (accounts = Ready to assign + envelopes, per
/// currency) holds by definition — Ready to assign is computed as the
/// difference — so it can't catch a wrong balance. Instead this test keeps
/// its own plain model of what every account and envelope should hold,
/// runs random operations through [AllocationEngine], and compares the two
/// after every step. Each run ends with a sync round trip and a base
/// currency change, neither of which may move a balance.
///
/// A failure prints the seed and the step; rerun one seed with
/// `--plain-name "seed N"`.
void main() {
  const seeds = 25;
  const steps = 60;
  // The sync file is encrypted when a password is stored; there is none.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (var seed = 1; seed <= seeds; seed++) {
    test('seed $seed', () => _run(seed, steps));
  }
}

const _base = 'USD';
const _toBase = {'USD': 1.0, 'EUR': 1.1, 'LBP': 1 / 90000};
const _accounts = {
  'usd': ('USD', 500.0),
  'card': ('USD', 0.0),
  'eur': ('EUR', 200.0),
  'lbp': ('LBP', 9000000.0),
};
// category → envelope it spends from (null: not budgeted)
const _spendCats = {
  'food': 'env-food',
  'food-sub': 'env-food', // a subcategory spends from its parent's envelope
  'fun': 'env-fun',
  'loose': null,
  'old': null, // linked to an archived envelope
};
const _envelopes = ['env-food', 'env-fun', 'env-save'];

class _Effect {
  final Map<String, double> accounts = {};
  final Map<String, Map<String, double>> envelopes = {};
  void acct(String id, double d) => accounts[id] = (accounts[id] ?? 0) + d;
  void env(String id, String cur, double d) =>
      (envelopes[id] ??= {})[cur] = ((envelopes[id] ??= {})[cur] ?? 0) + d;
}

class _Tx {
  final String type; // 'income' | 'expense' | 'transfer'
  final _Effect effect;
  _Tx(this.type, this.effect);
}

Future<void> _run(int seed, int steps) async {
  final rnd = Random(seed);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  final engine = AllocationEngine(db);
  final calc = BalanceCalculator(db);
  const hh = 'hh';
  final log = <String>[];

  // ── Fixture ─────────────────────────────────────────────────────
  await db.into(db.households).insert(HouseholdsCompanion.insert(
      id: hh, name: 'Home', createdByDeviceId: 'd'));
  for (final e in _accounts.entries) {
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: e.key,
          householdId: hh,
          name: e.key,
          type: 'bank',
          currency: e.value.$1,
          initialBalance: Value(e.value.$2),
          deviceId: 'd',
        ));
  }
  for (final (cur, rate) in [('EUR', 1.1), ('LBP', 1 / 90000)]) {
    await db.into(db.fxRates).insert(FxRatesCompanion.insert(
        id: 'fx-$cur', fromCurrency: cur, toCurrency: _base, rate: rate));
  }
  for (final id in [..._envelopes, 'env-old']) {
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: id,
          householdId: hh,
          name: id,
          categoryId: id,
          archived: Value(id == 'env-old'),
          deviceId: 'd',
        ));
  }
  Future<void> cat(String id, {String? env, String? parent, String type = 'expense'}) =>
      db.into(db.categories).insert(CategoriesCompanion.insert(
            id: id,
            householdId: hh,
            name: id,
            transactionType: Value(type),
            allocationId: Value(env),
            parentId: Value(parent),
          ));
  await cat('food', env: 'env-food');
  await cat('food-sub', parent: 'food');
  await cat('fun', env: 'env-fun');
  await cat('loose');
  await cat('old', env: 'env-old');
  await cat('salary', type: 'income');

  // ── Model ───────────────────────────────────────────────────────
  final acct = {for (final e in _accounts.entries) e.key: e.value.$2};
  final env = <String, Map<String, double>>{};
  final txs = <String, _Tx>{};
  double envBal(String id, String cur) => env[id]?[cur] ?? 0;
  void apply(_Effect e, [int sign = 1]) {
    e.accounts.forEach((k, v) => acct[k] = acct[k]! + sign * v);
    e.envelopes.forEach((k, m) => m.forEach((c, v) =>
        (env[k] ??= {})[c] = envBal(k, c) + sign * v));
  }

  String cur(String account) => _accounts[account]!.$1;
  double round(double v, String c) {
    final scale = pow(10, currencyDecimals(c)).toDouble();
    return (v * scale).round() / scale;
  }

  double amountIn(String c) => switch (c) {
        'LBP' => (rnd.nextInt(200) + 1) * 10000.0,
        _ => (rnd.nextInt(20000) + 1) / 100,
      };
  T pick<T>(List<T> l) => l[rnd.nextInt(l.length)];

  // An expense line as the engine stores it: in its account's currency.
  ({double amount, TxLine line}) line(String account, String category,
      {String? lineCurrency}) {
    final c = cur(account);
    final lc = lineCurrency ?? c;
    final typed = amountIn(lc);
    final stored =
        lc == c ? typed : round(typed * _toBase[lc]! / _toBase[c]!, c);
    return (
      amount: stored,
      line: TxLine(
          amount: typed,
          currency: lc,
          categoryId: category,
          accountId: account,
          exchangeRateToBase: _toBase[lc]!),
    );
  }

  _Effect expenseEffect(List<(String, String, double)> lines) {
    final e = _Effect();
    for (final (account, category, amount) in lines) {
      e.acct(account, -amount);
      final envelope = _spendCats[category];
      if (envelope != null) e.env(envelope, cur(account), -amount);
    }
    return e;
  }

  Future<void> check(String what) async {
    final got = await calc.allAccountBalances(hh);
    for (final id in _accounts.keys) {
      expect(got[id], closeTo(acct[id]!, 0.005),
          reason: 'seed $seed, after $what: account $id\n${log.join('\n')}');
    }
    final gotEnv = await calc.allAllocationBalancesByCurrency(hh);
    for (final id in _envelopes) {
      final curs = {...?gotEnv[id]?.keys, ...?env[id]?.keys};
      for (final c in curs) {
        expect(gotEnv[id]?[c] ?? 0, closeTo(envBal(id, c), 0.005),
            reason: 'seed $seed, after $what: envelope $id $c\n'
                '${log.join('\n')}');
      }
    }
    expect(gotEnv['env-old'] ?? const {}, isEmpty,
        reason: 'seed $seed, after $what: an archived envelope took spending');
  }

  // ── Random operations ───────────────────────────────────────────
  for (var step = 0; step < steps; step++) {
    final op = rnd.nextInt(10);
    String what;
    switch (op) {
      case 0: // income
        final a = pick(_accounts.keys.toList());
        final amt = amountIn(cur(a));
        final id = await engine.recordTransaction(
          householdId: hh,
          accountId: a,
          type: 'income',
          lines: [TxLine(amount: amt, currency: cur(a), categoryId: 'salary',
              accountId: a, exchangeRateToBase: _toBase[cur(a)]!)],
          baseCurrency: _base,
        );
        final e = _Effect()..acct(a, amt);
        apply(e);
        txs[id] = _Tx('income', e);
        what = 'income $a $amt';
      case 1 || 2: // expense, sometimes typed in another currency
        final a = pick(_accounts.keys.toList());
        final c = pick(_spendCats.keys.toList());
        final foreign = rnd.nextInt(4) == 0
            ? pick(_toBase.keys.where((x) => x != cur(a)).toList())
            : null;
        final l = line(a, c, lineCurrency: foreign);
        final id = await engine.recordTransaction(
            householdId: hh, accountId: a, type: 'expense',
            lines: [l.line], baseCurrency: _base);
        final e = expenseEffect([(a, c, l.amount)]);
        apply(e);
        txs[id] = _Tx('expense', e);
        what = 'expense $a $c ${l.line.amount} ${l.line.currency}';
      case 3: // split over categories and accounts
        final parts = [
          for (var i = 0; i < 2 + rnd.nextInt(2); i++)
            (pick(_accounts.keys.toList()), pick(_spendCats.keys.toList())),
        ];
        final built = [for (final (a, c) in parts) (a, c, line(a, c))];
        final id = await engine.recordTransaction(
          householdId: hh,
          accountId: parts.first.$1,
          type: 'expense',
          lines: [for (final b in built) b.$3.line],
          baseCurrency: _base,
        );
        final e = expenseEffect(
            [for (final (a, c, l) in built) (a, c, l.amount)]);
        apply(e);
        txs[id] = _Tx('expense', e);
        what = 'split ${built.map((b) => '${b.$1}/${b.$2}/${b.$3.amount}').join(' ')}';
      case 4: // transfer, maybe between currencies
        final from = pick(_accounts.keys.toList());
        final to = pick(_accounts.keys.where((x) => x != from).toList());
        final amt = amountIn(cur(from));
        final rate = _toBase[cur(from)]! / _toBase[cur(to)]!;
        final id = await engine.recordTransfer(
          householdId: hh,
          fromAccountId: from,
          toAccountId: to,
          amount: amt,
          currency: cur(from),
          exchangeRateToBase: rate,
          createdBy: 'test',
          deviceId: 'd',
        );
        final e = _Effect()
          ..acct(from, -amt)
          ..acct(to, amt * rate);
        apply(e);
        txs[id] = _Tx('transfer', e);
        what = 'transfer $from→$to $amt';
      case 5: // fund an envelope in some currency
        final e = pick(_envelopes);
        final c = pick(_toBase.keys.toList());
        final amt = amountIn(c);
        await engine.fundAllocation(
            allocationId: e, amount: amt, currency: c, deviceId: 'd');
        apply(_Effect()..env(e, c, amt));
        what = 'fund $e $amt $c';
      case 6: // move between envelopes or back to Ready to assign
        final from = pick<String?>([..._envelopes, null]);
        final to = pick<String?>(
            [..._envelopes, null].where((x) => x != from).toList());
        final c = pick(_toBase.keys.toList());
        final amt = amountIn(c);
        final enough = from == null || amt <= envBal(from, c) + 0.005;
        try {
          await engine.moveMoney(
              fromAllocationId: from, toAllocationId: to, amount: amt,
              currency: c);
          expect(enough, isTrue,
              reason: 'seed $seed: moved $amt $c out of $from holding '
                  '${from == null ? '-' : envBal(from, c)}');
          final e = _Effect();
          if (from != null) e.env(from, c, -amt);
          if (to != null) e.env(to, c, amt);
          apply(e);
        } on StateError {
          expect(enough, isFalse,
              reason: 'seed $seed: refused a move $from holding enough');
        }
        what = 'move $from→$to $amt $c (${enough ? 'ok' : 'refused'})';
      case 7: // delete a transaction
        if (txs.isEmpty) continue;
        final id = pick(txs.keys.toList());
        await engine.deleteTransaction(id);
        apply(txs.remove(id)!.effect, -1);
        what = 'delete $id';
      case 8: // recategorise an expense
        final ids = txs.entries
            .where((e) => e.value.type == 'expense')
            .map((e) => e.key)
            .toList();
        if (ids.isEmpty) continue;
        final id = pick(ids);
        final c = pick(_spendCats.keys.toList());
        final lines = await (db.select(db.transactionLines)
              ..where((l) => l.transactionId.equals(id)))
            .get();
        final newId = await engine.rewriteTransaction(id, categoryId: c);
        apply(txs.remove(id)!.effect, -1);
        final e = expenseEffect(
            [for (final l in lines) (l.accountId!, c, l.amount)]);
        apply(e);
        txs[newId] = _Tx('expense', e);
        what = 'recategorise $id → $c';
      default: // move an expense to another account, maybe another currency
        final ids = txs.entries
            .where((e) => e.value.type == 'expense')
            .map((e) => e.key)
            .toList();
        if (ids.isEmpty) continue;
        final id = pick(ids);
        final a = pick(_accounts.keys.toList());
        final lines = await (db.select(db.transactionLines)
              ..where((l) => l.transactionId.equals(id)))
            .get();
        final newId = await engine.rewriteTransaction(id, accountId: a);
        apply(txs.remove(id)!.effect, -1);
        final e = expenseEffect([
          for (final l in lines)
            (
              a,
              l.categoryId!,
              l.currency == cur(a)
                  ? l.amount
                  : round(l.amount * _toBase[l.currency]! / _toBase[cur(a)]!,
                      cur(a)),
            ),
        ]);
        apply(e);
        txs[newId] = _Tx('expense', e);
        what = 'move expense $id → $a';
    }
    log.add('${step.toString().padLeft(2)}: $what');
    await check(what);
  }

  // ── A sync round trip changes nothing ───────────────────────────
  final sync = SyncEngine(db);
  final json = await sync.exportToJson();
  expect(await sync.mergeFromJson(json), 0,
      reason: 'seed $seed: merging our own file changed rows');
  await check('merging our own sync file');

  final copy = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(copy.close);
  await SyncEngine(copy).restoreFromJson(json);
  final copyCalc = BalanceCalculator(copy);
  final original = await calc.allAccountBalances(hh);
  final restored = await copyCalc.allAccountBalances(hh);
  for (final id in _accounts.keys) {
    expect(restored[id], closeTo(original[id]!, 0.005),
        reason: 'seed $seed: account $id after restoring the sync file');
  }
  expect(await copyCalc.allAllocationBalancesByCurrency(hh),
      await calc.allAllocationBalancesByCurrency(hh),
      reason: 'seed $seed: envelopes after restoring the sync file');

  // ── A file from a phone still on 0.11 ───────────────────────────
  // Older phones write no destinationAmount (the transfer's rate is on the
  // header) and record a balance adjustment as a header-only income in the
  // account's currency. Their transfers come in as edited (newer), so the
  // merge takes them; both must land on the same balances.
  final old = jsonDecode(json) as Map<String, dynamic>;
  final later = DateTime.now().add(const Duration(days: 1)).toUtc();
  for (final t in (old['transactions'] as List).cast<Map<String, dynamic>>()) {
    if (t['type'] != 'transfer') continue;
    t.remove('destinationAmount');
    t['lastModified'] = later.toIso8601String();
  }
  const adjustment = 450000.0;
  (old['transactions'] as List).add({
    'id': 'from-0.11',
    'householdId': hh,
    'type': 'income',
    'accountId': 'lbp',
    'amount': adjustment,
    'currency': 'LBP',
    'exchangeRateToBase': _toBase['LBP'],
    'createdBy': 'user',
    'deviceId': 'old-phone',
    'createdAt': later.toIso8601String(),
    'lastModified': later.toIso8601String(),
    'deleted': false,
  });
  final oldFile = jsonEncode(old);
  await sync.mergeFromJson(oldFile);
  acct['lbp'] = acct['lbp']! + adjustment;
  await check('merging a file from a phone on 0.11');
  final fromOld = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(fromOld.close);
  await SyncEngine(fromOld).restoreFromJson(oldFile);
  final restoredOld = await BalanceCalculator(fromOld).allAccountBalances(hh);
  for (final id in _accounts.keys) {
    expect(restoredOld[id], closeTo(acct[id]!, 0.005),
        reason: 'seed $seed: account $id after restoring a 0.11 file');
  }

  // ── Changing the base currency moves no balance ─────────────────
  await changeBaseCurrency(db, hh, 'USD', 'EUR', 1 / 1.1);
  await check('changing the base currency to EUR');
}
