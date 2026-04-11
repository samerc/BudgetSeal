import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/engine_provider.dart';
import 'core/providers/household_provider.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  final container = ProviderContainer();
  await container.read(householdServiceProvider).loadSavedHousehold();

  // Process any due recurring transactions.
  try {
    final recurring = container.read(recurringEngineProvider);
    await recurring.processRecurring();
  } catch (_) {}

  // Check envelopes and upcoming bills for notifications.
  try {
    final householdId = container.read(currentHouseholdIdProvider);
    if (householdId != null) {
      final db = container.read(databaseProvider);
      await NotificationService.checkEnvelopes(db, householdId);
      await NotificationService.checkRecurring(db, householdId);
    }
  } catch (_) {}

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PocketPlanApp(),
    ),
  );
}
