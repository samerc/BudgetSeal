import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/providers/database_provider.dart';
import 'package:budgetseal/core/providers/household_provider.dart';
import 'package:budgetseal/core/services/family_service.dart';
import 'package:budgetseal/core/services/household_members.dart';
import 'package:budgetseal/features/family/requests_screen.dart';
import 'package:budgetseal/features/settings/members_screen.dart';
import 'package:budgetseal/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The family screens build on a small phone with large text, from a
/// grown-up's phone and a kid's.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  Future<void> seed({required bool kid}) async {
    SharedPreferences.setMockInitialValues({});
    DeviceIdentity.debugSet(kid ? 'kid' : 'mom');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    container.read(currentHouseholdIdProvider.notifier).set('h');
    await db.into(db.households).insert(HouseholdsCompanion.insert(
        id: 'h', name: 'Home', createdByDeviceId: 't'));
    for (final (id, name, role) in [
      ('mom', 'Mom', 'member'),
      ('kid', 'Lea', 'kid'),
    ]) {
      await db.into(db.users).insert(UsersCompanion.insert(
          id: id, householdId: 'h', name: name, deviceId: id,
          role: Value(role)));
    }
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: 'fun', householdId: 'h', name: 'Lea fun', categoryId: 'fun',
        deviceId: 't', ownerDeviceId: const Value('kid')));
    await db.into(db.allocations).insert(AllocationsCompanion.insert(
        id: 'food', householdId: 'h', name: 'Food', categoryId: 'food',
        deviceId: 't'));
    DeviceIdentity.debugSet('kid');
    await FamilyService(db).ask(
        householdId: 'h', allocationId: 'fun', amount: 20, currency: 'USD',
        note: 'School trip');
    DeviceIdentity.debugSet(kid ? 'kid' : 'mom');
  }

  tearDown(() async {
    container.dispose();
    await db.close();
    DeviceIdentity.debugSet('local');
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.15)),
          child: child!,
        ),
        home: page,
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
  }

  testWidgets("a grown-up's phone: the request to decide, the Home card, "
      'members', (tester) async {
    await tester.runAsync(() => seed(kid: false));
    await pump(tester, const RequestsScreen());
    expect(find.text('Lea asks for \$20.00'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    await pump(tester, const Scaffold(body: RequestsCard()));
    expect(find.text('1 money request'), findsOneWidget);
    await pump(tester, const MembersScreen());
    expect(find.text('Mom (you)'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets("a kid's phone: their envelope only, asking for money",
      (tester) async {
    await tester.runAsync(() => seed(kid: true));
    await pump(tester, const KidHomeScreen());
    expect(find.text('Lea fun'), findsOneWidget);
    expect(find.text('Food'), findsNothing);
    await pump(tester, const RequestsScreen());
    expect(find.text('Send request'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    await unmount(tester);
  });
}
