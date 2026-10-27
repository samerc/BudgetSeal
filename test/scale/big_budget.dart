import 'dart:math';

import 'package:budgetseal/core/data/category_presets.dart';
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/engine/planned_engine.dart';
import 'package:budgetseal/core/engine/recurring_engine.dart';
import 'package:budgetseal/shared/utils/format_number.dart';
import 'package:drift/drift.dart';

/// A realistic multi-year budget built through the engines, the way the
/// app writes it, with its own model of what every account and envelope
/// should hold.
///
/// Used by `big_budget_test.dart` (correctness and timings at scale) and to
/// write a database file for a phone (`BIG_BUDGET_DB=path`).
class BigBudget {
  static const hh = 'big-hh';
  static const base = 'USD';
  static const toBase = {'USD': 1.0, 'EUR': 1.08, 'LBP': 1 / 89500};

  /// id → (name, type, currency, opening balance)
  static const accounts = {
    'checking': ('Checking', 'checking', 'USD', 2500.0),
    'savings': ('Savings', 'savings', 'USD', 8000.0),
    'card': ('Visa card', 'credit', 'USD', 0.0),
    'cash': ('Wallet', 'cash', 'USD', 300.0),
    'eur': ('Euro account', 'checking', 'EUR', 1500.0),
    'lbp': ('Lira cash', 'cash', 'LBP', 20000000.0),
  };

  /// Where everyday spending is paid from (weights).
  static const _payWeights = {
    'card': 50,
    'checking': 24,
    'cash': 17,
    'lbp': 6,
    'eur': 3,
  };

  /// Subcategory (or group) → places it's bought at, for titles and search.
  static const _places = {
    'groceries': ['Carrefour', 'Spinneys', 'Lidl', 'Monoprix', 'Le Charcutier'],
    'dining_out': ['Pizza Hut', 'Café Younes', 'Sushi Bar', 'Barbar', 'Zaatar w Zeit'],
    'coffee': ['Starbucks', 'Costa', 'Café Younes', 'Kalei'],
    'fuel': ['Total', 'Medco', 'Coral', 'IPT'],
    'public_transit': ['Bus', 'Taxi', 'Uber', 'Metro'],
    'shopping': ['Zara', 'H&M', 'Amazon', 'IKEA', 'Virgin Megastore'],
    'health': ['Pharmacy', 'Dr. Haddad', 'Lab tests', 'Dentist'],
    'entertainment': ['Cinema', 'Concert', 'Bowling', 'Steam'],
    'home': ['Hardware store', 'Cleaning supplies', 'Plumber'],
    'personal': ['Barber', 'Gym day pass', 'Cosmetics'],
    'education': ['Bookstore', 'Udemy', 'School supplies'],
    'pets': ['Pet shop', 'Vet'],
    'travel': ['Hotel', 'Airbnb', 'Airline ticket'],
  };

  final AppDatabase db;
  final Random rnd;
  final AllocationEngine engine;

  // ── The model ──────────────────────────────────────────────────
  final Map<String, double> acct = {
    for (final e in accounts.entries) e.key: e.value.$4,
  };
  final Map<String, Map<String, double>> env = {};
  // live transaction → its effect on the model (for deletes and edits)
  final Map<String, _Effect> _live = {};
  final List<String> _expenseIds = [];

  /// category id → envelope it spends from (null: not budgeted)
  final Map<String, String?> spendEnvelope = {};
  final List<String> expenseLeaves = [];
  final Map<String, String> envelopeName = {};

  // ── Counts, for the report ─────────────────────────────────────
  final counts = <String, int>{};
  void _count(String k, [int n = 1]) => counts[k] = (counts[k] ?? 0) + n;

  /// Milliseconds per 1,000 transactions written, every 1,000 (does
  /// writing slow down as the history grows?).
  final writeMsPer1000 = <int>[];

  BigBudget(this.db, {int seed = 7})
      : rnd = Random(seed),
        engine = AllocationEngine(db);

  double envBal(String id, String cur) => env[id]?[cur] ?? 0;
  int get liveTransactions => _live.length;

  String cur(String account) => accounts[account]!.$3;

  double _round(double v, String c) {
    final scale = pow(10, currencyDecimals(c)).toDouble();
    return (v * scale).round() / scale;
  }

