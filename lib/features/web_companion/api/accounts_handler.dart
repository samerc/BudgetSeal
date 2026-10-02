import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/engine/allocation_engine.dart';
import '../../../core/engine/balance_calculator.dart';
import '../../../core/fx/fx_service.dart';
import '../../../core/providers/engine_provider.dart';
import '../../../l10n/s_lookup.dart';
import '../../../shared/utils/format_number.dart' show currencyDecimals;
import '_running.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_serializers.dart';
import '_validation.dart';

const _uuid = Uuid();

// ── GET /api/accounts ─────────────────────────────────────────────────────────

Handler listAccountsHandler(Ref ref) {
  return (Request request) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      // ?archived=1 adds archived accounts (for unarchiving).
      final withArchived = request.url.queryParameters['archived'] == '1';
      final accounts = await (db.select(db.accounts)
            ..where((a) =>
                a.householdId.equals(householdId) &
                (withArchived
                    ? const Constant(true)
                    : a.archived.equals(false)) &
                a.deleted.equals(false))
            ..orderBy([(a) => OrderingTerm.asc(a.name)]))
          .get();

      final calculator = BalanceCalculator(db);
      final balances = await calculator.allAccountBalances(householdId);

      return ok({
        'items': accounts
            .map((a) => accountToJson(a, balances[a.id] ?? 0.0))
            .toList(),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/accounts ────────────────────────────────────────────────────────

Handler createAccountHandler(Ref ref) {
  return (Request request) async {
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final name = requireString(body, 'name');
    if (name == null) return badRequest('name is required');

    final currency = requireString(body, 'currency');
    if (currency == null) return badRequest('currency is required');
    if (currency.length > 10 || !RegExp(r'^[A-Za-z]{1,10}$').hasMatch(currency)) {
      return badRequest('currency must be a 1–10 letter code (e.g. USD)');
    }

    final type = optString(body, 'type') ?? 'cash';
    if (!['cash', 'bank', 'credit', 'wallet'].contains(type)) {
      return badRequest('type must be cash, bank, credit, or wallet');
    }

    final db = ref.read(databaseProvider);

    try {
      final id = _uuid.v4();
      await db.accountsDao.upsert(AccountsCompanion.insert(
        id: id,
        householdId: householdId,
        name: truncate(name, kMaxNameLength),
        type: type,
        currency: currency.toUpperCase(),
        initialBalance: Value((optDouble(body, 'initialBalance') ?? 0.0)
            .clamp(-kMaxAmount, kMaxAmount)),
        deviceId: 'web',
      ));
      return created({'id': id});
    } catch (e) {
      return serverError(e);
    }
  };
}

Future<Account?> _ownAccount(AppDatabase db, String householdId, String id) =>
    (db.select(db.accounts)
          ..where((a) =>
              a.id.equals(id) &
              a.householdId.equals(householdId) &
              a.deleted.equals(false)))
        .getSingleOrNull();

/// Half a unit of the account's last decimal — "zero" for archiving.
double _zero(Account a) =>
    0.5 / math.pow(10, a.decimalPlaces ?? currencyDecimals(a.currency));

Future<double> _balance(AppDatabase db, Account a) async {
  final running = await accountRunning(db, a);
  return running.isEmpty ? a.initialBalance : running.values.last.balance;
}

// ── GET /api/accounts/:id ─────────────────────────────────────────────────────

Handler getAccountHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    if (id == null) return badRequest('Missing id');
    final db = ref.read(databaseProvider);
    try {
      final a = await _ownAccount(db, householdId, id);
      if (a == null) return notFound();
      final running = await accountRunning(db, a);
      final prefs = await SharedPreferences.getInstance();
      return ok({
        ...accountToJson(
            a, running.isEmpty ? a.initialBalance : running.values.last.balance),
        'initialBalance': a.initialBalance,
        'transactionCount': running.length,
        'reconciledAt': DateTime.tryParse(
                prefs.getString('reconciled_$id') ?? '')
            ?.toIso8601String(),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── PUT /api/accounts/:id ─────────────────────────────────────────────────────
// name, type, initialBalance, decimalPlaces (null = the currency's default).
// The currency stays: changing it would reinterpret every amount.

Handler updateAccountHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null) return badRequest('Missing id');
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final type = optString(body, 'type');
    if (type != null && !['cash', 'bank', 'credit', 'wallet'].contains(type)) {
      return badRequest('type must be cash, bank, credit, or wallet');
    }
    final initial = optDouble(body, 'initialBalance');
    if (initial != null && initial.abs() > kMaxAmount) {
      return badRequest('initialBalance is out of range');
    }
    final dp = body['decimalPlaces'];
    if (dp != null && (dp is! int || dp < 0 || dp > 3)) {
      return badRequest('decimalPlaces must be 0–3 or null');
    }

    final db = ref.read(databaseProvider);
    try {
      final a = await _ownAccount(db, householdId, id);
      if (a == null) return notFound();
      final name = requireStringLimited(body, 'name');
      await (db.update(db.accounts)..where((x) => x.id.equals(id)))
          .write(AccountsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        type: type == null ? const Value.absent() : Value(type),
        initialBalance:
            initial == null ? const Value.absent() : Value(initial),
        decimalPlaces: body.containsKey('decimalPlaces')
            ? Value(dp as int?)
            : const Value.absent(),
        lastModified: Value(DateTime.now()),
      ));
      return ok({'id': id});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/accounts/:id/archive  { archived: bool } ───────────────────────
// Like the app: only an account at zero can be archived (archived accounts
// drop out of every balance, which would silently pull money out of
// Ready to assign).

Handler archiveAccountHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null) return badRequest('Missing id');
    final body = await parseBody(request) ?? const <String, dynamic>{};
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final archive = optBool(body, 'archived') ?? true;
    final db = ref.read(databaseProvider);
    try {
      final a = await _ownAccount(db, householdId, id);
      if (a == null) return notFound();
      if (archive) {
        final balance = await _balance(db, a);
        if (balance.abs() >= _zero(a)) {
          return badRequest('Only an account at zero can be archived',
              {'code': 'not_zero', 'balance': balance});
        }
      }
      await (db.update(db.accounts)..where((x) => x.id.equals(id))).write(
          AccountsCompanion(
              archived: Value(archive), lastModified: Value(DateTime.now())));
      return ok({'archived': archive});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/accounts/:id/reconcile  { balance } ─────────────────────────────
// The real balance from the bank. A difference is recorded as a "Balance
// adjustment" income/expense (as the app does); either way the account is
// marked reconciled now (same preference key as the app).

Handler reconcileAccountHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null) return badRequest('Missing id');
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();
    final actual = requireDouble(body, 'balance');
    if (actual == null || actual.abs() > kMaxAmount) {
      return badRequest('balance must be a number');
    }
    final db = ref.read(databaseProvider);
    try {
      final a = await _ownAccount(db, householdId, id);
      if (a == null) return notFound();
      final diff = actual - await _balance(db, a);
      final adjust = diff.abs() >= _zero(a);
      if (adjust) {
        final base = (await (db.select(db.households)
                      ..where((h) => h.id.equals(householdId)))
                    .getSingleOrNull())
                ?.baseCurrency ??
            a.currency;
        final rate = a.currency == base
            ? 1.0
            : await latestCachedRate(db, a.currency, base) ?? 1.0;
        await ref.read(allocationEngineProvider).recordTransaction(
              householdId: householdId,
              accountId: id,
              type: diff > 0 ? 'income' : 'expense',
              baseCurrency: base,
              lines: [
                TxLine(
                    amount: diff.abs(),
                    currency: a.currency,
                    exchangeRateToBase: rate),
              ],
              note: currentS().acctBalanceAdjustment,
              deviceId: 'web',
            );
      }
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reconciled_$id', now.toIso8601String());
      return ok({
        'adjusted': adjust ? diff : 0,
        'reconciledAt': now.toIso8601String(),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}
