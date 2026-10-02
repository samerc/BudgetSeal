import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/providers/engine_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_budget.dart';
import '_validation.dart';

// ── GET /api/envelopes ────────────────────────────────────────────────────────

Handler listEnvelopesHandler(Ref ref) {
  return (Request request) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      final snapshot = await budgetSnapshot(db, householdId);
      return ok({
        'items': snapshot['envelopes'],
        'unallocated': snapshot['unallocated'],
        'period': snapshot['period'],
        'baseCurrency':
            (snapshot['household'] as Map<String, dynamic>)['baseCurrency'],
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
        currency: currency.toUpperCase(),
        deviceId: 'web',
        note: truncate(optString(body, 'note') ?? '', kMaxNoteLength),
      );

      return ok({'success': true});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/envelopes/move ──────────────────────────────────────────────────

/// Moves money between envelopes, or between an envelope and Ready to assign
/// (`fromId`/`toId` null). Covering an overspent envelope is a move into it.
/// An envelope source must hold the amount in that currency.
Handler moveEnvelopeMoneyHandler(Ref ref) {
  return (Request request) async {
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final fromId = optString(body, 'fromId');
    final toId = optString(body, 'toId');
    if (fromId == null && toId == null) {
      return badRequest('fromId or toId is required');
    }
    if (fromId == toId) return badRequest('fromId and toId must differ');

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
      for (final id in [fromId, toId]) {
        if (id == null) continue;
        final alloc = await db.allocationsDao.getById(id);
        if (alloc == null ||
            alloc.householdId != householdId ||
            alloc.deleted ||
            alloc.archived) {
          return notFound('Envelope not found');
        }
      }

      final note = truncate(optString(body, 'note') ?? '', kMaxNoteLength);
      await ref.read(allocationEngineProvider).moveMoney(
            fromAllocationId: fromId,
            toAllocationId: toId,
            amount: amount,
            currency: currency.toUpperCase(),
            deviceId: 'web',
            fromNote: note,
            toNote: note,
          );
      return ok({'success': true});
    } on StateError {
      return badRequest('Not enough money in that envelope');
    } catch (e) {
      return serverError(e);
    }
  };
}
