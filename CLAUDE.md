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

# Regenerate app icons (artwork: assets/icon/source/app_icon.svg — see its README)
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
│   │   ├── app_database.dart   # Drift database definition (schema v20)
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
│   │   ├── accent_color_provider.dart    # Brand accent pair (or Material You)
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
├── l10n/                       # Localization
│   ├── app_{en,ar,fr}.arb      # ARB translation files (~1,800 keys each)
│   ├── generated/              # Auto-generated S class (flutter gen-l10n)
│   └── s_lookup.dart           # currentS() helper for non-widget code
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
│   ├── planned/                # Planned payments: list, form
│   │   ├── planned_payments_screen.dart  # List grouped by month, post/delete
│   │   └── plan_payment_screen.dart      # Create/edit planned payment form
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
│           ├── _budget.dart / _running.dart  # budget snapshot, account running balance
│           ├── dashboard_handler.dart
│           ├── transactions_handler.dart     # list/get/create/update/delete + bulk
│           ├── categories_handler.dart
│           ├── accounts_handler.dart         # + detail, edit, archive, reconcile
│           ├── envelopes_handler.dart        # + move money / cover
│           ├── objectives_handler.dart       # goals & loans
│           ├── upcoming_handler.dart         # bill occurrences + planned payments
│           ├── import_handler.dart           # CSV import
│           ├── changes_handler.dart          # ChangeFeed + /api/changes long-poll
│           ├── recurring_handler.dart
│           ├── subscriptions_handler.dart
│           └── reports_handler.dart
└── shared/
    ├── theme/
    │   ├── app_colors.dart     # Theme-aware color system (light + dark)
    │   ├── app_theme.dart      # Material theme definitions
    │   ├── brand_palette.dart  # 8 accent pairs (bright/deep/fills), Gold default
    │   └── design_tokens.dart  # Spacing, card, and typography constants
    ├── utils/
    │   ├── format_number.dart  # Amount formatting with currency symbols
    │   ├── haptics.dart
    │   ├── receipt_helper.dart
    │   ├── page_transitions.dart
    │   ├── app_info.dart
    │   └── responsive.dart
    └── widgets/                # Reusable widgets
        ├── app_card.dart             # Standard card container (radius 16, Tappable touch)
        ├── allocation_card.dart      # Envelope card with circular progress + semantics
        ├── amount_field.dart         # Opens calculator sheet (not keyboard)
        ├── animated_amount.dart      # Count-up/down currency animation (RepaintBoundary)
        ├── animated_circular_progress.dart # Custom-painted progress ring (RepaintBoundary)
        ├── breathing_widget.dart     # Pulsing attention animation
        ├── calculator_amount_field.dart
        ├── category_icon.dart        # Maps category names to PNG icons
        ├── currency_display.dart
        ├── currency_picker_field.dart
        ├── empty_state.dart
        ├── error_boundary.dart       # Catches build errors, shows fallback screen
        ├── error_retry.dart          # Error display with auto-sanitized details
        ├── faded_edges.dart          # ShaderMask gradient fade on scroll boundaries
        ├── hint_banner.dart
        ├── rolling_number.dart       # Odometer-style digit rolling animation
        ├── section_header.dart       # Standard section header (13px, w700, ls 0.8)
        ├── skeleton_loader.dart
        ├── spending_heatmap.dart     # GitHub-style daily spending grid
        └── tappable.dart             # Premium tactile button (scale + haptic, platform-aware)

assets/web/
    index.html    # SPA shell (PIN screen, sidebar) — no inline scripts
    app.js        # ~3200 lines, vanilla JS, hash routing, data-action delegation, 13 screens, live updates
    styles.css    # App design language (accent vars, paper/night, RTL via logical props)
    chart.umd.min.js, nunito-sans*.woff2   # bundled so it works offline
    locale_{en,ar,fr}.json  # generated from the CSV (csv_to_web_json.dart)
    help.html     # Bundled help guide (also hostable as standalone webpage)

docs/
    i18n_strings.csv  # Master i18n CSV (key, context, english, arabic, french)
