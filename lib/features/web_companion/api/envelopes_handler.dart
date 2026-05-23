import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/engine/balance_calculator.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/engine_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_serializers.dart';
import '_validation.dart';

// ── GET /api/envelopes ────────────────────────────────────────────────────────

Handler listEnvelopesHandler(Ref ref) {
  return (Request request) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      final allocs = await (db.select(db.allocations)
            ..where((a) =>
                a.householdId.equals(householdId) & a.archived.equals(false))
            ..orderBy([(a) => OrderingTerm.asc(a.name)]))
          .get();

      final calculator = BalanceCalculator(db);
      final allocBalances =
          await calculator.allAllocationBalancesByCurrency(householdId);
      final unallocated = await calculator.unallocatedByCurrency(householdId);

      return ok({
        'items': allocs
            .map((a) => allocationToJson(a, allocBalances[a.id] ?? {}))
            .toList(),
        'unallocated': unallocated,
      });
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/envelopes/:id/fund ──────────────────────────────────────────────

Handler fundEnvelopeHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null || id.isEmpty) return badRequest('Missing id');

    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

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
      return badRequest('currency must be a 1-10 letter code');
    }

    final db = ref.read(databaseProvider);

    try {
      final alloc = await db.allocationsDao.getById(id);
      if (alloc == null || alloc.householdId != householdId) {
        return notFound('Envelope not found');
      }

      final engine = ref.read(allocationEngineProvider);
      await engine.fundAllocation(
        allocationId: id,
        amount: amount,
        currency: currency,
        deviceId: 'web',
        note: truncate(optString(body, 'note') ?? '', kMaxNoteLength),
      );

      return ok({'success': true});
    } catch (e) {
      return serverError(e);
    }
  };
}
