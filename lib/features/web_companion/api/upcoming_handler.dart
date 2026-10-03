import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/engine/allocation_engine.dart';
import '../../../core/engine/planned_engine.dart';
import '../../../core/engine/recurring_engine.dart';
import '../../../core/fx/fx_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/engine_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_serializers.dart';
import '_validation.dart';
import 'transactions_handler.dart' show parseWebDate;

// Upcoming bills (enabled recurring items and subscriptions, every occurrence
// in the window) and planned payments (transactions with status 'planned',
// stored like plan_payment_screen.dart does and posted like
// planned_payments_screen.dart does).

Future<String> _base(AppDatabase db, String householdId) async =>
    (await (db.select(db.households)..where((h) => h.id.equals(householdId)))
            .getSingleOrNull())
        ?.baseCurrency ??
    'USD';

Future<(Map<String, Category>, Map<String, Account>)> _refs(
    AppDatabase db, String householdId) async {
  final cats = await (db.select(db.categories)
        ..where((c) => c.householdId.equals(householdId)))
      .get();
  final accts = await (db.select(db.accounts)
        ..where((a) => a.householdId.equals(householdId)))
      .get();
  return ({for (final c in cats) c.id: c}, {for (final a in accts) a.id: a});
}

// ── GET /api/upcoming?days=30 ─────────────────────────────────────────────────

