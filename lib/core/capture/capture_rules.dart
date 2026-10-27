import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// The rule for [text] (a shop, a bank message): the one whose match
/// appears in it, the longest match first (so "spinneys achrafieh" beats
/// "spinneys"); null when none does.
Future<CaptureRule?> findCaptureRule(
    AppDatabase db, String householdId, String text) async {
  final t = _norm(text);
  if (t.isEmpty) return null;
  final rules = await (db.select(db.captureRules)
        ..where((r) =>
            r.householdId.equals(householdId) & r.deleted.equals(false)))
      .get();
  rules.sort((a, b) => b.match.length.compareTo(a.match.length));
  for (final r in rules) {
    final m = _norm(r.match);
    if (m.isNotEmpty && t.contains(m)) return r;
  }
  return null;
}

/// A captured payment from [shop] was saved with [categoryId] (and
/// [accountId]): remember it, so the next one from there is filled in
/// (user's decision: learn from fixes). A rule the user made is only
/// counted, never changed; a learned one follows the latest choice.
Future<void> learnCaptureRule(
  AppDatabase db, {
  required String householdId,
  required String shop,
  required String? categoryId,
  required String? accountId,
}) async {
  final match = _norm(shop);
  if (match.length < 3 || categoryId == null) return;
  final existing = await (db.select(db.captureRules)
        ..where((r) =>
            r.householdId.equals(householdId) &
            r.deleted.equals(false) &
            r.match.lower().equals(match)))
      .getSingleOrNull();
  final now = DateTime.now();
  if (existing == null) {
    await db.into(db.captureRules).insert(CaptureRulesCompanion.insert(
          id: const Uuid().v4(),
          householdId: householdId,
          match: match,
          categoryId: Value(categoryId),
          accountId: Value(accountId),
          learned: const Value(true),
          uses: const Value(1),
        ));
    return;
  }
  await (db.update(db.captureRules)..where((r) => r.id.equals(existing.id)))
      .write(CaptureRulesCompanion(
    uses: Value(existing.uses + 1),
    categoryId: existing.learned ? Value(categoryId) : const Value.absent(),
    accountId: existing.learned ? Value(accountId) : const Value.absent(),
    lastModified: Value(now),
  ));
}
