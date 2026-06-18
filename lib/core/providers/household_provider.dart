import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

final currentHouseholdIdProvider =
    NotifierProvider<CurrentHouseholdIdNotifier, String?>(
        CurrentHouseholdIdNotifier.new);

class CurrentHouseholdIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

final householdProvider = StreamProvider<Household?>((ref) {
  final db = ref.watch(databaseProvider);
  final id = ref.watch(currentHouseholdIdProvider);
  if (id == null) return Stream.value(null);
  return (db.select(db.households)..where((t) => t.id.equals(id)))
      .watchSingleOrNull();
});

final householdServiceProvider = Provider((ref) => HouseholdService(ref));

class HouseholdService {
  final Ref _ref;
  const HouseholdService(this._ref);

  static const _uuid = Uuid();

  Future<String> createHousehold({
    required String name,
    required String baseCurrency,
    required int periodStartDay,
    required String deviceId,
  }) async {
    final db = _ref.read(databaseProvider);
    final id = _uuid.v4();
    await db.into(db.households).insert(HouseholdsCompanion.insert(
          id: id,
          name: name,
          baseCurrency: Value(baseCurrency),
          periodStartDay: Value(periodStartDay),
          createdByDeviceId: deviceId,
        ));

    // NOTE: Category seeding is owned entirely by the onboarding flow
    // (see onboarding_screen.dart, which uses the i18n-aware presets in
    // category_presets.dart and respects the user's "Full set / Empty"
    // choice). Do NOT seed categories here — doing so created a second,
    // hardcoded English-only set on top of the onboarding set, producing
    // duplicate categories.

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_household_id', id);
    _ref.read(currentHouseholdIdProvider.notifier).set(id);
    return id;
  }

  Future<void> loadSavedHousehold() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('current_household_id');
    _ref.read(currentHouseholdIdProvider.notifier).set(id);
  }
}
