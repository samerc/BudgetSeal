import 'dart:math';

import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:drift/drift.dart';

/// The store screenshots' budget: three months of an ordinary household's
/// money, written through the engine the way the app writes it. Every past
/// month's envelopes were funded with what was spent, so only this month
/// has money left in them.
class DemoBudget {
  DemoBudget(this.db) : engine = AllocationEngine(db);

  static const hh = 'demo';
  static const base = 'USD';

  final AppDatabase db;
  final AllocationEngine engine;
  final _rnd = Random(4);

  /// id → (name, type, opening balance)
  static const _accounts = {
    'checking': ('Checking', 'checking', 900.0),
    'card': ('Visa card', 'credit', 0.0),
    'cash': ('Wallet', 'cash', 120.0),
    'savings': ('Savings', 'savings', 2550.0),
  };

  /// envelope id → (name, emoji, category, monthly target, places, price range)
  static const _spending = {
    'groceries': ('Groceries', '🛒', 'groceries', 520.0,
        ['Whole Foods', 'Lidl', "Trader Joe's", 'Farmers market'], (18.0, 95.0), 7),
    'dining': ('Dining out', '🍽️', 'dining_out', 220.0,
        ['Sushi Go', 'Pizza night', 'Thai Garden', 'Brunch'], (14.0, 48.0), 4),
    'coffee': ('Coffee', '☕', 'coffee', 60.0,
        ['Starbucks', 'Blue Bottle', 'Corner café'], (3.5, 6.5), 9),
    'rent': ('Rent', '🔑', 'rent', 1450.0, ['Rent'], (1450.0, 1450.0), 1),
    'bills': ('Bills', '💡', 'bills', 190.0,
        ['Electricity', 'Internet', 'Phone'], (35.0, 70.0), 3),
    'transport': ('Transport', '🚗', 'transport', 160.0,
        ['Shell', 'Uber', 'Metro card'], (9.0, 48.0), 4),
    'fun': ('Fun', '🎬', 'entertainment', 120.0,
        ['Cinema', 'Concert', 'Bowling', 'Netflix'], (11.0, 38.0), 3),
    'shopping': ('Shopping', '🛍️', 'shopping', 150.0,
        ['IKEA', 'Zara', 'Amazon'], (19.0, 64.0), 2),
  };

  /// saving envelope id → (name, emoji, target, held now)
  static const _saving = {
    'japan': ('Japan trip', '✈️', 3000.0, 1850.0),
    'emergency': ('Emergency fund', '🛡️', 10000.0, 1200.0),
  };

