import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/ledger_dao.dart';
import 'sync_encryption.dart';

/// Exports all data from the local database as a JSON map.
/// Imports remote data and merges by lastModified (newer wins).
/// When a sync password is set, the sync file is encrypted with AES-256.
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
    final objectivesList = await _db.select(_db.objectives).get();

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
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
      'objectives': objectivesList.map(_objectiveToMap).toList(),
    };

    // A few MB of JSON for a long history: encode off the UI thread.
    final json = await Isolate.run(() => jsonEncode(data));
    // Encrypt if a sync password is set
    return SyncEncryption.encrypt(json);
  }

  // ── Import (full restore) ─────────────────────────────────────

  /// Replace all local data with the contents of a sync file.
  /// Used for restore-from-backup scenarios.
  /// Automatically decrypts if the file is encrypted.
  Future<void> restoreFromJson(String rawContent) async {
    final data = await _readFile(rawContent);

    await _db.transaction(() async {
      // Delete all existing data (order matters for foreign keys)
      await _db.delete(_db.allocationLedger).go();
      await _db.delete(_db.transactionLines).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.transactionTemplates).go();
      await _db.delete(_db.recurringTransactions).go();
      await _db.delete(_db.objectives).go();
      await _db.delete(_db.fxRates).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.allocations).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.users).go();
      await _db.delete(_db.households).go();

      // Insert in dependency order using batch for performance
      await _db.batch((b) {
        for (final h in _list(data, 'households')) {
          b.insert(_db.households, _householdFromMap(h),
              onConflict: DoUpdate((_) => _householdFromMap(h)));
        }
        for (final u in _list(data, 'users')) {
          b.insert(_db.users, _userFromMap(u),
              onConflict: DoUpdate((_) => _userFromMap(u)));
        }
        for (final a in _list(data, 'accounts')) {
          b.insert(_db.accounts, _accountFromMap(a),
              onConflict: DoUpdate((_) => _accountFromMap(a)));
        }
        for (final a in _list(data, 'allocations')) {
          b.insert(_db.allocations, _allocationFromMap(a),
              onConflict: DoUpdate((_) => _allocationFromMap(a)));
        }
        for (final c in _list(data, 'categories')) {
          b.insert(_db.categories, _categoryFromMap(c),
              onConflict: DoUpdate((_) => _categoryFromMap(c)));
        }
        for (final t in _list(data, 'transactions')) {
          b.insert(_db.transactions, _transactionFromMap(t),
              onConflict: DoUpdate((_) => _transactionFromMap(t)));
        }
        for (final l in _list(data, 'transactionLines')) {
          b.insert(_db.transactionLines, _txLineFromMap(l),
              onConflict: DoUpdate((_) => _txLineFromMap(l)));
        }
        for (final l in _list(data, 'allocationLedger')) {
          b.insert(_db.allocationLedger, _ledgerFromMap(l),
              onConflict: DoUpdate((_) => _ledgerFromMap(l)));
        }
        for (final r in _list(data, 'recurringTransactions')) {
          b.insert(_db.recurringTransactions, _recurringFromMap(r),
              onConflict: DoUpdate((_) => _recurringFromMap(r)));
        }
        for (final t in _list(data, 'transactionTemplates')) {
          b.insert(_db.transactionTemplates, _templateFromMap(t),
              onConflict: DoUpdate((_) => _templateFromMap(t)));
        }
        for (final f in _list(data, 'fxRates')) {
          b.insert(_db.fxRates, _fxRateFromMap(f),
              onConflict: DoUpdate((_) => _fxRateFromMap(f)));
        }
        for (final o in _list(data, 'objectives')) {
          b.insert(_db.objectives, _objectiveFromMap(o),
              onConflict: DoUpdate((_) => _objectiveFromMap(o)));
        }
      });
    });
  }

  /// Household ids in a sync file (decrypting it if needed): tells a
  /// device connecting to an existing file whether it's the same budget.
  Future<Set<String>> householdIdsIn(String rawContent) async {
    final data = await _readFile(rawContent);
    return {
      for (final h in _list(data, 'households'))
        (h as Map<String, dynamic>)['id'] as String,
    };
  }

  // ── Merge (row-level sync) ────────────────────────────────────

  /// Merge remote data into local database.
  /// For each row: if remote lastModified > local lastModified, update local.
  /// If row doesn't exist locally, insert it.
  /// Returns the number of rows updated/inserted.
  Future<int> mergeFromJson(String rawContent) async {
    final data = await _readFile(rawContent);
    int changed = 0;

    await _db.transaction(() async {
      // A transaction deleted on the other device that this one doesn't
      // have (never got it, or purged it in Health Check) has nothing to
      // delete here: skip it with its lines and ledger rows, or purged rows
      // would come back from every sync.
      final localTx = (await _db
              .customSelect('SELECT id FROM transactions')
              .get())
          .map((r) => r.data['id'] as String)
          .toSet();
      final skipTx = {
        for (final t in _list(data, 'transactions'))
          if ((t as Map<String, dynamic>)['deleted'] == true &&
              !localTx.contains(t['id']))
            t['id'] as String,
      };
      List<dynamic> keep(String key, String txField) => skipTx.isEmpty
          ? _list(data, key)
          : _list(data, key)
              .where((r) => !skipTx.contains(
                  (r as Map<String, dynamic>)[txField]))
              .toList();

      changed += await _mergeTable(
          _db.households, _list(data, 'households'), _householdFromMap,
          getId: (m) => m['id'] as String,
          column: 'last_modified',
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.users, _list(data, 'users'), _userFromMap,
          getId: (m) => m['id'] as String,
          column: 'last_modified',
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.accounts, _list(data, 'accounts'), _accountFromMap,
          getId: (m) => m['id'] as String,
          column: 'last_modified',
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.allocations, _list(data, 'allocations'), _allocationFromMap,
          getId: (m) => m['id'] as String,
          column: 'last_modified',
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.categories, _list(data, 'categories'), _categoryFromMap,
          getId: (m) => m['id'] as String,
          column: 'last_modified',
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.transactions, keep('transactions', 'id'), _transactionFromMap,
          getId: (m) => m['id'] as String,
          column: 'last_modified',
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(_db.transactionLines,
          keep('transactionLines', 'transactionId'), _txLineFromMap,
          getId: (m) => m['id'] as String, getModified: (_) => null);

      changed += await _mergeTable(_db.allocationLedger,
          keep('allocationLedger', 'sourceTransactionId'), _ledgerFromMap,
          getId: (m) => m['id'] as String,
          column: 'created_at',
          getModified: (m) => _parseDate(m['createdAt']));

      changed += await _mergeTable(_db.recurringTransactions,
          _list(data, 'recurringTransactions'), _recurringFromMap,
          getId: (m) => m['id'] as String,
          column: 'last_modified',
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(_db.transactionTemplates,
          _list(data, 'transactionTemplates'), _templateFromMap,
          getId: (m) => m['id'] as String,
          column: 'last_modified',
          getModified: (m) => _parseDate(m['lastModified']));

      changed += await _mergeTable(
          _db.fxRates, _list(data, 'fxRates'), _fxRateFromMap,
          getId: (m) => m['id'] as String,
          column: 'fetched_at',
          getModified: (m) => _parseDate(m['fetchedAt']));

      changed += await _mergeTable(
          _db.objectives, _list(data, 'objectives'), _objectiveFromMap,
          getId: (m) => m['id'] as String,
          column: 'last_modified',
          getModified: (m) => _parseDate(m['lastModified']));

      // Ledger rows of deleted transactions are removed for good on the
      // device that deleted them, but the other device's file still has
      // them: drop them again (balances ignore them anyway).
      await LedgerDao(_db).deleteForDeletedTransactions();
    });

    return changed;
  }

  /// Generic merge for any table with a text primary key.
  /// Bulk-fetches all existing rows' IDs and timestamps in one query,
  /// then only inserts/updates rows that are new or newer.
  Future<int> _mergeTable(
    TableInfo<dynamic, dynamic> table,
    List<dynamic> remoteRows,
    Insertable<dynamic> Function(Map<String, dynamic>) fromMap, {
    required String Function(Map<String, dynamic>) getId,
    required DateTime? Function(Map<String, dynamic>) getModified,
    String? column,
  }) async {
    if (remoteRows.isEmpty) return 0;

    // Bulk-fetch all local rows' IDs + the table's own timestamp column in
    // one query. A table without one (transaction lines) is insert-only.
    final hasDeleted = table.columnsByName.containsKey('deleted');
    final localRows = await (_db.customSelect(
      'SELECT id, ${column ?? 'NULL'} AS ts, '
      '${hasDeleted ? 'deleted' : '0'} AS del FROM ${table.actualTableName}',
    )).get();

    final localTimestamps = <String, DateTime?>{};
    final localDeleted = <String>{};
    for (final row in localRows) {
      final id = row.data['id'] as String;
      if (row.data['del'] == 1) localDeleted.add(id);
      final tsStr = row.data['ts'];
      DateTime? ts;
      if (tsStr != null) {
        ts = tsStr is int
            ? DateTime.fromMillisecondsSinceEpoch(tsStr * 1000)
            : DateTime.tryParse(tsStr.toString());
      }
      localTimestamps[id] = ts;
    }

    final toWrite = <Insertable<dynamic>>[];
    for (final row in remoteRows) {
      final map = row as Map<String, dynamic>;
      final id = getId(map);
      final remoteModified = getModified(map);

      if (!localTimestamps.containsKey(id)) {
        toWrite.add(fromMap(map)); // new row
      } else if (remoteModified != null) {
        final localModified = localTimestamps[id];
        if (localModified != null && remoteModified.isAfter(localModified)) {
          toWrite.add(fromMap(map));
        } else if (remoteModified == localModified &&
            map['deleted'] == true &&
            !localDeleted.contains(id)) {
          // Same second (times are stored in whole seconds): a delete wins
          // over the edit it can't be told apart from.
          toWrite.add(fromMap(map));
        }
      }
    }
    if (toWrite.isEmpty) return 0;
    // One batch per table (a first sync can bring thousands of rows).
    // Cast to satisfy drift's generic constraints on insert<T extends Table>().
    await _db.batch((b) => b.insertAllOnConflictUpdate(
        table as TableInfo<Table, dynamic>, toWrite));
    return toWrite.length;
  }

  // ── Helpers ───────────────────────────────────────────────────

  /// Decrypts (if needed) and parses a sync file, off the UI thread.
  Future<Map<String, dynamic>> _readFile(String rawContent) async {
    final jsonStr = await SyncEncryption.decrypt(rawContent);
    final dynamic decoded;
    try {
      decoded = await Isolate.run(() => jsonDecode(jsonStr));
    } catch (e) {
      throw FormatException('Sync file is corrupted or not valid JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Sync file has unexpected format');
    }
    return decoded;
  }

  List<dynamic> _list(Map<String, dynamic> data, String key) =>
      (data[key] as List<dynamic>?) ?? [];

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    // Files are written in UTC ("…Z"); older files have local times
    // without a zone, which tryParse reads as local.
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  // ── Row → Map converters ──────────────────────────────────────

  Map<String, dynamic> _householdToMap(Household h) => {
        'id': h.id,
        'name': h.name,
        'baseCurrency': h.baseCurrency,
        'periodStartDay': h.periodStartDay,
        'createdByDeviceId': h.createdByDeviceId,
        'createdAt': h.createdAt.toUtc().toIso8601String(),
        'lastModified': h.lastModified.toUtc().toIso8601String(),
      };

  Map<String, dynamic> _userToMap(User u) => {
        'id': u.id,
        'householdId': u.householdId,
        'displayName': u.name,
        'role': u.role,
        'deviceId': u.deviceId,
        'createdAt': u.createdAt.toUtc().toIso8601String(),
        'lastModified': u.lastModified.toUtc().toIso8601String(),
      };

  Map<String, dynamic> _accountToMap(Account a) => {
        'id': a.id,
        'householdId': a.householdId,
        'name': a.name,
        'type': a.type,
        'currency': a.currency,
        'initialBalance': a.initialBalance,
        'decimalPlaces': a.decimalPlaces,
        'isTravel': a.isTravel,
        'archived': a.archived,
        'deviceId': a.deviceId,
        'createdAt': a.createdAt.toUtc().toIso8601String(),
        'lastModified': a.lastModified.toUtc().toIso8601String(),
        'deleted': a.deleted,
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
        'createdAt': c.createdAt.toUtc().toIso8601String(),
        'lastModified': c.lastModified.toUtc().toIso8601String(),
        'deleted': c.deleted,
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
        'icon': a.icon,
        'autoReset': a.autoReset,
        'archived': a.archived,
        'sortOrder': a.sortOrder,
        'deviceId': a.deviceId,
        'createdAt': a.createdAt.toUtc().toIso8601String(),
        'lastModified': a.lastModified.toUtc().toIso8601String(),
        'deleted': a.deleted,
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
        'status': t.status,
        'createdBy': t.createdBy,
        'deviceId': t.deviceId,
        'createdAt': t.createdAt.toUtc().toIso8601String(),
        'lastModified': t.lastModified.toUtc().toIso8601String(),
        'deleted': t.deleted,
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
        'createdAt': l.createdAt.toUtc().toIso8601String(),
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
        'nextDueDate': r.nextDueDate.toUtc().toIso8601String(),
        'anchorDay': r.anchorDay,
        'endDate': r.endDate?.toUtc().toIso8601String(),
        'lastGeneratedDate': r.lastGeneratedDate?.toUtc().toIso8601String(),
        'enabled': r.enabled,
        'isSubscription': r.isSubscription,
        'priceHistory': r.priceHistory,
        'createdAt': r.createdAt.toUtc().toIso8601String(),
        'lastModified': r.lastModified.toUtc().toIso8601String(),
        'deleted': r.deleted,
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
        'lastUsedAt': t.lastUsedAt?.toUtc().toIso8601String(),
        'createdAt': t.createdAt.toUtc().toIso8601String(),
        'lastModified': t.lastModified.toUtc().toIso8601String(),
        'deleted': t.deleted,
      };

  Map<String, dynamic> _fxRateToMap(FxRate f) => {
        'id': f.id,
        'baseCurrency': f.fromCurrency,
        'targetCurrency': f.toCurrency,
        'rate': f.rate,
        'fetchedAt': f.fetchedAt.toUtc().toIso8601String(),
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
        decimalPlaces: Value(m['decimalPlaces'] as int?),
        isTravel: Value(m['isTravel'] as bool? ?? false),
        archived: Value(m['archived'] as bool? ?? false),
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
        deleted: Value(m['deleted'] as bool? ?? false),
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
        deleted: Value(m['deleted'] as bool? ?? false),
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
        icon: Value(m['icon'] as String?),
        autoReset: Value(m['autoReset'] as bool? ?? true),
        archived: Value(m['archived'] as bool? ?? false),
        sortOrder: Value((m['sortOrder'] as num?)?.toInt()),
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
        deleted: Value(m['deleted'] as bool? ?? false),
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
        receiptPath: Value(m['receiptPath'] as String?),
        status: Value(m['status'] as String?),
        createdBy: m['createdBy'] as String? ?? 'sync',
        deviceId: m['deviceId'] as String? ?? 'sync',
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
        deleted: Value(m['deleted'] as bool? ?? false),
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
        anchorDay: Value(m['anchorDay'] as int?),
        endDate: Value(_parseDate(m['endDate'])),
        lastGeneratedDate: Value(_parseDate(m['lastGeneratedDate'])),
        enabled: Value(m['enabled'] as bool? ?? true),
        isSubscription: Value(m['isSubscription'] as bool? ?? false),
        priceHistory: Value(m['priceHistory'] as String?),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
        deleted: Value(m['deleted'] as bool? ?? false),
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
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
        deleted: Value(m['deleted'] as bool? ?? false),
      );

  FxRatesCompanion _fxRateFromMap(Map<String, dynamic> m) =>
      FxRatesCompanion.insert(
        id: m['id'] as String,
        fromCurrency: m['baseCurrency'] as String,
        toCurrency: m['targetCurrency'] as String,
        rate: (m['rate'] as num).toDouble(),
        fetchedAt: Value(_parseDate(m['fetchedAt']) ?? DateTime.now()),
      );

  // ── Objectives ──────────────────────────────────────────────────

  Map<String, dynamic> _objectiveToMap(Objective o) => {
        'id': o.id,
        'householdId': o.householdId,
        'name': o.name,
        'type': o.type,
        'icon': o.icon,
        'targetAmount': o.targetAmount,
        'targetCurrency': o.targetCurrency,
        'currentAmount': o.currentAmount,
        'endDate': o.endDate?.toUtc().toIso8601String(),
        'contactName': o.contactName,
        'direction': o.direction,
        'colorHex': o.colorHex,
        'archived': o.archived,
        'deviceId': o.deviceId,
        'createdAt': o.createdAt.toUtc().toIso8601String(),
        'lastModified': o.lastModified.toUtc().toIso8601String(),
        'deleted': o.deleted,
      };

  ObjectivesCompanion _objectiveFromMap(Map<String, dynamic> m) =>
      ObjectivesCompanion.insert(
        id: m['id'] as String,
        householdId: m['householdId'] as String,
        name: m['name'] as String,
        type: m['type'] as String? ?? 'goal',
        targetCurrency: m['targetCurrency'] as String? ?? 'USD',
        deviceId: m['deviceId'] as String? ?? 'sync',
        icon: Value(m['icon'] as String?),
        targetAmount: Value((m['targetAmount'] as num?)?.toDouble() ?? 0),
        currentAmount: Value((m['currentAmount'] as num?)?.toDouble() ?? 0),
        endDate: Value(_parseDate(m['endDate'])),
        contactName: Value(m['contactName'] as String?),
        direction: Value(m['direction'] as String?),
        colorHex: Value(m['colorHex'] as String? ?? '#2563EB'),
        archived: Value(m['archived'] as bool? ?? false),
        createdAt: Value(_parseDate(m['createdAt']) ?? DateTime.now()),
        lastModified: Value(_parseDate(m['lastModified']) ?? DateTime.now()),
        deleted: Value(m['deleted'] as bool? ?? false),
      );
}
