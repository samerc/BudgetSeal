import '../database/app_database.dart';

/// The envelope an expense in [categoryId] spends from, by the rules
/// [AllocationEngine.recordTransaction] applies when it writes the debit:
/// the category's own link; else (no link) its parent's; else a legacy
/// envelope keyed by the category. An archived or deleted envelope takes no
/// spending, so the result is null unless it is in [liveAllocations].
///
/// Pure, so the add screen can preview the envelope while typing.
String? envelopeForCategory(
  String categoryId, {
  required Map<String, Category> categoriesById,
  required Iterable<Allocation> liveAllocations,
}) {
  final cat = categoriesById[categoryId];
  if (cat == null) return null;
  String? id = cat.allocationId;
  if (id == null && cat.parentId != null) {
    id = categoriesById[cat.parentId!]?.allocationId;
  }
  if (id == null) {
    for (final a in liveAllocations) {
      if (a.categoryId == categoryId) return a.id;
    }
    return null;
  }
  for (final a in liveAllocations) {
    if (a.id == id) return id;
  }
  return null;
}