  Future<void> build() async {
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: hh, name: 'Our budget', createdByDeviceId: 'demo'));
    for (final e in _accounts.entries) {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: e.key, householdId: hh, name: e.value.$1, type: e.value.$2,
          currency: base, initialBalance: Value(e.value.$3), deviceId: 'demo'));
    }
    // Colors as the category presets have them.
    for (final (id, name, emoji, type, color) in [
      ('groceries', 'Groceries', '🛒', 'expense', '#EF4444'),
      ('dining_out', 'Dining out', '🍽️', 'expense', '#F97316'),
      ('coffee', 'Coffee', '☕', 'expense', '#F59E0B'),
      ('rent', 'Rent', '🔑', 'expense', '#6366F1'),
      ('bills', 'Bills', '💡', 'expense', '#8B5CF6'),
      ('transport', 'Transport', '🚗', 'expense', '#06B6D4'),
      ('entertainment', 'Fun', '🎬', 'expense', '#EC4899'),
      ('shopping', 'Shopping', '🛍️', 'expense', '#14B8A6'),
      ('japan', 'Japan trip', '✈️', 'expense', '#0EA5E9'),
      ('emergency', 'Emergency fund', '🛡️', 'expense', '#64748B'),
      ('salary', 'Salary', '💵', 'income', '#10B981'),
      ('freelance', 'Freelance', '💻', 'income', '#10B981'),
    ]) {
      final envelope = {
        for (final s in _spending.entries) s.value.$3: s.key,
        'japan': 'japan',
        'emergency': 'emergency',
      }[id];
      await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: id, householdId: hh, name: name, icon: Value(emoji),
          transactionType: Value(type), colorHex: Value(color),
          allocationId: Value(envelope)));
    }
    var order = 0;
    for (final e in _spending.entries) {
      await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: e.key, householdId: hh, name: e.value.$1, categoryId: e.value.$3,
          icon: Value(e.value.$2), targetAmount: Value(e.value.$4),
          targetCurrency: const Value(base), sortOrder: Value(order++),
          deviceId: 'demo'));
    }
    for (final e in _saving.entries) {
      await db.into(db.allocations).insert(AllocationsCompanion.insert(
          id: e.key, householdId: hh, name: e.value.$1, categoryId: e.key,
          type: const Value('saving'), periodicity: const Value('permanent'),
          icon: Value(e.value.$2), targetAmount: Value(e.value.$3),
          targetCurrency: const Value(base), sortOrder: Value(order++),
          deviceId: 'demo'));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // The savings envelopes already hold what was put aside before.
    for (final e in _saving.entries) {
      await _fund(e.key, e.value.$4 - 250, DateTime(today.year, today.month - 3, 1));
    }

    for (var back = 2; back >= 0; back--) {
      final month = DateTime(today.year, today.month - back, 1);
      final last = back == 0
          ? today
          : DateTime(month.year, month.month + 1, 0);
      await _income('checking', 'salary', 3200, 'Salary', month);
      if (back == 2) {
        await _income('checking', 'freelance', 680, 'Logo design',
            DateTime(month.year, month.month, 14));
      }
      // Savings move out of Checking each month; the card is paid for
      // what it was used for the month before.
      await _transfer('checking', 'savings', 400, 'To savings',
          DateTime(month.year, month.month, 2));
      if (_cardOwed > 0) {
        await _transfer('checking', 'card', _cardOwed, 'Card payment',
            DateTime(month.year, month.month, 6));
        _cardOwed = 0;
      }
      var cardThisMonth = 0.0;
      final spent = <String, double>{};
      for (final e in _spending.entries) {
        final (_, _, category, _, places, (lo, hi), count) = e.value;
        for (var i = 0; i < count; i++) {
          final day = 1 + _rnd.nextInt(last.day);
          if (back == 0 && day > today.day) continue;
          final amount = lo == hi
              ? lo
              : ((lo + _rnd.nextDouble() * (hi - lo)) * 100).round() / 100;
          final account = category == 'rent' || category == 'bills'
              ? 'checking'
              : _rnd.nextInt(5) == 0
                  ? 'cash'
                  : 'card';
          await _expense(account, category, amount, places[i % places.length],
              DateTime(month.year, month.month, day, 9 + _rnd.nextInt(11),
                  _rnd.nextInt(60)));
          spent[e.key] = (spent[e.key] ?? 0) + amount;
          if (account == 'card') cardThisMonth += amount;
        }
      }
      _cardOwed += cardThisMonth;
      // Past months: funded with what they spent. This month: the target
      // (Shopping not quite yet).
      for (final e in _spending.entries) {
        final amount = back == 0
            ? (e.key == 'shopping' ? 90.0 : e.value.$4)
            : (spent[e.key] ?? 0);
        if (amount > 0) await _fund(e.key, amount, month);
      }
      for (final id in _saving.keys) {
        await _fund(id, back == 0 ? 50 : 100, month);
      }
    }
    // The rest of what came in went to the emergency fund, leaving a
    // little to assign.
    await _fund('emergency', _cameIn - _funded - 342.5,
        DateTime(today.year, today.month, 1));

    for (final (id, title, amount, days, category) in [
      ('netflix', 'Netflix', 15.49, 3, 'entertainment'),
      ('spotify', 'Spotify', 10.99, 6, 'entertainment'),
      ('internet', 'Internet', 49.0, 9, 'bills'),
      ('rent', 'Rent', 1450.0, 2, 'rent'),
      ('gym', 'Gym', 35.0, 12, 'shopping'),
    ]) {
      await db.into(db.recurringTransactions).insert(
          RecurringTransactionsCompanion.insert(
              id: id, householdId: hh, type: 'expense', amount: amount,
              currency: base, accountId: 'checking', frequency: 'monthly',
              categoryId: Value(category), title: Value(title),
              nextDueDate: today.add(Duration(days: days))));
    }
    await db.into(db.recurringTransactions).insert(
        RecurringTransactionsCompanion.insert(
            id: 'pay', householdId: hh, type: 'income', amount: 3200,
            currency: base, accountId: 'checking', frequency: 'monthly',
            categoryId: const Value('salary'), title: const Value('Salary'),
            nextDueDate: today.add(const Duration(days: 16))));
  }

  /// Opening balances + income, and what was funded: Ready to assign is
  /// the difference.
  double _cameIn = _accounts.values.fold(0.0, (a, e) => a + e.$3);
  double _funded = 0;
  double _cardOwed = 0;

  Future<void> _transfer(
      String from, String to, double amount, String note, DateTime at) =>
      engine.recordTransfer(
          householdId: hh, fromAccountId: from, toAccountId: to,
          amount: amount, currency: base, exchangeRateToBase: 1,
          createdBy: 'demo', deviceId: 'demo', note: note, date: at);

  Future<void> _income(String account, String category, double amount,
      String note, DateTime at) async {
    _cameIn += amount;
    await engine.recordTransaction(
      householdId: hh, accountId: account, type: 'income', baseCurrency: base,
      note: note, date: at, deviceId: 'demo',
      lines: [TxLine(amount: amount, currency: base, categoryId: category,
          accountId: account)],
    );
  }

  Future<void> _expense(String account, String category, double amount,
      String note, DateTime at) async {
    await engine.recordTransaction(
      householdId: hh, accountId: account, type: 'expense', baseCurrency: base,
      note: note, date: at, deviceId: 'demo',
      lines: [TxLine(amount: amount, currency: base, categoryId: category,
          accountId: account)],
    );
  }

  /// Funding is dated "now" by the engine; move it to the month it's for.
  Future<void> _fund(String envelope, double amount, DateTime at) async {
    _funded += amount;
    await engine.fundAllocation(
        allocationId: envelope, amount: amount, currency: base,
        deviceId: 'demo');
    await db.customUpdate(
      'UPDATE allocation_ledger SET created_at = ? WHERE rowid = '
      '(SELECT MAX(rowid) FROM allocation_ledger)',
      variables: [Variable.withDateTime(at)],
      updates: {db.allocationLedger},
    );
  }
}
