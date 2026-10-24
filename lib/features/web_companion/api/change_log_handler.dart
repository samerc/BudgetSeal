import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';

import '../../../core/engine/change_log.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/providers/member_names_provider.dart';
import '../../../core/services/household_members.dart';
import '../../../shared/utils/note_text.dart';
import '_validation.dart';

// ── GET /api/change-log ───────────────────────────────────────────────────────

/// The app's Settings › Change history: what was added, edited or deleted
/// and when, newest first. Amounts are per line currency (never summed
/// across currencies); a transfer keeps its sent amount.
Handler changeLogHandler(Ref ref) {
  return (Request request) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      const limit = 300;
      final log = await loadChangeLog(db, householdId, limit: limit);
      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catNames = {for (final c in categories) c.id: c.name};
      final members = await HouseholdMembers.names(db, householdId);
      return ok({
        'limit': limit,
        'items': [
          for (final e in log.events)
            () {
              final tx = e.tx;
              final lines = log.lines[tx.id] ?? const [];
              final amounts = <String, double>{};
              if (tx.type == 'transfer' || lines.isEmpty) {
                amounts[tx.currency] = tx.amount;
              } else {
                for (final l in lines) {
                  amounts[l.currency] = (amounts[l.currency] ?? 0) + l.amount;
                }
              }
              final catId = tx.categoryId ?? lines.firstOrNull?.categoryId;
              return {
                'kind': e.kind.name,
                'at': e.at.toUtc().toIso8601String(),
                'txId': tx.id,
                'type': tx.type,
                'date': tx.createdAt.toUtc().toIso8601String(),
                'note': visibleNote(tx.note).split(' — ').first.trim(),
                'categoryName': catNames[catId],
                'amounts': [
                  for (final a in amounts.entries)
                    {'currency': a.key, 'amount': a.value}
                ],
                // Shared budgets: whose device saved it (not for deletes).
                'by': e.kind == ChangeKind.deleted || tx.id.startsWith('rec:')
                    ? null
                    : memberNameFor(members, tx.deviceId),
                'source': tx.id.startsWith('rec:')
                    ? 'bill'
                    : tx.deviceId == 'web'
                        ? 'web'
                        : null,
              };
            }(),
        ],
      });
    } catch (e) {
      return serverError(e);
    }
  };
}