  T _pick<T>(List<T> l) => l[rnd.nextInt(l.length)];

  String _weighted(Map<String, int> w) {
    var r = rnd.nextInt(w.values.reduce((a, b) => a + b));
    for (final e in w.entries) {
      if (r < e.value) return e.key;
      r -= e.value;
    }
    return w.keys.last;
  }

  /// A typical price in [c] for [category].
  double _price(String category, String c) {
    final usd = switch (category) {
      'groceries' => 8 + rnd.nextDouble() * 60,
      'dining_out' => 8 + rnd.nextDouble() * 35,
      'coffee' => 2 + rnd.nextDouble() * 4,
      'fuel' => 20 + rnd.nextDouble() * 30,
      'public_transit' => 1 + rnd.nextDouble() * 10,
      'travel' => 40 + rnd.nextDouble() * 250,
      _ => 3 + rnd.nextDouble() * 40,
    };
    final v = usd / toBase[c]!;
    // Lira prices are round thousands, like real ones.
    return c == 'LBP' ? (v / 1000).roundToDouble() * 1000 : _round(v, c);
  }

  // ── Setup ──────────────────────────────────────────────────────
  Future<void> _setup() async {
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: hh, name: 'Big budget', createdByDeviceId: 'seed'));
    for (final e in accounts.entries) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
            id: e.key,
            householdId: hh,
            name: e.value.$1,
            type: e.value.$2,
            currency: e.value.$3,
            initialBalance: Value(e.value.$4),
            deviceId: 'seed',
          ));
    }
    for (final c in ['EUR', 'LBP']) {
      await db.into(db.fxRates).insert(FxRatesCompanion.insert(
          id: 'fx-$c', fromCurrency: c, toCurrency: base, rate: toBase[c]!));
    }
    var order = 0;
    for (final p in detailedPresets) {
      final isEnvelope =
          p.parentKey == null && p.type == 'expense' && p.nameKey != 'other';
      if (isEnvelope) {
        envelopeName['env-${p.nameKey}'] = p.fallbackName;
        await db.into(db.allocations).insert(AllocationsCompanion.insert(
              id: 'env-${p.nameKey}',
              householdId: hh,
              name: p.fallbackName,
              categoryId: p.nameKey,
              icon: Value(p.emoji),
              targetAmount: Value(_target(p.nameKey)),
              targetCurrency: const Value(base),
              sortOrder: Value(order++),
              deviceId: 'seed',
            ));
      }
      await db.into(db.categories).insert(CategoriesCompanion.insert(
            id: p.nameKey,
            householdId: hh,
            name: p.fallbackName,
            transactionType: Value(p.type),
            parentId: Value(p.parentKey),
            icon: Value(p.emoji),
            colorHex: Value(p.colorHex),
            allocationId: Value(isEnvelope ? 'env-${p.nameKey}' : null),
          ));
    }
    // A subcategory spends from its group's envelope.
    for (final p in detailedPresets.where((p) => p.type == 'expense')) {
      final group = p.parentKey ?? p.nameKey;
      spendEnvelope[p.nameKey] =
          envelopeName.containsKey('env-$group') ? 'env-$group' : null;
    }
    final parents = {
      for (final p in detailedPresets)
        if (p.parentKey != null) p.parentKey!,
    };
    expenseLeaves.addAll(detailedPresets
        .where((p) => p.type == 'expense' && !parents.contains(p.nameKey))
        .map((p) => p.nameKey));
  }

  static double _target(String key) => switch (key) {
        'food_drink' => 900,
        'transport' => 300,
        'bills' => 700,
        'shopping' => 250,
        'home' => 1300,
        'travel' => 200,
        _ => 120,
      };

  // ── Model bookkeeping ──────────────────────────────────────────
  void _apply(_Effect e, [int sign = 1]) {
    e.accounts.forEach((k, v) => acct[k] = acct[k]! + sign * v);
    e.envelopes.forEach((k, m) => m.forEach(
        (c, v) => (env[k] ??= {})[c] = envBal(k, c) + sign * v));
  }

  _Effect _expenseEffect(List<(String, String, double)> lines) {
    final e = _Effect();
    for (final (account, category, amount) in lines) {
      e.acct(account, -amount);
      final envelope = spendEnvelope[category];
      if (envelope != null) e.env(envelope, cur(account), -amount);
    }
    return e;
  }

  // ── Writes, each mirrored in the model ─────────────────────────
  final _sw = Stopwatch();
  int _written = 0;
  void _tick() {
    _written++;
    if (_written % 1000 == 0) {
      writeMsPer1000.add(_sw.elapsedMilliseconds);
      _sw.reset();
    }
  }

  Future<void> _income(String a, double amount, String category,
      String note, DateTime at) async {
    final id = await engine.recordTransaction(
      householdId: hh,
      accountId: a,
      type: 'income',
      lines: [
        TxLine(
            amount: amount,
            currency: cur(a),
            categoryId: category,
            accountId: a,
            exchangeRateToBase: toBase[cur(a)]!),
      ],
      baseCurrency: base,
      note: note,
      date: at,
    );
    final e = _Effect()..acct(a, amount);
    _apply(e);
    _live[id] = e;
    _count('income');
    _tick();
  }

  /// One expense line as the engine stores it (in its account's currency),
  /// sometimes typed in another currency.
  ({double stored, TxLine line}) _line(String a, String category,
      {String? note}) {
    final c = cur(a);
    final typedIn = rnd.nextInt(25) == 0
        ? _pick(toBase.keys.where((x) => x != c).toList())
        : c;
    final typed = _price(category, typedIn);
    final stored =
        typedIn == c ? typed : _round(typed * toBase[typedIn]! / toBase[c]!, c);
    if (typedIn != c) _count('foreign-currency lines');
    return (
      stored: stored,
      line: TxLine(
          amount: typed,
          currency: typedIn,
          categoryId: category,
          accountId: a,
          exchangeRateToBase: toBase[typedIn]!,
          note: note ?? ''),
    );
  }

  Future<void> _expense(DateTime at) async {
    final a = _weighted(_payWeights);
    final category = _pick(expenseLeaves);
    final group = detailedPresets
            .firstWhere((p) => p.nameKey == category)
            .parentKey ??
        category;
    final places = _places[category] ?? _places[group] ?? const ['Shop'];
    final l = _line(a, category);
    final id = await engine.recordTransaction(
      householdId: hh,
      accountId: a,
      type: 'expense',
      lines: [l.line],
      baseCurrency: base,
      note: _pick(places),
      date: at,
    );
    final e = _expenseEffect([(a, category, l.stored)]);
    _apply(e);
    _live[id] = e;
    _expenseIds.add(id);
    _count('expense');
    _tick();
  }

  Future<void> _split(DateTime at) async {
    final a = _weighted(_payWeights);
    final parts = [
      for (var i = 0; i < 2 + rnd.nextInt(3); i++)
        // Now and then one line is paid from another account.
        (rnd.nextInt(6) == 0 ? _weighted(_payWeights) : a, _pick(expenseLeaves)),
    ];
    final built = [
      for (final (acc, c) in parts) (acc, c, _line(acc, c, note: 'item'))
    ];
    final id = await engine.recordTransaction(
      householdId: hh,
      accountId: a,
      type: 'expense',
      lines: [for (final b in built) b.$3.line],
      baseCurrency: base,
      note: _pick(['Carrefour', 'Amazon', 'IKEA', 'Spinneys']),
      date: at,
    );
    final e =
        _expenseEffect([for (final (acc, c, l) in built) (acc, c, l.stored)]);
    _apply(e);
    _live[id] = e;
    _expenseIds.add(id);
    _count('split');
    _tick();
  }

  Future<void> _transfer(
      String from, String to, double amount, String note, DateTime at) async {
    final rate = toBase[cur(from)]! / toBase[cur(to)]!;
    final id = await engine.recordTransfer(
      householdId: hh,
      fromAccountId: from,
      toAccountId: to,
      amount: amount,
      currency: cur(from),
      exchangeRateToBase: rate,
      createdBy: 'seed',
      deviceId: 'seed',
      note: note,
      date: at,
    );
    final e = _Effect()
      ..acct(from, -amount)
      ..acct(to, amount * rate);
    _apply(e);
    _live[id] = e;
    _count('transfer');
    _tick();
  }

  /// Funding happens "now" in the engine; the seed moves the ledger row to
  /// the month it belongs to so history and period reports look real.
  Future<void> _fund(String envelope, double amount, String c, DateTime at) async {
    await engine.fundAllocation(
        allocationId: envelope, amount: amount, currency: c, deviceId: 'seed');
    await db.customUpdate(
      'UPDATE allocation_ledger SET created_at = ? WHERE rowid = '
      '(SELECT MAX(rowid) FROM allocation_ledger)',
      variables: [Variable.withDateTime(at)],
      updates: {db.allocationLedger},
    );
    _apply(_Effect()..env(envelope, c, amount));
    _count('funding');
  }

  Future<void> _move(DateTime at) async {
    final envs = envelopeName.keys.toList();
    final from = _pick(envs);
    final to = _pick(envs.where((x) => x != from).toList());
    final amount = (5 + rnd.nextInt(60)).toDouble();
    if (envBal(from, base) < amount) return; // the engine would refuse
    await engine.moveMoney(
        fromAllocationId: from, toAllocationId: to, amount: amount,
        currency: base);
    _apply(_Effect()
      ..env(from, base, -amount)
      ..env(to, base, amount));
    _count('envelope moves');
  }

  Future<void> _deleteOne() async {
    if (_expenseIds.isEmpty) return;
    final id = _expenseIds.removeAt(rnd.nextInt(_expenseIds.length));
    await engine.deleteTransaction(id);
    _apply(_live.remove(id)!, -1);
    _count('deleted');
  }

  Future<void> _recategoriseOne() async {
    if (_expenseIds.isEmpty) return;
    final i = rnd.nextInt(_expenseIds.length);
    final id = _expenseIds[i];
    final category = _pick(expenseLeaves);
    final lines = await (db.select(db.transactionLines)
          ..where((l) => l.transactionId.equals(id)))
        .get();
    final newId = await engine.rewriteTransaction(id, categoryId: category);
    _apply(_live.remove(id)!, -1);
    final e = _expenseEffect(
        [for (final l in lines) (l.accountId!, category, l.amount)]);
    _apply(e);
    _live[newId] = e;
    _expenseIds[i] = newId;
    _count('edited');
  }

  // ── The history ────────────────────────────────────────────────
  /// [months] of history up to today, about [perDay] purchases a day.
  Future<void> build({int months = 36, double perDay = 9}) async {
    await _setup();
    _sw.start();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(today.year, today.month - months, 1);

    // Bills and subscriptions, posted by the recurring engine's catch-up.
    final recurring = RecurringEngine(db);
    final bills = [
      ('Rent', 1200.0, 'checking', 'home', 1),
      ('Netflix', 15.99, 'card', 'entertainment', 3),
      ('Spotify', 10.99, 'card', 'entertainment', 8),
      ('Phone', 35.0, 'card', 'bills', 12),
      ('Internet', 45.0, 'checking', 'bills', 15),
      ('Gym', 40.0, 'card', 'personal', 20),
      ('Electricity', 900000.0, 'lbp', 'bills', 25),
    ];
    final billIds = <String, (double, String, String)>{};
    for (final (title, amount, a, category, day) in bills) {
      final id = await recurring.create(
        householdId: hh,
        type: 'expense',
        title: title,
        amount: amount,
        currency: cur(a),
        accountId: a,
        categoryId: category,
        frequency: 'monthly',
        startDate: DateTime(start.year, start.month, day, 9),
        isSubscription: category == 'entertainment',
      );
      billIds[id] = (amount, a, category);
    }
    await recurring.create(
      householdId: hh,
      type: 'expense',
      title: 'Car insurance',
      amount: 620,
      currency: base,
      accountId: 'checking',
      categoryId: 'transport',
      frequency: 'yearly',
      startDate: DateTime(start.year, start.month, 10, 9),
    ).then((id) => billIds[id] = (620, 'checking', 'transport'));

    for (var d = start; !d.isAfter(today); d = DateTime(d.year, d.month, d.day + 1)) {
      DateTime at(int hour) =>
          DateTime(d.year, d.month, d.day, hour, rnd.nextInt(60));
      if (d.day == 15) {
        await _income('checking', 4800, 'salary', 'Salary', at(8));
      }
      if (d.day == 1) {
        await _income('checking', 4800, 'salary', 'Salary', at(8));
        for (final envelope in envelopeName.keys) {
          final key = envelope.substring(4);
          await _fund(envelope, _target(key), base, at(8));
        }
        // Lira for cash spending in the food and transport envelopes.
        await _fund('env-food_drink', 20000000, 'LBP', at(8));
        await _fund('env-transport', 10000000, 'LBP', at(8));
        await _fund('env-bills', 1000000, 'LBP', at(8));
      }
      if (d.day == 5) {
        await _transfer('checking', 'card', 1200 + rnd.nextInt(900).toDouble(),
            'Card payment', at(10));
        await _transfer('checking', 'savings', 400, 'Savings', at(10));
      }
      if (d.day == 18 && rnd.nextBool()) {
        await _income('eur', 300 + rnd.nextInt(900).toDouble(), 'freelance',
            'Freelance invoice', at(16));
      }
      if (d.weekday == DateTime.saturday) {
        await _transfer('checking', 'cash', 250, 'ATM', at(11));
        await _transfer('cash', 'lbp', 150, 'Exchange', at(11));
      }
      // Everyday purchases (more on weekends).
      final n = (perDay * (d.weekday >= 6 ? 1.4 : 0.85) * (0.5 + rnd.nextDouble()))
          .round();
      for (var i = 0; i < n; i++) {
        if (rnd.nextInt(25) == 0) {
          await _split(at(9 + rnd.nextInt(13)));
        } else {
          await _expense(at(7 + rnd.nextInt(16)));
        }
      }
      if (rnd.nextInt(4) == 0) await _move(at(20));
      if (rnd.nextInt(3) == 0) await _recategoriseOne();
      if (rnd.nextInt(5) == 0) await _deleteOne();
    }

    final posted = await recurring.processRecurring();
    _count('bills posted', posted);
    for (final MapEntry(key: id, value: (amount, a, category))
        in billIds.entries) {
      final generated = await (db.select(db.transactions)
            ..where((t) => t.id.like('rec:$id:%') & t.deleted.equals(false)))
          .get();
      for (final t in generated) {
        final e = _expenseEffect([(a, category, amount)]);
        _apply(e);
        _live[t.id] = e;
      }
    }

    // Planned payments ahead, which must not move any balance.
    final planned = PlannedEngine(db);
    for (var i = 1; i <= 15; i++) {
      await planned.save(
        householdId: hh,
        type: 'expense',
        accountId: 'checking',
        amount: 50.0 + i * 10,
        currency: base,
        categoryId: _pick(expenseLeaves),
        note: 'Planned $i',
        date: today.add(Duration(days: i * 6)),
        createdBy: 'seed',
        deviceId: 'seed',
      );
    }
    _count('planned', 15);

    // Goals, loans and templates (lists, not money).
    for (final (i, name, type) in [
      (0, 'New car', 'goal'),
      (1, 'Emergency fund', 'goal'),
      (2, 'Loan to Rami', 'loan'),
      (3, 'Laptop', 'goal'),
    ]) {
      await db.into(db.objectives).insert(ObjectivesCompanion.insert(
            id: 'obj-$i',
            householdId: hh,
            name: name,
            type: type,
            targetAmount: Value(1000.0 * (i + 2)),
            targetCurrency: base,
            currentAmount: Value(300.0 * i),
            deviceId: 'seed',
          ));
    }
    for (var i = 0; i < 12; i++) {
      final category = expenseLeaves[i % expenseLeaves.length];
      await db.into(db.transactionTemplates).insert(
          TransactionTemplatesCompanion.insert(
              id: 'tpl-$i',
              householdId: hh,
              title: 'Template $i',
              type: 'expense',
              amount: 10.0 + i,
              currency: base,
              accountId: const Value('card'),
              categoryId: Value(category),
              useCount: Value(i)));
    }
    _sw.stop();
  }
}

class _Effect {
  final Map<String, double> accounts = {};
  final Map<String, Map<String, double>> envelopes = {};
  void acct(String id, double d) => accounts[id] = (accounts[id] ?? 0) + d;
  void env(String id, String cur, double d) =>
      (envelopes[id] ??= {})[cur] = ((envelopes[id] ??= {})[cur] ?? 0) + d;
}
