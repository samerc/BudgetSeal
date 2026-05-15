# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PocketPlan** — A YNAB-style envelope budgeting app for Android and iOS. Offline-first, built in Flutter with Drift (SQLite), Riverpod state management, and GoRouter navigation. Single-user consumer app with optional cloud sync via Google Drive or system file picker (Dropbox/OneDrive). Includes subscription tracking, envelope budgeting (spending + flexible), goals & loans tracking, age-of-money analytics, CSV import/export, and a Web Companion (local WiFi HTTP server so a laptop browser can manage the budget).

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run -d <device>

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Run code generation (Drift + Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Run analyzer
dart analyze lib/

# Run tests
flutter test

# Regenerate app icons
dart run flutter_launcher_icons
```

## Architecture

### Offline-First
SQLite (via Drift) is the primary data store, not a cache. The app works 100% without internet. Cloud sync is optional and file-based.

### Directory Structure
```
lib/
├── app.dart                    # GoRouter routes, app lifecycle, auto-sync
├── main.dart                   # Entry point, recurring processing, notifications
├── core/
│   ├── database/
│   │   ├── app_database.dart   # Drift database definition (schema v13)
│   │   ├── app_database.g.dart # Generated code (do not edit)
│   │   ├── daos/               # Data access objects (accounts, transactions, allocations, ledger)
│   │   └── tables/             # Table definitions (12 tables)
│   ├── engine/
│   │   ├── allocation_engine.dart   # Central money flow engine (all writes go through here)
│   │   ├── balance_calculator.dart  # Computes balances dynamically from ledger
│   │   ├── period_engine.dart       # Period transitions and leftover resolution
│   │   ├── recurring_engine.dart    # Auto-posts recurring transactions
│   │   ├── age_of_money.dart        # Age-of-money metric computation
│   │   └── invariant_checker.dart   # Validates balance invariants
│   ├── providers/              # Riverpod providers (~22 files)
│   │   ├── database_provider.dart
│   │   ├── engine_provider.dart
│   │   ├── household_provider.dart  # Current household ID + service
│   │   ├── accounts_provider.dart
│   │   ├── allocations_provider.dart
│   │   ├── categories_provider.dart
│   │   ├── transactions_provider.dart
│   │   ├── sync_provider.dart       # Cloud sync orchestration
│   │   ├── theme_provider.dart
│   │   ├── biometric_provider.dart
│   │   ├── age_of_money_provider.dart
│   │   ├── backup_reminder_provider.dart
│   │   ├── currency_symbol_provider.dart
│   │   ├── entry_mode_provider.dart # Transaction entry mode preference
│   │   ├── font_provider.dart
│   │   ├── hints_provider.dart
│   │   ├── home_tab_provider.dart   # Remembers preferred home tab
│   │   ├── number_format_provider.dart
│   │   ├── receipt_sync_provider.dart
│   │   ├── report_stats_provider.dart  # Pre-aggregated monthly stats (O(N) single pass)
│   │   ├── tx_colors_provider.dart  # Transaction type color coding
│   │   ├── accent_color_provider.dart    # Material You dynamic accent color
│   │   ├── objectives_provider.dart     # Goals & loans data
│   │   └── web_companion_provider.dart  # Server state (running/stopped/ip/port)
│   ├── sync/
│   │   ├── sync_engine.dart         # JSON export/import/merge
│   │   ├── cloud_provider.dart      # Abstract cloud storage interface
│   │   ├── google_drive_provider.dart
│   │   └── file_picker_provider.dart
│   ├── fx/                     # Currency exchange rates
│   └── services/
│       ├── notification_service.dart
│       ├── auto_backup_service.dart  # Scheduled local DB backups
│       ├── daily_reminder_service.dart # Daily transaction logging reminder
│       ├── period_reset_service.dart   # Auto/manual envelope period resets
│       └── autofill_service.dart       # Last-transaction lookup for auto-fill
├── features/                   # Screen-level code, one folder per feature
│   ├── dashboard/
│   ├── main/                   # Main screen with bottom nav bar
│   ├── transactions/           # List, add, detail, assisted flow
│   ├── allocations/            # Envelopes: list, detail, funding (spending + flexible)
│   ├── accounts/
│   ├── categories/
│   ├── subscriptions/          # Subscription tracker: list, detail, price history
│   ├── reports/                # Hub with 4 tabs: Overview, Categories, Insights, Balance Sheet
│   ├── recurring/              # Recurring transactions + upcoming bills
│   ├── templates/
│   ├── periods/                # Period transition + leftover resolution
│   ├── objectives/             # Goals & loans: list, detail, progress
│   ├── travel/                 # Travel exchange: temp currency wallets
│   ├── settings/               # Settings, sync, backup, import/export, about
│   ├── onboarding/             # 3-page onboarding + guided setup
│   ├── splash/
│   ├── lock/                   # Biometric lock screen
│   └── web_companion/
│       ├── web_companion_screen.dart      # Phone UI (start/stop, QR, PIN management)
│       ├── web_companion_service.dart     # Shelf server lifecycle + middleware pipeline
│       ├── web_companion_router.dart      # All shelf routes + auth middleware
│       ├── web_companion_auth.dart        # PIN (SHA-256 hashed), sessions, lockout
│       └── api/
│           ├── _validation.dart / _serializers.dart
│           ├── dashboard_handler.dart
│           ├── transactions_handler.dart
│           ├── categories_handler.dart
│           ├── accounts_handler.dart
│           ├── envelopes_handler.dart
│           ├── recurring_handler.dart
│           ├── subscriptions_handler.dart
│           └── reports_handler.dart
└── shared/
    ├── theme/
    │   ├── app_colors.dart     # Theme-aware color system (light + dark)
    │   ├── app_theme.dart      # Material theme definitions
    │   └── design_tokens.dart  # Spacing, card, and typography constants
    ├── utils/
    │   ├── format_number.dart  # Amount formatting with currency symbols
    │   ├── haptics.dart
    │   ├── receipt_helper.dart
    │   ├── page_transitions.dart
    │   ├── app_info.dart
    │   └── responsive.dart
    └── widgets/                # Reusable widgets
        ├── app_card.dart             # Standard card container (radius 14, theme-aware)
        ├── allocation_card.dart      # Envelope card with circular progress
        ├── amount_field.dart         # Opens calculator sheet (not keyboard)
        ├── animated_amount.dart      # Count-up/down currency animation
        ├── animated_circular_progress.dart # Custom-painted progress ring
        ├── breathing_widget.dart     # Pulsing attention animation
        ├── calculator_amount_field.dart
        ├── category_icon.dart        # Maps category names to PNG icons
        ├── currency_display.dart
        ├── currency_picker_field.dart
        ├── empty_state.dart
        ├── error_retry.dart
        ├── hint_banner.dart
        ├── section_header.dart       # Standard section header (13px, w700, ls 0.8)
        ├── skeleton_loader.dart
        └── spending_heatmap.dart     # GitHub-style daily spending grid

assets/web/
    index.html    # SPA shell + sidebar with SVG nav icons
    app.js        # ~1200 lines, vanilla JS, hash routing, 8 screens
    styles.css    # Full design system (tokens, dark mode, components)
    help.html     # Bundled help guide (also hostable as standalone webpage)

docs/
    i18n_strings.csv  # Master i18n CSV (key, context, english, arabic, french)
```

## Core Concepts

### Envelope Budgeting (Allocations)
The primary feature. Money flows: Income → Account → Unallocated pool → Fund envelopes → Spend from envelopes.

Two envelope types: **Spending** (periodic budget, resets each month) and **Flexible** (accumulates, optional target). Legacy `saving` type in DB is treated as `flexible` — no migration needed. Savings goals and debt tracking use the separate **Goals & Loans** feature (`/objectives`), which creates real transactions. Envelopes are virtual budget labels only.

**Critical rule:** All money writes go through `AllocationEngine`. Screens never write to the database directly for transactions, transfers, or ledger entries.

### Balance Computation
Balances are computed dynamically from the ledger, never stored. Core invariant per currency:
```
Sum(account balances) = Unallocated + Sum(allocation balances)
```
`BalanceCalculator` has batch methods (`allAccountBalances`, `allAllocationBalancesByCurrency`) that compute all balances in ~7 fixed queries regardless of count. Providers use these batch methods — never loop `accountBalance()` per account.

### Transaction Model
- `transactions` table — header (type, amount, account, date)
- `transaction_lines` table — split lines (amount, currency, category, per-line account)
- `allocation_ledger` table — envelope debits/credits linked to transactions
- Each line can reference a different account (multi-account splits)

### Subscriptions
Recurring transactions can be flagged as subscriptions (`isSubscription` column). The `subscriptions/` feature provides a dedicated list and detail view with price history tracking (`priceHistory` JSON column). Subscriptions are still recurring transactions under the hood — the flag enables the separate UI.

### Cloud Sync
Single-file sync approach (`PocketPlan_Sync.json`):
- Exports all 12 tables as JSON
- Merge by `lastModified` timestamp (newer row wins)
- Supports Google Drive (OAuth) and system file picker (Dropbox/OneDrive/local)
- Auto-syncs on app resume and pause via `WidgetsBindingObserver`
- Restore from sync file during onboarding
- Optional AES-256-CBC encryption with PBKDF2 key derivation (user-set password)

### Sync Encryption
`lib/core/sync/sync_encryption.dart` — optional end-to-end encryption for the sync file on Google Drive. User sets a sync password in Cloud Sync settings. The password is stored in Flutter Secure Storage (Android Keystore / iOS Keychain). PBKDF2 derives a 256-bit key (100,000 iterations, SHA-256). Encrypted format: `ENC:1:<salt>:<IV>:<ciphertext>`. Backward compatible — unencrypted files are auto-detected and read normally. Both devices in a shared household must use the same password.

## Key Patterns

### Theme-Aware Colors
Always use `AppColors.tp(context)`, `AppColors.ts(context)`, `AppColors.sf(context)`, etc. instead of hardcoded colors. The app supports light and dark mode.

Never use hardcoded `AppColors.surfaceVariant`, `AppColors.textSecondary`, `AppColors.textPrimary`, or `AppColors.textHint` in widget build methods. Use the context-aware methods: `AppColors.sfv(context)`, `AppColors.ts(context)`, `AppColors.tp(context)`, `AppColors.th(context)`. The const versions exist only for const contexts (e.g., default parameter values).

- `AppColors.th(context)` as card background = too low-contrast in dark mode — use `sf()` + `bd()` border instead.
- Accent-tinted containers: use explicit variants — dark `Color(0xFF1E3A5F)`, light `Color(0xFFDBEAFE)`.

### Hex Color Parsing
Always use `AppColors.fromHex(hex)` — cached, single implementation. Never define local `_hexToColor()` functions.

### Riverpod 3 Providers
- `Notifier<T>` + `NotifierProvider` (not the old `StateNotifier`)
- `AsyncValue.value` (not the old `.valueOrNull`)
- Providers defined with `NotifierProvider<N, T>(N.new)` pattern

### Navigation
GoRouter with `context.push()` / `context.pop()` / `context.go()`. Routes defined in `app.dart`.

### Amount Entry
All amount fields use the calculator bottom sheet (`CalculatorAmountField`), not the system keyboard. The `AmountField` widget wraps this automatically. Never use `TextField(keyboardType: TextInputType.numberWithOptions)`.

### Category Selection
Both the assisted flow and classic form use the same `CategorySheet` with: search field, type toggle (Expense/Income), parent/subcategory hierarchy with `CategoryIcon`, keyboard dismiss on scroll. Never use plain chip grids without search.

### Exchange Rate Input
Both forms have a swap button (↕) on the exchange rate field to toggle between "1 USD = X LBP" and "1 LBP = X USD". The `rateInverted` flag tracks direction; `exchangeRateToBase` is stored correctly regardless.

### Drift Queries
Always filter `deleted.equals(false)` on transactions. `getById()` must include this filter — it's easy to miss. All list queries already have it.

### Error Handling
All `.when()` error handlers use `ErrorRetry` widget with user-friendly messages and expandable technical details.

## Known Crash Patterns — Read Before Touching These Areas

### Icon Pickers — Inline Only, Never Overlays
`showModalBottomSheet` + `showDialog` = `_dependents.isEmpty` crash. Tried 5+ times with every variant (useRootNavigator, ctx vs context). **Only working solution:** inline expandable emoji grid inside the form with a `setState` toggle. Applied in `categories_screen.dart` and `allocation_detail_screen.dart`.

### Bill Splitter — Flat ListView Only
Nested `Column + Expanded + bottomNavigationBar` = blank screen. Nested Rows with Expanded = blank screen. AnimatedSwitcher with switch expression = blank screen. **Only working solution:** single `ListView` body, flat `if`/spread for step content, nav buttons inline at the bottom.

### Data Reset Flow
Never close the database and wait for providers. Instead: `db.batch()` delete all rows → clear SharedPreferences → `context.go('/onboarding')`.

### Daily Reminder Timezone
Must call `tz.setLocalLocation()` after `initializeTimeZones()`. Without it everything runs as UTC. Use `flutter_timezone` to get the device identifier.

### Currency Display Bug
`tx.currency` is the base currency, not the line's native currency. For display, use `lines.first.currency`. Passing the wrong currency code to `formatAmount()` silently shows the wrong symbol.

## Design Conventions

- **Card radius:** 16 (`CardTokens.radius`), **padding:** 16h / 14v — consistent everywhere. All `BorderRadius.circular()` calls use the token, never hardcoded.
- **Category icons:** 48px circles in lists (`CategoryIconTokens.listSize`), 36px compact, 64px hero.
- **Screen titles:** 28px w800 (`TypographyTokens.screenTitleSize`) — Cashew-inspired large bold.
- **Section headers:** visible, secondary text color, bigger weight — not dimmed.
- **Cards in dark/black mode:** faint white border (5-7% opacity) for edge definition. No visible outlines. Light mode uses subtle `#E8EBF0` border.
- No glassmorphism. No left-border accent bars on cards (looks like a prototype).
- Design inspiration: Cashew app (cohesion and feel, not direct copying)
- "Good morning" greeting removed — user disliked it
- Colors are always theme-aware — never hardcode on adaptive surfaces (exception: `Colors.white` on explicit accent banners/gradients is fine)

## Database

### Schema Version: 15
12 tables: households, users, accounts, categories, allocations, transactions, transaction_lines, allocation_ledger, recurring_transactions, transaction_templates, fx_rates, objectives.

v9→v10 added `isSubscription` and `priceHistory` columns to `recurring_transactions` for subscription tracking.
v10→v11 added `icon` (nullable TEXT) to `allocations` for envelope emoji icons.
v11→v12 added `deleted` (BOOLEAN, default false) to `transactions` for soft-delete support.
v12→v13 added `autoReset` (BOOLEAN, default true) to `allocations` for period reset behavior.
v13→v14 added `decimalPlaces` (nullable INT) to `accounts` for per-currency decimal precision, `status` (nullable TEXT) to `transactions` for upcoming/skipped bills, and created `objectives` table for goals and loan tracking.
v14→v15 added `isTravel` (BOOLEAN, default false) to `accounts` for travel wallet support.

### Migrations
Defined in `app_database.dart` `migration` getter. After schema changes:
1. Increment `schemaVersion`
2. Add migration logic in `onUpgrade`
3. Run `dart run build_runner build --delete-conflicting-outputs`

### Key Columns
Every table has `id` (UUID text primary key). Most have `createdAt`, `lastModified`, `deviceId` for sync support.

Notable additions:
- `accounts.decimalPlaces` — nullable INT, overrides currency decimal display
- `accounts.isTravel` — BOOLEAN, marks temporary travel wallets (auto-archive at zero)
- `transactions.status` — nullable TEXT ('upcoming', 'skipped', or null for posted)

## Dependencies (key ones)

**Version pinning conflict:** drift/drift_dev 2.32+ requires analyzer 10+, but riverpod_generator requires analyzer <10. Both are pinned at 2.31.x until riverpod_generator supports analyzer 10+. This also blocks sqlite3 3.x, drift_flutter 0.3.x, and sqlite3_flutter_libs 0.6.x. The `win32` 5.x vs 6.x split similarly blocks share_plus 13.x and network_info_plus 8.x (flutter_secure_storage pins win32 ^5.x).

| Package | Constraint | Purpose |
|---------|------------|---------|
| drift | ^2.22.0 | SQLite ORM |
| drift_flutter | ^0.2.0 | Drift Flutter integration |
| flutter_riverpod | ^3.0.0 | State management |
| riverpod_annotation | ^4.0.0 | Riverpod code generation |
| go_router | ^17.0.0 | Navigation |
| fl_chart | ^1.2.0 | Charts (pie, line, bar) |
| google_sign_in | ^7.0.0 | Google Drive auth |
| googleapis | ^16.0.0 | Google Drive API |
| googleapis_auth | ^2.0.0 | Google API OAuth |
| local_auth | ^3.0.0 | Biometric lock |
| flutter_local_notifications | ^21.0.0 | Bill/envelope alerts |
| shared_preferences | ^2.5.0 | Simple key-value settings |
| csv | ^8.0.0 | CSV import/export |
| share_plus | ^12.0.0 | Share files/data |
| file_picker | ^11.0.0 | System file picker for sync |
| haptic_feedback | ^0.6.0 | Haptic feedback |
| sliver_tools | ^0.2.12 | Advanced sliver widgets |
| google_fonts | ^8.0.0 | Custom fonts |
| dynamic_color | ^1.7.0 | Material You system accent color |
| confetti | ^0.8.0 | Celebration effects (goal completion) |
| google_mlkit_text_recognition | ^0.15.1 | Offline receipt OCR (bill splitter) |
| encrypt | ^5.0.3 | AES-256 encryption for sync files |
| flutter_secure_storage | ^10.0.0 | Secure credential storage (Keystore/Keychain) |
| pointycastle | ^3.9.1 | PBKDF2 key derivation |
| shelf | ^1.4.2 | HTTP server (Web Companion) |
| shelf_router | ^1.1.4 | Route matching (Web Companion) |
| network_info_plus | ^7.0.0 | WiFi IP detection (Web Companion) |
| qr_flutter | ^4.1.0 | QR code display (Web Companion) |
| flutter_foreground_task | ^9.0.0 | Android foreground service (Web Companion) |
| wakelock_plus | ^1.2.10 | iOS screen-on (Web Companion) |
| crypto | ^3.0.0 | SHA-256 PIN hashing (Web Companion) |
| webview_flutter | ^4.10.0 | In-app help guide WebView |

## Testing

```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/core/engine/allocation_engine_test.dart
flutter test test/core/engine/balance_calculator_test.dart
flutter test test/core/database/migration_test.dart
```

Tests use `AppDatabase.forTesting(NativeDatabase.memory())` for in-memory databases.

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
`SpendingWidget.kt` — shows placeholder spending data. Files in `android/app/src/main/`.

### Google Drive Setup
Requires OAuth client ID configured in Google Cloud Console. Client ID goes in `android/app/src/main/res/values/strings.xml` (or via google-services.json).

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

## Security

### Google Drive Queries
All Drive API queries use `_escGdql()` to escape single quotes in parameters, preventing GDQL injection. Always use this helper when interpolating values into Drive query strings.

### Biometric Lock
`local_auth` handles authentication. If the device has no biometrics/PIN, the lock screen still calls `authenticate()` (which prompts the user to set up credentials) rather than bypassing. App re-locks on pause (when biometric is enabled) so switching away and back requires re-authentication.

### Temp File Cleanup
Backup `.db` and export `.csv` files are written to the system temp directory for sharing, then deleted in a `finally` block. Never leave financial data in temp.

### Sync File Encryption
The sync file is optionally encrypted with AES-256-CBC. User sets a password in Cloud Sync settings → PBKDF2 derives the key → file is encrypted before upload. Unencrypted files are auto-detected for backward compatibility.

### Backup Restore Validation
Backup restore validates: SQLite magic bytes (`SQLite format 3`), file size < 100MB, auto-backup of current DB before overwriting.

## Error Handling

All `_load()` methods in StatefulWidget screens must be wrapped in try-catch. If an async load fails without catching, `_loading` stays `true` and the screen shows an infinite spinner. Pattern:

```dart
Future<void> _load() async {
  try {
    // ... database/API calls ...
    if (mounted) setState(() => _loading = false);
  } catch (e) {
    debugPrint('[ScreenName] Error loading: $e');
    if (mounted) setState(() => _loading = false);
  }
}
```

For user-initiated actions (save, delete, toggle), show a SnackBar on both success and failure.

### Multi-Currency Amount Safety
When computing base-currency totals (summaries, reports, dashboard), always use `isRealRate()` from `format_number.dart` to skip lines where the currency differs from base but `exchangeRateToBase` is 1.0 (rate not set). Without this check, foreign-currency amounts inflate totals (e.g., LBP 1,200,000 counted as $1,200,000).

**Critical rule:** Never sum `targetAmount` across envelopes without checking `targetCurrency`. Never sum account balances across currencies. Always filter to `baseCurrency` or group by currency before aggregation.

### Running Balances for Transfers
In `_applyTxToRunning()` (transactions_provider.dart), transfer destinations must use `tx.amount * tx.exchangeRateToBase` to convert to the destination currency. Using raw `tx.amount` adds the source currency amount to the destination account's running balance.

### Per-Line Currency in Assisted Flow
Each `_LineItem` stores its own `currency`, `accountId`, and `exchangeRateToBase` — captured via `_captureLineContext()` when adding another item or saving. The save logic uses each item's stored values, not the global `_selectedCurrency`.

### Per-Line Account in TransactionEntry
`_buildEntry()` in `transactions_provider.dart` uses the line's `accountId` (not the header's `tx.accountId`) for single-line transactions where the line has a per-line account. This ensures the transaction list and detail screen show the correct account name, currency, and running balance.

