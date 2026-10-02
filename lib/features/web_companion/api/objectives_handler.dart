import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/engine/allocation_engine.dart';
import '../../../core/fx/fx_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/engine_provider.dart';
import '../../../core/providers/household_provider.dart';
import '../../../l10n/s_lookup.dart';
import '../../../shared/utils/note_text.dart';
import '_validation.dart';
import 'transactions_handler.dart' show parseWebDate;

// Goals & loans. Payments are ordinary transactions whose note carries
// "[obj:ID|amount]" (amount in the objective's currency); progress is the sum
// of those tags, as on the phone (objective_detail_screen.dart).

final _tagRe = RegExp(r'\[obj:([^\]|]+)(?:\|([0-9.]+))?\]');
final _hexRe = RegExp(r'^#[0-9A-Fa-f]{6}$');
final _curRe = RegExp(r'^[A-Za-z]{1,10}$');

typedef _Paid = ({double paid, List<Transaction> payments});

/// Tagged payments per objective id (newest first) and their total.
Future<Map<String, _Paid>> _payments(
    AppDatabase db, String householdId, Map<String, Objective> byId) async {
  final txs = await (db.select(db.transactions)
        ..where((t) =>
            t.householdId.equals(householdId) &
            t.deleted.equals(false) &
            t.status.isNull() &
            t.note.like('%[obj:%'))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  final paid = <String, double>{};
  final lists = <String, List<Transaction>>{};
  final untagged = <String, String>{}; // tx id → objective id (old "[obj:ID]")
  for (final t in txs) {
    for (final m in _tagRe.allMatches(t.note)) {
      final id = m.group(1)!;
      if (!byId.containsKey(id)) continue;
      (lists[id] ??= []).add(t);
      final amount = double.tryParse(m.group(2) ?? '');
      if (amount != null) {
        paid[id] = (paid[id] ?? 0) + amount;
      } else {
        untagged[t.id] = id;
      }
    }
  }
  if (untagged.isNotEmpty) {
    final lines = await (db.select(db.transactionLines)
          ..where((l) => l.transactionId.isIn(untagged.keys)))
        .get();
    for (final l in lines) {
      final id = untagged[l.transactionId]!;
      if (l.currency == byId[id]!.targetCurrency) {
        paid[id] = (paid[id] ?? 0) + l.amount;
      }
    }
  }
  return {
    for (final id in byId.keys)
      id: (paid: paid[id] ?? 0, payments: lists[id] ?? const []),
  };
}

/// Remaining amount spread over the months left (a started month counts).
double? _monthlyPace(Objective o, double paid) {
  final end = o.endDate;
  final remaining = o.targetAmount - paid;
  if (end == null || remaining <= 0) return null;
  final now = DateTime.now();
  if (!end.isAfter(now)) return null;
  var months = (end.year - now.year) * 12 + end.month - now.month;
  if (end.day >= now.day) months += 1;
  return remaining / months.clamp(1, 1200);
}

Map<String, dynamic> _toJson(Objective o, _Paid p) => {
      'id': o.id,
      'name': o.name,
      'type': o.type,
      'icon': o.icon,
      'colorHex': o.colorHex,
      'targetAmount': o.targetAmount,
      'targetCurrency': o.targetCurrency,
      'currentAmount': p.paid,
      'endDate': o.endDate?.toIso8601String(),
      'contactName': o.contactName,
      'direction': o.direction,
      'paymentCount': p.payments.length,
      'lastPaymentDate': p.payments.isEmpty
          ? null
          : p.payments.first.createdAt.toIso8601String(),
      'monthlyPace': _monthlyPace(o, p.paid),
    };

Future<List<Objective>> _all(AppDatabase db, String householdId) =>
    (db.select(db.objectives)
          ..where((o) =>
              o.householdId.equals(householdId) &
              o.archived.equals(false) &
              o.deleted.equals(false))
          ..orderBy([(o) => OrderingTerm.asc(o.name)]))
        .get();

Future<Objective?> _one(AppDatabase db, String householdId, String id) =>
    (db.select(db.objectives)
          ..where((o) =>
              o.id.equals(id) &
              o.householdId.equals(householdId) &
              o.deleted.equals(false)))
        .getSingleOrNull();

/// Keeps the stored progress in step (the phone's list reads it).
Future<void> _storePaid(AppDatabase db, Objective o, double paid) async {
  if ((paid - o.currentAmount).abs() < 0.005) return;
  await (db.update(db.objectives)..where((x) => x.id.equals(o.id))).write(
      ObjectivesCompanion(
          currentAmount: Value(paid), lastModified: Value(DateTime.now())));
}

// ── GET /api/objectives ───────────────────────────────────────────────────────

Handler listObjectivesHandler(Ref ref) {
  return (Request request) async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final db = ref.read(databaseProvider);
    try {
      final all = await _all(db, householdId);
      final paid = await _payments(db, householdId, {for (final o in all) o.id: o});
      return ok({'items': [for (final o in all) _toJson(o, paid[o.id]!)]});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── GET /api/objectives/:id ───────────────────────────────────────────────────

Handler getObjectiveHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    if (id == null) return badRequest('Missing id');
    final db = ref.read(databaseProvider);
    try {
      final o = await _one(db, householdId, id);
      if (o == null) return notFound();
      final p = (await _payments(db, householdId, {id: o}))[id]!;
      final accounts = {
        for (final a in await (db.select(db.accounts)
              ..where((a) => a.householdId.equals(householdId)))
            .get())
          a.id: a,
      };
      return ok({
        ..._toJson(o, p),
        'payments': [
          for (final t in p.payments)
            {
              'id': t.id,
              'date': t.createdAt.toIso8601String(),
              'type': t.type,
              'amount': double.tryParse(_tagRe
                          .allMatches(t.note)
                          .firstWhere((m) => m.group(1) == id)
                          .group(2) ??
                      '') ??
                  t.amount,
              'accountName': accounts[t.accountId]?.name,
              'note': visibleNote(t.note),
            },
        ],
      });
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/objectives  ·  PUT /api/objectives/:id ──────────────────────────

/// Reads the editable fields; on create every required one must be there.
({ObjectivesCompanion? data, String? error}) _readFields(
    Map<String, dynamic> body, Objective? existing) {
  final type = optString(body, 'type') ?? existing?.type;
  if (type != 'goal' && type != 'loan') {
    return (data: null, error: 'type must be goal or loan');
  }
  final name = requireStringLimited(body, 'name') ?? existing?.name;
  if (name == null || name.isEmpty) {
    return (data: null, error: 'name is required');
  }
  final target = body.containsKey('targetAmount')
      ? requireDouble(body, 'targetAmount')
      : existing?.targetAmount;
  if (target == null || target < 0 || target > kMaxAmount) {
    return (data: null, error: 'targetAmount must be 0 or more');
  }
  final currency =
      (optString(body, 'targetCurrency') ?? existing?.targetCurrency)
          ?.toUpperCase();
  if (currency == null || !_curRe.hasMatch(currency)) {
    return (data: null, error: 'targetCurrency must be a currency code');
  }
  final color = optString(body, 'colorHex') ?? existing?.colorHex ?? '#2563EB';
  if (!_hexRe.hasMatch(color)) {
    return (data: null, error: 'colorHex must be like #2563EB');
  }
  final direction = type == 'loan'
      ? (optString(body, 'direction') ?? existing?.direction ?? 'lent')
      : null;
  if (direction != null && direction != 'lent' && direction != 'borrowed') {
    return (data: null, error: 'direction must be lent or borrowed');
  }
  final endDate = body.containsKey('endDate')
      ? parseWebDate(optString(body, 'endDate'))
      : existing?.endDate;
  final contact = type == 'loan'
      ? (body.containsKey('contactName')
          ? truncate((optString(body, 'contactName') ?? '').trim(),
              kMaxNameLength)
          : existing?.contactName)
      : null;
  final icon = body.containsKey('icon')
      ? truncate(optString(body, 'icon') ?? '', 16)
      : existing?.icon;
  return (
    data: ObjectivesCompanion(
      name: Value(name),
      type: Value(type!),
      targetAmount: Value(target),
      targetCurrency: Value(currency),
      colorHex: Value(color),
      direction: Value(direction),
      endDate: Value(endDate),
      contactName: Value(contact),
      icon: Value(icon == null || icon.isEmpty ? null : icon),
      lastModified: Value(DateTime.now()),
    ),
    error: null,
  );
}

Handler createObjectiveHandler(Ref ref) {
  return (Request request) async {
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final fields = _readFields(body, null);
    if (fields.error != null) return badRequest(fields.error!);
    final db = ref.read(databaseProvider);
    try {
      final id = const Uuid().v4();
      await db.into(db.objectives).insert(fields.data!.copyWith(
            id: Value(id),
            householdId: Value(householdId),
            deviceId: const Value('web'),
          ));
      return created({'id': id});
    } catch (e) {
      return serverError(e);
    }
  };
}

Handler updateObjectiveHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null) return badRequest('Missing id');
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final db = ref.read(databaseProvider);
    try {
      final existing = await _one(db, householdId, id);
      if (existing == null) return notFound();
      final fields = _readFields(body, existing);
      if (fields.error != null) return badRequest(fields.error!);
      await (db.update(db.objectives)..where((o) => o.id.equals(id)))
          .write(fields.data!);
      return ok({'id': id});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── DELETE /api/objectives/:id?payments=delete|keep ───────────────────────────
// Like the phone: "delete" also removes the payments (money goes back to the
// accounts); "keep" (default) leaves the transactions.

Handler deleteObjectiveHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null) return badRequest('Missing id');
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final db = ref.read(databaseProvider);
    try {
      final o = await _one(db, householdId, id);
      if (o == null) return notFound();
      final withPayments = request.url.queryParameters['payments'] == 'delete';
      final engine = ref.read(allocationEngineProvider);
      await db.transaction(() async {
        if (withPayments) {
          final p = (await _payments(db, householdId, {id: o}))[id]!;
          for (final t in p.payments) {
            await engine.deleteTransaction(t.id);
          }
        }
        await (db.update(db.objectives)..where((x) => x.id.equals(id))).write(
            ObjectivesCompanion(
                deleted: const Value(true),
                lastModified: Value(DateTime.now())));
      });
      return ok({'success': true});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/objectives/:id/pay ──────────────────────────────────────────────
// { accountId, amount (objective currency), categoryId?, date? } → a real
// transaction: income for money lent coming back, expense otherwise.

Handler payObjectiveHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null) return badRequest('Missing id');
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final amount = requireAmount(body, 'amount');
    if (amount == null) return badRequest('amount must be a positive number');
    final accountId = requireString(body, 'accountId');
    if (accountId == null) return badRequest('accountId is required');
    final categoryId = optString(body, 'categoryId');

    final db = ref.read(databaseProvider);
    try {
      final o = await _one(db, householdId, id);
      if (o == null) return notFound();
      if (await validateIdExists(db, 'accounts', accountId, householdId) ==
          null) {
        return badRequest('accountId does not exist');
      }
      if (categoryId != null &&
          await validateIdExists(db, 'categories', categoryId, householdId) ==
              null) {
        return badRequest('categoryId does not exist');
      }
      final household = await (db.select(db.households)
            ..where((h) => h.id.equals(householdId)))
          .getSingleOrNull();
      final base = household?.baseCurrency ?? 'USD';
      final rate = o.targetCurrency == base
          ? 1.0
          : await latestCachedRate(db, o.targetCurrency, base) ?? 1.0;

      final s = currentS();
      final isLoan = o.type == 'loan';
      final isLent = o.direction == 'lent';
      final contact = o.contactName ?? '';
      final noteName = isLoan && contact.isNotEmpty ? '${o.name} — $contact' : o.name;
      final prefix = isLoan
          ? (isLent ? s.objNotePaymentReceived : s.objNotePayment)
          : s.objNoteGoalSavings;

      final txId = await ref.read(allocationEngineProvider).recordTransaction(
            householdId: householdId,
            accountId: accountId,
            type: isLoan && isLent ? 'income' : 'expense',
            lines: [
              TxLine(
                amount: amount,
                currency: o.targetCurrency,
                exchangeRateToBase: rate,
                categoryId: categoryId,
              ),
            ],
            baseCurrency: base,
            note: '$prefix — $noteName [obj:$id|$amount]',
            deviceId: 'web',
            date: parseWebDate(optString(body, 'date')) ?? DateTime.now(),
          );
      final p = (await _payments(db, householdId, {id: o}))[id]!;
      await _storePaid(db, o, p.paid);
      return created({'id': txId, 'currentAmount': p.paid});
    } on CurrencyConversionException catch (e) {
      return badRequest('No exchange rate from ${e.from} to ${e.to}');
    } catch (e) {
      return serverError(e);
    }
  };
}
