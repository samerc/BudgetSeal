import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/engine/allocation_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/engine_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_serializers.dart';
import '_validation.dart';

// ── GET /api/transactions ─────────────────────────────────────────────────────

Handler listTransactionsHandler(Ref ref) {
  return (Request request) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      final params = request.url.queryParameters;
      final page = int.tryParse(params['page'] ?? '1') ?? 1;
      final limit =
          (int.tryParse(params['limit'] ?? '50') ?? 50).clamp(1, 200);
      final offset = (page - 1) * limit;
      final typeFilter = params['type'];
      final accountFilter = params['accountId'];

      if (typeFilter != null &&
          !['income', 'expense', 'transfer'].contains(typeFilter)) {
        return badRequest('type must be income, expense, or transfer');
      }

      // Optional date range filter
      final fromDate = params['from'] != null
          ? DateTime.tryParse(params['from']!)
          : null;
      final toDate = params['to'] != null
          ? DateTime.tryParse(params['to']!)
          : null;
      final search = params['search']?.trim();

      final query = db.select(db.transactions)
        ..where((t) {
          var expr =
              t.householdId.equals(householdId) & t.deleted.equals(false);
          if (typeFilter != null) expr = expr & t.type.equals(typeFilter);
          if (accountFilter != null) {
            expr = expr &
                (t.accountId.equals(accountFilter) |
                    t.destinationAccountId.equals(accountFilter));
          }
          if (fromDate != null) {
            expr = expr & t.createdAt.isBiggerOrEqualValue(fromDate);
          }
          if (toDate != null) {
            expr = expr & t.createdAt.isSmallerThanValue(toDate);
          }
          if (search != null && search.isNotEmpty) {
            // Truncate search to prevent performance issues
            final truncatedSearch = search.length > 200
                ? search.substring(0, 200)
                : search;
            expr = expr & t.note.lower().contains(truncatedSearch.toLowerCase());
          }
          return expr;
        })
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(limit, offset: offset);

      final txs = await query.get();

      final accounts = await (db.select(db.accounts)
            ..where((a) => a.householdId.equals(householdId)))
          .get();
      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catMap = {for (final c in categories) c.id: c};
      final acctMap = {for (final a in accounts) a.id: a};

      // Batch-fetch first line per transaction so the frontend can display
      // the native currency/amount (tx.amount/currency is always base).
      final txIds = txs.map((t) => t.id).toList();
      final allLines = txIds.isNotEmpty
          ? await (db.select(db.transactionLines)
                ..where((l) => l.transactionId.isIn(txIds)))
              .get()
          : <TransactionLine>[];
      final firstLineMap = <String, TransactionLine>{};
      for (final l in allLines) {
        firstLineMap.putIfAbsent(l.transactionId, () => l);
      }

      final household = await (db.select(db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();
      final baseCurrency = household?.baseCurrency ?? 'USD';

      return ok({
        'page': page,
        'limit': limit,
        'baseCurrency': baseCurrency,
        'items': txs.map((t) {
          final json = txToJson(t, catMap, acctMap);
          final line = firstLineMap[t.id];
          if (line != null) {
            json['lineCurrency'] = line.currency;
            json['lineAmount'] = line.amount;
            json['lineExchangeRate'] = line.exchangeRateToBase;
          }
          return json;
        }).toList(),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── GET /api/transactions/:id ─────────────────────────────────────────────────

Handler getTransactionHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null || id.isEmpty) return badRequest('Missing id');

    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      final tx = await db.transactionsDao.getById(id);
      if (tx == null || tx.householdId != householdId) return notFound();

      final lines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.equals(id)))
          .get();

      final accounts = await (db.select(db.accounts)
            ..where((a) => a.householdId.equals(householdId)))
          .get();
      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catMap = {for (final c in categories) c.id: c};
      final acctMap = {for (final a in accounts) a.id: a};

      return ok({
        ...txToJson(tx, catMap, acctMap),
        'lines': lines.map((l) => lineToJson(l, catMap, acctMap)).toList(),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/transactions ────────────────────────────────────────────────────

Handler createTransactionHandler(Ref ref) {
  return (Request request) async {
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final type = requireString(body, 'type');
    if (type == null || !['income', 'expense', 'transfer'].contains(type)) {
      return badRequest('type must be income, expense, or transfer');
    }

    try {
      final engine = ref.read(allocationEngineProvider);
      final db = ref.read(databaseProvider);

      final household = await (db.select(db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();
      final baseCurrency = household?.baseCurrency ?? 'USD';

      final note = truncate(optString(body, 'note') ?? '', kMaxNoteLength);
      final date = _parseDate(optString(body, 'date'));

      String txId;

      if (type == 'transfer') {
        final fromAccountId = requireString(body, 'accountId');
        final toAccountId = requireString(body, 'destinationAccountId');
        final amount = requireDouble(body, 'amount');
        final currency = optString(body, 'currency') ?? baseCurrency;
        final rate = optDouble(body, 'exchangeRateToBase') ?? 1.0;

        if (fromAccountId == null) {
          return badRequest('accountId is required for transfers');
        }
        if (toAccountId == null) {
          return badRequest('destinationAccountId is required for transfers');
        }
        if (amount == null || amount <= 0) {
          return badRequest('amount must be a positive number');
        }
        if (amount > kMaxAmount) {
          return badRequest('amount exceeds maximum allowed value');
        }
        if (rate <= 0) return badRequest('exchangeRateToBase must be positive');
        // Validate accounts exist
        if (await validateIdExists(db, 'accounts', fromAccountId) == null) {
          return badRequest('accountId does not exist');
        }
        if (await validateIdExists(db, 'accounts', toAccountId) == null) {
          return badRequest('destinationAccountId does not exist');
        }

        txId = await engine.recordTransfer(
          householdId: householdId,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amount: amount,
          currency: currency,
          exchangeRateToBase: rate,
          createdBy: 'web',
          deviceId: 'web',
          note: note,
          date: date,
        );
      } else {
        final accountId = requireString(body, 'accountId');
        if (accountId == null) return badRequest('accountId is required');
        if (await validateIdExists(db, 'accounts', accountId) == null) {
          return badRequest('accountId does not exist');
        }

        final List<TxLine> lines;
        if (body['lines'] is List && (body['lines'] as List).isNotEmpty) {
          if ((body['lines'] as List).length > 50) {
            return badRequest('Too many lines (max 50)');
          }
          final parsed = <TxLine>[];
          for (final raw in body['lines'] as List) {
            if (raw is! Map<String, dynamic>) {
              return badRequest('Each line must be an object');
            }
            final amt = requireDouble(raw, 'amount');
            if (amt == null || amt <= 0) {
              return badRequest('Each line must have a positive amount');
            }
            if (amt > kMaxAmount) {
              return badRequest('Line amount exceeds maximum allowed value');
            }
            final lineCatId = optString(raw, 'categoryId');
            if (lineCatId != null && await validateIdExists(db, 'categories', lineCatId) == null) {
              return badRequest('categoryId "$lineCatId" does not exist');
            }
            final lineAcctId = optString(raw, 'accountId');
            if (lineAcctId != null && await validateIdExists(db, 'accounts', lineAcctId) == null) {
              return badRequest('line accountId "$lineAcctId" does not exist');
            }
            final lineRate = optDouble(raw, 'exchangeRateToBase') ?? 1.0;
            if (lineRate <= 0) return badRequest('exchangeRateToBase must be positive');
            parsed.add(TxLine(
              amount: amt,
              currency: optString(raw, 'currency') ?? baseCurrency,
              categoryId: lineCatId,
              accountId: lineAcctId,
              exchangeRateToBase: lineRate,
              note: truncate(optString(raw, 'note') ?? '', kMaxNoteLength),
            ));
          }
          lines = parsed;
        } else {
          final amount = requireDouble(body, 'amount');
          if (amount == null || amount <= 0) {
            return badRequest('amount must be a positive number');
          }
          if (amount > kMaxAmount) {
            return badRequest('amount exceeds maximum allowed value');
          }
          final catId = optString(body, 'categoryId');
          if (catId != null && await validateIdExists(db, 'categories', catId) == null) {
            return badRequest('categoryId does not exist');
          }
          final rate = optDouble(body, 'exchangeRateToBase') ?? 1.0;
          if (rate <= 0) return badRequest('exchangeRateToBase must be positive');
          lines = [
            TxLine(
              amount: amount,
              currency: optString(body, 'currency') ?? baseCurrency,
              categoryId: catId,
              accountId: accountId,
              exchangeRateToBase: rate,
              note: note,
            )
          ];
        }

        txId = await engine.recordTransaction(
          householdId: householdId,
          accountId: accountId,
          type: type,
          lines: lines,
          baseCurrency: baseCurrency,
          note: note,
          deviceId: 'web',
          date: date,
        );
      }

      return created({'id': txId});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── PUT /api/transactions/:id ─────────────────────────────────────────────────
// Soft-deletes the existing transaction and creates a new one.
// Returns the new id (the old one is soft-deleted).

Handler updateTransactionHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null || id.isEmpty) return badRequest('Missing id');

    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final db = ref.read(databaseProvider);

    try {
      final existing = await db.transactionsDao.getById(id);
      if (existing == null || existing.householdId != householdId) {
        return notFound();
      }

      final engine = ref.read(allocationEngineProvider);
      final household = await (db.select(db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();
      final baseCurrency = household?.baseCurrency ?? 'USD';

      // Fetch existing lines before delete (soft-delete keeps line rows)
      final existingLines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.equals(id)))
          .get();

      final type = existing.type;
      final note = truncate(optString(body, 'note') ?? existing.note, 500);
      final date = _parseDate(optString(body, 'date')) ?? existing.createdAt;

      String newId;

      if (type == 'transfer') {
        // Validate inputs before deleting the original
        final fromAcct = optString(body, 'accountId') ?? existing.accountId;
        final toAcct = optString(body, 'destinationAccountId') ??
            existing.destinationAccountId ?? '';
        final amount = optDouble(body, 'amount') ?? existing.amount;
        final currency = optString(body, 'currency') ?? existing.currency;
        final rate = optDouble(body, 'exchangeRateToBase') ?? existing.exchangeRateToBase;

        await engine.deleteTransaction(id);

        newId = await engine.recordTransfer(
          householdId: householdId,
          fromAccountId: fromAcct,
          toAccountId: toAcct,
          amount: amount,
          currency: currency,
          exchangeRateToBase: rate,
          createdBy: 'web',
          deviceId: 'web',
          note: note,
          date: date,
        );
      } else {
        final accountId =
            optString(body, 'accountId') ?? existing.accountId;

        // Build and validate lines BEFORE deleting the original
        final List<TxLine> lines;
        if (body['lines'] is List && (body['lines'] as List).isNotEmpty) {
          final parsed = <TxLine>[];
          for (final raw in body['lines'] as List) {
            if (raw is! Map<String, dynamic>) {
              return badRequest('Each line must be an object');
            }
            final amt = requireDouble(raw, 'amount');
            if (amt == null || amt <= 0) {
              return badRequest('Each line must have a positive amount');
            }
            parsed.add(TxLine(
              amount: amt,
              currency: optString(raw, 'currency') ?? baseCurrency,
              categoryId: optString(raw, 'categoryId'),
              accountId: optString(raw, 'accountId'),
              exchangeRateToBase:
                  optDouble(raw, 'exchangeRateToBase') ?? 1.0,
              note: truncate(optString(raw, 'note') ?? '', 500),
            ));
          }
          lines = parsed;
        } else if (existingLines.isNotEmpty) {
          // Patch first line with any changed fields; keep the rest
          lines = existingLines.map((l) {
            final isFirst = l.id == existingLines.first.id;
            return TxLine(
              amount: isFirst
                  ? (optDouble(body, 'amount') ?? l.amount)
                  : l.amount,
              currency: isFirst
                  ? (optString(body, 'currency') ?? l.currency)
                  : l.currency,
              categoryId: (isFirst && body.containsKey('categoryId'))
                  ? optString(body, 'categoryId')
                  : l.categoryId,
              accountId: isFirst
                  ? (optString(body, 'accountId') ?? l.accountId)
                  : l.accountId,
              exchangeRateToBase: isFirst
                  ? (optDouble(body, 'exchangeRateToBase') ?? l.exchangeRateToBase)
                  : l.exchangeRateToBase,
              note: isFirst ? note : l.note,
            );
          }).toList();
        } else {
          lines = [
            TxLine(
              amount: optDouble(body, 'amount') ?? existing.amount,
              currency: optString(body, 'currency') ?? existing.currency,
              categoryId: body.containsKey('categoryId')
                  ? optString(body, 'categoryId')
                  : existing.categoryId,
              accountId: accountId,
              exchangeRateToBase:
                  optDouble(body, 'exchangeRateToBase') ?? existing.exchangeRateToBase,
              note: note,
            )
          ];
        }

        // Lines validated — safe to delete the original and re-create
        await engine.deleteTransaction(id);

        newId = await engine.recordTransaction(
          householdId: householdId,
          accountId: accountId,
          type: type,
          lines: lines,
          baseCurrency: baseCurrency,
          note: note,
          deviceId: 'web',
          date: date,
        );
      }

      return ok({'id': newId});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── DELETE /api/transactions/:id ──────────────────────────────────────────────

Handler deleteTransactionHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null || id.isEmpty) return badRequest('Missing id');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final db = ref.read(databaseProvider);

    try {
      final tx = await db.transactionsDao.getById(id);
      if (tx == null || tx.householdId != householdId) return notFound();

      final engine = ref.read(allocationEngineProvider);
      await engine.deleteTransaction(id);

      return ok({'success': true});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── Utilities ─────────────────────────────────────────────────────────────────

DateTime? _parseDate(String? s) {
  if (s == null) return null;
  return DateTime.tryParse(s);
}
