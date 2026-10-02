import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/engine_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Two-phase delete with Undo (see CLAUDE.md "Undo Delete"): marks the
/// transactions deleted now but keeps their ledger entries, then shows a
/// 5-second SnackBar. Undo restores them; once the SnackBar closes un-undone
/// the engine delete removes the ledger entries.
///
/// [onUndo] runs after the rows are restored (e.g. to un-hide a swiped row).
/// Call with a context whose ScaffoldMessenger outlives the screen if the
/// caller pops right after (the SnackBar is shown before this returns).
Future<void> deleteTransactionsWithUndo(
  BuildContext context,
  List<String> ids, {
  VoidCallback? onUndo,
}) async {
  if (ids.isEmpty) return;
  final tr = S.of(context);
  // The SnackBar outlives the calling screen; use the container, not `ref`.
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.of(context);
  final db = container.read(databaseProvider);
  final engine = container.read(allocationEngineProvider);

  Future<void> setDeleted(bool deleted) async {
    await (db.update(db.transactions)..where((t) => t.id.isIn(ids))).write(
        TransactionsCompanion(
            deleted: Value(deleted), lastModified: Value(DateTime.now())));
    container.invalidate(transactionEntriesProvider);
    container.invalidate(monthlyTransactionsProvider);
  }

  await setDeleted(true);
  var undone = false;
  messenger.clearSnackBars();
  messenger
      .showSnackBar(SnackBar(
        content: Text(ids.length == 1
            ? tr.txTransactionDeleted
            : tr.txNDeleted(ids.length)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: tr.txUndoAction,
          onPressed: () async {
            undone = true;
            await setDeleted(false);
            onUndo?.call();
          },
        ),
      ))
      .closed
      .then((_) async {
    if (undone) return;
    for (final id in ids) {
      await engine.deleteTransaction(id);
    }
  }).catchError((Object e) {
    // Rows stay soft-deleted (balances ignore their ledger); the startup
    // sweep in main.dart removes the leftover ledger entries.
    debugPrint('[DeleteWithUndo] Finishing delete failed: $e');
  });
}
