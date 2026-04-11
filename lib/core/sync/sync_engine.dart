import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Exports all data from the local database as a JSON map.
/// Imports remote data and merges by lastModified (newer wins).
class SyncEngine {
  final AppDatabase _db;

  SyncEngine(this._db);

  // ── Export ────────────────────────────────────────────────────

  /// Export the entire database as a JSON-encoded string (the sync file content).
  Future<String> exportToJson() async {
    final households = await _db.select(_db.households).get();
    final users = await _db.select(_db.users).get();
    final accounts = await _db.select(_db.accounts).get();
    final categories = await _db.select(_db.categories).get();
    final allocations = await _db.select(_db.allocations).get();
    final transactions = await _db.select(_db.transactions).get();
    final transactionLines = await _db.select(_db.transactionLines).get();
    final allocationLedger = await _db.select(_db.allocationLedger).get();
    final recurringTransactions =
        await _db.select(_db.recurringTransactions).get();
    final transactionTemplates =
        await _db.select(_db.transactionTemplates).get();
    final fxRates = await _db.select(_db.fxRates).get();

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'households': households.map(_householdToMap).toList(),
      'users': users.map(_userToMap).toList(),
      'accounts': accounts.map(_accountToMap).toList(),
      'categories': categories.map(_categoryToMap).toList(),
      'allocations': allocations.map(_allocationToMap).toList(),
      'transactions': transactions.map(_transactionToMap).toList(),
      'transactionLines': transactionLines.map(_txLineToMap).toList(),
      'allocationLedger': allocationLedger.map(_ledgerToMap).toList(),
      'recurringTransactions':
          recurringTransactions.map(_recurringToMap).toList(),
      'transactionTemplates': transactionTemplates.map(_templateToMap).toList(),
      'fxRates': fxRates.map(_fxRateToMap).toList(),
    };

