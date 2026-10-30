# Android, iOS, reminders & resume work

Developer notes moved out of CLAUDE.md (Oct 2026). Read before changing this area; update when you change it.

## Resume Work

On every resume `app.dart` runs `_processDueWork()`: `processRecurring()` (invalidates transaction/balance providers if anything posted) then `NotificationService.runChecks()` (envelope checks keep their 24h cooldown; bill reminders are rescheduled — see budget.md "Bill reminders"). `MainScreen` shows the one welcome tip (`dashboard_welcome`, on whichever tab opens first), then asks for the Android 13+ notification permission once (`NotificationService.requestPermissionOnce`) via `afterHints()`. First-visit tips go through `showHintIfNeeded()` (`shared/widgets/hint_banner.dart`), which queues them — never two dialogs (or a dialog and the system prompt) at once. Upcoming-bill views use `recurringAmountOn(rec, date)` so subscription price changes show before they post.

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
`SpendingWidget.kt` shows Ready to assign and today's spending, written by `HomeWidgetService` (Dart) into shared_preferences and redrawn via the `budgetseal/widget` channel in `MainActivity.kt` (`redrawAll` updates every widget type).
- `EnvelopesWidget.kt` (Oct 24 2026, `envelopes_widget.xml`, 4 fixed rows): spending envelopes in Budget-tab order with their balance in their own currency (`widget_env_count`, `widget_env_name_i` / `_amount_i` / `_neg_i` — negative in red), title and empty text localized from Dart. Tap → `/funding`.
- `QuickAddWidget.kt` (`quick_add_widget.xml`, gold `widget_accent_background`): one "+ Add" button (label `widget_add_label`) → `/add-transaction`.
- `TemplatesWidget.kt` (Oct 30 2026, `templates_widget.xml`, 4×1): up to 3 templates by use count (`widget_tmpl_count`, `widget_tmpl_id_i`, `widget_tmpl_label_i` = "title
amount"; chips `widget_chip_background`) → route `/template/<id>`, which app.dart's `_openNotificationRoute` turns into `useTemplate()` + `/add-transaction` (an empty form if it was deleted); a gold "+" → `/add-transaction`; `widget_tmpl_empty` when there are none. Request codes 10–13.
- Widget taps: `MainActivity.routeIntent(context, route, requestCode)` puts the route in the `budgetseal_route` extra. Cold start: Dart's `HomeWidgetService.init()` (main.dart) asks `launchRoute` once; while running (`singleTask` since Oct 27 2026 — was `singleTop`; a share from another app must reach the running app instead of starting a second copy, with its own engine and database connection, in the sharing app's task), `onNewIntent` calls Dart's `open`. Both set `NotificationService.openRoute`, so routing is shared with notifications and app shortcuts. Shared_preferences ints arrive in Kotlin as Long (`getLong`).
- Widget picker descriptions are in `res/values/strings.xml` (English only).
- Colors: `widget_surface` / `widget_text` / `widget_text_secondary` / `widget_negative` in `values/colors.xml` (AppColors light surface/text/overspent) and `values-night/colors.xml` (dark surface/text, lighter red) — the widgets follow the phone's dark mode, not the in-app theme choice. `EnvelopesWidget.kt` picks the amount color with `context.getColor(R.color.…)`. No hex colors in the widget layouts.

### Debug vs Play Store build
Debug builds are `com.budgetseal.app.debug`, labelled "BudgetSeal Dev" (`applicationIdSuffix` + the `appLabel` manifest placeholder in `build.gradle.kts`), so they install next to the Play Store app with their own data.