```

## Core Concepts

### Envelope Budgeting (Allocations)
The primary feature. Money flows: Income → Account → Unallocated pool → Fund envelopes → Spend from envelopes.

Two envelope types: **Spending** (periodic budget, resets each month) and **Flexible** (accumulates, optional target). Legacy `saving` type in DB is treated as `flexible` — no migration needed. Savings goals and debt tracking use the separate **Goals & Loans** feature (`/objectives`), which creates real transactions. Envelopes are virtual budget labels only.

A subcategory with no envelope of its own spends from its parent category's envelope (`recordTransaction` and the Budget tab's planned preview both resolve it). The Budget tab's "Spent" and the envelope hero's "$X spent" come from `periodSpendingProvider` (consumption ledger in the current period, by transaction date — `budgetPeriodFor()` in `period_engine.dart`), never from target − balance.

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
- Accent-tinted containers: `AppColors.accentLight` (the selected pair's soft fill for the current mode). Never hardcode blues.
- **Text/icons on an accent fill: `AppColors.onAccent`, never `Colors.white`** — in dark mode the accent is a bright tone (gold) and white on it is unreadable. On `AppColors.accentBright` fills use `brandInk`.

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
Both the assisted flow and classic form use the same `CategorySheet` (Cashew style): search field, type toggle (Expense/Income), then a 4-column icon grid of parent categories. Tapping a parent that has subcategories opens a subcategory step (back arrow returns); searching shows a flat grid of all matches. Never drop the search field.

### Add/Edit Form & Detail Header
The classic form opens with a Cashew header band (category-pastel colored): an inset pill type selector (Expense/Income/Transfer, sliding white indicator), a 64px category icon with an edit badge and the category name under it (tap → CategorySheet), and a 40pt amount on the right (tap → `showCalculatorSheet()`). The AppBar title states the type ("New expense", "Edit transfer"…). Title, date/time and note share one filled card with dividers; the item/transfer cards use the same filled surface (`sfv`, no shadow). With a single line, `LineCard(compact: true)` hides its category, amount and per-item note, and the account dropdown shows the name only (the currency badge beside it is the currency picker). Transfers have no amount row in the card — the band is the amount. Add item / Scan receipt / Gallery are one row of equal `_ActionChip` tiles. Title suggestions never repeat the text already typed. The save action is a bottom bar whose label steps "Enter amount" → "Add transaction"/"Save". `transaction_detail_screen.dart` uses the same band (name under the icon, type under the amount) so view and edit match, and hides its "Line detail" card when the line only repeats the header's category and note. The calculator is a seamless key grid, LTR in every locale, shows the user's decimal separator, and disables Done at zero (except when clearing an existing value).

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

### Buttons in a Row — Give Them a Width
The theme gives Filled/Outlined buttons `minimumSize: Size.fromHeight(52)` (full width). A bare FilledButton/OutlinedButton as a direct `Row` child (not in `Expanded`/a sized box) gets infinite width → layout fails and the screen renders blank. Wrap it in `Expanded`, or set `minimumSize: const Size(0, 44)` in its style. (Bit the add form's "Save & new", the reorder sheet and the category sheet's Add.)

### Data Reset Flow
Never close the database and wait for providers. Instead: `db.batch()` delete all rows → clear SharedPreferences → `context.go('/onboarding')`.

### Resume Work

On every resume `app.dart` runs `_processDueWork()`: `processRecurring()` (invalidates transaction/balance providers if anything posted) then `NotificationService.runChecks()` (each check keeps its 24h cooldown). `MainScreen` asks for the Android 13+ notification permission once (`NotificationService.requestPermissionOnce`). Upcoming-bill views use `recurringAmountOn(rec, date)` so subscription price changes show before they post.

## Daily Reminder Timezone
Must call `tz.setLocalLocation()` after `initializeTimeZones()`. Without it everything runs as UTC. Use `flutter_timezone` to get the device identifier.

### Currency Display Bug
`tx.currency` is the base currency, not the line's native currency. For display, use `lines.first.currency`. Passing the wrong currency code to `formatAmount()` silently shows the wrong symbol.

## Design Conventions

- **Card radius:** 16 (`CardTokens.radius`), **padding:** 16h / 14v — consistent everywhere. All `BorderRadius.circular()` calls use the token, never hardcoded.
- **Category icons:** 48px circles in lists (`CategoryIconTokens.listSize`), 36px compact, 64px hero.
- **Screen titles:** 28px w800 (`TypographyTokens.screenTitleSize`) — Cashew-inspired large bold.
- **Section headers (Cashew SettingsHeader):** sentence case, 15px w700, accent color, no letter spacing. ARB header strings are stored in sentence case (never ALL CAPS); `SectionHeader` no longer upper-cases.
- **Cards (Cashew style, Oct 2026):** warm neutral surface (`AppColors.sf` — white on paper in light, night `#1C1D24` in dark), no border; light mode gets a soft shadow (`AppColors.cardShadow`), black mode a faint white edge (`AppColors.cardBorder`). `AppColors.bd` is a hairline (6% black / 7% white) for dividers.
- **Pastel fills:** use `AppColors.pastel(context, color)` / `lightenPastel` / `darkenPastel` (Cashew's color model) for anything colored by a category/envelope/accent — never `color.withValues(alpha: 0.1)` tints.
- No glassmorphism. No left-border accent bars on cards (looks like a prototype).
- Design target: Cashew's layout grammar (measure real values from github.com/jameskokoska/Cashew, `budget/lib`), with BudgetSeal's own brand on top: gold accent pairs, warm paper/night surfaces, Bricolage Grotesque for titles and hero amounts, the gold "Ready to assign" banner. Measure, never copy Cashew code or assets (GPL-3.0).
- **Display font:** `TypographyTokens.displayFamily` ('BricolageGrotesque', bundled in `assets/fonts/`, SIL OFL) for screen titles (`LargeTitleHeader`, `screenTitleSize` styles, `displaySmall`) and hero amounts (form/detail bands, envelope hero and cards, account/goal balances, dashboard net worth/unallocated, Ready to assign). Body text keeps the user's font.
- "Good morning" greeting removed — user disliked it
- Colors are always theme-aware — never hardcode on adaptive surfaces. On accent fills use `AppColors.onAccent` (not `Colors.white`).

## Database

### Schema Version: 20
12 tables: households, users, accounts, categories, allocations, transactions, transaction_lines, allocation_ledger, recurring_transactions, transaction_templates, fx_rates, objectives.

v9→v10 added `isSubscription` and `priceHistory` columns to `recurring_transactions` for subscription tracking.
v10→v11 added `icon` (nullable TEXT) to `allocations` for envelope emoji icons.
v11→v12 added `deleted` (BOOLEAN, default false) to `transactions` for soft-delete support.
v12→v13 added `autoReset` (BOOLEAN, default true) to `allocations` for period reset behavior.
v13→v14 added `decimalPlaces` (nullable INT) to `accounts` for per-currency decimal precision, `status` (nullable TEXT) to `transactions` for upcoming/skipped bills, and created `objectives` table for goals and loan tracking.
v14→v15 added `isTravel` (BOOLEAN, default false) to `accounts` for travel wallet support.
v15→v16 added performance indexes: `idx_transactions_household_date`, `idx_transactions_household_deleted`, `idx_transaction_lines_tx`, `idx_ledger_allocation`, `idx_allocations_household`, `idx_categories_household`.
v16→v17 added indexes: `idx_ledger_source_tx` on `allocation_ledger(source_transaction_id)`, `idx_categories_allocation` on `categories(allocation_id)`.
v17→v18 added `deleted` to accounts/categories/allocations/objectives/recurring/templates and `lastModified` to recurring/templates.
v19→v20 added `sortOrder` (nullable INT) to `allocations` for the manual Budget tab order (synced).
v18→v19 added `anchorDay` (nullable INT) to `recurring_transactions`: the day of month a series was set up on. `advanceRecurringDate()` (recurring_engine.dart) clamps monthly/yearly dates to short months and returns to the anchor (Jan 31 → Feb 28 → Mar 31); legacy rows get the anchor filled from their due day the next time they post.

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

**Toolchain:** Flutter 3.47.5 / Dart 3.13. iOS deployment target 15.5 (required by ML Kit). **Held-back majors:** go_router 18, google_fonts 9, dynamic_color 2 and shimmer 4 all depend on the standalone `material_ui` package, whose `ColorScheme`/`TextTheme`/`MaterialApp` types are distinct from `package:flutter/material.dart`. Upgrading them requires migrating the whole app (`dart fix --apply --code=migrate_design_widgets`), so they stay on 17.x / 8.x / 1.x / 3.x until that's done. pointycastle stays on 3.x because `encrypt` 5.0.3 (latest, unmaintained) requires `^3.6.2`. file_picker 12+ API: use `FilePicker.pickFile()` (returns `PlatformFile?`), not `pickFiles()`.

| Package | Constraint | Purpose |
|---------|------------|---------|
| drift | ^2.35.0 | SQLite ORM |
| drift_flutter | ^0.3.1 | Drift Flutter integration |
| flutter_riverpod | ^3.4.0 | State management |
| go_router | ^17.5.0 | Navigation |
| fl_chart | ^1.2.0 | Charts (pie, line, bar) |
| google_sign_in | ^7.0.0 | Google Drive auth |
| googleapis | ^17.0.0 | Google Drive API |
| googleapis_auth | ^2.3.4 | Google API OAuth |
| local_auth | ^3.0.0 | Biometric lock |
| flutter_local_notifications | ^22.3.0 | Bill/envelope alerts |
| shared_preferences | ^2.5.0 | Simple key-value settings |
| csv | ^8.0.0 | CSV import/export |
| share_plus | ^13.3.0 | Share files/data |
| file_picker | ^13.1.0 | System file picker for sync |
| haptic_feedback | ^0.6.0 | Haptic feedback |
| sliver_tools | ^0.2.12 | Advanced sliver widgets |
| google_fonts | ^8.2.0 | Custom fonts |
| dynamic_color | ^1.9.0 | Material You system accent color |
| confetti | ^0.8.0 | Celebration effects (goal completion) |
| google_mlkit_text_recognition | ^0.17.1 | Offline receipt OCR (bill splitter) |
| encrypt | ^5.0.3 | AES-256 encryption for sync files |
| flutter_secure_storage | ^11.2.0 | Secure credential storage (Keystore/Keychain) |
| pointycastle | ^3.9.1 | PBKDF2 key derivation |
| shelf | ^1.4.2 | HTTP server (Web Companion) |
| shelf_router | ^1.1.4 | Route matching (Web Companion) |
| network_info_plus | ^8.2.0 | WiFi IP detection (Web Companion) |
| qr_widget | ^4.1.0 | QR code display (Web Companion) |
| flutter_foreground_task | ^11.0.3 | Android foreground service (Web Companion) |
| wakelock_plus | ^1.8.0 | iOS screen-on (Web Companion) |
| crypto | ^3.0.0 | SHA-256 PIN hashing (Web Companion) |
| webview_flutter | ^4.14.0 | In-app help guide WebView |
| quick_actions | ^1.1.1 | Launcher app shortcuts |

## Testing

```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/core/engine/allocation_engine_test.dart
flutter test test/core/engine/balance_calculator_test.dart
flutter test test/core/database/migration_test.dart
flutter test test/widgets/   # Tappable, RollingNumber, FadedEdges, ErrorBoundary (15 tests)
```

Tests use `AppDatabase.forTesting(NativeDatabase.memory())` for in-memory databases.

Manual test scripts:
- `test/manual_test_script.md` — full app test checklist (14 sections, 100+ items)
- `test/web_companion_test_script.md` — Web Companion API + security tests (40+ curl commands)

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
Backup restore validates: SQLite magic bytes (`SQLite format 3`), file size < 100MB, auto-backup of current DB before overwriting. The restore is **staged**, never copied over the open DB: `AutoBackupService.restoreFromBackup()` writes `budgetseal.db.restore`, sets `restorePending` (auto-sync, `SyncNotifier.sync()` and `runIfDue()` all skip while it's set) and the Backup screen asks the user to restart; `_openConnection()` in `app_database.dart` swaps the file in (and drops -wal/-shm) before Drift opens it.

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
The envelope detail screen shows: balance hero card (pastel of the linked category color, `BudgetProgress` bar with percent + pace marker, tonal fund button; label reads "$X spent" for spending envelopes and "$X to go" for flexible ones) → settings form (hidden, via 3-dot menu) → recent transactions → spending history. Settings, withdraw, revalue, archive, and delete are in the 3-dot menu. No duplicate transaction lists.

### Multi-Currency Envelopes
Envelopes can hold balances in multiple currencies. The fund sheet offers a currency picker showing all available unallocated currencies. The balance hero card shows the target currency balance prominently, with other currencies as `+ $50`. The allocation card does the same.

### Moving Money Between Envelopes
`AllocationEngine.moveMoney(fromAllocationId?, toAllocationId?, amount, currency)` — null side = Ready to assign; envelope↔envelope rows use entryType `'transfer'`, RTA→envelope `'funding'`, envelope→RTA `'withdrawal'`; one db transaction; an envelope source must hold the amount (StateError). UI: `showMoveMoneySheet()` (`features/allocations/move_money_sheet.dart`) from the envelope ⋮ menu (Move money; becomes Cover when overspent), the red **Cover** pill on overspent `AllocationCard`s (`onCover`), and the Saved SnackBar (`envelopeAfterSave()` in `widgets/save_feedback.dart` reads the consumption row → "X left" / "over by X" + Cover → `/allocations/:id` with extra `{'cover': true}` opens the sheet).

### Funding & Period Helpers
- Funding screen presets: Quick Fill (to target), Same as last period (`LedgerDao.fundedInPeriod`: funding + incoming moves by ledger date), What I spent last period (`watchSpendingInPeriod(...).first`), Clear. Fund All runs in one db transaction; funded rows keep their input.
- Envelope fund sheet chips: To target, All available.
- Budget tab: `PeriodSummaryCard` (first 7 days of a period, dismissed per period via `period_summary_dismissed`); ⋮ → Reorder envelopes (`allocations.sortOrder`, schema v20, `AllocationsDao.saveOrder`; `watchAll` orders sortOrder nulls-last, then name).
- Period review includes negative balances: `resolveLeftover` with a negative amount → `toUnallocated` writes a covering `funding` row, `keep` a `carry_forward` marker. Pending detection counts any non-zero balance.
- Categories: envelope badge + long-press → Envelope (`category_envelope_sheet.dart`: link/unlink/create envelope named after the category).
- Goals: `_monthlyPace` = remaining / months left (started month counts) shown as "Needed per month".

### Withdrawal Validation
`withdrawFromAllocation()` checks sufficient balance before debiting. Throws `StateError` if the allocation doesn't have enough in the requested currency. Callers must catch and show an error.

### Notification Grouping
`NotificationService` groups multiple low-envelope alerts into one notification and multiple upcoming-bill alerts into one. Uses fixed notification IDs (1001, 1002) so each check replaces the previous. 24-hour cooldown between checks via SharedPreferences. Overspent detection checks each currency independently (never sums across currencies).

### Envelope Currency Handling
- **Line currency = account currency**: `recordTransaction()` runs `_toAccountCurrencies()` first — a line entered in another currency (€50 on a USD account) is converted with its own rate or the latest cached rate (`latestCachedRate()` in fx_service.dart) and the original amount is appended to the line note. No rate at all → `CurrencyConversionException` (UI text via `txSaveErrorText()` in `shared/utils/save_errors.dart`). Account balances sum line amounts, so they never mix currencies.
- **Envelope debit in the spent currency**: the consumption ledger entry uses the line's currency, never a conversion into the envelope's currency (that broke the per-currency invariant). A foreign debit shows as cross-currency debt on the envelope (`hasCrossDebt`).
- **Scheduled items get today's rate**: recurring bills post with `latestCachedRate()` (cache only — runs before `runApp`, must not hit the network); a cross-currency recurring transfer without a rate stays due. Planned payments fetch a rate (`fxServiceProvider`) when the user posts them.
- **Goal payment tags** are `[obj:ID|amount]` (amount in the objective's currency, since the line is stored in the account's currency); `visibleNote()` (`shared/utils/note_text.dart`) hides the tag wherever a note is displayed — keep the raw note when editing.
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

### Database Indexes (v16)
Six indexes on hot query paths: transactions by (household_id, created_at) and (household_id, deleted), transaction_lines by transaction_id, allocation_ledger by allocation_id, allocations and categories by household_id. Eliminates full table scans for all core list/balance queries.

### Allocation Engine Batching
`recordTransaction()` pre-fetches all category→allocation mappings and allocation currencies in 3 batched queries before the line loop, instead of 2 queries per line (N+1 → O(1) per write).

### Transaction List Filtering
All filters (date range, type, category, amount, search) applied in a single `.where()` pass instead of 5 sequential `.toList()` copies. Reduces allocations and iteration from O(5N) to O(N).

### RepaintBoundary on Animations
`AnimatedCircularProgress` and `AnimatedAmount` wrapped in `RepaintBoundary` to isolate their repaints from parent widget trees. `AnimatedCircularProgress` also hoists child into `AnimatedBuilder.child` to avoid rebuilding children on every animation frame.

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
- Security middleware pipeline order: `catchAll → privateIp → bodySize (512 KB) → rateLimit (120 req/min) → writeRateLimit (40 writes/min) → abuseDetection (SQL/XSS/honeypot/field size) → security headers (CSP, X-Frame-Options, etc.) → auth → router`.
- Handlers use `ref.read(databaseProvider)` and `.get()` (one-shot Future), not `.watch()` (streams). Web client polls on demand.

### Security
- **CORS**: Same-origin only (echoes request `Origin` header). Never use `Access-Control-Allow-Origin: *` — it allows any malicious website to exfiltrate budget data via CSRF.
- **Security headers** on all responses: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Cache-Control: no-store`, `Content-Security-Policy` (restricts scripts/styles/fonts), `Permissions-Policy` (denies camera/mic/geo).
- **`serverError()`** logs exception details locally via `debugPrint` but returns generic "Internal server error" to the client. Never leak stack traces, DB schema, or internal types.
- **`/auth/status`** does not expose `activeSessions` count — prevents session enumeration.
- **Browsers card (phone)**: while running, `web_companion_screen.dart` polls every 3 s: `auth.connectedCount()` (sessions seen within 75 s — an open page checks in at least every 30 s) and `activeSessionCount`. **Sign out all** / changing the PIN call `WebCompanionService.signOutAllBrowsers()` = `revokeAllSessions()` + `ChangeFeed.wake()`, so held long-polls answer now and the pages hit the 401 → PIN screen at once.
- **`/auth/logout`** endpoint revokes the session token explicitly.
- **Session timeouts**: 4-hour inactivity timeout + 8-hour absolute session lifetime. Max 10 concurrent sessions (oldest evicted).
- **Private IP check** validates IPv4 (127.x, 10.x, 192.168.x, 172.16-31.x) and IPv6 (::1, fe80: link-local, fc/fd ULA).
- **Rate limiter** evicts stale IP entries every 5 minutes to prevent memory growth. Global: 120 req/min. Writes (POST/PUT/DELETE): 40/min per IP (room for fast keyboard entry).
- **Abuse detection**: regex patterns block SQL injection keywords (DROP TABLE, UNION SELECT, etc.) and XSS patterns (`<script>`, `javascript:`, `onerror=`). No `--` or `UPDATE x SET` patterns — they rejected ordinary notes ("Dinner -- with Sam"). Oversized fields (>10K chars) rejected. Honeypot field ("website") catches bots.
- **WiFi security warning**: Phone screen shows a network security notice before the Start button. Detects public networks by WiFi name keywords (guest, public, airport, hotel, cafe, free wifi…) and shows an elevated amber warning. An unknown name (null / `<unknown ssid>` — Android hides it without location permission) is NOT treated as public, and there are no bare `free`/`open` keywords (they flagged home routers like "Freebox").
- **No inline scripts or handlers in the SPA**: the CSP is `script-src 'self'`. Clicks go through `data-action` attributes and one delegated listener (`actions` map in app.js); forms wire their own `addEventListener`s. Never put user text inside a JS string in an attribute — HTML-decoding turns `&#39;` back into `'` before the JS runs (this broke account names with an apostrophe). `esc()` escapes every user value placed in markup; `safeHex()` validates colors used in `style`.
- **Search input** escapes SQL LIKE wildcards (`%`, `_`, `\`) in the backend before passing to Drift's `.like()`.
- **FK validation** checks household ownership: `validateIdExists()` verifies the referenced ID belongs to the authenticated user's household, preventing IDOR attacks.
- **Input validation** on all POST/PUT endpoints: type checks, string length limits (kMaxNameLength=100, kMaxNoteLength=500), amount bounds (>0, ≤1B), enum validation, FK existence + household checks. Invalid data returns 400 with clear error message.
- **Error sanitization**: `ErrorRetry` widget auto-strips exception types, file paths, SQL details, and stack traces. All SnackBars use generic messages. No `console.log/error/warn` in web SPA.

### Multi-Currency in Web Companion
- Transaction list handler returns `lineCurrency`, `lineAmount`, `lineExchangeRate` from the first transaction line alongside the header data. The frontend displays the native currency amount, not the base currency header amount.
- `isRealRate` check: both `cashflowReportHandler` and `byCategoryReportHandler` skip lines where currency differs from base but `exchangeRateToBase` is ~1.0 (rate not set). Same logic as `isRealRate()` in `format_number.dart`.
- Transactions with missing exchange rates show an amber "No rate" warning in the list.

### Web SPA (assets/web: index.html, styles.css, app.js)
- **Design = the app's**: warm paper/night surfaces, the user's accent pair (from `/auth/config`, set as `--acc-*` CSS variables), Bricolage Grotesque for titles/amounts (served from `assets/fonts` at `/fonts/`), Nunito Sans (bundled `nunito-sans*.woff2`, OFL in `assets/fonts/OFL-NunitoSans.txt`), pastel category chips with the app's PNG icons (`/icons/<file>`, name from `categoryIconFile()` in category_icon.dart, sent as `categoryIconFile`/`iconFile`), the gold Ready-to-assign banner, borderless filled inputs, pill buttons, radius-25 dialogs, Cashew-style popup toasts. Logical CSS properties only, so `dir="rtl"` mirrors everything.
- **No internet needed**: Chart.js is bundled (`assets/web/chart.umd.min.js`, MIT) and fonts are local; the CSP allows only `'self'`. Assets in `assets/web/` must sit directly in that folder (pubspec lists the folder, not subfolders). `.woff2`/`.min.js`, `/icons`, `/fonts`, `/brand` get a 7-day cache; the SPA's own files stay `no-store`.
- **`GET /auth/config`** (no token — the PIN screen needs it): `locale` (from `Intl.defaultLocale`, en/ar/fr), `accent` (bright/deep/fills of the chosen pair; Material You falls back to Gold), `number` = `numberFormatSpec()` (format_number.dart: separators, parentheses negatives, Arabic digits, symbol map). `fmt()` in app.js mirrors `formatAmount()` and wraps every amount in a left-to-right isolate (`\u2066…\u2069`, plus `\u200E` after an Arabic symbol) so signs/digits never reorder next to "ل.ل" or on an Arabic page.
- **Strings**: every visible string is `t('web_…')` / `data-i18n`; keys live in the ARBs + CSV and are generated into `locale_*.json` by `tool/csv_to_web_json.dart` (web keys must exist in the ARBs). Placeholders are plain `{n}` (no ICU plurals in web strings — Arabic uses "label: {n}" phrasing).
- **Dates**: the browser sends the user's calendar day `YYYY-MM-DD` (`dayKey()`, never `toISOString()` — UTC shifts the day). `parseWebDate()` (transactions_handler.dart) keeps the time of day when editing, uses now for today, noon otherwise.
- **Transactions**: grouped by day, "Load more" paging (`hasMore` from a limit+1 query), filters (type, year/month — "Whole year", search, account page). Row click = edit dialog; row buttons duplicate/delete. **Delete waits 5 s for Undo** (`pendingDeletes`, flushed with `keepalive` on `pagehide`/sign-out). Split transactions: lines shown read-only, amount/category hidden ("edited on your phone"). The form remembers the last account/type (`localStorage`), has Save & add another, Today/Yesterday chips, a category `<select>` filtered by type with subcategories indented.
- **Bulk entry** (`#/bulk`, "Add several" on Transactions; `renderBulk()`/`saveBulk()`): expense/income grid (date, type, account, category, title, amount in the account's currency). Tab across, Enter down (adds a row copying date/type/account), Ctrl+Enter saves; paste (TSV or CSV lines) recognises dates (`parseLooseDate`, day-first unless impossible or en-US), amounts (minus/parentheses → expense), category and account names; the rest is the title. Draft in `sessionStorage` (`bs_bulk`). Saved via `POST /api/transactions/bulk`; a 400 carries `row` and that row is highlighted.
- **CSV import** (`#/import`, "Import CSV" on Transactions): the browser parses the file (`parseCsv`: quotes, `,`/`;`/tab), guesses column roles (`guessRoles`: date/description/amount or debit+credit/category, header words in EN/FR/AR + sample rows), shows a mapper + preview, and sends `{date: YYYY-MM-DD, description, amount (signed), category}` rows in chunks of 500 to `POST /api/import` — first `dryRun` (counts for the confirm dialog), then for real. Day-first vs month-first is decided once per file (any first field > 12), as in the app. Server rules = `import_screen.dart`: skip rows already on the account (`day|amount|type`, also within the file), category by name else guessed from past titles, `recordTransaction` in the account's currency at `latestCachedRate()`, all rows in one db transaction.
- **Currencies in the form**: an expense/income line in a non-base currency shows a rate field ("1 EUR = ? USD"); empty → the server uses `latestCachedRate()` (no network in a request), else 1.0 + "No rate". A transfer between accounts in different currencies asks for the **amount received**; the server stores `exchangeRateToBase = received / sent` (source → destination, as the app does) and refuses a cross-currency transfer without it.
- **Budget**: `budgetSnapshot()` (`api/_budget.dart`, shared by dashboard + envelopes) returns envelopes in the Budget tab's order (sortOrder nulls-last, then name) with `spentByCurrency` (period consumption from `watchSpendingInPeriod().first`) and the linked category's color, plus `unallocated` per currency and the current `period`. Fund dialog: To target / All available chips; over-funding warns inline and the second submit goes ahead. Move dialog (`openMove()`, ⇄ on every card; overspent cards show **Cover** instead of Fund): From/To selects (Ready to assign = `''`), currency, "Overspent amount" / "All of it" chips; Cover takes from Ready to assign, or the richest envelope when RTA can't cover it. An envelope source can't give more than it holds (client + server); RTA may go negative after the second submit.
- **Account page** (`#/accounts/<id>`): `GET /api/transactions?accountId=` adds `accountAmount` (the row's signed effect on that account, in its currency) and `runningBalance` (balance right after it) from `accountRunning()` (`api/_running.dart`: replays the account's posted history from `initialBalance`, oldest first by createdAt then id, with `_applyTxToRunning()`'s rules; the list orders by createdAt desc, id desc to match). Header: balance, "Reconciled <date>" (pref `reconciled_<id>`, shared with the app), Edit (name, type, starting balance, decimal places; currency is fixed), Reconcile (actual balance → "Balance adjustment" income/expense via `recordTransaction`, then marks reconciled). Archive only at zero (half a unit of the last decimal, 400 `code: not_zero` otherwise); Accounts page lists archived accounts (`?archived=1`) with Unarchive.
- **Upcoming** (`#/upcoming`, `api/upcoming_handler.dart`): bills = enabled, non-deleted recurring + subscriptions, every occurrence in the 7/30/90-day window (`advanceRecurringDate`, `recurringAmountOn`, stops at `endDate`); only `occurrence: 0` opens the Post now / Skip dialog (`RecurringEngine.postNow/skipNext`). Planned payments are stored exactly like `plan_payment_screen.dart` (status `'planned'`, account currency, rate 1.0, one line; edit = delete lines + soft-delete + insert) and posted like `planned_payments_screen.dart` (create first, then `deleteTransaction`, on the planned date, `latestCachedRate()`; each item in its own db transaction; a cross-currency transfer without a rate fails alone).
- **Goals & loans** (`#/goals`, `api/objectives_handler.dart`): progress = sum of the `[obj:ID|amount]` tags on non-deleted, posted transactions (legacy `[obj:ID]` → lines in the objective's currency), the same rule as the phone's `_syncCurrentAmount`; the pay handler stores it back into `objectives.currentAmount`. Pay = `recordTransaction` (income for a lent loan, else expense) with a line in the objective's currency at `latestCachedRate()`, note `"<prefix> — <name> [obj:ID|amount]"` (prefix from `currentS()`). Delete soft-deletes; `?payments=delete` also deletes the payments (one db transaction). Cards reuse the envelope card styles; goals count up, loans show what's still owed.
- **Recurring/subscriptions** share handlers (`listRecurring/createRecurring/updateRecurring/deleteRecurring` with `subscription:`), always filtering `deleted = false`. Editable: title, amount (subscriptions add a price-history entry), note, account, destination, category, frequency/interval, next date (also sets `anchorDay`), enabled. Subscriptions page shows per-month/per-year cost (`perMonth()`).
- **Notes**: payloads carry `visibleNote()`; the PUT handler re-appends the hidden `[obj:…]` tag (`noteTag()`), and an empty `note` clears it. Edits record the new transaction, carry `receiptPath`, and soft-delete the old one inside one `db.transaction`.
- **Live updates**: `ChangeFeed` (`api/changes_handler.dart`, created in `WebCompanionService.start()`, disposed on stop) listens to Drift's `tableUpdates()` — the phone's writes included — and bumps a version (writes within 250 ms = one change; last 100 keep their table names). `GET /api/changes?since=N` answers at once if N is behind or unknown (server restarted), else holds up to 25 s. The SPA's `liveLoop()` long-polls it; a change → `liveFlush()` redraws quietly (`reloadTx()` on transaction/account pages keeps the toolbar and loaded pages; other pages `navigate(route, true)`), but waits while a dialog is open, the tab is hidden, the user is typing (outside the transaction list) or on `#/bulk`/`#/import` — closing the dialog / focusout / showing the tab flushes it. A change within 1.5 s of this tab's own write is ignored (`state.lastWrite`). A quick answer without a change waits 2 s (no busy loop). Headless Edge screenshots need the mock to answer `/api/changes` at once (a held request stalls virtual time).
- **Connection**: `/auth/status` every 30 s (the long-poll also reports reachability); unreachable → banner + red dot; `authenticated:false` or a 401 on the long-poll → PIN screen with "session ended". PIN errors show attempts left / lockout minutes (`attemptsLeft`, `retryInMinutes` from `/auth/pin`).
- Token in `sessionStorage` (`bs_token`). `api()` shows localized toasts (429, 5xx, missing rate; English users see the server's 400 message). Shortcuts: N new, / search, R reload, 1–9 pages, Enter saves a form, Esc closes, ? help.
- Visual QA without a phone: a mock server serving `assets/web` with canned JSON + headless Edge screenshots works well (Edge won't go below ~500 px wide — use an iframe for phone width).

### REST API Endpoints
```
POST /auth/pin                         → { token, expiresAt } | 401 { attemptsLeft } | 429 { isLockout, retryInMinutes }
GET  /auth/status                      → { authenticated: bool }
GET  /auth/config                      → { locale, accent, number }   (no token)
GET  /icons/<file> /fonts/<file> /brand/<file>  → bundled category icons, fonts, app icon

GET  /api/dashboard                    → household, period, accounts, envelopes, unallocated, 8 recent transactions
GET  /api/transactions?page=&limit=    → { items, hasMore } (type, accountId incl. per-line accounts, from, to, search)
POST /api/transactions                 → create (transfer: exchangeRateToBase = source → destination)
GET  /api/changes?since=N              → { version, tables } — long-poll (≤25 s) for any database change
POST /api/import                       → { accountId, dryRun?, rows[≤1000] } → { imported, ready, categorized, duplicates, skipped }
POST /api/transactions/bulk            → { items: [create payload…] } ≤100 rows, all validated, then written in one db transaction → { ids, count } | 400 { error, row }
GET  /api/transactions/:id             → single + lines
PUT  /api/transactions/:id             → update (type can change; returns the new id)
DELETE /api/transactions/:id           → soft delete

GET  /api/categories                   → all non-archived (with iconFile)
POST /api/categories                   → create (parentId must be a top-level category)
PUT  /api/categories/:id               → update (parentId: not itself, not if it has children)

GET  /api/accounts                     → with balances
POST /api/accounts                     → create (initialBalance may be negative)
GET  /api/accounts?archived=1          → also archived accounts
GET  /api/accounts/:id                 → account + balance, initialBalance, transactionCount, reconciledAt
PUT  /api/accounts/:id                 → name, type, initialBalance, decimalPlaces (null = auto)
POST /api/accounts/:id/archive         → { archived } (archiving needs a zero balance)
POST /api/accounts/:id/reconcile       → { balance } → { adjusted, reconciledAt }

GET  /api/envelopes                    → { items, unallocated, period, baseCurrency }
POST /api/envelopes/:id/fund           → add funding
POST /api/envelopes/move               → { fromId?, toId?, amount, currency } (null side = Ready to assign; AllocationEngine.moveMoney; 400 if the source envelope lacks it)

GET  /api/upcoming?days=30             → bill occurrences (recurring + subscriptions) with dueDate, daysUntil, occurrence, amount on that date
POST /api/recurring/:id/post-now       → RecurringEngine.postNow (records today, advances)
POST /api/recurring/:id/skip           → RecurringEngine.skipNext
GET  /api/planned                      → planned payments (status 'planned'), oldest first
POST /api/planned · PUT /api/planned/:id → { type, accountId, destinationAccountId?, amount, categoryId?, note?, date }
DELETE /api/planned/:id                → delete a plan
POST /api/planned/post                 → { ids } → { posted, failed[] }

GET  /api/objectives                   → goals & loans (currentAmount from payment tags, paymentCount, monthlyPace)
POST /api/objectives                   → create { type goal|loan, name, targetAmount, targetCurrency, endDate?, contactName?, direction lent|borrowed, colorHex, icon? }
GET  /api/objectives/:id               → one + payments
PUT  /api/objectives/:id               → update
DELETE /api/objectives/:id?payments=keep|delete → soft delete (optionally its payments too)
POST /api/objectives/:id/pay           → { accountId, amount, categoryId?, date? } → real transaction

GET  /api/recurring                    → recurring items (not subscriptions, not deleted)
POST /api/recurring                    → create (transfer needs destinationAccountId)
PUT  /api/recurring/:id                → update
DELETE /api/recurring/:id              → soft delete

GET  /api/subscriptions                → subscriptions (not deleted)
POST /api/subscriptions                → create
PUT  /api/subscriptions/:id            → update (price change → priceHistory)
DELETE /api/subscriptions/:id          → soft delete

GET  /api/reports/cashflow?year&month  → monthly totals, topExpenses, transactionCount, daily
GET  /api/reports/by-category?year&month&type → spending/income per category (type=expense|income)
```
Tests: `test/features/web_companion_api_test.dart` calls the handlers with an in-memory DB through a `ProviderContainer` (`Provider<Ref>((ref) => ref)` hands them a Ref; route params go in `context['shelf_router/params']`).

### SPA Hash Routes
```
#/                Home (Ready to assign, net worth, accounts, envelopes, recent)
#/transactions    Day-grouped list, search, type + month filters, CSV export
#/bulk            Add several: grid entry + spreadsheet paste
#/import          CSV import: file → column mapper → preview → check & import
#/accounts/<id>   One account: running balance per row, reconcile, edit, archive
#/envelopes       Budget: Ready to assign + envelope cards + fund / move / cover
#/reports         Month arrows, stats, daily chart, category donut/shares, biggest expenses
#/accounts        Net worth per currency, accounts by type
#/upcoming        Bills due (7/30/90 days, post now / skip) + planned payments (plan, post, post all, edit)
#/goals           Goals & loans: cards, detail with payments, pay, create/edit/delete
#/categories      Expense/Income toggle, parents with subcategories
#/recurring       Active + paused recurring items
#/subscriptions   Monthly/yearly cost + subscriptions
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

## Bills, Reports & Around the App (Oct 2026)

- `RecurringEngine.postNow(id)` (record today, advance) / `skipNext(id)` (advance only) from Upcoming Bills (tap a bill). `RecurringEngine.postedNotice` (ValueNotifier) counts auto-posted items; `MainScreen` shows "N recurring items posted".
- Reports: `reportsByPeriodProvider` (pref `reports_budget_period`) → `reportsStartDayProvider` (null unless the period start day ≠ 1); `reportBucketFor()` / `reportRangeFor()` in report_stats_provider.dart; the hub sets module-level `_reportsStartDay` and all month getters use `_reportMonth()`. Toggle: calendar icon by the Reports title.
- Reconcile (account ⋮ → Reconcile balance): live difference preview, "matches" just marks reconciled; last date in prefs `reconciled_<accountId>`.
- CSV import: Debit/Credit roles (`_rowAmount` = credit − debit), duplicate skip (account|day|amount|type vs existing lines), category guess from past titles contained in the description.
- Settings Cloud Sync tile subtitle reflects `syncProvider` (syncing / failed / "Synced <when>"). Onboarding base currency defaults to the region currency (`_localeCurrency`).
- Daily reminder: `DailyReminderService.refresh(loggedToday:)` on resume refills the 14-day window and cancels today's when a non-recurring transaction exists for today.
- Home widget: `HomeWidgetService.update()` writes `widget_title`/`widget_line` to shared_preferences (Android reads `FlutterSharedPreferences` → `flutter.widget_*` in `SpendingWidget.kt`) and calls the `budgetseal/widget` method channel (`MainActivity.kt`) to redraw; app.dart calls it on pause.

## Daily Reminder

`DailyReminderService` schedules a daily local notification via `flutter_local_notifications`. Users configure in Settings: toggle on/off, pick time (default 7 PM), optional custom message. If no custom message, rotates between 5 default prompts. Initialized in `main()` via `DailyReminderService.init()` which re-schedules if enabled. Uses `timezone` package for `zonedSchedule` with `matchDateTimeComponents.time`.

**Critical:** `DailyReminderService` shares the same `FlutterLocalNotificationsPlugin` instance as `NotificationService` via `setSharedPlugin()` — having two separate instances causes the second `initialize()` to break the first's scheduling callbacks on Android. The plugin is initialized once in `NotificationService.init()`, then shared via `DailyReminderService.setSharedPlugin(NotificationService.plugin)` in `main.dart`.

**Exact alarm fallback:** On Android 14+, `SCHEDULE_EXACT_ALARM` requires explicit user grant. The service checks `canScheduleExactNotifications()` first — if denied, falls back to `inexactAllowWhileIdle` (fires within ~15 min window, fine for daily reminders). Never calls `requestExactAlarmsPermission()` automatically as it navigates away from the app.

## Category Icons

Users can pick from 120+ curated emojis organized by group, OR type/paste any emoji from the system keyboard via the text field at the top of the picker. The `CategoryIcon` widget resolves display priority: PNG asset by name match → emoji → first-letter fallback.

## UI Consistency

### Screen Design Patterns
- **Tab screens** (Dashboard, Activity, Budget, Reports, More): no back button. Home, Budget and More use `LargeTitleHeader` (`lib/shared/widgets/large_title_header.dart`) as the first sliver — Cashew's PageFrame title that shrinks from 28pt into a pinned 56px bar on scroll (actions stay top-end, optional subtitle fades). It pads for the status bar itself — no SafeArea around it.
- **Sub-screens** (Recurring, Subscriptions, Templates, Categories): Custom SafeArea header, 24px bold title, back IconButton, filter chips, summary banner, pull-to-refresh
- **Detail/form screens** (Account detail, Allocation detail, etc.): Standard AppBar with auto back

### Standard Widgets
- Loading: `SkeletonList` (Cashew ghost rows: circle + bars, theme-aware shimmer) for lists, `CircularProgressIndicator` for detail screens
- Empty: `EmptyState` widget everywhere (icon in a 96px pastel circle, 18/w700 title, pastel action)
- Error: `ErrorRetry` widget everywhere
- Cards: Use `AppCard` widget or `CardTokens.radius` (14) + `CardTokens.padding` (16h, 14v) + `AppColors.sf(context)` bg + `AppColors.bd(context)` border
- Section headers: Use `SectionHeader` widget or `TypographyTokens.sectionHeaderSize/Weight/LetterSpacing`
- Screen titles: `TypographyTokens.screenTitleSize` (24) + `TypographyTokens.screenTitleWeight` (w800)
- Chips: Pill-shaped (20px radius), colored border+bg when selected
- SnackBars: Always `behavior: SnackBarBehavior.floating`. The theme makes them Cashew popups (popup surface, dark text, accent action) — don't pass a saturated `backgroundColor` (the theme's dark text would be unreadable on it); errors use the same style.
- Accent-colored text (section headers, links): `AppColors.accentText(context)` — lifted in dark mode for contrast.
- All list screens have `RefreshIndicator`

### Navigation
- `MainScreen` uses a lazy `IndexedStack` (tabs built on first visit, then kept alive) — tab switches are instant like Cashew. Re-tapping the active tab scrolls its `PrimaryScrollController` to the top.
- `PopScope` checks `GoRouter.canPop()` so pushed routes (funding, accounts, etc.) pop correctly instead of exiting the app

## Health Check

`lib/features/settings/health_check_screen.dart` — accessible from Settings > Health Check (`/health-check` route).

Three levels in one screen:
- **Level 1 (Detect):** Balance invariant per currency (green/red), orphan ledger count, backup status, transaction/ledger counts
- **Level 2 (Diagnose):** Per-currency expected vs actual unallocated, list accounts with balances, list envelopes with ledger sums, highlight mismatches
- **Level 3 (Repair):** "Repair Balances" button creates adjustment ledger entries for the largest allocation in each affected currency. "Purge Deleted" hard-deletes soft-deleted transactions. Export diagnostic JSON via share sheet.

## Soft Delete

Transactions use a `deleted` boolean column (schema v12) instead of hard deletion. `AllocationEngine.deleteTransaction()` sets `deleted = true` and removes ledger entries. All transaction queries filter `deleted = false` except sync export (which includes deleted rows so they propagate across devices). The Health Check screen offers a "Purge" action to permanently remove soft-deleted transactions (also cleans up receipt files).

### Undo Delete
Every transaction delete — swipe left, the detail screen's Delete, the selection bar — goes through `deleteTransactionsWithUndo()` (`features/transactions/widgets/delete_with_undo.dart`) and shows a 5-second SnackBar with "Undo" (no confirm dialog for single deletes). A swiped row is hidden at once via `_swipedIds` so the Dismissible leaves the tree before the provider updates. The flow: mark `deleted=true` directly (preserving ledger entries), show SnackBar. If user taps Undo, restore `deleted=false`. If SnackBar closes without undo, call `engine.deleteTransaction()` to remove ledger entries permanently. This two-phase approach prevents data loss on accidental deletes.
Every delete/undo write also bumps `lastModified` (sync merges by it — without the bump a delete never reaches other devices). If the app dies before the SnackBar closes, `main.dart` runs `LedgerDao.deleteForDeletedTransactions()` at startup; balance queries ignore ledger rows of deleted transactions anyway.

## Animation Widgets

### AnimatedAmount
`lib/shared/widgets/animated_amount.dart` — count-up/down effect for currency amounts using `IntTween` on cents for smooth integer stepping. `lazyFirstRender: true` (default) skips animation on first build — only animates on subsequent value changes. Used on dashboard totals (income, expense, net worth, unallocated).

### AnimatedCircularProgress
`lib/shared/widgets/animated_circular_progress.dart` — custom-painted circular progress ring with overspend indicator. Main arc (0-100%) in `color`, second arc overlay in `overspendColor` for values > 100%. AnimationController at 1500ms with `easeInOutCubicEmphasized`. Used on allocation cards for envelopes with targets.

### RollingNumber
`lib/shared/widgets/rolling_number.dart` — odometer-style rolling digit animation. Each digit scrolls independently (rightmost fastest, leftmost slowest). Non-digit characters (currency symbols, separators) crossfade. Wraps around 0↔9 via shortest path. Used on dashboard net worth and unallocated amounts.

### Tappable
`lib/shared/widgets/tappable.dart` — Cashew-style touch wrapper. iOS: opacity fade to 0.5. Android: InkSparkle ripple. Defaults are calm (`scaleFactor: 1.0`, `haptic: false`) for cards and rows; pass a scale < 1 and `haptic: true` only for button-like surfaces (quick actions, templates, keypad). Long-press always fires a heavy haptic.

### FadedEdges
`lib/shared/widgets/faded_edges.dart` — ShaderMask-based gradient fade at scroll boundaries. Supports top/bottom/start/end fades. Used on transaction month tabs for smooth horizontal scroll fade.

### ErrorBoundary
`lib/shared/widgets/error_boundary.dart` — wraps child subtree; shows friendly fallback ("Something went wrong" + Try Again + Go Back) when `_hasError` is set. Does NOT override `ErrorWidget.builder` (that causes `_dependents.isEmpty` crash). Error catching handled by `FlutterError.onError` in main.dart.

### BreathingWidget
`lib/shared/widgets/breathing_widget.dart` — pulsing scale animation (1.0→1.15, 2500ms, repeating). Set `active: false` to render statically.

## Spending Heatmap

`lib/shared/widgets/spending_heatmap.dart` — GitHub-style activity grid showing daily spending intensity. Green = net positive (income > expense), red = net negative, gray = no activity. Horizontal scroll, month labels, tooltips on tap. Data from `dailySpendingProvider` (SQL query grouped by day). Displayed in Reports Overview tab.

## Bill Splitter

`lib/features/transactions/bill_splitter_screen.dart` — More > Bill Splitter or the Split quick action (`/bill-splitter`, premium). Three steps in one flat ListView: Items (scan or manual; amounts via `showCalculatorSheet`, never the keyboard) → People + assignment (items start unassigned; "Everyone" chip; alone, every item is the user's) → Review.

- `_people.first` is the user ("Me") and can't be removed — its share is what gets saved.
- `_calculateBreakdown()` → items (discounts are negative items), tax & service (`_taxIsAmount`/`_taxPercent`, proportional to each person's items), tip (percentage proportional, fixed amount even). `_calculateSplits()` rounds per person with largest-remainder so shares sum to the rounded total.
- **Who paid** (`_PaidMode`): `me` → pushes the classic form with the user's share + one line per person (`billLinePart`), then on a saved txId creates a `lent` loan per person in `objectives` (bill currency); `other` → no transaction, a `borrowed` loan to the payer for the user's share; `each` → the user's share only. Only `context.pop()` after a save — a closed form leaves the bill intact.
- Share split → `SharePlus` text. Back steps back, then asks before discarding (`PopScope`). Bill currency change prefills the rate (`rateToBaseOrOne`); rate fields parse with `parseLooseAmount`.
- OCR (`lib/shared/utils/ocr_service.dart`, ML Kit, offline): lines merged by Y-position, classified by `OcrLineKind` (item/discount/tax/total/other) from EN/FR/AR (+ES/DE) keywords; letters counted with `\p{L}` so Arabic names survive. `OcrResult.receiptTotal` (largest total) drives the step-1 total check; `taxTotal` prefills tax when items + tax match the receipt total. Tests: `test/features/ocr_service_test.dart`.

## Customizable Dashboard

`lib/core/providers/dashboard_layout_provider.dart` — `DashboardSection` enum with 4 sections (quickActions, spending, money, activity). Each section has visibility toggle. Order + visibility persisted to SharedPreferences as JSON. `DashboardLayoutNotifier` provides reorder/toggle/reset methods.

Dashboard flow: Quick Actions (top) → Spending Overview (donut + income/expense/net + spending insight) → Your Money (Cashew Upcoming/Overdue bill boxes from `widgets/bills_boxes.dart`, then compact net worth | unallocated split card) → Activity (templates + recent transactions). Bill boxes: Upcoming = enabled recurring due within 7 days; the Overdue box only appears when something is past due (the recurring engine normally posts due bills at launch); only base-currency amounts are summed. Donut slices that share a color (subcategories inherit the parent's) get shifted shades. Status card and envelope health were removed — those live in Reports > Insights and Budget tab respectively.

`lib/features/dashboard/dashboard_customize_sheet.dart` — bottom sheet with `ReorderableListView`, drag handles, and visibility switches. Opened via the tune icon in the dashboard header.

## Transaction Selection

Cashew-style: long-press a transaction to enter selection mode (there is no context menu). Tap rows to select/deselect; adjacent selected rows merge into one highlighted block, with an animated check circle. The selection bar replaces the header and shows count, Edit + Duplicate (exactly one selected) and Delete (with Undo). Edit (selection bar, swipe right, detail screen) and Duplicate open the form with `txFormArgs()` (`widgets/tx_form_args.dart`) — every line, rate and both transfer accounts; the edit form reloads the transaction's receipts from the DB so they carry over. Changing month clears the selection. Swipe gestures are disabled during selection mode. Rows are the shared `TxTile` widget (`lib/features/transactions/widgets/tx_tile.dart`), also used for the dashboard's recent transactions (`showBalance: false, showDate: true`).

## Activity Tab FAB

The + FAB on the Activity tab uses a custom `Material` + `InkWell` circle (not `FloatingActionButton`) so both `onTap` and `onLongPress` work reliably. Tap opens expense form directly (most common action). Long-press opens a type picker bottom sheet (expense/income/transfer). **Never wrap `FloatingActionButton` with `GestureDetector(onLongPress:)`** — the FAB's internal `InkWell` swallows the long-press gesture.

## Finding & Fixing Transactions

- Activity tab reads `transactionEntriesProvider` (all months) instead of the monthly provider while `_allMonths` (search text, date range, or a "See all" request); the "All months" chip clears the request.
- Filters: type, account (`_accountFilter`: header, destination or any line), category (also matches subcategories), date, amount (`parseLooseAmount`). Closed panel → `_buildActiveFilters()` chips + Clear all; `_clearAllFilters()`.
- **See all** (account detail, envelope detail): `activityFilterRequestProvider` (`core/providers/activity_filter_provider.dart`) → `MainScreen` switches to Activity → `TransactionsScreen._applyFilterRequest` (also on first build, since tabs are lazy).
- Selection ⋮: Select all (`_lastFiltered`), bulk category/account/date via `AllocationEngine.rewriteTransaction()` (re-records through `recordTransaction` + soft-deletes the old row, receipts carried; transfers: date only), Export CSV (`shareEntriesCsv`, one row per line in its own currency).
- Detail screen uses `transactionByIdProvider(id)` (single row, no running-balance replay) and has Duplicate in ⋮. Envelope ledger rows, Reports drill-down rows and donut slices are tappable.

## Transaction Flash

When adding a transaction via the classic form, the new transaction ID is passed back via `context.pop(txId)`. The transactions screen highlights the matching tile with a 1.5-second accent glow fade-out using `AnimatedContainer`.

## Search Debounce

Transaction search uses a 400ms `Timer` debounce to avoid excessive `setState` calls during typing. Timer is properly disposed.

## Filter Persistence

Transaction type filter (All/Income/Expense/Transfer) is saved to SharedPreferences and restored on screen init. Persists across sessions.

## Confetti Celebration

Flexible envelopes with a target trigger a 2-second confetti burst (via `confetti` package) when their balance reaches the target amount. Plays once per screen visit. `ConfettiWidget` overlaid at top-center of the allocation detail screen with explosive blast direction.

## Duplicate Detection

Both the assisted flow and classic form check for duplicate transactions before saving. If a transaction with the same amount, category, and date already exists, a "Possible Duplicate" dialog shows the matched transaction's title, amount, and date so the user can compare before confirming. Skipped when editing existing transactions or for transfers.

## Transfer Display

Transfers render as a single row in the transaction list (not two rows). Shows "Source → Destination" as the title with two sub-lines: source account with amount (red dot) and destination account with converted amount (green dot). Amounts shown in each account's native currency.

## Theme System

`buildLightTheme(fontName, [accentColor])`, `buildDarkTheme(fontName, [accentColor])`, and `buildBlackTheme(fontName, [accentColor])` in `app_theme.dart` generate full ThemeData. `buildBlackTheme` derives from dark with pure black overrides. Font selection is dynamic via `fontProvider`. Default font: Nunito Sans (`defaultAppFont`, closest to Cashew's Avenir). Available: Plus Jakarta Sans, DM Sans, Inter, Poppins, Nunito, Rubik, Space Grotesk.

All three themes come from one `_buildTheme()`; surfaces are fixed warm neutrals (paper `#F7F5F1`/white in light, night `#121318`/`#1C1D24` in dark, pure black in black) — not accent-tinted — exposed through the `SurfaceColors` theme extension, which `AppColors.bg/sf/sfv/popup/bd` read. The accent lives in fills, text, buttons and the brand banner. Inputs are borderless filled (radius 15), dialogs radius 25, sheets radius 20 with no drag handle, buttons radius 20 (`RadiusTokens`).

**Theme modes:** `themeModeProvider` stores a String (`'system'`/`'light'`/`'dark'`/`'black'`). `flutterThemeMode` getter maps black → dark for Flutter's ThemeMode. `isBlackMode` getter for AMOLED-specific logic. `app.dart` must `ref.watch(themeModeProvider)` for the state (not `.notifier`) to rebuild on theme change.

### Design Tokens
`lib/shared/theme/design_tokens.dart` defines the single source of truth:
- **Spacing**: xs(4), sm(8), md(12), lg(16), xl(24), xxl(32), sectionGap(16), headerToCard(8)
- **CardTokens**: radius(16), paddingH(16), paddingV(14), borderRadius, padding
- **RadiusTokens**: sm(8), md(12), lg(16), pill(20), sheet(24) — for elements that need different radii than cards
- **Durations**: fast(150ms), standard(250ms), emphasis(350ms) — animation timing
- **CategoryIconTokens**: listSize(48), compactSize(36), heroSize(64)
- **TypographyTokens**: screenTitle(28/w800), sectionHeader(13/w700/ls0.8), cardTitle(15/w600), amountLarge(24/w700), amountDisplay(18/w800), amountRegular(15/w700), amountSmall(13/w600), body(14/w400), caption(12/w500), overline(11/w600), mini(10/w500), txTitle(15/w600), txSubtitle(12/w400), dateHeader(14/w600)
- **InputLimits**: nameMaxLength(100), noteMaxLength(500), maxAmount(1e9)

### Color Palette
- Accent: user-selectable pair from `brandPalette` (`lib/shared/theme/brand_palette.dart`), default **Gold** (bright `#E3AD45` / deep `#8A5E0F`)
- Expense/Overspent: `#DC2626` (Deep Red)
- Income/Healthy: `#059669` (Deep Emerald)
- Caution: `#D97706` (Deep Amber)
- Light bg: `#F7F5F1` (paper), Dark bg: `#121318` (night), Black bg: `#000000`
- Text: light `#1C1A16` / `#6B655B`, dark `#F2EEE6` / `#A8A49B` (warm neutrals)

### Shared Layout Widgets
- `SectionHeader` (`lib/shared/widgets/section_header.dart`): sentence case, 15px w700, accent color, optional trailing action
- `AppCard` (`lib/shared/widgets/app_card.dart`): theme-aware bg/border, radius 16, standard padding, optional onTap

## More Tab Structure

The More tab is split into two screens:

**More page** (tab) — feature hub:
- Grouped list (`_MoreGroup` cards of `_MoreRow`s with dividers): **Money** (Accounts, Categories, Recurring & Bills, Subscriptions, Planned Payments), **Tools** (Goals & Loans, Bill Splitter, Travel Exchange, Web Companion), **App** (Settings, Help, About). Rows: icon circle, name, one-line description, chevron. Icon colors come from `HSLColor` hues at one shared saturation/lightness — don't hand-pick hex colors (they turn muddy as pastels).
- Backup reminder: one slim amber row (message · Backup Now · dismiss) above the groups
- App group: Settings & Customization → navigates to `/settings`
- Help Guide → navigates to `/help` (WebView loading bundled `assets/web/help.html`)
- About PocketPlan
- Household name + currency shown as subtitle under "More" header (no separate card)

Bill Splitter is also accessible from: Dashboard quick actions ("Split" button) and long-press on the Activity tab FAB.

**Settings screen** (`/settings`) — all configuration. Rows are flat Cashew `SettingsContainer`s (`_SettingsTile`: transparent Material + ListTile, 42px pastel icon circle, 16/w700 title) — never wrap a ListTile in a colored DecoratedBox (hides the ripple).
- **APPEARANCE**: Theme (System/Light/Dark/Black), Colors, Entry Mode, Auto-fill, Start Screen, Font, Text Size, Transaction List layout
- **DATA**: Cloud Sync, Share Household, Backup & Restore, Import & Export, Notifications, Health Check
- **PREFERENCES**: Household Name, Base Currency, Period Start Day, Currency Symbols, Number Format, Date Format
- **SECURITY**: Biometric Lock

Bill Splitter is also accessible from: Dashboard quick actions ("Split" button) and long-press on the Activity tab FAB.

## Onboarding

3-page flow: Welcome (how-it-works + Restore/Join buttons) → Setup (household name, currency, period day, account + expandable "More options" for categories & entry mode) → Done. Setup uses `db.batch()` for atomic account + category creation. Field-level validation shows amber error text when household or account name is empty, cleared on typing.

## Faster Logging

- **Last used account**: `LastUsedService` (`core/services/last_used_service.dart`) stores the last account and transfer pair; both forms apply it to new transactions (`_applyAccountDefaults`). `_accountIsDefault` marks a defaulted account so category/title auto-fill may still replace it; picking an account by hand clears the flag.
- **Classic form**: Save & new (`_save(addAnother: true)` → `_resetForNext()`), Undo action on the Saved SnackBar for new transactions (`_undoSaveAction`), ⇅ swap on the transfer card, `DateQuickChip` (Today/Yesterday, shared with assisted), discard guard (`PopScope(canPop: false)` + `_signature()` compared at pop time — typing doesn't rebuild), prefilled foreign lines fetch a rate after the first frame.
- **CategorySheet** takes `initialType` and `recentIds` (`recentCategoryIds()`); the assisted picker shows the same recents as chips.
- **Calculator**: a prefilled amount is highlighted (`_prefilled`) and replaced by the first digit.
- **Assisted**: `initialDate`/`initialTitle` params (quick-add title, viewed month), Enter on the title step continues, editable title row on the amount step, × removes the active item chip, the autofilled amount survives `_showAmountScreen()`.
- **Activity tab**: new transactions in a past month are dated its last day (`_newTxDate()`); quick add flashes the new row.
- **Notification/shortcut routing**: payloads are routes; `NotificationService.openRoute` (ValueNotifier) is set by taps (and cold-start launch details) and by `AppShortcutsService` (quick_actions: add transaction, fund envelopes, upcoming bills); `app.dart` pushes it.

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
- "Pending" (`PeriodResetService.getPendingManualIds`) = manual, periodic, created before the current period start, positive balance, and no `period_reset`/`carry_forward` ledger row since the period start — reviewing (the `carry_forward` marker counts) clears it until the next period. The Review screen (`/period-transition`) lists only pending envelopes and invalidates `pendingResetProvider` when done.
- `PeriodResetService.checkAndAutoReset()` runs once per app launch, tracked via SharedPreferences timestamp. The first run on an install only records the period (never empties envelopes mid-period). Reset ledger rows use the deterministic id `reset:<allocId>:<periodStart yyyy-MM-dd>:<currency>` inserted with `insertOrIgnore`, so two synced devices can't reset the same envelope twice. Period bounds come from `budgetPeriodFor()` (clamped start day).

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
- **Progress** (`currentAmount`) is recomputed from the tagged payments' lines in the objective's currency each time the detail screen loads or a payment is recorded (`_syncCurrentAmount`) — never `+= amount`, which lost payments across synced devices and ignored deletions.
- **Payment history**: payments are linked by `[obj:UUID]` tag embedded in the transaction note. Query searches by ID tag first, falls back to name matching for legacy payments. The tag is stripped from display. Renaming an objective does not break payment history.
- **Loan direction hint**: a text hint below the direction toggle explains what each direction means ("You gave money — payments are incoming" / "You owe money — payments are outgoing").

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

## Accent Color (brand palette)

`lib/shared/theme/brand_palette.dart` + `lib/core/providers/accent_color_provider.dart`.

- **8 tuned pairs** (`AccentPair`): Gold (default), Wax red, Copper, Sage, Teal, Sapphire, Plum, Rose. Each has a `bright` tone (dark/black mode, and filled brand surfaces in every mode), a `deep` tone (light-mode text/icons/buttons — bright tones fail contrast on white), and a `lightFill`/`darkFill`. Plus `'system'` (Material You via `DynamicColorBuilder`; falls back to Gold when unavailable).
- The provider stores the pair id (`accent_color` pref). Old values ('default' Royal Blue or a hex) migrate to the nearest pair by hue on load.
- **`AppColors.accent` is mutable and mode-dependent**: `AppColors.setAccent(pair, system:)` + `applyMode(isDark)` (called in app.dart's build and again in the MaterialApp builder once the real brightness is known) set `accent` (deep/bright), `accentLight` (fill), `accentBright`, `onAccent`. `accentText(context)` is just `accent` for pairs.
- Light and dark `ThemeData` are built with different accents (`buildLightTheme(font, pair.deep, pair.lightFill)`, `buildDarkTheme(font, pair.bright, pair.darkFill)`); `colorScheme.onPrimary`, FilledButton and FAB foregrounds use `AppColors.inkOn(accent)`.
- **Ready to assign banner** (Budget tab, `_UnallocatedBanner`): `accentBright` fill with `brandInk` text in every mode, ink pill "Assign" button → `/funding`. It's the signature brand element — don't make it dark in light mode (user rejected that).
- Settings > Appearance > Accent Color: 4-column grid of split swatches (bright | deep halves) + System row.

## Per-Account Decimal Precision

`accounts.decimalPlaces` (nullable int) — overrides the default decimal display for a currency.

- **Auto-detect**: `currencyDecimals()` in `format_number.dart` returns ISO 4217 defaults (0 for JPY/KRW, 3 for BHD/KWD, 2 for everything else)
- **Manual override**: Account detail form has a "Decimal Places" dropdown (Auto / 0 / 1 / 2 / 3)
- `formatAmount()` and `formatSignedAmount()` both respect currency-specific decimals automatically

## Transaction Status

`transactions.status` (nullable TEXT) — supports upcoming/skipped bills and planned payments.

- `null` = normal posted transaction (default, backward compatible)
- `'upcoming'` = pending bill generated but not yet confirmed
- `'skipped'` = user skipped this occurrence
- `'planned'` = user-created planned future payment (not yet posted)
- Field is synced across devices and exposed in web companion API
- **All balance/report queries must filter `status IS NULL`** to exclude non-posted transactions

## Planned Payments

`lib/features/planned/` — plan future one-time payments without affecting current balances.

- **Entry**: More > Planned Payments > + FAB opens `plan_payment_screen.dart`
- **Form fields**: type, amount (calculator), account, category, title/note, target month + optional exact date
- **Storage**: normal transaction with `status = 'planned'`, excluded from all balance/report queries
- **Posting**: swipe right or tap "Post" — creates a real transaction via AllocationEngine (with proper ledger entries), then soft-deletes the planned one. Order: create first, delete after (prevents data loss on failure).
- **Post All**: month header button posts all planned items for that month in batch
- **Transaction list**: planned items appear dimmed at top of target month, excluded from daily totals
- **Envelope preview**: Budget tab shows `$X planned` on envelope cards when planned expenses exist for linked categories
- Routes: `/planned-payments`, `/plan-payment`

## Upcoming Bills

`lib/features/recurring/upcoming_bills_screen.dart` — shows all enabled recurring transactions sorted by next due date.

- **Urgency indicators**: Cashew blues — indigo `#6577E0` "Overdue by N days", blue `#58A4C2` "Due today/tomorrow/in N days" (lighter variants in dark mode). No red/amber/green alarm colors.
- Displays frequency, amount, type icon per bill
- Route: `/upcoming-bills`, accessible from More > Upcoming Bills

## Fonts

Default font: **Nunito Sans** (closest to Cashew's Avenir). Available: Plus Jakarta Sans, DM Sans, Inter, Poppins, Nunito, Rubik, Space Grotesk. These are body fonts; titles and hero amounts always use the bundled display face **Bricolage Grotesque** (`TypographyTokens.displayFamily`).

## Number & Date Formatting

### Number Format
`formatAmount()` and `formatSignedAmount()` in `format_number.dart` respect user preferences for thousands separator (comma/period/space/none), decimal separator (period/comma), and negative format (minus `-$100` or parentheses `($100)`). `formatNumber()` formats plain numbers (exchange rates, converted amounts) with the same separator prefs. `currencyDecimals()` returns ISO 4217 defaults (0 for JPY, 3 for KWD, 2 for everything else). Settings apply instantly via global `setNumberFormatPrefs()` called from `app.dart` on provider change.

### Date Format
`formatDate()` and `formatDateSmart()` in `date_format_provider.dart` use the user's preferred pattern. Global `setDateFormatPattern()` called from `app.dart`. All user-facing date displays use `formatDate()` — month-only headers (`MMMM yyyy`) and machine formats (`yyyy-MM-dd`) are intentionally hardcoded. Settings apply instantly without restart.

### Key Rules
- Parsing typed/imported amounts: `parseLooseAmount()` (format_number.dart) accepts `1,234.56`, `1.234,56`, `12,50`, `(5)`. Times: `TimeOfDay.format(context)` (follows the device 12/24h setting), never a hardcoded `h:mm a`.
- Never use `toStringAsFixed()` for user-visible currency amounts — use `formatAmount()` or `formatNumber()`.
- Never use `DateFormat('...')` for user-facing full dates — use `formatDate()`.
- Input fields (TextControllers) and percentages may use `toStringAsFixed()` since they need `.` for parsing.
- Month-only labels (`MMMM`, `MMM yyyy`) stay hardcoded — they're contextual, not configurable.

## Archived Envelopes

`recordTransaction()` ignores archived/deleted envelopes when resolving category → envelope (the line stays unbudgeted). Budget tab ⋮ menu → **Archived envelopes** (`archived_envelopes_sheet.dart`) lists them with Unarchive (`AllocationsDao.unarchive`). Envelope cards resolve their category through `categories.allocationId` (top-level category first), falling back to the legacy `allocations.categoryId` join.

## Exchange Rates Screen

`/exchange-rates` (Settings › Preferences › Exchange rates) lists every currency used by accounts, recurring items and manual rates. Refresh calls `getRateWithCache(forceRefresh: true)`. Tapping a currency sets a **manual rate** (`fx_rates.source = 'manual'`, `FxService.saveManualRate/clearManualRate`); `manualRate()` is checked first by `getRateWithCache()` and `latestCachedRate()` in either direction, so it wins until cleared. Lines saved without a user rate use `rateToBaseOrOne()` (live → cached → 1.0); a foreign line still at 1.0 shows an amber "No rate" tag in `TxTile`.

## Archived Accounts

An account can only be archived at a zero balance (`_canArchive()` in account_detail_screen.dart) — archived accounts drop out of every balance, so archiving one with money would silently pull it out of Unallocated. Accounts screen has a 3-dot menu with "Show Archived" / "Hide Archived" toggle. Archived accounts appear in a separate "ARCHIVED" section below active ones, dimmed at 60% opacity with an archive badge. Each has an unarchive icon button that opens a confirmation dialog, sets `archived: false` + `lastModified: now`, and refreshes the provider.

## Unallocated Multi-Currency Display

The Ready to assign banner (unallocated money) on the Budget tab shows only the base currency amount by default. If the user has unallocated funds in other currencies, a "+ N other currencies" link and chevron arrow appear. Tapping expands an animated breakdown showing each currency with its amount. This avoids the anti-pattern of converting/summing across currencies with unreliable exchange rates. Single-currency users see no extra UI.

## Reports Categories Tab

Cashew layout: pill toggle (Top spending / Top transactions) → donut (`_CategoryPie`, total in the center) → `_CategoryRow` entries (real `CategoryIcon`, amount with base-currency symbol, thin `BudgetProgress` share bar, "N% · N transactions", month-over-month change). Repeated colors get distinct shades via `_distinctColors()`. The hub's tab bar uses a pastel pill indicator.

## Reports Month Navigation

All report tabs (Overview, Categories, Insights) have a `_MonthNav` widget with left/right arrows and swipe gesture support. Users can browse any past month. The `reportStatsProvider.monthRange()` accepts an optional `from` parameter so the 6-month trend chart centers around the selected month. `_DailyPaceChart` accepts an optional `month` parameter — for past months it shows full-month data instead of stopping at `now.day`. The Insights tab filters spending velocity, biggest expense, and savings rate to the selected month using proper `monthStart`/`monthEnd` range checks.

## Help Guide

`assets/web/help.html` — comprehensive user guide bundled in the app. 17 sections covering every feature with step-by-step instructions. Responsive (desktop sidebar + mobile hamburger), dark mode support, screenshot placeholders.

**In-app delivery:** `lib/features/settings/help_screen.dart` — `WebView` loads the HTML from `rootBundle`. Injects dark mode CSS variables based on current app theme. Supports deep-linking to sections via `?section=` query parameter (e.g., `context.push('/help?section=envelopes')`).

Route: `/help`, accessible from More > Help Guide.

## i18n (Internationalization)

Fully wired for 3 locales: **English**, **Arabic**, **French**. Language picker in Settings > Appearance.

### Flutter App
- `lib/l10n/app_{en,ar,fr}.arb` — ~1,800 keys per locale (unused keys pruned Oct 2026)
- Generated `S` class at `lib/l10n/generated/app_localizations.dart`, accessed via `S.of(context).keyName`
- `l10n.yaml` configures ARB dir, output class `S`, `nullable-getter: false`
- `lib/core/providers/locale_provider.dart` persists language choice to SharedPreferences
- `lib/l10n/s_lookup.dart` — `currentS()` helper for services/engines without BuildContext (reads `Intl.defaultLocale`)
- `Intl.defaultLocale` set in both `main.dart` (before engine/notification init) and `app.dart` (on locale change)
- Numbers always use Western numerals (0-9) via `locale: 'en_US'` in NumberFormat — standard for finance apps even in Arabic

### Web SPA
- `assets/web/locale_{en,ar,fr}.json` — ~250 web keys (snake_case), generated from the CSV by `csv_to_web_json.dart`; every web key must exist in the ARBs or regeneration drops it
- `t(key, params)` function in `app.js` for string lookup with `{param}` substitution
- `loadLocale(lang)` fetches JSON on init, persists in `localStorage`

### Tooling
```bash
# Convert CSV → ARB files (snake_case → camelCase, auto-detects {param} placeholders)
dart tool/csv_to_arb.dart

# Convert CSV → web JSON locale files
dart tool/csv_to_web_json.dart

# Regenerate Flutter S class from ARB files
flutter gen-l10n

# Local translation editor (browser-based, reads/writes CSV)
dart tool/translation_editor.dart   # then open http://localhost:4488
```

### Key Rules
- `docs/i18n_strings.csv` is the master source (~1,800 strings, synced with the ARBs in Oct 2026). Update CSV first, then run tooling. `csv_to_arb.dart` keeps each key's placeholder types from the current `app_en.arb` (`int`, plurals) instead of guessing from names, and turns the CSV's literal `
` back into real newlines — the round trip CSV → ARB is lossless. ARB values never start/end with spaces (the CSV trims them): put separators like ` · ` in the template or the code.
- Glossary: "Ready to assign" = FR « Prêt à répartir » / AR «جاهز للتوزيع»; Web Companion = FR « Compagnon Web » / AR «المرافق الإلكتروني». French quotes are « … », Arabic «…». Android notification channel names come from the ARBs (`notifAlertsChannel`, `notifReminderChannel`, `wcForegroundChannel`) since they show in system settings.
- Currency names in the picker come from `currencyName(S, code)` (`currency_sheet.dart`, keys `currencyName<Code>`); search matches the code, the translated and the English name. A new currency in `kCurrencies` needs a key.
- No duplicate keys in an ARB (the last one silently wins). Counts use ICU plurals (`{n, plural, =1{…} other{…}}`; Arabic also `=2`/`few`/`many`).
- Every feature addition/change must update `docs/i18n_strings.csv`, ARB files, and `assets/web/help.html`.
- **Never use `S.of(context)` inside `StatefulBuilder` within `showModalBottomSheet`** — capture `final tr = S.of(context)` BEFORE the sheet to avoid `_dependents.isEmpty` crash.
- Use `currentS()` from `s_lookup.dart` in services/engines without BuildContext.
- Category presets use `translatedName(S s)` — categories are created in the user's language during onboarding.

### RTL Support (Arabic)
- `EdgeInsetsDirectional.only(start:/end:)` for directional padding (not `left:/right:`)
- `AlignmentDirectional.centerStart/centerEnd` for directional alignment
- Transfer arrows use direction-aware `→`/`←` based on `Directionality.of(context)`
- Month swipe gestures invert in RTL
- Widgets that draw a number one character per widget (e.g. `RollingNumber`) must force `TextDirection.ltr` on their Row, or amounts print backwards in Arabic
- Asymmetric paddings use `EdgeInsetsDirectional.fromSTEB`, never `EdgeInsets.fromLTRB` (charts excepted — fl_chart doesn't mirror)
- `FadedEdges` gradient resolved directionally
