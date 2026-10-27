import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/engine/allocation_engine.dart';
import 'package:budgetseal/core/providers/allocations_provider.dart';
import 'package:budgetseal/core/providers/categories_provider.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/family_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/core/providers/transactions_provider.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderBase;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Allocation _env({String? owner, bool private = false}) => Allocation(
    id: 'e', householdId: 'h', name: 'E', categoryId: 'c', type: 'spending',
    periodicity: 'periodic', rollover: false, autoReset: true, archived: false,
    deviceId: 't', createdAt: DateTime(2026), lastModified: DateTime(2026),
    deleted: false, ownerDeviceId: owner, isPrivate: private);

void main() {
  test('who sees an envelope', () {
    bool sees(Allocation a, {bool kid = false}) =>
        envelopeVisible(a, me: 'me', kid: kid);
    expect(sees(_env()), isTrue);
    expect(sees(_env(owner: 'sara')), isTrue);
    expect(sees(_env(owner: 'sara', private: true)), isFalse);
    expect(sees(_env(owner: 'me', private: true)), isTrue);
    // A kid sees only theirs.
    expect(sees(_env(), kid: true), isFalse);
    expect(sees(_env(owner: 'sara'), kid: true), isFalse);
    expect(sees(_env(owner: 'me', private: true), kid: true), isTrue);
  });

  group('on this phone', () {
    late AppDatabase db;
    late ProviderContainer c;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      DeviceIdentity.debugSet('me');
      db = AppDatabase.forTesting(NativeDatabase.memory());
      c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
      c.read(currentHouseholdIdProvider.notifier).set('h');
      await db.into(db.households).insert(HouseholdsCompanion.insert(
          id: 'h', name: 'Home', createdByDeviceId: 't'));
      for (final (id, name) in [('me', 'Sam'), ('sara', 'Sara')]) {
        await db.into(db.users).insert(UsersCompanion.insert(
            id: id, householdId: 'h', name: name, deviceId: id));
      }
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'bank', householdId: 'h', name: 'Bank', type: 'bank',
          currency: 'USD', initialBalance: const Value(1000), deviceId: 't'));
      for (final (id, owner, private) in [
        ('food', null, false),
        ('gift', 'sara', true),
        ('mine', 'me', true),
      ]) {
        await db.into(db.allocations).insert(AllocationsCompanion.insert(
            id: id, householdId: 'h', name: id, categoryId: id,
            deviceId: 't', ownerDeviceId: Value(owner),
            isPrivate: Value(private)));
        await db.into(db.categories).insert(CategoriesCompanion.insert(
            id: id, householdId: 'h', name: id, allocationId: Value(id)));
      }
      final e = AllocationEngine(db);
      await e.fundAllocation(
          allocationId: 'gift', amount: 50, currency: 'USD', deviceId: 't');
      await e.recordTransaction(
          householdId: 'h', accountId: 'bank', type: 'expense',
          lines: const [TxLine(amount: 30, currency: 'USD', categoryId: 'gift')],
          baseCurrency: 'USD', note: 'Necklace for Sam');
      await e.recordTransaction(
          householdId: 'h', accountId: 'bank', type: 'expense',
          lines: const [TxLine(amount: 12, currency: 'USD', categoryId: 'food')],
          baseCurrency: 'USD', note: 'Lunch');
    });
    tearDown(() async {
      c.dispose();
      await db.close();
      DeviceIdentity.debugSet('local');
    });

    Future<void> settle() async {
      // Kept alive as a screen would.
      void keep<T>(ProviderBase<T> p) => c.listen<T>(p, (_, __) {});
      keep(allocationsProvider);
      keep(categoriesProvider);
      keep(membersProvider);
      keep(transactionEntriesProvider);
      keep(visibleAllocationsProvider);
      keep(hiddenCategoryIdsProvider);
      keep(privateBalancesProvider);
      keep(amKidProvider);
      await c.read(allocationsProvider.future);
      await c.read(categoriesProvider.future);
      await c.read(membersProvider.future);
    }

    test("another member's private envelope: hidden, its category hidden, "
        'its spending shown as Private, its money on one line', () async {
      await settle();
      expect([for (final a in c.read(visibleAllocationsProvider).value!) a.data.allocation.id]..sort(),
          ['food', 'mine']);
      expect(c.read(hiddenCategoryIdsProvider), {'gift'});
      expect(c.read(privateBalancesProvider), {'USD': 20.0});
      final entries = await c.read(transactionEntriesProvider.future);
      final gift = entries.singleWhere((e) => e.lines.single.amount == 30);
      expect((gift.isPrivate, gift.tx.note, gift.lines.single.categoryId),
          (true, '', null));
      final lunch = entries.singleWhere((e) => e.lines.single.amount == 12);
      expect((lunch.isPrivate, lunch.tx.note), (false, 'Lunch'));
    });

    test("a kid's phone shows only the kid's envelopes", () async {
      await (db.update(db.users)..where((u) => u.id.equals('me')))
          .write(const UsersCompanion(role: Value(kidRole)));
      await settle();
      expect(c.read(amKidProvider), isTrue);
      expect([for (final a in c.read(visibleAllocationsProvider).value!) a.data.allocation.id],
          ['mine']);
      expect(c.read(privateBalancesProvider), isEmpty);
    });
  });
}