### Envelope Detail Layout
The envelope detail screen shows: balance hero card (gradient, with progress bar and integrated fund button) → settings form (hidden, via 3-dot menu) → recent transactions → spending history. Settings, withdraw, revalue, archive, and delete are in the 3-dot menu. No duplicate transaction lists.

### Multi-Currency Envelopes
Envelopes can hold balances in multiple currencies. The fund sheet offers a currency picker showing all available unallocated currencies. The balance hero card shows the target currency balance prominently, with other currencies as `+ $50`. The allocation card does the same.

### Withdrawal Validation
`withdrawFromAllocation()` checks sufficient balance before debiting. Throws `StateError` if the allocation doesn't have enough in the requested currency. Callers must catch and show an error.

### Notification Grouping
`NotificationService` groups multiple low-envelope alerts into one notification and multiple upcoming-bill alerts into one. Uses fixed notification IDs (1001, 1002) so each check replaces the previous. 24-hour cooldown between checks via SharedPreferences. Overspent detection checks each currency independently (never sums across currencies).

### Envelope Currency Handling
- **Cross-currency debit conversion**: When an expense line is in a foreign currency (e.g., LBP) but the linked envelope targets a different currency (e.g., USD), `AllocationEngine.recordTransaction()` converts the amount to base currency via `exchangeRateToBase` before recording the ledger entry. The envelope stays single-currency. Lines with no real exchange rate (`isRealRate` returns false) are skipped to avoid inflating the envelope.
- `tx.amount` and `tx.currency` are always in the household's **base currency** — never use them directly for display in envelope contexts.
- For envelope progress/spent calculations, sum **line amounts** that match the envelope's `targetCurrency`, not `tx.amount`.
- Budget summary on the allocations screen only sums base-currency envelopes to avoid mixing currencies.
- The spend button pre-fills the envelope's `targetCurrency`, not `baseCurrency`.
- `AllocationWithBalance.totalInBase` sums raw balances across currencies without conversion — use `balanceByCurrency[currency]` for accurate per-currency display.
- **Allocation card multi-currency display**: `isTargetOverspent` (target currency negative) shows red border/amount. `hasCrossDebt` (other currency negative) shows amber border + debt amount in amber text. Progress bar stays green when target is met even with cross-currency debt.

