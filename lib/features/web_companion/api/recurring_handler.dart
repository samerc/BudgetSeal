import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/engine_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_serializers.dart';
import '_validation.dart';

const _frequencies = ['daily', 'weekly', 'monthly', 'yearly'];

// ── GET /api/recurring ────────────────────────────────────────────────────────

Handler listRecurringHandler(Ref ref) =>
    (Request request) => listRecurring(ref, subscriptions: false);

/// Recurring items (or subscriptions), soonest first, without deleted rows.
Future<Response> listRecurring(Ref ref, {required bool subscriptions}) async {
  final householdId = ref.read(currentHouseholdIdProvider);
  if (householdId == null) return forbidden();

  try {
    final db = ref.read(databaseProvider);
    final items = await (db.select(db.recurringTransactions)
          ..where((r) =>
              r.householdId.equals(householdId) &
              r.deleted.equals(false) &
              r.isSubscription.equals(subscriptions))
          ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
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
      'items': items.map((r) => recurringToJson(r, catMap, acctMap)).toList(),
    });
  } catch (e) {
    return serverError(e);
  }
}

// ── POST /api/recurring ───────────────────────────────────────────────────────

Handler createRecurringHandler(Ref ref) => (Request request) async {
      final body = await parseBody(request);
      if (body == null) return badRequest('Invalid JSON body');
      return createRecurring(ref, body, subscription: false);
    };

Future<Response> createRecurring(Ref ref, Map<String, dynamic> body,
    {required bool subscription}) async {
  final householdId = ref.read(currentHouseholdIdProvider);
  if (householdId == null) return forbidden();

  final type = subscription ? 'expense' : requireString(body, 'type');
  if (type == null || !['income', 'expense', 'transfer'].contains(type)) {
    return badRequest('type must be income, expense, or transfer');
  }

  final accountId = requireString(body, 'accountId');
  if (accountId == null) return badRequest('accountId is required');

  final amount = requireDouble(body, 'amount');
  if (amount == null || amount <= 0) {
    return badRequest('amount must be a positive number');
  }
  if (amount > kMaxAmount) {
    return badRequest('amount exceeds maximum allowed value');
  }

  final frequency = optString(body, 'frequency') ?? 'monthly';
  if (!_frequencies.contains(frequency)) {
    return badRequest('frequency must be daily, weekly, monthly, or yearly');
  }

  final startDateStr = requireString(body, 'startDate');
  if (startDateStr == null) return badRequest('startDate is required');
  final startDate = DateTime.tryParse(startDateStr);
  if (startDate == null) return badRequest('Invalid startDate');

  final db = ref.read(databaseProvider);
  final account = await (db.select(db.accounts)
        ..where((a) =>
            a.id.equals(accountId) & a.householdId.equals(householdId)))
      .getSingleOrNull();
  if (account == null) return badRequest('accountId does not exist');

  // Amounts are in the account's currency, like the app's recurring form.
  final currency = optString(body, 'currency') ?? account.currency;
  if (!RegExp(r'^[A-Za-z]{1,10}$').hasMatch(currency)) {
    return badRequest('currency must be a 1–10 letter code (e.g. USD)');
  }

  final destAcctId = type == 'transfer'
      ? optString(body, 'destinationAccountId')
      : null;
  if (type == 'transfer') {
    if (destAcctId == null) {
      return badRequest('destinationAccountId is required for transfers');
    }
    if (destAcctId == accountId) {
      return badRequest('The two accounts must be different');
    }
    if (await validateIdExists(db, 'accounts', destAcctId, householdId) ==
        null) {
      return badRequest('destinationAccountId does not exist');
    }
  }
  final categoryId = type == 'transfer' ? null : optString(body, 'categoryId');
  if (categoryId != null &&
      await validateIdExists(db, 'categories', categoryId, householdId) ==
          null) {
    return badRequest('categoryId does not exist');
  }
  final endDate = _parseDate(optString(body, 'endDate'));
  if (endDate != null && endDate.isBefore(startDate)) {
    return badRequest('endDate must be after startDate');
  }

  try {
    final id = await ref.read(recurringEngineProvider).create(
          householdId: householdId,
          type: type,
          title: truncate(optString(body, 'title') ?? '', kMaxNameLength),
          amount: amount,
          currency: currency.toUpperCase(),
          accountId: accountId,
          destinationAccountId: destAcctId,
          categoryId: categoryId,
          frequency: frequency,
          interval: (requireInt(body, 'interval') ?? 1).clamp(1, 365),
          startDate: startDate,
          endDate: endDate,
          note: truncate(optString(body, 'note') ?? '', kMaxNoteLength),
          isSubscription: subscription,
        );
    return created({'id': id});
  } catch (e) {
    return serverError(e);
  }
}

// ── PUT /api/recurring/:id ────────────────────────────────────────────────────

Handler updateRecurringHandler(Ref ref) =>
    (Request request) => updateRecurring(ref, request, subscription: false);

