# Android, iOS, reminders & resume work

Developer notes moved out of CLAUDE.md (Oct 2026). Read before changing this area; update when you change it.

## Resume Work

On every resume `app.dart` runs `_processDueWork()`: `processRecurring()` (invalidates transaction/balance providers if anything posted) then `NotificationService.runChecks()` (each check keeps its 24h cooldown). `MainScreen` shows the one welcome tip (`dashboard_welcome`, on whichever tab opens first), then asks for the Android 13+ notification permission once (`NotificationService.requestPermissionOnce`) via `afterHints()`. First-visit tips go through `showHintIfNeeded()` (`shared/widgets/hint_banner.dart`), which queues them — never two dialogs (or a dialog and the system prompt) at once. Upcoming-bill views use `recurringAmountOn(rec, date)` so subscription price changes show before they post.

## Daily Reminder Timezone
Must call `tz.setLocalLocation()` after `initializeTimeZones()`. Without it everything runs as UTC. Use `flutter_timezone` to get the device identifier.

## Android

### Min SDK
`minSdk = 26` (Android 8.0+). Required by `local_auth`, `webview_flutter`, and `flutter_local_notifications`. Notification channels work properly at API 26+.

### Permissions (`android/app/src/main/AndroidManifest.xml`)
Standard: `INTERNET`, `RECEIVE_BOOT_COMPLETED`, `USE_BIOMETRIC`, `USE_FINGERPRINT`, `POST_NOTIFICATIONS`.

Added for Web Companion:
```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
```

Service declaration (inside `<application>`):
```xml
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundTaskService"
    android:foregroundServiceType="dataSync"
    android:exported="false"/>
```

### Home Screen Widget
`SpendingWidget.kt` shows Ready to assign and today's spending, written by `HomeWidgetService` (Dart) into shared_preferences and redrawn via the `budgetseal/widget` channel in `MainActivity.kt`.

### Debug vs Play Store build
Debug builds are `com.budgetseal.app.debug`, labelled "BudgetSeal Dev" (`applicationIdSuffix` + the `appLabel` manifest placeholder in `build.gradle.kts`), so they install next to the Play Store app with their own data.

### Google Drive Setup
Requires OAuth client ID configured in Google Cloud Console. Client ID goes in `android/app/src/main/res/values/strings.xml` (or via google-services.json). Each Android OAuth client is tied to an app id + signing SHA-1: release (`com.budgetseal.app` + upload/Play signing key) and debug (`com.budgetseal.app.debug` + `~/.android/debug.keystore` SHA-1) need separate clients.

## iOS

### `ios/Runner/Info.plist` additions for Web Companion
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>PocketPlan needs local network access to serve the Web Companion interface to your browser.</string>
<key>NSBonjourServices</key>
<array>
    <string>_http._tcp</string>
</array>
```

## Daily Reminder

`DailyReminderService` schedules a daily local notification via `flutter_local_notifications`. Users configure in Settings: toggle on/off, pick time (default 7 PM), optional custom message. If no custom message, rotates between 5 default prompts. Initialized in `main()` via `DailyReminderService.init()` which re-schedules if enabled. Uses `timezone` package for `zonedSchedule` with `matchDateTimeComponents.time`.

**Critical:** `DailyReminderService` shares the same `FlutterLocalNotificationsPlugin` instance as `NotificationService` via `setSharedPlugin()` — having two separate instances causes the second `initialize()` to break the first's scheduling callbacks on Android. The plugin is initialized once in `NotificationService.init()`, then shared via `DailyReminderService.setSharedPlugin(NotificationService.plugin)` in `main.dart`.

**Exact alarm fallback:** On Android 14+, `SCHEDULE_EXACT_ALARM` requires explicit user grant. The service checks `canScheduleExactNotifications()` first — if denied, falls back to `inexactAllowWhileIdle` (fires within ~15 min window, fine for daily reminders). Never calls `requestExactAlarmsPermission()` automatically as it navigates away from the app.