## Performance

### Batch Balance Computation
`BalanceCalculator.allAccountBalances()` computes all account balances in 7 fixed queries (not per-account). `allAllocationBalancesByCurrency()` uses a single query via `LedgerDao.getAllForHousehold()`. Providers (`accountsWithBalanceProvider`, `allocationsProvider`) use these batch methods.

### Report Stats
`reportStatsProvider` aggregates all transactions into monthly buckets in one O(N) pass. Report tabs look up pre-computed `MonthlyStats` by month key instead of re-scanning the full list. `_typicalMonthlySpend` is a method on `ReportStats`, not an inline loop.

### Color Cache
`AppColors.fromHex()` caches parsed colors in a static map. Never re-parse hex strings on rebuild.

### SQL Running Balances
`TransactionsDao.getRunningBalancesBeforeDate()` computes per-account running balance totals using 4 SQL `GROUP BY` queries instead of loading all prior transactions into memory. Used by `monthlyTransactionsProvider` for O(1) memory regardless of history size.

### Tab Keep-Alive
All 4 main tabs (Dashboard, Transactions, Allocations, Reports) use `AutomaticKeepAliveClientMixin` so switching tabs doesn't destroy/rebuild widget trees.

### Sync Batching
`SyncEngine.restoreFromJson()` uses Drift `batch()` for bulk inserts (one DB round-trip instead of N). `_mergeTable()` bulk-fetches all existing IDs in one query instead of N+1 per-row lookups.