Handler upcomingBillsHandler(Ref ref) {
  return (Request request) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final days =
        (int.tryParse(request.url.queryParameters['days'] ?? '') ?? 30)
            .clamp(1, 120);
    final db = ref.read(databaseProvider);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final until = today.add(Duration(days: days + 1));
      final recs = await (db.select(db.recurringTransactions)
            ..where((r) =>
                r.householdId.equals(householdId) &
                r.enabled.equals(true) &
                r.deleted.equals(false) &
                r.nextDueDate.isSmallerThanValue(until))
            ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
          .get();
      final (cats, accts) = await _refs(db, householdId);

      final items = <Map<String, dynamic>>[];
      for (final r in recs) {
        var due = r.nextDueDate;
        // Every occurrence in the window; only the first can be posted/skipped.
        for (var i = 0; i < 62 && due.isBefore(until); i++) {
          if (r.endDate != null && due.isAfter(r.endDate!)) break;
          final day = DateTime(due.year, due.month, due.day);
          items.add({
            ...recurringToJson(r, cats, accts),
            'occurrence': i,
            'dueDate': due.toIso8601String(),
            'daysUntil': day.difference(today).inDays,
            'amount': recurringAmountOn(r, due),
            'accountCurrency': accts[r.accountId]?.currency,
          });
          due = advanceRecurringDate(due, r.frequency, r.interval,
              anchorDay: r.anchorDay);
        }
      }
      items.sort((a, b) =>
          (a['dueDate'] as String).compareTo(b['dueDate'] as String));
      return ok({'items': items, 'days': days});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/recurring/:id/post-now · /skip ──────────────────────────────────

Handler recurringActionHandler(Ref ref, {required bool post}) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null) return badRequest('Missing id');
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final db = ref.read(databaseProvider);
    try {
      final rec = await (db.select(db.recurringTransactions)
            ..where((r) =>
                r.id.equals(id) &
                r.householdId.equals(householdId) &
                r.deleted.equals(false)))
          .getSingleOrNull();
      if (rec == null) return notFound();
      final engine = ref.read(recurringEngineProvider);
      if (post) {
        await engine.postNow(id);
      } else {
        await engine.skipNext(id);
      }
      return ok({'success': true});
    } on CurrencyConversionException catch (e) {
      return badRequest('No exchange rate from ${e.from} to ${e.to}');
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── GET /api/planned ──────────────────────────────────────────────────────────

Handler listPlannedHandler(Ref ref) {
  return (Request request) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final db = ref.read(databaseProvider);
    try {
      final txs = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.status.equals('planned') &
                t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
      final lines = txs.isEmpty
          ? <TransactionLine>[]
          : await (db.select(db.transactionLines)
                ..where((l) => l.transactionId.isIn(txs.map((t) => t.id))))
              .get();
      final byTx = <String, List<TransactionLine>>{};
      for (final l in lines) {
        (byTx[l.transactionId] ??= []).add(l);
      }
      final (cats, accts) = await _refs(db, householdId);
      return ok({
        'items': [
          for (final t in txs)
            txToJson(t, cats, accts,
                firstLine: byTx[t.id]?.first,
                lineCount: byTx[t.id]?.length ?? 0),
        ],
        'baseCurrency': await _base(db, householdId),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/planned · PUT /api/planned/:id ──────────────────────────────────
// { type, accountId, destinationAccountId?, amount, categoryId?, note?, date }
// in the (source) account's currency, rate 1.0 until it's posted.

Future<Response> _savePlanned(Ref ref, Request request, String? id) async {
  final body = await parseBody(request);
  if (body == null) return badRequest('Invalid JSON body');
  final householdId = ref.read(currentHouseholdIdProvider);
  if (householdId == null) return forbidden();

  final type = requireString(body, 'type');
  if (!const {'expense', 'income', 'transfer'}.contains(type)) {
    return badRequest('type must be income, expense, or transfer');
  }
  final amount = requireAmount(body, 'amount');
  if (amount == null) return badRequest('amount must be a positive number');
  final accountId = requireString(body, 'accountId');
  if (accountId == null) return badRequest('accountId is required');
  final date = parseWebDate(optString(body, 'date'));
  if (date == null) return badRequest('date is required (YYYY-MM-DD)');
  final destId = type == 'transfer' ? optString(body, 'destinationAccountId') : null;
  final categoryId = type == 'transfer' ? null : optString(body, 'categoryId');
  final note = truncate((optString(body, 'note') ?? '').trim(), kMaxNoteLength);

  final db = ref.read(databaseProvider);
  try {
    final account = await (db.select(db.accounts)
          ..where((a) => a.id.equals(accountId) & a.householdId.equals(householdId)))
        .getSingleOrNull();
    if (account == null) return badRequest('accountId does not exist');
    if (type == 'transfer') {
      if (destId == null || destId == accountId) {
        return badRequest('A transfer needs a different destinationAccountId');
      }
      if (await validateIdExists(db, 'accounts', destId, householdId) == null) {
        return badRequest('destinationAccountId does not exist');
      }
    }
    if (categoryId != null &&
        await validateIdExists(db, 'categories', categoryId, householdId) == null) {
      return badRequest('categoryId does not exist');
    }

    Transaction? old;
    if (id != null) {
      old = await (db.select(db.transactions)
            ..where((t) =>
                t.id.equals(id) &
                t.householdId.equals(householdId) &
                t.status.equals('planned') &
                t.deleted.equals(false)))
          .getSingleOrNull();
      if (old == null) return notFound();
    }

    final newId = await PlannedEngine(db).save(
      replaceId: old?.id,
      householdId: householdId,
      type: type!,
      accountId: accountId,
      destinationAccountId: destId,
      amount: amount,
      currency: account.currency,
      categoryId: categoryId,
      note: note,
      date: date,
      createdBy: 'web',
      deviceId: 'web',
    );
    return id == null ? created({'id': newId}) : ok({'id': newId});
  } catch (e) {
    return serverError(e);
  }
}

Handler createPlannedHandler(Ref ref) =>
    (Request request) => _savePlanned(ref, request, null);

Handler updatePlannedHandler(Ref ref) => (Request request) {
      final id = request.params['id'];
      if (id == null) return badRequest('Missing id');
      return _savePlanned(ref, request, id);
    };

// ── DELETE /api/planned/:id ───────────────────────────────────────────────────

Handler deletePlannedHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null) return badRequest('Missing id');
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final db = ref.read(databaseProvider);
    try {
      final tx = await (db.select(db.transactions)
            ..where((t) =>
                t.id.equals(id) &
                t.householdId.equals(householdId) &
                t.status.equals('planned') &
                t.deleted.equals(false)))
          .getSingleOrNull();
      if (tx == null) return notFound();
      await ref.read(allocationEngineProvider).deleteTransaction(id);
      return ok({'success': true});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/planned/post  { ids: [...] } ────────────────────────────────────
// Records each plan as a real transaction (on its planned date, at the
// latest cached rate), then deletes the plan — one db transaction per item,
// so one failure doesn't undo the others.

Handler postPlannedHandler(Ref ref) {
  return (Request request) async {
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final ids = body['ids'];
    if (ids is! List || ids.isEmpty || ids.length > 200 || ids.any((e) => e is! String)) {
      return badRequest('ids must be a list of planned payment ids');
    }
    final db = ref.read(databaseProvider);
    try {
      final base = await _base(db, householdId);
      Future<double?> rate(String from, String to) async =>
          from == to ? 1.0 : await latestCachedRate(db, from, to);

      var posted = 0;
      final failed = <String>[];
      for (final id in ids.cast<String>()) {
        final tx = await (db.select(db.transactions)
              ..where((t) =>
                  t.id.equals(id) &
                  t.householdId.equals(householdId) &
                  t.status.equals('planned') &
                  t.deleted.equals(false)))
            .getSingleOrNull();
        if (tx == null) {
          failed.add(id);
          continue;
        }
        try {
          await PlannedEngine(db).post(
            tx.id,
            baseCurrency: base,
            rate: rate,
            createdBy: 'web',
            deviceId: 'web',
          );
          posted++;
        } on CurrencyConversionException {
          failed.add(id);
        }
      }
      return ok({'posted': posted, 'failed': failed});
    } catch (e) {
      return serverError(e);
    }
  };
}
