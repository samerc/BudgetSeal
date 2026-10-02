import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/engine/allocation_engine.dart';
import '../../../core/fx/fx_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/engine_provider.dart';
import '../../../core/providers/household_provider.dart';
import '../../../shared/utils/note_text.dart';
import '_running.dart';
import '_serializers.dart';
import '_validation.dart';

const _types = ['income', 'expense', 'transfer'];

// ── GET /api/transactions ─────────────────────────────────────────────────────

Handler listTransactionsHandler(Ref ref) {
  return (Request request) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      final params = request.url.queryParameters;
      final page = (int.tryParse(params['page'] ?? '1') ?? 1).clamp(1, 10000);
      final limit =
          (int.tryParse(params['limit'] ?? '50') ?? 50).clamp(1, 200);
      final offset = (page - 1) * limit;
      final typeFilter = params['type'];
      final accountFilter = params['accountId'];

      if (typeFilter != null && !_types.contains(typeFilter)) {
        return badRequest('type must be income, expense, or transfer');
      }

      // Optional date range filter
      final fromDate =
          params['from'] != null ? DateTime.tryParse(params['from']!) : null;
      final toDate =
          params['to'] != null ? DateTime.tryParse(params['to']!) : null;
      final search = params['search']?.trim();

      final query = db.select(db.transactions)
        ..where((t) {
          var expr = t.householdId.equals(householdId) &
              t.deleted.equals(false) &
              t.status.isNull();
          if (typeFilter != null) expr = expr & t.type.equals(typeFilter);
          if (accountFilter != null) {
            // Header, transfer destination, or any line on that account.
            final lineTx = db.selectOnly(db.transactionLines)
              ..addColumns([db.transactionLines.transactionId])
              ..where(db.transactionLines.accountId.equals(accountFilter));
            expr = expr &
                (t.accountId.equals(accountFilter) |
                    t.destinationAccountId.equals(accountFilter) |
                    t.id.isInQuery(lineTx));
          }
          if (fromDate != null) {
            expr = expr & t.createdAt.isBiggerOrEqualValue(fromDate);
          }
          if (toDate != null) {
            expr = expr & t.createdAt.isSmallerThanValue(toDate);
          }
          if (search != null && search.isNotEmpty) {
            final s = search.length > 200 ? search.substring(0, 200) : search;
            expr = expr & t.note.lower().contains(s.toLowerCase());
          }
          return expr;
        })
        ..orderBy([
          (t) => OrderingTerm.desc(t.createdAt),
          (t) => OrderingTerm.desc(t.id),
        ])
        // One extra row tells the browser whether a next page exists.
        ..limit(limit + 1, offset: offset);

      final rows = await query.get();
      final hasMore = rows.length > limit;
      final txs = hasMore ? rows.sublist(0, limit) : rows;

      final accounts = await (db.select(db.accounts)
            ..where((a) => a.householdId.equals(householdId)))
          .get();
      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catMap = {for (final c in categories) c.id: c};
      final acctMap = {for (final a in accounts) a.id: a};

      // First line per transaction: native currency/amount and category
      // (tx.amount/currency is always the base currency).
      final txIds = txs.map((t) => t.id).toList();
      final allLines = txIds.isEmpty
          ? <TransactionLine>[]
          : await (db.select(db.transactionLines)
                ..where((l) => l.transactionId.isIn(txIds)))
              .get();
      final firstLine = <String, TransactionLine>{};
      final lineCount = <String, int>{};
      for (final l in allLines) {
        firstLine.putIfAbsent(l.transactionId, () => l);
        lineCount[l.transactionId] = (lineCount[l.transactionId] ?? 0) + 1;
      }

      final household = await (db.select(db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();

      // One account's page: what each row did to it and the balance after.
      final account = accountFilter == null ? null : acctMap[accountFilter];
      final running = account == null || account.householdId != householdId
          ? null
          : await accountRunning(db, account);

      return ok({
        'page': page,
        'limit': limit,
        'hasMore': hasMore,
        'baseCurrency': household?.baseCurrency ?? 'USD',
        'items': txs
            .map((t) => {
                  ...txToJson(t, catMap, acctMap,
                      firstLine: firstLine[t.id],
                      lineCount: lineCount[t.id] ?? 0),
                  if (running?[t.id] != null) ...{
                    'accountAmount': running![t.id]!.effect,
                    'runningBalance': running[t.id]!.balance,
                  },
                })
            .toList(),
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
        ...txToJson(tx, catMap, acctMap,
            firstLine: lines.firstOrNull, lineCount: lines.length),
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

    try {
      final db = ref.read(databaseProvider);
      final baseCurrency = await _baseCurrency(db, householdId);
      final prepared =
          await _prepareCreate(ref, db, householdId, baseCurrency, body);
      if (prepared.error != null) return badRequest(prepared.error!);
      return created({'id': await prepared.write!()});
    } on CurrencyConversionException catch (e) {
      return badRequest('No exchange rate from ${e.from} to ${e.to}');
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/transactions/bulk ───────────────────────────────────────────────
// { items: [ <create payload>, … ] } — every row is validated first, then all
// are written in one db transaction (all or nothing). A bad row → 400 with
// its index in `row`.

const _kMaxBulkRows = 100;

Handler bulkCreateTransactionsHandler(Ref ref) {
  return (Request request) async {
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final items = body['items'];
    if (items is! List || items.isEmpty) {
      return badRequest('items must be a non-empty list');
    }
    if (items.length > _kMaxBulkRows) {
      return badRequest('At most $_kMaxBulkRows rows at a time');
    }

    final db = ref.read(databaseProvider);
    var row = 0;
    try {
      final baseCurrency = await _baseCurrency(db, householdId);
      final writes = <Future<String> Function()>[];
      for (; row < items.length; row++) {
        final item = items[row];
        if (item is! Map<String, dynamic>) {
          return _rowError(row, 'Invalid row');
        }
        final prepared =
            await _prepareCreate(ref, db, householdId, baseCurrency, item);
        if (prepared.error != null) return _rowError(row, prepared.error!);
        writes.add(prepared.write!);
      }
      row = 0;
      final ids = await db.transaction(() async {
        final ids = <String>[];
        for (; row < writes.length; row++) {
          ids.add(await writes[row]());
        }
        return ids;
      });
      return created({'ids': ids, 'count': ids.length});
    } on CurrencyConversionException catch (e) {
      return _rowError(row, 'No exchange rate from ${e.from} to ${e.to}');
    } catch (e) {
      return serverError(e);
    }
  };
}

Response _rowError(int row, String error) => badRequest(error, {'row': row});

/// Validates one create payload. Returns an error, or a function that writes
/// it (nothing is written until it's called).
Future<({String? error, Future<String> Function()? write})> _prepareCreate(
  Ref ref,
  AppDatabase db,
  String householdId,
  String baseCurrency,
  Map<String, dynamic> body,
) async {
  final type = requireString(body, 'type');
  if (type == null || !_types.contains(type)) {
    return (error: 'type must be income, expense, or transfer', write: null);
  }
  final engine = ref.read(allocationEngineProvider);
  final note = truncate(optString(body, 'note') ?? '', kMaxNoteLength);
  final date = parseWebDate(optString(body, 'date'));

  if (type == 'transfer') {
    final transfer = await _readTransfer(db, householdId, body);
    if (transfer.error != null) return (error: transfer.error, write: null);
    return (
      error: null,
      write: () => engine.recordTransfer(
            householdId: householdId,
            fromAccountId: transfer.from!,
            toAccountId: transfer.to!,
            amount: transfer.amount!,
            currency: transfer.currency!,
            exchangeRateToBase: transfer.rate!,
            createdBy: 'web',
            deviceId: 'web',
            note: note,
            date: date,
          ),
    );
  }

  final accountId = requireString(body, 'accountId');
  if (accountId == null) return (error: 'accountId is required', write: null);
  if (await validateIdExists(db, 'accounts', accountId, householdId) == null) {
    return (error: 'accountId does not exist', write: null);
  }
  final lines =
      await _readLines(db, householdId, body, accountId, baseCurrency, note);
  if (lines.error != null) return (error: lines.error, write: null);
  return (
    error: null,
    write: () => engine.recordTransaction(
          householdId: householdId,
          accountId: accountId,
          type: type,
          lines: lines.lines!,
          baseCurrency: baseCurrency,
          note: note,
          deviceId: 'web',
          date: date,
        ),
  );
}

// ── PUT /api/transactions/:id ─────────────────────────────────────────────────
// Records the edited transaction and soft-deletes the old one, in one db
// transaction (like the app's edit). Returns the new id.

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

      final type = optString(body, 'type') ?? existing.type;
      if (!_types.contains(type)) {
        return badRequest('type must be income, expense, or transfer');
      }
      final typeChanged = type != existing.type;

      final engine = ref.read(allocationEngineProvider);
      final baseCurrency = await _baseCurrency(db, householdId);
      final existingLines = await (db.select(db.transactionLines)
            ..where((l) => l.transactionId.equals(id)))
          .get();

      // The browser edits the visible note; a goal/loan payment keeps its tag.
      final visible = body.containsKey('note')
          ? (body['note'] is String ? body['note'] as String : '')
          : visibleNote(existing.note);
      final note =
          truncate(visible.trim() + noteTag(existing.note), kMaxNoteLength);
      final date = parseWebDate(optString(body, 'date'),
              keepTimeOf: existing.createdAt) ??
          existing.createdAt;

      // Validate everything before writing anything.
      _Transfer? transfer;
      List<TxLine>? lines;
      String accountId = existing.accountId;
      if (type == 'transfer') {
        transfer = await _readTransfer(db, householdId, body,
            existing: typeChanged ? null : existing);
        if (transfer.error != null) return badRequest(transfer.error!);
      } else {
        accountId = optString(body, 'accountId') ?? existing.accountId;
        if (await validateIdExists(db, 'accounts', accountId, householdId) ==
            null) {
          return badRequest('accountId does not exist');
        }
        final hasNewLines =
            body['lines'] is List && (body['lines'] as List).isNotEmpty;
        if (hasNewLines || typeChanged || existingLines.isEmpty) {
          final parsed = await _readLines(
              db, householdId, body, accountId, baseCurrency, note,
              fallback: existing);
          if (parsed.error != null) return badRequest(parsed.error!);
          lines = parsed.lines;
        } else {
          // Patch the first line with the edited fields; keep the others.
          final amount = optDouble(body, 'amount');
          if (amount != null && (amount <= 0 || amount > kMaxAmount)) {
            return badRequest('amount must be a positive number');
          }
          final catId = optString(body, 'categoryId');
          if (catId != null &&
              await validateIdExists(db, 'categories', catId, householdId) ==
                  null) {
            return badRequest('categoryId does not exist');
          }
          final first = existingLines.first;
          lines = [
            for (final l in existingLines)
              l.id == first.id
                  ? TxLine(
                      amount: amount ?? l.amount,
                      currency: optString(body, 'currency') ?? l.currency,
                      categoryId:
                          body.containsKey('categoryId') ? catId : l.categoryId,
                      accountId: optString(body, 'accountId') ?? l.accountId,
                      exchangeRateToBase:
                          optDouble(body, 'exchangeRateToBase') ??
                              l.exchangeRateToBase,
                      note: existingLines.length == 1 ? note : l.note,
                    )
                  : TxLine(
                      amount: l.amount,
                      currency: l.currency,
                      categoryId: l.categoryId,
                      accountId: l.accountId,
                      exchangeRateToBase: l.exchangeRateToBase,
                      note: l.note,
                    ),
          ];
        }
      }

      final newId = await db.transaction(() async {
        final String newId;
        if (transfer != null) {
          newId = await engine.recordTransfer(
            householdId: householdId,
            fromAccountId: transfer.from!,
            toAccountId: transfer.to!,
            amount: transfer.amount!,
            currency: transfer.currency!,
            exchangeRateToBase: transfer.rate!,
            createdBy: 'web',
            deviceId: 'web',
            note: note,
            date: date,
          );
        } else {
          newId = await engine.recordTransaction(
            householdId: householdId,
            accountId: accountId,
            type: type,
            lines: lines!,
            baseCurrency: baseCurrency,
            note: note,
            deviceId: 'web',
            date: date,
          );
        }
        // Receipts stay with the edited transaction.
        if (existing.receiptPath != null) {
          await (db.update(db.transactions)..where((t) => t.id.equals(newId)))
              .write(TransactionsCompanion(
                  receiptPath: Value(existing.receiptPath)));
        }
        await engine.deleteTransaction(id);
        return newId;
      });

      return ok({'id': newId});
    } on CurrencyConversionException catch (e) {
      return badRequest('No exchange rate from ${e.from} to ${e.to}');
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

      await ref.read(allocationEngineProvider).deleteTransaction(id);
      return ok({'success': true});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── Utilities ─────────────────────────────────────────────────────────────────

Future<String> _baseCurrency(AppDatabase db, String householdId) async {
  final household = await (db.select(db.households)
        ..where((h) => h.id.equals(householdId)))
      .getSingleOrNull();
  return household?.baseCurrency ?? 'USD';
}

/// The browser sends the user's calendar day (`YYYY-MM-DD`). Editing keeps
/// the transaction's time of day; a new one dated today gets the current
/// time (so it sorts on top), another day gets noon. Full timestamps pass
/// through unchanged.
DateTime? parseWebDate(String? s, {DateTime? keepTimeOf}) {
  if (s == null) return null;
  final d = DateTime.tryParse(s);
  if (d == null) return null;
  if (s.length > 10) return d;
  if (keepTimeOf != null) {
    final t = keepTimeOf.toLocal();
    return DateTime(d.year, d.month, d.day, t.hour, t.minute, t.second);
  }
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return now;
  }
  return DateTime(d.year, d.month, d.day, 12);
}

class _Transfer {
  final String? from, to, currency, error;
  final double? amount, rate;
  const _Transfer(
      {this.from, this.to, this.currency, this.amount, this.rate})
      : error = null;
  const _Transfer.error(String this.error)
      : from = null,
        to = null,
        currency = null,
        amount = null,
        rate = null;
}

/// A transfer's fields. The amount is in the source account's currency and
/// `exchangeRateToBase` is the source → destination rate (the destination
/// receives amount × rate), like the app's transfer form.
Future<_Transfer> _readTransfer(
    AppDatabase db, String householdId, Map<String, dynamic> body,
    {Transaction? existing}) async {
  final from = optString(body, 'accountId') ?? existing?.accountId;
  final to = optString(body, 'destinationAccountId') ??
      existing?.destinationAccountId;
  if (from == null) {
    return const _Transfer.error('accountId is required for transfers');
  }
  if (to == null) {
    return const _Transfer.error(
        'destinationAccountId is required for transfers');
  }
  if (from == to) {
    return const _Transfer.error('The two accounts must be different');
  }
  final fromAcct = await (db.select(db.accounts)
        ..where((a) => a.id.equals(from) & a.householdId.equals(householdId)))
      .getSingleOrNull();
  final toAcct = await (db.select(db.accounts)
        ..where((a) => a.id.equals(to) & a.householdId.equals(householdId)))
      .getSingleOrNull();
  if (fromAcct == null) return const _Transfer.error('accountId does not exist');
  if (toAcct == null) {
    return const _Transfer.error('destinationAccountId does not exist');
  }
  final amount = optDouble(body, 'amount') ?? existing?.amount;
  if (amount == null || amount <= 0) {
    return const _Transfer.error('amount must be a positive number');
  }
  if (amount > kMaxAmount) {
    return const _Transfer.error('amount exceeds maximum allowed value');
  }
  final sameCurrency = fromAcct.currency == toAcct.currency;
  final rate = sameCurrency
      ? 1.0
      : (optDouble(body, 'exchangeRateToBase') ?? existing?.exchangeRateToBase);
  if (rate == null || rate <= 0) {
    return const _Transfer.error(
        'Enter the amount received for a transfer between currencies');
  }
  return _Transfer(
      from: from,
      to: to,
      currency: fromAcct.currency,
      amount: amount,
      rate: rate);
}

/// Lines from `lines` (split) or the single `amount`/`categoryId` fields.
Future<({List<TxLine>? lines, String? error})> _readLines(
  AppDatabase db,
  String householdId,
  Map<String, dynamic> body,
  String accountId,
  String baseCurrency,
  String note, {
  Transaction? fallback,
}) async {
  ({List<TxLine>? lines, String? error}) fail(String m) =>
      (lines: null, error: m);

  if (body['lines'] is List && (body['lines'] as List).isNotEmpty) {
    final raw = body['lines'] as List;
    if (raw.length > 50) return fail('Too many lines (max 50)');
    final parsed = <TxLine>[];
    for (final r in raw) {
      if (r is! Map<String, dynamic>) return fail('Each line must be an object');
      final amt = requireDouble(r, 'amount');
      if (amt == null || amt <= 0) {
        return fail('Each line must have a positive amount');
      }
      if (amt > kMaxAmount) return fail('Line amount exceeds maximum');
      final catId = optString(r, 'categoryId');
      if (catId != null &&
          await validateIdExists(db, 'categories', catId, householdId) ==
              null) {
        return fail('categoryId does not exist');
      }
      final lineAcct = optString(r, 'accountId');
      if (lineAcct != null &&
          await validateIdExists(db, 'accounts', lineAcct, householdId) ==
              null) {
        return fail('line accountId does not exist');
      }
      final lineCur = optString(r, 'currency') ?? baseCurrency;
      final rate = optDouble(r, 'exchangeRateToBase') ??
          await _cachedRate(db, lineCur, baseCurrency);
      if (rate <= 0) return fail('exchangeRateToBase must be positive');
      parsed.add(TxLine(
        amount: amt,
        currency: lineCur,
        categoryId: catId,
        accountId: lineAcct,
        exchangeRateToBase: rate,
        note: truncate(optString(r, 'note') ?? '', kMaxNoteLength),
      ));
    }
    return (lines: parsed, error: null);
  }

  final amount = optDouble(body, 'amount') ?? fallback?.amount;
  if (amount == null || amount <= 0) {
    return fail('amount must be a positive number');
  }
  if (amount > kMaxAmount) return fail('amount exceeds maximum allowed value');
  final catId = body.containsKey('categoryId')
      ? optString(body, 'categoryId')
      : fallback?.categoryId;
  if (catId != null &&
      await validateIdExists(db, 'categories', catId, householdId) == null) {
    return fail('categoryId does not exist');
  }
  // A transfer's rate is source → destination, not to base: don't reuse it
  // when a transfer becomes an expense or income.
  final fallbackRate =
      fallback?.type == 'transfer' ? null : fallback?.exchangeRateToBase;
  final currency =
      optString(body, 'currency') ?? fallback?.currency ?? baseCurrency;
  final rate = optDouble(body, 'exchangeRateToBase') ??
      fallbackRate ??
      await _cachedRate(db, currency, baseCurrency);
  if (rate <= 0) return fail('exchangeRateToBase must be positive');
  return (
    lines: [
      TxLine(
        amount: amount,
        currency: currency,
        categoryId: catId,
        accountId: accountId,
        exchangeRateToBase: rate,
        note: note,
      )
    ],
    error: null,
  );
}

/// A line saved from the browser without a rate gets the phone's latest
/// cached rate (no network call inside a request), else 1.0 — the "No rate"
/// tag then shows, as in the app.
Future<double> _cachedRate(AppDatabase db, String currency, String base) async {
  if (currency == base) return 1.0;
  return await latestCachedRate(db, currency, base) ?? 1.0;
}