## Web Companion

Local WiFi HTTP server (port **7432**) built into the app. Phone is the server; a laptop browser connects over the same WiFi network and gets a full budget management SPA. HTTP only (HTTPS not viable for private IPs — CAs won't issue certs). All 4 phases complete.

### Architecture Decisions
- Server runs in the **main Dart isolate** — same as Flutter UI, so handlers call Riverpod providers directly.
- `flutter_foreground_task` on Android keeps the process alive. **Must call `FlutterForegroundTask.init()`** before `startService()` — without it, the foreground service never starts and Android kills the process when the screen turns off.
- `_NoOpTaskHandler.onRepeatEvent` refreshes the notification every 5 seconds via `FlutterForegroundTask.updateService()` to keep the service active. `onDestroy` signature: `Future<void> onDestroy(DateTime timestamp, bool isTimeout)` — the `isTimeout` param is required in v9.
- `ForegroundTaskOptions`: `allowWakeLock: true`, `allowWifiLock: true` (critical for HTTP server).
- Auto-stop after **6 hours** (Android 15+ caps dataSync foreground services at 6h; we match this on all platforms).
- PIN stored as SHA-256 hash in FlutterSecureStorage.
- Session tokens: UUID4, 4-hour inactivity expiry, server-side in-memory map, max 10 sessions (oldest evicted).
- Security middleware pipeline order: `privateIp → bodySize (512 KB) → rateLimit (120 req/min) → security headers → router`.
- Handlers use `ref.read(databaseProvider)` and `.get()` (one-shot Future), not `.watch()` (streams). Web client polls on demand.

### Security
- **CORS**: Same-origin only (echoes request `Origin` header). Never use `Access-Control-Allow-Origin: *` — it allows any malicious website to exfiltrate budget data via CSRF.
- **Security headers** on all responses: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Cache-Control: no-store`.
- **`serverError()`** logs exception details locally via `debugPrint` but returns generic "Internal server error" to the client. Never leak stack traces, DB schema, or internal types.
- **`/auth/status`** does not expose `activeSessions` count — prevents session enumeration.
- **Private IP check** validates IPv4 (127.x, 10.x, 192.168.x, 172.16-31.x) and IPv6 (::1, fe80: link-local, fc/fd ULA).
- **Rate limiter** evicts stale IP entries every 5 minutes to prevent memory growth.
- **WiFi security warning**: Phone screen shows a network security notice before the Start button. Detects public networks by WiFi name keywords (guest, public, airport, hotel, cafe, etc.) and shows an elevated amber warning.
- **`esc()` in app.js** escapes `'` (single quotes) as `&#39;` — prevents XSS in onclick attributes when account/category names contain quotes.
- **Search input** escapes SQL LIKE wildcards (`%`, `_`, `\`) in the backend before passing to Drift's `.like()`.

### Multi-Currency in Web Companion
- Transaction list handler returns `lineCurrency`, `lineAmount`, `lineExchangeRate` from the first transaction line alongside the header data. The frontend displays the native currency amount, not the base currency header amount.
- `isRealRate` check: both `cashflowReportHandler` and `byCategoryReportHandler` skip lines where currency differs from base but `exchangeRateToBase` is ~1.0 (rate not set). Same logic as `isRealRate()` in `format_number.dart`.
- Transactions with missing exchange rates show an amber "No rate" warning in the list.

### Web SPA Notes
- Token stored in `sessionStorage` (clears on browser close), sent as `Authorization: Bearer <token>`.
- `api()` function in `app.js` separates fetch failures from JSON parse failures — each logs to `console.error` with the path.
- `getAccounts()` / `getCategories()` use `if (!('accounts' in cache))` — only populate cache on success (`if (d) cache.accounts = ...`). Failed loads leave the key absent so the next call retries. Do NOT use `if (!cache.accounts)` — an empty array `[]` is truthy, permanently poisoning the cache after a failed load.
- `Content-Type: application/json` is only sent on requests that have a body (POST/PUT), not on GETs.
- Categories and accounts are prefetched in the background after auth success.
- `invalidateAll()` clears all cached data after any mutation (add/edit/delete).

### SPA Features
- **Skeleton loaders** on all pages instead of spinner.
- **Keyboard shortcuts**: `N` = new transaction, `/` = search, `Esc` = close modal, `?` = help. Disabled during input focus and when modal is open.
- **Transaction search**: server-side LIKE query on `note` field with SQL wildcard escaping.
- **Month navigation**: year arrows + month tabs (Jan–Dec + All). Backend supports `from`/`to` date params.
- **Account filtering**: transactions list supports `accountId` param (matches both source and destination for transfers).
- **Dark mode toggle**: cycles System → Light → Dark, persisted in `localStorage`, applied via `html[data-theme]` attribute.
- **Connection status**: green/red dot in sidebar, pings `/auth/status` every 15 seconds.
- **CSV export**: downloads current table as `.csv` file.
- **Styled confirm dialogs**: `confirmDialog()` returns Promise, used for delete recurring/subscriptions. Transaction delete is immediate (soft-delete, recoverable via Health Check).
- **Exchange rate field**: auto-shown in transaction form when currency differs from base, with conversion hint.

### REST API Endpoints
```
POST /auth/pin                         → { token, expiresAt }
GET  /auth/status                      → { authenticated: bool }

GET  /api/dashboard                    → period info, envelopes, recent 10 transactions
GET  /api/transactions?page=&limit=    → paginated list (supports type, accountId, from, to, search)
POST /api/transactions                 → create
GET  /api/transactions/:id             → single + lines
PUT  /api/transactions/:id             → update
DELETE /api/transactions/:id           → soft delete

GET  /api/categories                   → all non-archived
POST /api/categories                   → create (supports parentId)
PUT  /api/categories/:id               → update

GET  /api/accounts                     → with balances
POST /api/accounts                     → create

GET  /api/envelopes                    → allocations with balances
POST /api/envelopes/:id/fund           → add funding

GET  /api/recurring                    → all recurring
POST /api/recurring                    → create
PUT  /api/recurring/:id                → update
DELETE /api/recurring/:id              → delete

GET  /api/subscriptions                → recurring where isSubscription=true
POST /api/subscriptions                → create
PUT  /api/subscriptions/:id            → update

GET  /api/reports/cashflow?year&month  → monthly totals, topExpenses, transactionCount
GET  /api/reports/by-category?year&month&type → spending/income per category (type=expense|income)
```

### SPA Hash Routes
```
#/              Dashboard (envelopes, period summary, recent transactions)
#/transactions  List with search, month tabs, type filters, CSV export
#/categories    Manage categories (hierarchy with parent/sub)
#/accounts      Accounts grouped by type + net worth + per-account transactions
#/envelopes     Envelope balances + fund
#/recurring     Recurring transactions
#/subscriptions Subscriptions
#/reports       Summary stats, daily chart, doughnut, category breakdown, top expenses
```

## Auto Backup

`AutoBackupService` in `lib/core/services/auto_backup_service.dart`:
- Copies `pocketplan.db` to `app_documents/backups/` with timestamped filenames
- Runs on app resume AND pause (exit) via `AutoBackupService.runIfDue()` in `app.dart`
- User settings: enable/disable, frequency (6h–weekly), retention (3–30 backups)
- Old backups auto-deleted beyond retention limit
- Backup history visible on the Backup & Restore screen with per-file restore/delete

## Linked Transactions

Mixed-type items from the assisted flow (e.g., expense + income in one session) are split into separate transactions but linked via matching `note` + `createdAt` timestamp. The transaction detail screen queries for siblings and shows a "RELATED TRANSACTIONS" section. For transactions with empty notes, the query additionally requires different `type` to avoid false positives.

## Daily Reminder

`DailyReminderService` schedules a daily local notification via `flutter_local_notifications`. Users configure in Settings: toggle on/off, pick time (default 7 PM), optional custom message. If no custom message, rotates between 5 default prompts. Initialized in `main()` via `DailyReminderService.init()` which re-schedules if enabled. Uses `timezone` package for `zonedSchedule` with `matchDateTimeComponents.time`.

**Critical:** `DailyReminderService` shares the same `FlutterLocalNotificationsPlugin` instance as `NotificationService` via `setSharedPlugin()` — having two separate instances causes the second `initialize()` to break the first's scheduling callbacks on Android. The plugin is initialized once in `NotificationService.init()`, then shared via `DailyReminderService.setSharedPlugin(NotificationService.plugin)` in `main.dart`.

**Exact alarm fallback:** On Android 14+, `SCHEDULE_EXACT_ALARM` requires explicit user grant. The service checks `canScheduleExactNotifications()` first — if denied, falls back to `inexactAllowWhileIdle` (fires within ~15 min window, fine for daily reminders). Never calls `requestExactAlarmsPermission()` automatically as it navigates away from the app.

## Category Icons

Users can pick from 120+ curated emojis organized by group, OR type/paste any emoji from the system keyboard via the text field at the top of the picker. The `CategoryIcon` widget resolves display priority: PNG asset by name match → emoji → first-letter fallback.

## UI Consistency

### Screen Design Patterns
- **Tab screens** (Dashboard, Activity, Budget, Reports, More): Custom SafeArea header, 24-28px bold title, no back button
- **Sub-screens** (Recurring, Subscriptions, Templates, Categories): Custom SafeArea header, 24px bold title, back IconButton, filter chips, summary banner, pull-to-refresh
- **Detail/form screens** (Account detail, Allocation detail, etc.): Standard AppBar with auto back

### Standard Widgets
- Loading: `SkeletonList` for lists, `CircularProgressIndicator` for detail screens
- Empty: `EmptyState` widget everywhere
- Error: `ErrorRetry` widget everywhere
- Cards: Use `AppCard` widget or `CardTokens.radius` (14) + `CardTokens.padding` (16h, 14v) + `AppColors.sf(context)` bg + `AppColors.bd(context)` border
- Section headers: Use `SectionHeader` widget or `TypographyTokens.sectionHeaderSize/Weight/LetterSpacing`
- Screen titles: `TypographyTokens.screenTitleSize` (24) + `TypographyTokens.screenTitleWeight` (w800)
- Chips: Pill-shaped (20px radius), colored border+bg when selected
- SnackBars: Always `behavior: SnackBarBehavior.floating`
- All list screens have `RefreshIndicator`

### Navigation
- `PageView` in `MainScreen` uses `NeverScrollableScrollPhysics` — tab switching is via bottom bar only (no swipe conflict with content gestures)
- `PopScope` checks `GoRouter.canPop()` so pushed routes (funding, accounts, etc.) pop correctly instead of exiting the app

## Health Check

`lib/features/settings/health_check_screen.dart` — accessible from Settings > Health Check (`/health-check` route).

Three levels in one screen:
- **Level 1 (Detect):** Balance invariant per currency (green/red), orphan ledger count, backup status, transaction/ledger counts
- **Level 2 (Diagnose):** Per-currency expected vs actual unallocated, list accounts with balances, list envelopes with ledger sums, highlight mismatches
- **Level 3 (Repair):** "Repair Balances" button creates adjustment ledger entries for the largest allocation in each affected currency. "Purge Deleted" hard-deletes soft-deleted transactions. Export diagnostic JSON via share sheet.

## Soft Delete

Transactions use a `deleted` boolean column (schema v12) instead of hard deletion. `AllocationEngine.deleteTransaction()` sets `deleted = true` and removes ledger entries. All transaction queries filter `deleted = false` except sync export (which includes deleted rows so they propagate across devices). The Health Check screen offers a "Purge" action to permanently remove soft-deleted transactions.

## Animation Widgets

### AnimatedAmount
`lib/shared/widgets/animated_amount.dart` — count-up/down effect for currency amounts using `IntTween` on cents for smooth integer stepping. `lazyFirstRender: true` (default) skips animation on first build — only animates on subsequent value changes. Used on dashboard totals (income, expense, net worth, unallocated).

### AnimatedCircularProgress
`lib/shared/widgets/animated_circular_progress.dart` — custom-painted circular progress ring with overspend indicator. Main arc (0-100%) in `color`, second arc overlay in `overspendColor` for values > 100%. AnimationController at 1500ms with `easeInOutCubicEmphasized`. Used on allocation cards for envelopes with targets.

### BreathingWidget
`lib/shared/widgets/breathing_widget.dart` — pulsing scale animation (1.0→1.15, 2500ms, repeating). Set `active: false` to render statically. Used on dashboard for overspent envelope warning icons.

### Platform Curves
`lib/shared/utils/platform_curves.dart` — `PlatformCurves.page`, `.standard`, `.emphasis` return platform-appropriate curves (iOS: snappy easeInOut, Android: easeInOutCubicEmphasized). Matching duration helpers.

## Spending Heatmap

`lib/shared/widgets/spending_heatmap.dart` — GitHub-style activity grid showing daily spending intensity. Green = net positive (income > expense), red = net negative, gray = no activity. Horizontal scroll, month labels, tooltips on tap. Data from `dailySpendingProvider` (SQL query grouped by day). Displayed in Reports Overview tab.

## Bill Splitter

`lib/features/transactions/bill_splitter_screen.dart` — accessible from More > Bill Splitter (`/bill-splitter` route).

Two modes:
- **Manual**: Enter total + number of people, even or custom split
- **Scan Receipt**: Camera/gallery → offline OCR via `google_mlkit_text_recognition` → extracted line items with amounts → assign each item to people → per-person totals

OCR service at `lib/shared/utils/ocr_service.dart` — regex parsing of receipt text to extract `(name, amount, quantity)` tuples. Line merging by Y-position (handles ML Kit splitting items across blocks). Handles both US (1,234.56) and European (1.234,56 or 4,50) number formats. Quantity detection from leading "2x" or trailing numbers. Filters out non-item lines (totals, tax, headers). Fully offline, no internet needed.

Interactive receipt overlay shows tappable bounding boxes on the receipt image. Tap a person chip, then tap items to assign. Lines without detected prices prompt for manual amount entry. Quantity > 1 items offer "split into individual items" for multi-person assignment.

Tip: percentage slider (0-30%) or fixed amount toggle. Cross-currency support with exchange rate input + swap button. "Create Transaction" button disabled if user's share is $0. Warning dialog if cross-currency rate not set.

## Customizable Dashboard

`lib/core/providers/dashboard_layout_provider.dart` — `DashboardSection` enum with 4 sections (quickActions, spending, money, activity). Each section has visibility toggle. Order + visibility persisted to SharedPreferences as JSON. `DashboardLayoutNotifier` provides reorder/toggle/reset methods.

Dashboard flow: Quick Actions (top) → Spending Overview (donut + income/expense/net + spending insight) → Your Money (compact net worth | unallocated split card) → Activity (templates + recent transactions). Status card and envelope health were removed — those live in Reports > Insights and Budget tab respectively.

`lib/features/dashboard/dashboard_customize_sheet.dart` — bottom sheet with `ReorderableListView`, drag handles, and visibility switches. Opened via the tune icon in the dashboard header.

## Transaction Selection

Long-press a transaction to enter selection mode. Tap tiles to select/deselect (with checkboxes). Action bar shows count + bulk delete button. Dismissible swipe gestures are disabled during selection mode. Haptic feedback on selection changes.

## Activity Tab FAB

The + FAB on the Activity tab uses a custom `Material` + `InkWell` circle (not `FloatingActionButton`) so both `onTap` and `onLongPress` work reliably. Tap opens expense form directly (most common action). Long-press opens a type picker bottom sheet (expense/income/transfer). **Never wrap `FloatingActionButton` with `GestureDetector(onLongPress:)`** — the FAB's internal `InkWell` swallows the long-press gesture.

## Transaction Flash

When adding a transaction via the classic form, the new transaction ID is passed back via `context.pop(txId)`. The transactions screen highlights the matching tile with a 1.5-second accent glow fade-out using `AnimatedContainer`.

## Search Debounce

Transaction search uses a 400ms `Timer` debounce to avoid excessive `setState` calls during typing. Timer is properly disposed.

## Filter Persistence

Transaction type filter (All/Income/Expense/Transfer) is saved to SharedPreferences and restored on screen init. Persists across sessions.

## Confetti Celebration

Flexible envelopes with a target trigger a 2-second confetti burst (via `confetti` package) when their balance reaches the target amount. Plays once per screen visit. `ConfettiWidget` overlaid at top-center of the allocation detail screen with explosive blast direction.

## Duplicate Detection

Both the assisted flow and classic form check for duplicate transactions before saving. If a transaction with the same amount, category, and date already exists, a "Possible Duplicate" dialog asks the user to confirm. Skipped when editing existing transactions or for transfers.

## Transfer Display

Transfers render as a single row in the transaction list (not two rows). Shows "Source → Destination" as the title with two sub-lines: source account with amount (red dot) and destination account with converted amount (green dot). Amounts shown in each account's native currency.

## Theme System

`buildLightTheme(fontName, [accentColor])`, `buildDarkTheme(fontName, [accentColor])`, and `buildBlackTheme(fontName, [accentColor])` in `app_theme.dart` generate full ThemeData. `buildBlackTheme` derives from dark with pure black overrides. Font selection is dynamic via `fontProvider`. Default font: Plus Jakarta Sans. Available: DM Sans, Inter, Nunito Sans, Poppins, Nunito, Rubik, Space Grotesk.

**Theme modes:** `themeModeProvider` stores a String (`'system'`/`'light'`/`'dark'`/`'black'`). `flutterThemeMode` getter maps black → dark for Flutter's ThemeMode. `isBlackMode` getter for AMOLED-specific logic. `app.dart` must `ref.watch(themeModeProvider)` for the state (not `.notifier`) to rebuild on theme change.

### Design Tokens
`lib/shared/theme/design_tokens.dart` defines the single source of truth:
- **Spacing**: xs(4), sm(8), md(12), lg(16), xl(24), xxl(32), sectionGap(16), headerToCard(8)
- **CardTokens**: radius(16), paddingH(16), paddingV(14), borderRadius, padding
- **CategoryIconTokens**: listSize(48), compactSize(36), heroSize(64)
- **TypographyTokens**: screenTitle(28/w800), sectionHeader(13/w700/ls0.8), cardTitle(15/w600), amountLarge(24/w700), amountRegular(15/w700), amountSmall(13/w600), body(14/w400), caption(12/w500), overline(11/w600), txTitle(15/w600), txSubtitle(12/w400), dateHeader(14/w600)

### Color Palette
- Accent: `#2563EB` (Royal Blue)
- Expense/Overspent: `#DC2626` (Deep Red)
- Income/Healthy: `#059669` (Deep Emerald)
- Caution: `#D97706` (Deep Amber)
- Light bg: `#F5F6FA`, Dark bg: `#0F1219`, Black bg: `#000000`

### Shared Layout Widgets
- `SectionHeader` (`lib/shared/widgets/section_header.dart`): uppercase, 13px w700, letter-spacing 0.8, optional trailing action
- `AppCard` (`lib/shared/widgets/app_card.dart`): theme-aware bg/border, radius 16, standard padding, optional onTap

## More Tab Structure

The More tab is split into two screens:

**More page** (tab) — feature hub:
- Accounts, Categories (top, no section header — used weekly)
- **TOOLS**: Recurring & Bills, Subscriptions, Goals & Loans, Bill Splitter, Travel Exchange, Web Companion
- Settings & Customization → navigates to `/settings`
- Help Guide → navigates to `/help` (WebView loading bundled `assets/web/help.html`)
- About PocketPlan
- Household name + currency shown as subtitle under "More" header (no separate card)

Bill Splitter is also accessible from: Dashboard quick actions ("Split" button) and long-press on the Activity tab FAB.

**Settings screen** (`/settings`) — all configuration:
- **APPEARANCE**: Theme (System/Light/Dark/Black), Colors, Entry Mode, Auto-fill, Start Screen, Font, Text Size, Transaction List layout
- **DATA**: Cloud Sync, Share Household, Backup & Restore, Import & Export, Notifications, Health Check
- **PREFERENCES**: Household Name, Base Currency, Period Start Day, Currency Symbols, Number Format, Date Format
- **SECURITY**: Biometric Lock

Bill Splitter is also accessible from: Dashboard quick actions ("Split" button) and long-press on the Activity tab FAB.

## Onboarding

3-page flow: Welcome (how-it-works + Restore/Join buttons) → Setup (household name, currency, period day, account, categories toggle, entry mode) → Done.

## Auto-fill

`lib/core/providers/autofill_provider.dart` + `lib/core/services/autofill_service.dart`. When a category is selected, auto-fills fields from the last transaction with that category. Configurable in Settings > Appearance > Auto-fill: Account (default on), Title (default on), Amount (default off), Category per account (default off), Override existing values (default off). Works in both AF and classic form.

## Over-funding Warning

Both the funding screen (bulk) and envelope detail screen (single fund) check if the funding amount exceeds unallocated balance. Shows a warning dialog: "Your unallocated balance will go negative. Continue anyway?" with Cancel/Fund Anyway options.

## Icon Pickers

Envelope and category icon pickers use an **inline expandable emoji grid** within the form itself (setState toggle, no overlays). Never use `showDialog` or `showModalBottomSheet` for icon pickers — they cause `_dependents.isEmpty` crashes when launched from bottom sheets or nested navigators. The grid shows 120+ curated emojis organized by group with a text field for custom emoji input.

## Period Reset

`lib/core/services/period_reset_service.dart` + `lib/core/providers/period_reset_provider.dart`. At app launch, `periodResetCheckProvider` checks all periodic envelopes whose period has elapsed.

- Envelopes with `autoReset = true` (default): automatically zeroed out via ledger entry on period start
- Envelopes with `autoReset = false`: flagged as "pending manual reset" — shown with amber glow on the Budget tab and a banner prompting the user to review
- Toggle per-envelope in the envelope detail screen settings (3-dot menu)
- `PeriodResetService.checkAndAutoReset()` runs once per app launch, tracked via SharedPreferences timestamp

## Future Months

Transaction list caps month tabs to current month. No future months shown. Right arrow hidden at current month. Swipe-forward blocked. Year picker only shows up to current year.

## Navigation Bar (5 tabs)

Home | Activity | Budget | Reports | More

Accounts are accessed from More > Accounts.

## Objectives (Goals & Loans)

`lib/features/objectives/` — standalone savings goals and debt tracking, separate from envelope budgeting.

- **Goals**: target amount + currency + optional deadline + progress tracking. Fund via "Add Funds" button.
- **Loans**: track money lent or borrowed. Has `contactName` (person) and `direction` ('lent' or 'borrowed'). Fund via "Record Payment".
- `objectives` table: id, householdId, name, type ('goal'/'loan'), icon, targetAmount, targetCurrency, currentAmount, endDate, contactName, direction, colorHex, archived, deviceId, createdAt, lastModified.
- Full sync support (export, import, merge by lastModified).
- Routes: `/objectives` (list), `/objectives/:id` (detail), `/objectives/new` (create).
- Accessible from More > Goals & Loans.

### Detail Screen Layout
- **New objectives**: full creation form (type toggle, name, fields, color picker)
- **Existing objectives**: summary view by default — progress hero card, summary info card (contact, currency, deadline, remaining), payment history list. Edit form hidden behind 3-dot menu → "Edit Settings".
- **Payment sheet**: account picker, optional category picker (filtered by tx type), amount calculator. Category choice is remembered per objective for the next payment.
- **Payments create real transactions** via `AllocationEngine.recordTransaction()` with optional `categoryId` on `TxLine`.
- **Payment history**: queries transactions matching the objective's note pattern, displays with date, note, and colored amount.

## Travel Exchange

`lib/features/travel/travel_exchange_screen.dart` — temporary currency wallets for trips.

### Flow
1. User taps "Travel Exchange" in More
2. Selects source account, amount to exchange, destination currency, amount received
3. App creates a travel wallet (`isTravel: true` on accounts table) + records the transfer
4. User spends from the travel wallet during the trip
5. On return: "Convert Back & Close" (account detail 3-dot menu) transfers remainder back and archives
6. Auto-archive: `TravelAccountService.checkAndAutoArchive()` runs on app resume, archives travel wallets at zero balance

### Reactivation
When exchanging to a currency that has an archived travel wallet, a dialog asks: **Reactivate** (unarchive existing) or **Create New**. Prevents account clutter across repeated trips.

### Key Rules
- Travel accounts have `isTravel = true` — visually distinguished with a plane badge
- Auto-archive threshold is currency-aware: 0.5 for JPY (0 decimals), 0.005 for USD (2 decimals), 0.0005 for KWD (3 decimals)
- Same-currency exchange is blocked (no point creating a travel wallet in your own currency)
- Regular account creation never suggests archived travel wallets

## Material You / Accent Color

`lib/core/providers/accent_color_provider.dart` — supports system dynamic color (Android 12+ Material You) and 10 preset accent colors.

- **Options**: 'system' (device wallpaper accent), 'default' (Royal Blue #2563EB), or any preset hex color
- **Presets**: Indigo, Violet, Pink, Red, Orange, Yellow, Green, Teal, Cyan
- `DynamicColorBuilder` wraps the app in `app.dart` — resolves system accent on Android 12+
- Theme builders (`buildLightTheme`, `buildDarkTheme`, `buildBlackTheme`) accept optional `accentColor` parameter
- **`AppColors.accent` is mutable** — updated via `AppColors.setAccentColor()` in `app.dart` after `DynamicColorBuilder` resolves. All 340+ references to `AppColors.accent` automatically pick up the new color. Also derives `accentLight` dynamically.
- Settings: Appearance > Accent Color — circle grid picker with checkmark selection

## Per-Account Decimal Precision

`accounts.decimalPlaces` (nullable int) — overrides the default decimal display for a currency.

- **Auto-detect**: `currencyDecimals()` in `format_number.dart` returns ISO 4217 defaults (0 for JPY/KRW, 3 for BHD/KWD, 2 for everything else)
- **Manual override**: Account detail form has a "Decimal Places" dropdown (Auto / 0 / 1 / 2 / 3)
- `formatAmount()` and `formatSignedAmount()` both respect currency-specific decimals automatically

## Transaction Status

`transactions.status` (nullable TEXT) — supports upcoming/skipped bills from recurring transactions.

- `null` = normal posted transaction (default, backward compatible)
- `'upcoming'` = pending bill generated but not yet confirmed
- `'skipped'` = user skipped this occurrence
- Field is synced across devices and exposed in web companion API

## Upcoming Bills

`lib/features/recurring/upcoming_bills_screen.dart` — shows all enabled recurring transactions sorted by next due date.

- **Urgency indicators**: Red "Overdue by N days", Amber "Due today/tomorrow/in 3 days", Green "Due in N days"
- Displays frequency, amount, type icon per bill
- Route: `/upcoming-bills`, accessible from More > Upcoming Bills

## Fonts

Default font: Plus Jakarta Sans. Available: DM Sans, Inter, **Nunito Sans** (closest to Avenir), Poppins, Nunito, Rubik, Space Grotesk.

## Number & Date Formatting

### Number Format
`formatAmount()` and `formatSignedAmount()` in `format_number.dart` respect user preferences for thousands separator (comma/period/space/none), decimal separator (period/comma), and negative format (minus `-$100` or parentheses `($100)`). `formatNumber()` formats plain numbers (exchange rates, converted amounts) with the same separator prefs. `currencyDecimals()` returns ISO 4217 defaults (0 for JPY, 3 for KWD, 2 for everything else). Settings apply instantly via global `setNumberFormatPrefs()` called from `app.dart` on provider change.

### Date Format
`formatDate()` and `formatDateSmart()` in `date_format_provider.dart` use the user's preferred pattern. Global `setDateFormatPattern()` called from `app.dart`. All user-facing date displays use `formatDate()` — month-only headers (`MMMM yyyy`) and machine formats (`yyyy-MM-dd`) are intentionally hardcoded. Settings apply instantly without restart.

### Key Rules
- Never use `toStringAsFixed()` for user-visible currency amounts — use `formatAmount()` or `formatNumber()`.
- Never use `DateFormat('...')` for user-facing full dates — use `formatDate()`.
- Input fields (TextControllers) and percentages may use `toStringAsFixed()` since they need `.` for parsing.
- Month-only labels (`MMMM`, `MMM yyyy`) stay hardcoded — they're contextual, not configurable.

## Archived Accounts

Accounts screen has a 3-dot menu with "Show Archived" / "Hide Archived" toggle. Archived accounts appear in a separate "ARCHIVED" section below active ones, dimmed at 60% opacity with an archive badge. Each has an unarchive icon button that opens a confirmation dialog, sets `archived: false` + `lastModified: now`, and refreshes the provider.

## Unallocated Multi-Currency Display

The Unallocated card on the Budget tab shows only the base currency amount by default. If the user has unallocated funds in other currencies, a "+ N other currencies" link and chevron arrow appear. Tapping expands an animated breakdown showing each currency with its amount. This avoids the anti-pattern of converting/summing across currencies with unreliable exchange rates. Single-currency users see no extra UI.

## Reports Month Navigation

All report tabs (Overview, Categories, Insights) have a `_MonthNav` widget with left/right arrows and swipe gesture support. Users can browse any past month. The `reportStatsProvider.monthRange()` accepts an optional `from` parameter so the 6-month trend chart centers around the selected month. `_DailyPaceChart` accepts an optional `month` parameter — for past months it shows full-month data instead of stopping at `now.day`. The Insights tab filters spending velocity, biggest expense, and savings rate to the selected month using proper `monthStart`/`monthEnd` range checks.

## Help Guide

`assets/web/help.html` — comprehensive user guide bundled in the app. 17 sections covering every feature with step-by-step instructions. Responsive (desktop sidebar + mobile hamburger), dark mode support, screenshot placeholders.

**In-app delivery:** `lib/features/settings/help_screen.dart` — `WebView` loads the HTML from `rootBundle`. Injects dark mode CSS variables based on current app theme. Supports deep-linking to sections via `?section=` query parameter (e.g., `context.push('/help?section=envelopes')`).

Route: `/help`, accessible from More > Help Guide.

## i18n Preparation

`docs/i18n_strings.csv` — master translation file with ~750 strings covering the entire app (Flutter + Web SPA). Columns: `key`, `context`, `english`, `arabic`, `french`. Auto-generated Arabic and French translations for user review. Updated alongside every feature change. When ready to ship i18n, this CSV converts to Flutter ARB files + web JSON files.

**Rule:** Every feature addition/change must also update `docs/i18n_strings.csv` and `assets/web/help.html`.
