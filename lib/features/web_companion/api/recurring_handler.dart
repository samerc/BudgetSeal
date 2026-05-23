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

// ── GET /api/recurring ────────────────────────────────────────────────────────

Handler listRecurringHandler(Ref ref) {
  return (Request request) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      final engine = ref.read(recurringEngineProvider);
      final items =
          await engine.getAll(householdId, excludeSubscriptions: true);

      final db = ref.read(databaseProvider);
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
  };
}

// ── POST /api/recurring ───────────────────────────────────────────────────────

Handler createRecurringHandler(Ref ref) {
  return (Request request) async {
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final type = requireString(body, 'type');
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

    final currency = requireString(body, 'currency');
    if (currency == null) return badRequest('currency is required');
    if (!RegExp(r'^[A-Za-z]{1,10}$').hasMatch(currency)) {
      return badRequest('currency must be a 1–10 letter code (e.g. USD)');
    }

    final frequency = requireString(body, 'frequency');
    if (frequency == null ||
        !['daily', 'weekly', 'monthly', 'yearly'].contains(frequency)) {
      return badRequest('frequency must be daily, weekly, monthly, or yearly');
    }

    final startDateStr = requireString(body, 'startDate');
    if (startDateStr == null) {
      return badRequest('startDate is required (ISO 8601)');
    }
    final startDate = DateTime.tryParse(startDateStr);
    if (startDate == null) return badRequest('Invalid startDate');

    final db = ref.read(databaseProvider);
    // Validate FK references
    if (await validateIdExists(db, 'accounts', accountId) == null) {
      return badRequest('accountId does not exist');
    }
    final destAcctId = optString(body, 'destinationAccountId');
    if (type == 'transfer' && destAcctId == null) {
      return badRequest('destinationAccountId is required for transfers');
    }
    if (destAcctId != null && await validateIdExists(db, 'accounts', destAcctId) == null) {
      return badRequest('destinationAccountId does not exist');
    }
    final categoryId = optString(body, 'categoryId');
    if (categoryId != null && await validateIdExists(db, 'categories', categoryId) == null) {
      return badRequest('categoryId does not exist');
    }
    final endDate = _parseDate(optString(body, 'endDate'));
    if (endDate != null && endDate.isBefore(startDate)) {
      return badRequest('endDate must be after startDate');
    }

    try {
      final engine = ref.read(recurringEngineProvider);
      final id = await engine.create(
        householdId: householdId,
        type: type,
        title: truncate(optString(body, 'title') ?? '', kMaxNameLength),
        amount: amount,
        currency: currency,
        accountId: accountId,
        destinationAccountId: destAcctId,
        categoryId: categoryId,
        frequency: frequency,
        interval: (requireInt(body, 'interval') ?? 1).clamp(1, 365),
        startDate: startDate,
        endDate: endDate,
        note: truncate(optString(body, 'note') ?? '', kMaxNoteLength),
        isSubscription: false,
      );
      return created({'id': id});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── PUT /api/recurring/:id ────────────────────────────────────────────────────

Handler updateRecurringHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null || id.isEmpty) return badRequest('Missing id');

    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final db = ref.read(databaseProvider);

    try {
      final existing = await (db.select(db.recurringTransactions)
            ..where(
                (r) => r.id.equals(id) & r.householdId.equals(householdId)))
          .getSingleOrNull();
      if (existing == null) return notFound();

      final engine = ref.read(recurringEngineProvider);

      if (body.containsKey('enabled')) {
        final enabled = optBool(body, 'enabled') ?? existing.enabled;
        await engine.toggleEnabled(id, enabled);
      }

      double? validatedAmount;
      if (body.containsKey('amount')) {
        final newAmt = requireDouble(body, 'amount');
        if (newAmt == null || newAmt <= 0) {
          return badRequest('amount must be a positive number');
        }
        if (newAmt > kMaxAmount) {
          return badRequest('amount exceeds maximum allowed value');
        }
        validatedAmount = newAmt;
      }

      if (validatedAmount != null ||
          body.containsKey('title') ||
          body.containsKey('note')) {
        await (db.update(db.recurringTransactions)
              ..where((r) => r.id.equals(id)))
            .write(RecurringTransactionsCompanion(
          amount: validatedAmount != null
              ? Value(validatedAmount)
              : const Value.absent(),
          title: body.containsKey('title')
              ? Value(truncate(optString(body, 'title') ?? existing.title, kMaxNameLength))
              : const Value.absent(),
          note: body.containsKey('note')
              ? Value(truncate(optString(body, 'note') ?? existing.note, kMaxNoteLength))
              : const Value.absent(),
        ));
      }

      return ok({'id': id});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── DELETE /api/recurring/:id ─────────────────────────────────────────────────

Handler deleteRecurringHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null || id.isEmpty) return badRequest('Missing id');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final db = ref.read(databaseProvider);

    try {
      final existing = await (db.select(db.recurringTransactions)
            ..where(
                (r) => r.id.equals(id) & r.householdId.equals(householdId)))
          .getSingleOrNull();
      if (existing == null) return notFound();

      final engine = ref.read(recurringEngineProvider);
      await engine.delete(id);

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
