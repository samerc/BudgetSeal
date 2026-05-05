# PocketPlan — Claude Code Guide

## Project overview

PocketPlan is a Flutter envelope budgeting app (YNAB-style) for Android and iOS. Every dollar gets assigned to an envelope. Offline-first, optional file-based cloud sync (Google Drive / Dropbox / OneDrive). No backend server.

**Status:** Feature-complete and approaching launch readiness.

---

## Tech stack

| Layer | Choice |
|---|---|
| UI | Flutter (Material 3) |
| Database | Drift (SQLite) |
| State | Riverpod 3 |
| Navigation | GoRouter |
| Cloud sync | Google Drive API + file picker |
| Local HTTP server | shelf + shelf_router (Web Companion feature) |
| Font | Plus Jakarta Sans |

---

## Architecture rules

### Money writes always go through the engine
Never write transactions or allocation changes directly to the database. Use `AllocationEngine` (or `RecurringEngine` for recurring). Direct DB inserts bypass envelope balance accounting.

### Amount fields always use the calculator
Use `CalculatorAmountField` or `AmountField`. Never `TextField(keyboardType: TextInputType.numberWithOptions)`. The calculator lets users do inline math (split a bill, add tax) without leaving the field.

### Colors are always theme-aware
Use `AppColors.sf(context)`, `tp(context)`, `ts(context)`, `bd(context)`. Never hardcode colors on adaptive surfaces. Exception: `Colors.white` on explicit accent banners/gradients is fine.

- `AppColors.th(context)` as card background = too low-contrast in dark mode — use `sf()` + `bd()` border instead
- Accent-tinted containers: use explicit variants — dark `Color(0xFF1E3A5F)`, light `Color(0xFFDBEAFE)`

### Drift queries
Always filter `deleted.equals(false)` on transactions. `getById()` must include this filter — it's easy to miss. All list queries already have it.

---

## Known crash patterns — read before touching these areas

### Icon pickers — inline only, never overlays
`showModalBottomSheet` + `showDialog` = `_dependents.isEmpty` crash. Tried 5+ times with every variant (useRootNavigator, ctx vs context). **Only working solution:** inline expandable emoji grid inside the form with a `setState` toggle. Applied in `categories_screen.dart` and `allocation_detail_screen.dart`.

### Bill splitter — flat ListView only
Nested `Column + Expanded + bottomNavigationBar` = blank screen. Nested Rows with Expanded = blank screen. AnimatedSwitcher with switch expression = blank screen. **Only working solution:** single `ListView` body, flat `if`/spread for step content, nav buttons inline at the bottom.

### Data reset flow
Never close the database and wait for providers. Instead: `db.batch()` delete all rows → clear SharedPreferences → `context.go('/onboarding')`.

### Daily reminder timezone
Must call `tz.setLocalLocation()` after `initializeTimeZones()`. Without it everything runs as UTC. Use `flutter_timezone` to get the device identifier.

### Currency display
`tx.currency` is the base currency, not the line's native currency. For display, use `lines.first.currency`. Passing the wrong currency code to `formatAmount()` silently shows the wrong symbol.

---

## Design conventions

- **Card radius:** 14, **padding:** 16h / 14v — consistent everywhere
- **Section headers:** visible, black/primary text, bigger weight — not dimmed
- No glassmorphism. No left-border accent bars on cards (looks like a prototype).
- Design inspiration: Cashew app (cohesion and feel, not direct copying)
- "Good morning" greeting removed — user disliked it

---

## Web Companion feature

Local WiFi HTTP server (port **7432**) built into the app. Phone is the server, laptop browser is the client. All 4 phases complete.

### Files
```
lib/features/web_companion/
  web_companion_screen.dart       — phone UI (start/stop, QR, PIN)
  web_companion_service.dart      — shelf server lifecycle + middleware pipeline
  web_companion_router.dart       — all shelf routes + auth middleware
  web_companion_auth.dart         — PIN (SHA-256 hashed), sessions, lockout
  api/
    _validation.dart / _serializers.dart
    dashboard_handler.dart, transactions_handler.dart, categories_handler.dart
    accounts_handler.dart, envelopes_handler.dart, recurring_handler.dart
    subscriptions_handler.dart, reports_handler.dart

lib/core/providers/web_companion_provider.dart

assets/web/
  index.html  — SPA shell + sidebar with SVG nav icons
  app.js      — ~1200 lines, vanilla JS, hash routing, 8 screens
  styles.css  — full design system (tokens, dark mode, components)
```

### Architecture decisions
- Server runs in the **main Dart isolate** — same as Flutter UI, so handlers call Riverpod providers directly. `flutter_foreground_task` on Android is purely a process keep-alive; its `TaskHandler` is a no-op.
- `_NoOpTaskHandler.onDestroy` signature: `Future<void> onDestroy(DateTime timestamp, bool isTimeout)` — the `isTimeout` param is required in v9.
- Auto-stop after **6 hours** (Android 15+ caps dataSync foreground services).
- PIN stored as SHA-256 hash in FlutterSecureStorage.
- Session tokens: UUID4, 4-hour inactivity expiry, server-side in-memory map, max 10 sessions (oldest evicted).
- Security middleware pipeline order: privateIp → bodySize (512 KB) → rateLimit (120 req/min) → cors → router.

### Web SPA notes
- Token stored in `sessionStorage` (clears on browser close), sent as `Authorization: Bearer <token>`.
- `api()` function in `app.js` separates fetch failures from JSON parse failures — each logs to `console.error` with the path.
- `getAccounts()` / `getCategories()` only populate cache on success — failed loads leave the key absent so the next call retries.
- `Content-Type: application/json` is only sent on requests that have a body (POST/PUT), not on GETs.

---

## Permissions added for Web Companion

**Android** (`AndroidManifest.xml`):
`ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `POST_NOTIFICATIONS` + `ForegroundTaskService` with `foregroundServiceType="dataSync"`.

**iOS** (`Info.plist`):
`NSLocalNetworkUsageDescription`, `NSBonjourServices` (`_http._tcp`).

---

## Packages added for Web Companion
`shelf`, `shelf_router`, `network_info_plus`, `qr_flutter`, `flutter_foreground_task`, `wakelock_plus`, `crypto`