### Google Drive Setup
Requires OAuth client ID configured in Google Cloud Console. Client ID goes in `android/app/src/main/res/values/strings.xml` (or via google-services.json). Each Android OAuth client is tied to an app id + signing SHA-1, one fingerprint per client (project 87876782358):
- **BudgetSeal Play** — `com.budgetseal.app` + the **Play App Signing** key (Play Console › App integrity › Play app signing › "App signing key certificate"). Play re-signs every install with it, so without this client sign-in shows the account list and then fails (0.12.1, Oct 29 2026).
- **BudgetSeal Upload** (optional) — `com.budgetseal.app` + the upload key (`android/budgetseal.jks`, SHA-1 `81:DF:65:…:D4:3F`), for a release APK installed straight from the PC.
- **BudgetSeal Dev** — `com.budgetseal.app.debug` + `~/.android/debug.keystore` (SHA-1 `3B:70:85:8F…`; copy that keystore to any new PC).
- **PocketPlan Web** — the Web client whose id is `GOOGLE_SERVER_CLIENT_ID` in `.env`. Google deletes OAuth clients unused for 6 months; a sign-in keeps it alive.
- The consent screen (Google Auth Platform › Audience) is still **Testing**: only listed test users can connect Drive. Publish it (Branding page first) before a public release.

- **Share into BudgetSeal** (roadmap #2a, Oct 27 2026): intent filters `SEND` `text/plain` and `SEND` `image/*` on `MainActivity`. `readShare()` takes `EXTRA_SUBJECT` + `EXTRA_TEXT` and `EXTRA_STREAM` (an image is copied to `cache/shared/` — the sender's read grant ends with the intent; the type falls back to the share's own when the provider doesn't say), then sets the intent's action to MAIN so a recreated activity doesn't share it again. Channel `budgetseal/share`: `take` (Dart, at start and on `arrived`) returns `{text, files}` once. Dart side: `core/capture/share_intake.dart` (`ShareIntake.init()` in main.dart → `incoming`; `_openShare()` in app.dart builds `shareFormArgs()` and pushes `/add-transaction`, scheduling a frame because a share reaching the app on screen comes with none). Tested on the A02: cold and warm text shares, cold and warm image shares (adb: `am start -a android.intent.action.SEND -t image/png --eu android.intent.extra.STREAM file:///data/local/tmp/x.png -n com.budgetseal.app.debug/com.budgetseal.app.MainActivity` — a MediaStore URI from the shell has no read grant). **iOS: not yet** (needs a Share Extension target, built on a Mac).
- **Bank alerts** (roadmap #2c, Oct 27 2026): `AlertListener.kt` (`NotificationListenerService`, manifest `BIND_NOTIFICATION_LISTENER_SERVICE`, label = app label) — enabled only by the user in system settings. For every posted notification it notes the app's name in its own prefs file `budgetseal_alerts` (`seen_apps`, package → label; no content); for the picked apps (`apps`) it keeps title + big text/text in `queue` (deduped by key + text hash, last 200; group summaries skipped). Channel `budgetseal/alerts` in MainActivity: `status` ({enabled via `NotificationManagerCompat.getEnabledListenerPackages`, seen, apps}), `setApps`, `take` (the queue JSON, then cleared), `openSettings` (`ACTION_NOTIFICATION_LISTENER_SETTINGS`). `apply()` writes land a moment later. Package visibility: the label comes from `getApplicationInfo` in the service; the package name is shown when it can't be read. No `QUERY_ALL_PACKAGES` (Play-restricted) — apps are picked from those that posted. Test on a phone: `adb shell cmd notification allow_listener com.budgetseal.app.debug/com.budgetseal.app.AlertListener`, then `cmd notification post -S bigtext -t Bank tag "purchase of USD 18.40 at …"` (posted by "Shell"); revoke with `disallow_listener`. Play: the text never leaves the phone (Data safety: not collected).

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

### Device support (Play)
ML Kit's document scanner activity (`GmsDocumentScanningDelegateActivity`) declares `screenOrientation="portrait"`, which makes Play imply `android.hardware.screen.portrait` as required and drop landscape-only devices (POS screens, car head units). `AndroidManifest.xml` declares it `required="false"`. When Play warns "no longer supports N devices", open the device list and read the reason before proceeding.
