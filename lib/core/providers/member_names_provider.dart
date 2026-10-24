import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../services/household_members.dart';
import 'database_provider.dart';
import 'household_provider.dart';

/// Device id → member name for the current household, live (a sync that
/// brings someone's name in redraws).
final memberNamesProvider = StreamProvider<Map<String, String>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider);
  if (householdId == null) return Stream.value(const {});
  final db = ref.watch(databaseProvider);
  return (db.select(db.users)..where((u) => u.householdId.equals(householdId)))
      .watch()
      .map((rows) => {
            for (final User u in rows)
              if (u.name.trim().isNotEmpty) u.deviceId: u.name.trim()
          });
});

/// Who saved a transaction, for "Added by X" — null in a single-user
/// budget (only this device named, or nobody) and for rows from before
/// names, the Web Companion or other tools.
String? memberNameFor(Map<String, String> names, String deviceId) {
  if (!names.keys.any((d) => d != DeviceIdentity.id)) return null;
  return names[deviceId];
}
