import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_budget.dart';
import '_serializers.dart';
import '_validation.dart';

Handler dashboardHandler(Ref ref) {
  return (Request request) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      final snapshot = await budgetSnapshot(db, householdId);

      final txs = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.deleted.equals(false) &
                t.status.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(8))
          .get();

      final categories = await (db.select(db.categories)
            ..where((c) => c.householdId.equals(householdId)))
          .get();
      final accounts = await (db.select(db.accounts)
            ..where((a) => a.householdId.equals(householdId)))
          .get();
      final catMap = {for (final c in categories) c.id: c};
      final acctMap = {for (final a in accounts) a.id: a};

      // First line per recent tx: its native currency/amount and category
      // (tx.amount/currency is always the base currency).
      final txIds = txs.map((t) => t.id).toList();
      final lines = txIds.isEmpty
          ? <TransactionLine>[]
          : await (db.select(db.transactionLines)
                ..where((l) => l.transactionId.isIn(txIds)))
              .get();
      final firstLine = <String, TransactionLine>{};
      final lineCount = <String, int>{};
      for (final l in lines) {
        firstLine.putIfAbsent(l.transactionId, () => l);
        lineCount[l.transactionId] = (lineCount[l.transactionId] ?? 0) + 1;
      }

      return ok({
        ...snapshot,
        'recentTransactions': txs
            .map((t) => txToJson(t, catMap, acctMap,
                firstLine: firstLine[t.id], lineCount: lineCount[t.id] ?? 0))
            .toList(),
      });
    } catch (e) {
      return serverError(e);
    }
  };
}
