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

/// The app's Settings › Change history: what was added, edited, deleted or
/// restored, when, by whom, and what an edit changed, newest first. Amounts
/// are per line currency (never summed across currencies); a transfer
/// keeps its sent amount.
Handler changeLogHandler(Ref ref) {
  return (Request request) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      const limit = 300;
      final events = await loadChangeLog(db, householdId, limit: limit);
      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final catNames = {for (final c in categories) c.id: c.name};
      final accounts = await (db.select(db.accounts)
            ..where((a) => a.householdId.equals(householdId)))
          .get();
      final accountNames = {for (final a in accounts) a.id: a.name};
      final members = await HouseholdMembers.names(db, householdId);

      // A change's values for the page to show: names for ids (null = no
      // category), dates as ISO, amounts per currency.
      Object? value(String field, Object? v) => switch (field) {
            'amount' => [
                for (final e in (v as Map<String, double>? ?? const {}).entries)
                  {'currency': e.key, 'amount': e.value}
              ],
            'category' => [
                for (final id in v as List? ?? const [])
                  id == null ? null : catNames[id]
              ],
            'account' => [
                for (final id in v as List? ?? const [])
                  id == null ? null : accountNames[id]
              ],
            'date' => (v as DateTime?)?.toUtc().toIso8601String(),
            'note' => v == null ? null : visibleNote(v as String),
            _ => v,
          };

      return ok({
        'limit': limit,
        'items': [
          for (final e in events)
            {
              'kind': e.kind.name,
              'at': e.at.toUtc().toIso8601String(),
              'txId': e.tx.id,
              'type': e.tx.type,
              'date': e.tx.createdAt.toUtc().toIso8601String(),
              'note': visibleNote(e.tx.note).split(' — ').first.trim(),
              'categoryName': catNames[e.tx.categoryId],
              'amounts': [
                for (final a in e.amounts.entries)
                  {'currency': a.key, 'amount': a.value}
              ],
              // Shared budgets: whose device made the change.
              'by': e.by == null ? null : memberNameFor(members, e.by!),
              'source': e.source,
              'changes': [
                for (final c in e.changes)
                  {
                    'field': c.field,
                    'from': value(c.field, c.from),
                    'to': value(c.field, c.to),
                  }
              ],
              // Another phone's later edit replaced this one.
              'replaced': e.replacedBy != null,
              'replacedBy': e.replacedBy == null
                  ? null
                  : memberNameFor(members, e.replacedBy!),
            },
        ],
      });
    } catch (e) {
      return serverError(e);
    }
  };
}