/// Edits title, amount, note, account, category, schedule and the enabled
/// flag. A subscription's price change is added to its price history.
Future<Response> updateRecurring(Ref ref, Request request,
    {required bool subscription}) async {
  final id = request.params['id'];
  if (id == null || id.isEmpty) return badRequest('Missing id');

  final body = await parseBody(request);
  if (body == null) return badRequest('Invalid JSON body');

  final householdId = ref.read(currentHouseholdIdProvider);
  if (householdId == null) return forbidden();

  final db = ref.read(databaseProvider);

  try {
    final existing = await (db.select(db.recurringTransactions)
          ..where((r) =>
              r.id.equals(id) &
              r.householdId.equals(householdId) &
              r.deleted.equals(false) &
              r.isSubscription.equals(subscription)))
        .getSingleOrNull();
    if (existing == null) return notFound();

    double? amount;
    if (body.containsKey('amount')) {
      amount = requireDouble(body, 'amount');
      if (amount == null || amount <= 0) {
        return badRequest('amount must be a positive number');
      }
      if (amount > kMaxAmount) {
        return badRequest('amount exceeds maximum allowed value');
      }
    }

    final accountId = optString(body, 'accountId');
    if (accountId != null &&
        await validateIdExists(db, 'accounts', accountId, householdId) ==
            null) {
      return badRequest('accountId does not exist');
    }
    final destId = optString(body, 'destinationAccountId');
    if (destId != null &&
        await validateIdExists(db, 'accounts', destId, householdId) == null) {
      return badRequest('destinationAccountId does not exist');
    }
    final categoryId = optString(body, 'categoryId');
    if (categoryId != null &&
        await validateIdExists(db, 'categories', categoryId, householdId) ==
            null) {
      return badRequest('categoryId does not exist');
    }

    final frequency = optString(body, 'frequency');
    if (frequency != null && !_frequencies.contains(frequency)) {
      return badRequest('frequency must be daily, weekly, monthly, or yearly');
    }
    final nextDue = _parseDate(optString(body, 'nextDueDate'));
    if (body.containsKey('nextDueDate') && nextDue == null) {
      return badRequest('Invalid nextDueDate');
    }

    String? priceHistory = existing.priceHistory;
    if (subscription &&
        amount != null &&
        (amount - existing.amount).abs() > 0.001) {
      List<dynamic> history;
      try {
        history = existing.priceHistory != null
            ? jsonDecode(existing.priceHistory!) as List
            : [];
      } catch (_) {
        history = [];
      }
      history.add({
        'amount': amount,
        'from': DateTime.now().toIso8601String().substring(0, 10),
      });
      priceHistory = jsonEncode(history);
    }

    await (db.update(db.recurringTransactions)..where((r) => r.id.equals(id)))
        .write(RecurringTransactionsCompanion(
      amount: amount != null ? Value(amount) : const Value.absent(),
      title: body.containsKey('title')
          ? Value(truncate((body['title'] as String?)?.trim() ?? '',
              kMaxNameLength))
          : const Value.absent(),
      note: body.containsKey('note')
          ? Value(truncate(
              (body['note'] as String?)?.trim() ?? '', kMaxNoteLength))
          : const Value.absent(),
      accountId: accountId != null ? Value(accountId) : const Value.absent(),
      destinationAccountId: destId != null && existing.type == 'transfer'
          ? Value(destId)
          : const Value.absent(),
      categoryId: body.containsKey('categoryId') && existing.type != 'transfer'
          ? Value(categoryId)
          : const Value.absent(),
      frequency: frequency != null ? Value(frequency) : const Value.absent(),
      interval: body.containsKey('interval')
          ? Value((requireInt(body, 'interval') ?? 1).clamp(1, 365))
          : const Value.absent(),
      // Moving the due date also moves the day a monthly series returns to.
      nextDueDate: nextDue != null ? Value(nextDue) : const Value.absent(),
      anchorDay: nextDue != null ? Value(nextDue.day) : const Value.absent(),
      enabled: optBool(body, 'enabled') != null
          ? Value(optBool(body, 'enabled')!)
          : const Value.absent(),
      priceHistory: priceHistory != existing.priceHistory
          ? Value(priceHistory)
          : const Value.absent(),
      lastModified: Value(DateTime.now()),
    ));

    return ok({'id': id});
  } catch (e) {
    return serverError(e);
  }
}

// ── DELETE /api/recurring/:id ─────────────────────────────────────────────────

Handler deleteRecurringHandler(Ref ref) =>
    (Request request) => deleteRecurring(ref, request, subscription: false);

Future<Response> deleteRecurring(Ref ref, Request request,
    {required bool subscription}) async {
  final id = request.params['id'];
  if (id == null || id.isEmpty) return badRequest('Missing id');

  final householdId = ref.read(currentHouseholdIdProvider);
  if (householdId == null) return forbidden();

  final db = ref.read(databaseProvider);

  try {
    final existing = await (db.select(db.recurringTransactions)
          ..where((r) =>
              r.id.equals(id) &
              r.householdId.equals(householdId) &
              r.isSubscription.equals(subscription)))
        .getSingleOrNull();
    if (existing == null) return notFound();

    await ref.read(recurringEngineProvider).delete(id);
    return ok({'success': true});
  } catch (e) {
    return serverError(e);
  }
}

// ── Utilities ─────────────────────────────────────────────────────────────────

DateTime? _parseDate(String? s) {
  if (s == null) return null;
  return DateTime.tryParse(s);
}
