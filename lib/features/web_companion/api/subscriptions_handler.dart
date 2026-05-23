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

// ── GET /api/subscriptions ────────────────────────────────────────────────────

Handler listSubscriptionsHandler(Ref ref) {
  return (Request request) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      final engine = ref.read(recurringEngineProvider);
      final db = ref.read(databaseProvider);
      final allItems = await engine.getAll(householdId);
      final items = allItems.where((r) => r.isSubscription).toList();

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

// ── POST /api/subscriptions ───────────────────────────────────────────────────

Handler createSubscriptionHandler(Ref ref) {
  return (Request request) async {
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

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

    final frequency = optString(body, 'frequency') ?? 'monthly';
    if (!['daily', 'weekly', 'monthly', 'yearly'].contains(frequency)) {
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
    final categoryId = optString(body, 'categoryId');
    if (categoryId != null && await validateIdExists(db, 'categories', categoryId) == null) {
      return badRequest('categoryId does not exist');
    }

    try {
      final engine = ref.read(recurringEngineProvider);
      final id = await engine.create(
        householdId: householdId,
        type: 'expense',
        title: truncate(optString(body, 'title') ?? '', kMaxNameLength),
        amount: amount,
        currency: currency,
        accountId: accountId,
        categoryId: categoryId,
        frequency: frequency,
        interval: (requireInt(body, 'interval') ?? 1).clamp(1, 365),
        startDate: startDate,
        note: truncate(optString(body, 'note') ?? '', kMaxNoteLength),
        isSubscription: true,
      );
      return created({'id': id});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── PUT /api/subscriptions/:id ────────────────────────────────────────────────

Handler updateSubscriptionHandler(Ref ref) {
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
            ..where((r) =>
                r.id.equals(id) &
                r.householdId.equals(householdId) &
                r.isSubscription.equals(true)))
          .getSingleOrNull();
      if (existing == null) return notFound();

      final engine = ref.read(recurringEngineProvider);

      if (body.containsKey('enabled')) {
        final enabled = optBool(body, 'enabled') ?? existing.enabled;
        await engine.toggleEnabled(id, enabled);
      }

      // If amount changes for a subscription, append a price history entry
      final newAmount = optDouble(body, 'amount');
      if (body.containsKey('amount') && (newAmount == null || newAmount <= 0)) {
        return badRequest('amount must be a positive number');
      }
      if (newAmount != null && newAmount > kMaxAmount) {
        return badRequest('amount exceeds maximum allowed value');
      }
      String? updatedPriceHistory = existing.priceHistory;

      if (newAmount != null && (newAmount - existing.amount).abs() > 0.001) {
        final dateStr =
            DateTime.now().toIso8601String().substring(0, 10);
        final entry = {'amount': newAmount, 'from': dateStr};
        final history = existing.priceHistory != null
            ? (jsonDecode(existing.priceHistory!) as List)
                .cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        history.add(entry);
        updatedPriceHistory = jsonEncode(history);
      }

      if (body.containsKey('amount') ||
          body.containsKey('title') ||
          body.containsKey('note')) {
        await (db.update(db.recurringTransactions)
              ..where((r) => r.id.equals(id)))
            .write(RecurringTransactionsCompanion(
          amount: newAmount != null ? Value(newAmount) : const Value.absent(),
          title: body.containsKey('title')
              ? Value(truncate(
                  optString(body, 'title') ?? existing.title, kMaxNameLength))
              : const Value.absent(),
          note: body.containsKey('note')
              ? Value(truncate(optString(body, 'note') ?? existing.note, kMaxNoteLength))
              : const Value.absent(),
          priceHistory: updatedPriceHistory != existing.priceHistory
              ? Value(updatedPriceHistory)
              : const Value.absent(),
        ));
      }

      return ok({'id': id});
    } catch (e) {
      return serverError(e);
    }
  };
}
