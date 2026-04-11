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

    // Seed default categories
    await _seedDefaultCategories(db, id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_household_id', id);
    _ref.read(currentHouseholdIdProvider.notifier).set(id);
    return id;
  }

  Future<void> _seedDefaultCategories(AppDatabase db, String householdId) async {
    const expenseGroups = [
      ('Food & Dining', '#E57373', [
        'Groceries',
        'Restaurants',
        'Coffee & Snacks',
      ]),
      ('Transportation', '#FF8A65', [
        'Fuel',
        'Public Transit',
        'Parking & Tolls',
      ]),
      ('Housing', '#64B5F6', [
        'Rent / Mortgage',
        'Utilities',
        'Maintenance',
      ]),
      ('Shopping', '#BA68C8', [
        'Clothing',
        'Electronics',
        'Household Items',
      ]),
      ('Entertainment', '#FFD54F', [
        'Subscriptions',
        'Movies & Events',
        'Hobbies',
      ]),
      ('Health', '#4DB6AC', [
        'Medical',
        'Pharmacy',
        'Fitness',
      ]),
      ('Personal', '#90A4AE', [
        'Education',
        'Gifts',
        'Personal Care',
      ]),
    ];

    const incomeGroups = [
      ('Income', '#81C784', [
        'Salary',
        'Freelance',
        'Investments',
        'Other Income',
      ]),
    ];

    for (final (groupName, colorHex, subs) in expenseGroups) {
      final groupId = _uuid.v4();
      await db.into(db.categories).insert(CategoriesCompanion.insert(
            id: groupId,
            householdId: householdId,
            name: groupName,
            colorHex: Value(colorHex),
            transactionType: const Value('expense'),
          ));
      for (final subName in subs) {
        await db.into(db.categories).insert(CategoriesCompanion.insert(
              id: _uuid.v4(),
              householdId: householdId,
              name: subName,
              parentId: Value(groupId),
              colorHex: Value(colorHex),
              transactionType: const Value('expense'),
            ));
      }
    }

    for (final (groupName, colorHex, subs) in incomeGroups) {
      final groupId = _uuid.v4();
      await db.into(db.categories).insert(CategoriesCompanion.insert(
            id: groupId,
            householdId: householdId,
            name: groupName,
            colorHex: Value(colorHex),
            transactionType: const Value('income'),
          ));
      for (final subName in subs) {
        await db.into(db.categories).insert(CategoriesCompanion.insert(
              id: _uuid.v4(),
              householdId: householdId,
              name: subName,
              parentId: Value(groupId),
              colorHex: Value(colorHex),
              transactionType: const Value('income'),
            ));
      }
    }
  }

  Future<void> loadSavedHousehold() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('current_household_id');
    _ref.read(currentHouseholdIdProvider.notifier).set(id);
  }
}
