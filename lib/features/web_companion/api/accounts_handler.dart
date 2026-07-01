import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/engine/balance_calculator.dart';
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
      final accounts = await (db.select(db.accounts)
            ..where((a) =>
                a.householdId.equals(householdId) &
                a.archived.equals(false) &
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
