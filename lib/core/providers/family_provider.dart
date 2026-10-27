import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../services/household_members.dart';
import 'allocations_provider.dart';
import 'categories_provider.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// Family (roadmap #5). Members are the `users` rows (one per device);
/// `role` 'kid' marks a kid, anything else is a grown-up (user's decision:
/// kids ask for money, grown-ups approve).
const kidRole = 'kid';

final membersProvider = StreamProvider<List<User>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return Stream.value(const []);
  final db = ref.watch(databaseProvider);
  return (db.select(db.users)..where((u) => u.householdId.equals(householdId)))
      .watch();
});

/// This phone belongs to a kid: it shows only their own envelopes.
final amKidProvider = Provider<bool>((ref) =>
    (ref.watch(membersProvider).value ?? const <User>[])
        .any((u) => u.deviceId == DeviceIdentity.id && u.role == kidRole));

/// Whether [a] shows on this phone: another member's private envelope
/// doesn't; on a kid's phone, only theirs does.
bool envelopeVisible(Allocation a, {required String me, required bool kid}) {
  if (kid) return a.ownerDeviceId == me;
  return !(a.isPrivate && a.ownerDeviceId != null && a.ownerDeviceId != me);
}

/// The envelopes this phone shows (lists, pickers, reports by envelope).
/// Money totals still come from every envelope ([allocationsProvider]).
final visibleAllocationsProvider =
    Provider<AsyncValue<List<AllocationWithBalance>>>((ref) {
  final kid = ref.watch(amKidProvider);
  return ref.watch(allocationsProvider).whenData((all) => [
        for (final a in all)
          if (envelopeVisible(a.data.allocation,
              me: DeviceIdentity.id, kid: kid))
            a,
      ]);
});

/// The envelopes this phone doesn't show.
final hiddenAllocationIdsProvider = Provider<Set<String>>((ref) {
  final kid = ref.watch(amKidProvider);
  return {
    for (final a in ref.watch(allocationsProvider).value ?? const [])
      if (!envelopeVisible(a.data.allocation, me: DeviceIdentity.id, kid: kid))
        a.data.allocation.id,
  };
});

/// What the other members' private envelopes hold, per currency: one
/// "Private" line on the Budget tab, so the money still adds up there.
final privateBalancesProvider = Provider<Map<String, double>>((ref) {
  if (ref.watch(amKidProvider)) return const {};
  final hidden = ref.watch(hiddenAllocationIdsProvider);
  final out = <String, double>{};
  for (final a in ref.watch(allocationsProvider).value ?? const []) {
    if (!hidden.contains(a.data.allocation.id)) continue;
    a.balanceByCurrency.forEach((c, v) => out[c] = (out[c] ?? 0) + v);
  }
  return out;
});

/// Categories of hidden envelopes (directly or through their parent):
/// not offered in pickers, and their transactions show as "Private".
final hiddenCategoryIdsProvider = Provider<Set<String>>((ref) {
  final hidden = ref.watch(hiddenAllocationIdsProvider);
  if (hidden.isEmpty) return const {};
  final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
  final byId = {for (final c in cats) c.id: c};
  bool isHidden(Category c) =>
      (c.allocationId != null && hidden.contains(c.allocationId)) ||
      (c.allocationId == null &&
          c.parentId != null &&
          byId[c.parentId]?.allocationId != null &&
          hidden.contains(byId[c.parentId]!.allocationId));
  return {for (final c in cats) if (isHidden(c)) c.id};
});

/// [hiddenCategoryIdsProvider] as one string ("id,id"), for providers that
/// rebuild a lot (the transaction history): a String only changes when the
/// set does, while a Set is new on every envelope change.
final hiddenCategoryKeyProvider = Provider<String>((ref) =>
    (ref.watch(hiddenCategoryIdsProvider).toList()..sort()).join(','));

Set<String> hiddenCategoriesFromKey(String key) =>
    key.isEmpty ? const {} : key.split(',').toSet();
