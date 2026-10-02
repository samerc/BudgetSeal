import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';

import '../../../core/database/app_database.dart';
import '../../../core/engine/allocation_engine.dart';
import '../../../core/fx/fx_service.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/engine_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_validation.dart';

// ── POST /api/import ──────────────────────────────────────────────────────────
// { accountId, dryRun?, rows: [{ date: 'YYYY-MM-DD', description, amount
// (signed: + income, − expense), category? }] } — the browser reads the CSV
// and maps the columns; the rules here are the app's import_screen.dart:
// rows already in the account (same day, amount and type) are skipped, a
// category is matched by name or guessed from past titles, and every row goes
// through recordTransaction in the account's currency. dryRun only counts.

const _kMaxImportRows = 1000;
final _dayRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

String _dupKey(DateTime d, double amount, String type) =>
    '${d.year}-${d.month}-${d.day}|${amount.toStringAsFixed(2)}|$type';

Handler importCsvHandler(Ref ref) {
  return (Request request) async {
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final accountId = requireString(body, 'accountId');
    if (accountId == null) return badRequest('accountId is required');
    final rows = body['rows'];
    if (rows is! List || rows.isEmpty) {
      return badRequest('rows must be a non-empty list');
    }
    if (rows.length > _kMaxImportRows) {
      return badRequest('At most $_kMaxImportRows rows per request');
    }
    final dryRun = optBool(body, 'dryRun') ?? false;

    final db = ref.read(databaseProvider);
    try {
      final account = await (db.select(db.accounts)
            ..where((a) =>
                a.id.equals(accountId) &
                a.householdId.equals(householdId) &
                a.deleted.equals(false)))
          .getSingleOrNull();
      if (account == null) return badRequest('accountId does not exist');
      final base = (await (db.select(db.households)
                    ..where((h) => h.id.equals(householdId)))
                  .getSingleOrNull())
              ?.baseCurrency ??
          'USD';

      // History: duplicate keys on this account, and title → category.
      final txs = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.deleted.equals(false) &
                t.status.isNull() &
                t.type.isIn(['income', 'expense'])))
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
      final seen = <String>{};
      final titleCats = <(String, String)>[];
      for (final t in txs) {
        final local = t.createdAt.toLocal();
        final txLines = byTx[t.id] ?? const <TransactionLine>[];
        for (final l in txLines) {
          if ((l.accountId ?? t.accountId) == accountId) {
            seen.add(_dupKey(local, l.amount, t.type));
          }
        }
        final title = (t.note.contains(' — ') ? t.note.split(' — ').first : t.note)
            .toLowerCase()
            .trim();
        final catId = txLines.isNotEmpty ? txLines.first.categoryId : t.categoryId;
        if (title.length >= 3 && catId != null) titleCats.add((title, catId));
      }
      String? guess(String desc) {
        final d = desc.toLowerCase();
        if (d.isEmpty) return null;
        for (final (title, catId) in titleCats) {
          if (d == title || d.contains(title)) return catId;
        }
        return null;
      }

      final cats = await (db.select(db.categories)
            ..where((c) =>
                c.householdId.equals(householdId) & c.archived.equals(false)))
          .get();
      final catByName = {for (final c in cats) c.name.toLowerCase().trim(): c.id};

      // Validate and classify every row before writing anything.
      var skipped = 0, duplicates = 0;
      final toWrite = <({DateTime date, String desc, double amount, String type, String? catId})>[];
      for (final r in rows) {
        if (r is! Map<String, dynamic>) {
          skipped++;
          continue;
        }
        final amount = requireDouble(r, 'amount');
        final dateStr = optString(r, 'date');
        if (amount == null ||
            amount == 0 ||
            amount.abs() > kMaxAmount ||
            dateStr == null ||
            !_dayRe.hasMatch(dateStr)) {
          skipped++;
          continue;
        }
        final day = DateTime.tryParse(dateStr);
        if (day == null) {
          skipped++;
          continue;
        }
        final type = amount > 0 ? 'income' : 'expense';
        if (!seen.add(_dupKey(day, amount.abs(), type))) {
          duplicates++;
          continue;
        }
        final desc =
            truncate((optString(r, 'description') ?? '').trim(), kMaxNoteLength);
        final catName = (optString(r, 'category') ?? '').toLowerCase().trim();
        toWrite.add((
          date: DateTime(day.year, day.month, day.day, 12),
          desc: desc,
          amount: amount.abs(),
          type: type,
          catId: catByName[catName] ?? guess(desc),
        ));
      }

      if (!dryRun && toWrite.isNotEmpty) {
        final rate = account.currency == base
            ? 1.0
            : await latestCachedRate(db, account.currency, base) ?? 1.0;
        final engine = ref.read(allocationEngineProvider);
        await db.transaction(() async {
          for (final w in toWrite) {
            await engine.recordTransaction(
              householdId: householdId,
              accountId: accountId,
              type: w.type,
              lines: [
                TxLine(
                  amount: w.amount,
                  currency: account.currency,
                  categoryId: w.catId,
                  accountId: accountId,
                  exchangeRateToBase: rate,
                ),
              ],
              baseCurrency: base,
              note: w.desc,
              deviceId: 'web',
              date: w.date,
            );
          }
        });
      }
      return ok({
        'dryRun': dryRun,
        'imported': dryRun ? 0 : toWrite.length,
        'ready': toWrite.length,
        'categorized': toWrite.where((w) => w.catId != null).length,
        'duplicates': duplicates,
        'skipped': skipped,
      });
    } catch (e) {
      return serverError(e);
    }
  };
}
