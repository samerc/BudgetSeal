import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

/// This install's id, stamped on the transactions it saves so a shared
/// budget can say who added what. Rows saved before it existed (and by
/// other tools) carry `'local'`, `'web'`, `'period-reset'`… — not a person.
class DeviceIdentity {
  static const _key = 'device_id';
  static const prefix = 'dev-';

  /// `'local'` until [init] runs (tests keep it).
  static String _id = 'local';
  static String get id => _id;

  static Future<void> init([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || !id.startsWith(prefix)) {
      id = '$prefix${const Uuid().v4()}';
      await prefs.setString(_key, id);
    }
    _id = id;
  }

  /// For tests.
  static void debugSet(String id) => _id = id;

  /// The engines' default `'local'` becomes this device; anything else
  /// (`'web'`, `'period-reset'`) is kept.
  static String stamp(String deviceId) => deviceId == 'local' ? _id : deviceId;

  /// Whether [deviceId] names a person's device (not a legacy/tool value).
  static bool isPerson(String deviceId) => deviceId.startsWith(prefix);
}

/// Who uses a shared budget: one `users` row per device (id = device id),
/// synced with the rest of the household. Single-user households never get
/// a row and never see names.
class HouseholdMembers {
  static const _joinedKey = 'members_joined_shared';
  static const _skippedKey = 'members_name_skipped_others';

  /// Device id → name for [householdId].
  static Future<Map<String, String>> names(
      AppDatabase db, String householdId) async {
    final rows = await (db.select(db.users)
          ..where((u) => u.householdId.equals(householdId)))
        .get();
    return {
      for (final u in rows)
        if (u.name.trim().isNotEmpty) u.deviceId: u.name.trim()
    };
  }

  /// This device's name, or null.
  static Future<String?> myName(AppDatabase db, String householdId) async =>
      (await names(db, householdId))[DeviceIdentity.id];

  /// Saves (or renames) this device's member row.
  static Future<void> setMyName(
      AppDatabase db, String householdId, String name) async {
    final now = DateTime.now();
    await db.into(db.users).insertOnConflictUpdate(UsersCompanion.insert(
          id: DeviceIdentity.id,
          householdId: householdId,
          name: name.trim(),
          deviceId: DeviceIdentity.id,
          lastModified: Value(now),
        ));
  }

  /// This device took a budget from the cloud (a shared one, most likely).
  static Future<void> markJoined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_joinedKey, true);
  }

  /// "Just me": not asked again until someone new names themselves.
  static Future<void> skip(AppDatabase db, String householdId) async {
    final others = (await names(db, householdId))
        .keys
        .where((d) => d != DeviceIdentity.id)
        .length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_skippedKey, others);
  }

  /// Another person's device has added entries or named itself.
  static Future<bool> isShared(AppDatabase db, String householdId) async {
    final others = (await names(db, householdId))
        .keys
        .any((d) => d != DeviceIdentity.id);
    if (others) return true;
    final row = await (db.selectOnly(db.transactions)
          ..addColumns([db.transactions.id])
          ..where(db.transactions.householdId.equals(householdId) &
              db.transactions.deviceId.like('${DeviceIdentity.prefix}%') &
              db.transactions.deviceId.equals(DeviceIdentity.id).not())
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Ask this device for a name: it has none yet, and the budget is shared
  /// (another device named itself or added entries, or this one joined from
  /// the cloud) — unless "Just me" was chosen and nobody new appeared since.
  static Future<bool> shouldAsk(AppDatabase db, String householdId) async {
    if (!DeviceIdentity.isPerson(DeviceIdentity.id)) return false;
    final all = await names(db, householdId);
    if (all.containsKey(DeviceIdentity.id)) return false;
    final others = all.keys.where((d) => d != DeviceIdentity.id).length;
    final prefs = await SharedPreferences.getInstance();
    final skipped = prefs.getInt(_skippedKey);
    if (skipped != null && others <= skipped) return false;
    if (others > 0) return true;
    return (prefs.getBool(_joinedKey) ?? false) ||
        await isShared(db, householdId);
  }
}