    return jsonEncode(data);
  }

  // ── Import (full restore) ─────────────────────────────────────

  /// Replace all local data with the contents of a sync file.
  /// Used for restore-from-backup scenarios.
  Future<void> restoreFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    await _db.transaction(() async {
      // Delete all existing data (order matters for foreign keys)
      await _db.delete(_db.allocationLedger).go();
      await _db.delete(_db.transactionLines).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.transactionTemplates).go();
      await _db.delete(_db.recurringTransactions).go();
      await _db.delete(_db.fxRates).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.allocations).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.users).go();
      await _db.delete(_db.households).go();

      // Insert in dependency order
      for (final h in _list(data, 'households')) {
        await _db.into(_db.households).insertOnConflictUpdate(
            _householdFromMap(h));
      }
      for (final u in _list(data, 'users')) {
        await _db.into(_db.users).insertOnConflictUpdate(_userFromMap(u));
      }
      for (final a in _list(data, 'accounts')) {
        await _db.into(_db.accounts).insertOnConflictUpdate(
            _accountFromMap(a));
      }
      for (final a in _list(data, 'allocations')) {
        await _db.into(_db.allocations).insertOnConflictUpdate(
            _allocationFromMap(a));
      }
      for (final c in _list(data, 'categories')) {
        await _db.into(_db.categories).insertOnConflictUpdate(
            _categoryFromMap(c));
      }
      for (final t in _list(data, 'transactions')) {
        await _db.into(_db.transactions).insertOnConflictUpdate(
            _transactionFromMap(t));
      }
      for (final l in _list(data, 'transactionLines')) {
        await _db.into(_db.transactionLines).insertOnConflictUpdate(
            _txLineFromMap(l));
      }
      for (final l in _list(data, 'allocationLedger')) {
        await _db.into(_db.allocationLedger).insertOnConflictUpdate(
            _ledgerFromMap(l));
      }
      for (final r in _list(data, 'recurringTransactions')) {
        await _db.into(_db.recurringTransactions).insertOnConflictUpdate(
            _recurringFromMap(r));
      }
      for (final t in _list(data, 'transactionTemplates')) {
        await _db.into(_db.transactionTemplates).insertOnConflictUpdate(
            _templateFromMap(t));
      }
      for (final f in _list(data, 'fxRates')) {
        await _db.into(_db.fxRates).insertOnConflictUpdate(
            _fxRateFromMap(f));
      }
    });
  }

  // ── Merge (row-level sync) ────────────────────────────────────

  /// Merge remote data into local database.
  /// For each row: if remote lastModified > local lastModified, update local.
  /// If row doesn't exist locally, insert it.
  /// Returns the number of rows updated/inserted.
  Future<int> mergeFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    int changed = 0;

    await _db.transaction(() async {
      changed += await _mergeTable(
          _db.households, _list(data, 'households'), _householdFromMap,
          getId: (m) => m['id'] as String,
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.users, _list(data, 'users'), _userFromMap,
          getId: (m) => m['id'] as String,
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.accounts, _list(data, 'accounts'), _accountFromMap,
          getId: (m) => m['id'] as String,
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.allocations, _list(data, 'allocations'), _allocationFromMap,
          getId: (m) => m['id'] as String,
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.categories, _list(data, 'categories'), _categoryFromMap,
          getId: (m) => m['id'] as String,
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.transactions, _list(data, 'transactions'), _transactionFromMap,
          getId: (m) => m['id'] as String,
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(_db.transactionLines,
          _list(data, 'transactionLines'), _txLineFromMap,
          getId: (m) => m['id'] as String, getModified: (_) => null);

      changed += await _mergeTable(_db.allocationLedger,
          _list(data, 'allocationLedger'), _ledgerFromMap,
          getId: (m) => m['id'] as String,
          getModified: (m) => _parseDate(m['createdAt']));

      changed += await _mergeTable(_db.recurringTransactions,
          _list(data, 'recurringTransactions'), _recurringFromMap,
          getId: (m) => m['id'] as String,
          getModified: (m) => _parseDate(m['createdAt']));

      changed += await _mergeTable(_db.transactionTemplates,
          _list(data, 'transactionTemplates'), _templateFromMap,
          getId: (m) => m['id'] as String,
          getModified: (m) => _parseDate(m['lastUsedAt']));

      changed += await _mergeTable(
          _db.fxRates, _list(data, 'fxRates'), _fxRateFromMap,
          getId: (m) => m['id'] as String,
          getModified: (m) => _parseDate(m['fetchedAt']));
    });

    return changed;
  }

  /// Generic merge for any table with a text primary key.
  Future<int> _mergeTable(
    TableInfo<dynamic, dynamic> table,
    List<dynamic> remoteRows,
    Insertable<dynamic> Function(Map<String, dynamic>) fromMap, {
    required String Function(Map<String, dynamic>) getId,
    required DateTime? Function(Map<String, dynamic>) getModified,
  }) async {
    int changed = 0;
    for (final row in remoteRows) {
      final map = row as Map<String, dynamic>;
      final id = getId(map);
      final remoteModified = getModified(map);

      // Check if row exists locally
      final existing = await (_db.customSelect(
        'SELECT * FROM ${table.actualTableName} WHERE id = ?',
        variables: [Variable.withString(id)],
      )).get();

      if (existing.isEmpty) {
        // Insert new row
        await _insertOrUpdate(table, fromMap(map));
        changed++;
      } else if (remoteModified != null) {
        // Compare timestamps — update if remote is newer
        final localRow = existing.first;
        final localModifiedStr = localRow.data['last_modified'] ??
            localRow.data['created_at'] ??
            localRow.data['fetched_at'] ??
            localRow.data['last_used_at'];
        if (localModifiedStr != null) {
          final localModified = localModifiedStr is int
              ? DateTime.fromMillisecondsSinceEpoch(localModifiedStr * 1000)
              : DateTime.tryParse(localModifiedStr.toString());
          if (localModified != null &&
              remoteModified.isAfter(localModified)) {
            await _insertOrUpdate(table, fromMap(map));
            changed++;
          }
        }
      }
    }
    return changed;
  }

  /// Helper to insert-or-update using the correct table type.
  Future<void> _insertOrUpdate(
    TableInfo<dynamic, dynamic> table,
    Insertable<dynamic> companion,
  ) async {
    // Cast to satisfy drift's generic constraints on into<T extends Table>().
    await _db
        .into(table as TableInfo<Table, dynamic>)
        .insertOnConflictUpdate(companion);
  }

  // ── Helpers ───────────────────────────────────────────────────

  List<dynamic> _list(Map<String, dynamic> data, String key) =>
      (data[key] as List<dynamic>?) ?? [];

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    return DateTime.tryParse(v.toString());
  }

  // ── Row → Map converters ──────────────────────────────────────

  Map<String, dynamic> _householdToMap(Household h) => {
        'id': h.id,
        'name': h.name,
        'baseCurrency': h.baseCurrency,
        'periodStartDay': h.periodStartDay,
        'createdByDeviceId': h.createdByDeviceId,
        'createdAt': h.createdAt.toIso8601String(),
        'lastModified': h.lastModified.toIso8601String(),
      };

  Map<String, dynamic> _userToMap(User u) => {
        'id': u.id,
        'householdId': u.householdId,
        'displayName': u.name,
        'role': u.role,
        'deviceId': u.deviceId,
        'createdAt': u.createdAt.toIso8601String(),
        'lastModified': u.lastModified.toIso8601String(),
      };

  Map<String, dynamic> _accountToMap(Account a) => {
        'id': a.id,
        'householdId': a.householdId,
        'name': a.name,
        'type': a.type,
        'currency': a.currency,
        'initialBalance': a.initialBalance,
        'archived': a.archived,
        'deviceId': a.deviceId,
        'createdAt': a.createdAt.toIso8601String(),
        'lastModified': a.lastModified.toIso8601String(),
      };

  Map<String, dynamic> _categoryToMap(Category c) => {
        'id': c.id,
        'householdId': c.householdId,
        'name': c.name,
        'parentId': c.parentId,
        'transactionType': c.transactionType,
        'allocationId': c.allocationId,
        'defaultAccountId': c.defaultAccountId,
        'icon': c.icon,
        'colorHex': c.colorHex,
        'archived': c.archived,
        'createdAt': c.createdAt.toIso8601String(),
        'lastModified': c.lastModified.toIso8601String(),
      };

  Map<String, dynamic> _allocationToMap(Allocation a) => {
        'id': a.id,
        'householdId': a.householdId,
        'name': a.name,
        'categoryId': a.categoryId,
        'type': a.type,
        'periodicity': a.periodicity,
        'rollover': a.rollover,
        'targetAmount': a.targetAmount,
        'targetCurrency': a.targetCurrency,
        'archived': a.archived,
        'deviceId': a.deviceId,
        'createdAt': a.createdAt.toIso8601String(),
        'lastModified': a.lastModified.toIso8601String(),
      };

  Map<String, dynamic> _transactionToMap(Transaction t) => {
        'id': t.id,
        'householdId': t.householdId,
        'type': t.type,
        'accountId': t.accountId,
        'destinationAccountId': t.destinationAccountId,
        'categoryId': t.categoryId,
        'amount': t.amount,
        'currency': t.currency,
        'exchangeRateToBase': t.exchangeRateToBase,
        'note': t.note,
        'receiptPath': t.receiptPath,
        'createdBy': t.createdBy,
        'deviceId': t.deviceId,
        'createdAt': t.createdAt.toIso8601String(),
        'lastModified': t.lastModified.toIso8601String(),
      };

  Map<String, dynamic> _txLineToMap(TransactionLine l) => {
        'id': l.id,
        'transactionId': l.transactionId,
        'categoryId': l.categoryId,
        'accountId': l.accountId,
        'amount': l.amount,
        'currency': l.currency,
        'exchangeRateToBase': l.exchangeRateToBase,
        'note': l.note,
      };

  Map<String, dynamic> _ledgerToMap(AllocationLedgerData l) => {
        'id': l.id,
        'allocationId': l.allocationId,
        'sourceTransactionId': l.sourceTransactionId,
        'sourceAccountId': l.sourceAccountId,
        'entryType': l.entryType,
        'amount': l.amount,
        'currency': l.currency,
        'exchangeRateToBase': l.exchangeRateToBase,
        'note': l.note,
        'deviceId': l.deviceId,
        'createdAt': l.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _recurringToMap(RecurringTransaction r) => {
        'id': r.id,
        'householdId': r.householdId,
        'type': r.type,
        'title': r.title,
        'amount': r.amount,
        'currency': r.currency,
        'accountId': r.accountId,
        'destinationAccountId': r.destinationAccountId,
        'categoryId': r.categoryId,
        'note': r.note,
        'frequency': r.frequency,
        'interval': r.interval,
        'nextDueDate': r.nextDueDate.toIso8601String(),
        'endDate': r.endDate?.toIso8601String(),
        'lastGeneratedDate': r.lastGeneratedDate?.toIso8601String(),
        'enabled': r.enabled,
        'createdAt': r.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _templateToMap(TransactionTemplate t) => {
        'id': t.id,
        'householdId': t.householdId,
        'title': t.title,
        'type': t.type,
        'amount': t.amount,
        'currency': t.currency,
        'accountId': t.accountId,
        'categoryId': t.categoryId,
        'useCount': t.useCount,
        'lastUsedAt': t.lastUsedAt?.toIso8601String(),
        'createdAt': t.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _fxRateToMap(FxRate f) => {
        'id': f.id,
        'baseCurrency': f.fromCurrency,
        'targetCurrency': f.toCurrency,
        'rate': f.rate,
        'fetchedAt': f.fetchedAt.toIso8601String(),
      };

  // ── Map → Companion converters ────────────────────────────────

  HouseholdsCompanion _householdFromMap(Map<String, dynamic> m) =>
      HouseholdsCompanion.insert(
        id: m['id'] as String,
        name: m['name'] as String,
        createdByDeviceId: m['createdByDeviceId'] as String? ?? 'sync',
        baseCurrency: Value(m['baseCurrency'] as String? ?? 'USD'),
        periodStartDay: Value(m['periodStartDay'] as int? ?? 1),
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
      );

  UsersCompanion _userFromMap(Map<String, dynamic> m) =>
      UsersCompanion.insert(
        id: m['id'] as String,
        householdId: m['householdId'] as String,
        name: m['displayName'] as String? ?? '',
        role: Value(m['role'] as String? ?? 'owner'),
        deviceId: m['deviceId'] as String? ?? 'local',
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
      );

  AccountsCompanion _accountFromMap(Map<String, dynamic> m) =>
      AccountsCompanion.insert(
        id: m['id'] as String,
        householdId: m['householdId'] as String,
        name: m['name'] as String,
        type: m['type'] as String? ?? 'cash',
        currency: m['currency'] as String,
        deviceId: m['deviceId'] as String? ?? 'sync',
        initialBalance: Value((m['initialBalance'] as num?)?.toDouble() ?? 0),
        archived: Value(m['archived'] as bool? ?? false),
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
      );

  CategoriesCompanion _categoryFromMap(Map<String, dynamic> m) =>
      CategoriesCompanion.insert(
        id: m['id'] as String,
        householdId: m['householdId'] as String,
        name: m['name'] as String,
        parentId: Value(m['parentId'] as String?),
        transactionType: Value(m['transactionType'] as String? ?? 'expense'),
        allocationId: Value(m['allocationId'] as String?),
        defaultAccountId: Value(m['defaultAccountId'] as String?),
        icon: Value(m['icon'] as String? ?? 'category'),
        colorHex: Value(m['colorHex'] as String? ?? '#607D8B'),
        archived: Value(m['archived'] as bool? ?? false),
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
      );

  AllocationsCompanion _allocationFromMap(Map<String, dynamic> m) =>
      AllocationsCompanion.insert(
        id: m['id'] as String,
        householdId: m['householdId'] as String,
        name: m['name'] as String,
        categoryId: m['categoryId'] as String? ?? '',
        deviceId: m['deviceId'] as String? ?? 'sync',
        type: Value(m['type'] as String? ?? 'spending'),
        periodicity: Value(m['periodicity'] as String? ?? 'periodic'),
        rollover: Value(m['rollover'] as bool? ?? false),
        targetAmount: Value((m['targetAmount'] as num?)?.toDouble()),
        targetCurrency: Value(m['targetCurrency'] as String?),
        archived: Value(m['archived'] as bool? ?? false),
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
      );

  TransactionsCompanion _transactionFromMap(Map<String, dynamic> m) =>
      TransactionsCompanion.insert(
        id: m['id'] as String,
        householdId: m['householdId'] as String,
        type: m['type'] as String,
        accountId: m['accountId'] as String,
        destinationAccountId:
            Value(m['destinationAccountId'] as String?),
        categoryId: Value(m['categoryId'] as String?),
        amount: (m['amount'] as num).toDouble(),
        currency: m['currency'] as String,
        exchangeRateToBase: Value(
            (m['exchangeRateToBase'] as num?)?.toDouble() ?? 1.0),
        note: Value(m['note'] as String? ?? ''),
        createdBy: m['createdBy'] as String? ?? 'sync',
        deviceId: m['deviceId'] as String? ?? 'sync',
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
      );

  TransactionLinesCompanion _txLineFromMap(Map<String, dynamic> m) =>
      TransactionLinesCompanion.insert(
        id: m['id'] as String,
        transactionId: m['transactionId'] as String,
        categoryId: Value(m['categoryId'] as String?),
        accountId: Value(m['accountId'] as String?),
        amount: (m['amount'] as num).toDouble(),
        currency: m['currency'] as String,
        exchangeRateToBase: Value(
            (m['exchangeRateToBase'] as num?)?.toDouble() ?? 1.0),
        note: Value(m['note'] as String? ?? ''),
      );

  AllocationLedgerCompanion _ledgerFromMap(Map<String, dynamic> m) =>
      AllocationLedgerCompanion.insert(
        id: m['id'] as String,
        allocationId: m['allocationId'] as String,
        sourceTransactionId:
            Value(m['sourceTransactionId'] as String?),
        sourceAccountId: Value(m['sourceAccountId'] as String?),
        entryType: m['entryType'] as String,
        amount: (m['amount'] as num).toDouble(),
        currency: m['currency'] as String,
        exchangeRateToBase: Value(
            (m['exchangeRateToBase'] as num?)?.toDouble() ?? 1.0),
        note: Value(m['note'] as String? ?? ''),
        deviceId: m['deviceId'] as String? ?? 'sync',
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
      );

  RecurringTransactionsCompanion _recurringFromMap(Map<String, dynamic> m) =>
      RecurringTransactionsCompanion.insert(
        id: m['id'] as String,
        householdId: m['householdId'] as String,
        type: m['type'] as String,
        title: Value(m['title'] as String? ?? ''),
        amount: (m['amount'] as num).toDouble(),
        currency: m['currency'] as String,
        accountId: m['accountId'] as String,
        destinationAccountId:
            Value(m['destinationAccountId'] as String?),
        categoryId: Value(m['categoryId'] as String?),
        note: Value(m['note'] as String? ?? ''),
        frequency: m['frequency'] as String,
        interval: Value(m['interval'] as int? ?? 1),
        nextDueDate: _parseDate(m['nextDueDate']) ?? DateTime.now(),
        endDate: Value(_parseDate(m['endDate'])),
        lastGeneratedDate: Value(_parseDate(m['lastGeneratedDate'])),
        enabled: Value(m['enabled'] as bool? ?? true),
      );

  TransactionTemplatesCompanion _templateFromMap(Map<String, dynamic> m) =>
      TransactionTemplatesCompanion.insert(
        id: m['id'] as String,
        householdId: m['householdId'] as String,
        title: m['title'] as String,
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        currency: m['currency'] as String,
        accountId: Value(m['accountId'] as String?),
        categoryId: Value(m['categoryId'] as String?),
        useCount: Value(m['useCount'] as int? ?? 0),
        lastUsedAt: Value(_parseDate(m['lastUsedAt'])),
      );

  FxRatesCompanion _fxRateFromMap(Map<String, dynamic> m) =>
      FxRatesCompanion.insert(
        id: m['id'] as String,
        fromCurrency: m['baseCurrency'] as String,
        toCurrency: m['targetCurrency'] as String,
        rate: (m['rate'] as num).toDouble(),
        fetchedAt: Value(_parseDate(m['fetchedAt']) ?? DateTime.now()),
      );
}
