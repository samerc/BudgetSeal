import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/database/daos/ledger_dao.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/engine_provider.dart';
import 'core/providers/household_provider.dart';
import 'core/providers/premium_provider.dart';
import 'core/services/daily_reminder_service.dart';
import 'core/services/notification_service.dart';
import 'shared/utils/app_info.dart';

void main() {
  // Global error handler for Flutter framework errors (build, layout, paint)
  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    // In release mode, silently log — don't show red screen
    if (kReleaseMode) {
      FlutterError.presentError(details);
    }
  };

  // Global error zone for all uncaught async errors. The binding is created
  // inside it so runApp runs in the same zone (else Flutter warns of a zone
  // mismatch and errors escape the handler).
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Load the real app version/build so the About & Settings screens never
    // show a stale hardcoded version.
    await initAppInfo();
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
      channelDescription: 'BudgetSeal Web Companion server is running',
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

  // Set locale early so engine/notification code uses the right language.
  final prefs = await SharedPreferences.getInstance();
  Intl.defaultLocale = prefs.getString('app_locale') ??
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;

  // Notifications are optional: a plugin failure must not leave the app
  // stuck before runApp.
  try {
    await NotificationService.init();
    // Share the same plugin instance to avoid dual-initialize conflicts on Android.
    DailyReminderService.setSharedPlugin(NotificationService.plugin);
    await DailyReminderService.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  final container = ProviderContainer();
  await container.read(householdServiceProvider).loadSavedHousehold();
  // Load premium state before the UI builds so feature gates never see a
  // stale `false` on a cold start (the redeem code must "stick" across restarts).
  try {
    await container.read(hasPremiumProvider.notifier).restorePurchases();
  } catch (e) {
    debugPrint('Premium restore failed: $e');
  }

  // Undo-delete removes ledger rows after its SnackBar closes; if the app
  // was killed first, finish that cleanup now.
  try {
    await LedgerDao(container.read(databaseProvider))
        .deleteForDeletedTransactions();
  } catch (e) {
    debugPrint('Ledger cleanup failed: $e');
  }

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
      await NotificationService.checkBudgetWarnings(db, householdId);
      await NotificationService.checkRecurring(db, householdId);
    }
  } catch (e) {
    debugPrint('Notification check failed: $e');
  }

  // Draw behind the status/navigation bars on all Android versions
  // (Android 15+ enforces this anyway).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BudgetSealApp(),
    ),
  );
}

