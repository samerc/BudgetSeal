import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/engine_provider.dart';
import 'core/providers/household_provider.dart';
import 'core/services/daily_reminder_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler for Flutter framework errors (build, layout, paint)
  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    // In release mode, silently log — don't show red screen
    if (kReleaseMode) {
      FlutterError.presentError(details);
    }
  };

  // Global error zone for all uncaught async errors
  runZonedGuarded(() async {
    await _startApp();
  }, (error, stackTrace) {
    debugPrint('[Uncaught] $error');
  });
}

Future<void> _startApp() async {

  // Initialize flutter_foreground_task for the Web Companion server.
  FlutterForegroundTask.initCommunicationPort();
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'web_companion',
      channelName: 'Web Companion',
      channelDescription: 'PocketPlan Web Companion server is running',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      allowWakeLock: false,
    ),
  );

  await NotificationService.init();
  // Share the same plugin instance to avoid dual-initialize conflicts on Android.
  DailyReminderService.setSharedPlugin(NotificationService.plugin);
  await DailyReminderService.init();

  final container = ProviderContainer();
  await container.read(householdServiceProvider).loadSavedHousehold();

  // Process any due recurring transactions.
  try {
    final recurring = container.read(recurringEngineProvider);
    await recurring.processRecurring();
  } catch (e) {
    debugPrint('Recurring processing failed: $e');
  }

  // Check envelopes and upcoming bills for notifications.
  try {
    final householdId = container.read(currentHouseholdIdProvider);
    if (householdId != null) {
      final db = container.read(databaseProvider);
      await NotificationService.checkEnvelopes(db, householdId);
      await NotificationService.checkRecurring(db, householdId);
    }
  } catch (e) {
    debugPrint('Notification check failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PocketPlanApp(),
    ),
  );
}

