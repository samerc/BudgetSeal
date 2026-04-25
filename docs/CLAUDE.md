# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PocketPlan** — A YNAB-style envelope budgeting app for Android and iOS. Offline-first, built in Flutter with Drift (SQLite), Riverpod state management, and GoRouter navigation. Single-user consumer app with optional cloud sync via Google Drive or system file picker (Dropbox/OneDrive). Includes subscription tracking, savings envelopes, age-of-money analytics, and CSV import/export.

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
│   │   ├── app_database.dart   # Drift database definition (schema v12)
│   │   ├── app_database.g.dart # Generated code (do not edit)
│   │   ├── daos/               # Data access objects (accounts, transactions, allocations, ledger)
│   │   └── tables/             # Table definitions (11 tables)
│   ├── engine/
│   │   ├── allocation_engine.dart   # Central money flow engine (all writes go through here)
│   │   ├── balance_calculator.dart  # Computes balances dynamically from ledger
│   │   ├── period_engine.dart       # Period transitions and leftover resolution
│   │   ├── recurring_engine.dart    # Auto-posts recurring transactions
│   │   ├── age_of_money.dart        # Age-of-money metric computation
│   │   └── invariant_checker.dart   # Validates balance invariants
│   ├── providers/              # Riverpod providers (~21 files)
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
│   │   └── tx_colors_provider.dart  # Transaction type color coding
│   ├── sync/
│   │   ├── sync_engine.dart         # JSON export/import/merge
│   │   ├── cloud_provider.dart      # Abstract cloud storage interface
│   │   ├── google_drive_provider.dart
│   │   └── file_picker_provider.dart
│   ├── fx/                     # Currency exchange rates
│   └── services/
│       ├── notification_service.dart
│       ├── auto_backup_service.dart  # Scheduled local DB backups
│       └── daily_reminder_service.dart # Daily transaction logging reminder
├── features/                   # Screen-level code, one folder per feature
│   ├── dashboard/
│   ├── main/                   # Main screen with bottom nav bar
│   ├── transactions/           # List, add, detail, assisted flow
│   ├── allocations/            # Envelopes: list, detail, funding, savings
│   ├── accounts/
│   ├── categories/
│   ├── subscriptions/          # Subscription tracker: list, detail, price history
│   ├── reports/                # Hub with 4 tabs: Overview, Categories, Insights, Balance Sheet
│   ├── recurring/
│   ├── templates/
│   ├── periods/                # Period transition + leftover resolution
│   ├── settings/               # Settings, sync, backup, import/export, about
│   ├── onboarding/             # 3-page onboarding + guided setup
│   ├── splash/
│   └── lock/                   # Biometric lock screen
└── shared/
    ├── theme/
    │   ├── app_colors.dart     # Theme-aware color system (light + dark)
    │   └── app_theme.dart      # Material theme definitions
    ├── utils/
    │   ├── format_number.dart  # Amount formatting with currency symbols
    │   ├── haptics.dart
    │   ├── receipt_helper.dart
    │   ├── page_transitions.dart
    │   ├── app_info.dart
    │   └── responsive.dart
    └── widgets/                # Reusable widgets
        ├── allocation_card.dart         # Envelope card with circular progress
        ├── amount_field.dart         # Opens calculator sheet (not keyboard)
        ├── animated_amount.dart      # Count-up/down currency animation
        ├── animated_circular_progress.dart # Custom-painted progress ring
        ├── breathing_widget.dart     # Pulsing attention animation
        ├── animated_amount.dart      # Animated number transitions
        ├── balance_chip.dart
        ├── calculator_amount_field.dart
        ├── category_grid.dart
        ├── category_icon.dart        # Maps category names to PNG icons
        ├── currency_display.dart
        ├── currency_picker_field.dart
        ├── empty_state.dart
        ├── error_retry.dart
        ├── hint_banner.dart
        ├── pocketplan_logo.dart
        ├── skeleton_loader.dart
        ├── spending_heatmap.dart     # GitHub-style daily spending grid
        └── staggered_list.dart
```

## Core Concepts

### Envelope Budgeting (Allocations)
The primary feature. Money flows: Income → Account → Unallocated pool → Fund envelopes → Spend from envelopes.

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
- Exports all 11 tables as JSON
- Merge by `lastModified` timestamp (newer row wins)
- Supports Google Drive (OAuth) and system file picker (Dropbox/OneDrive/local)
- Auto-syncs on app resume and pause via `WidgetsBindingObserver`
- Restore from sync file during onboarding

## Key Patterns

### Theme-Aware Colors
Always use `AppColors.tp(context)`, `AppColors.ts(context)`, `AppColors.sf(context)`, etc. instead of hardcoded `AppColors.textPrimary`, `Colors.grey.shade200`, etc. The app supports light and dark mode.

### Hex Color Parsing
Always use `AppColors.fromHex(hex)` — cached, single implementation. Never define local `_hexToColor()` functions.

### Theme-Aware Widget Colors
Never use hardcoded `AppColors.surfaceVariant`, `AppColors.textSecondary`, `AppColors.textPrimary`, or `AppColors.textHint` in widget build methods. Use the context-aware methods: `AppColors.sfv(context)`, `AppColors.ts(context)`, `AppColors.tp(context)`, `AppColors.th(context)`. The const versions exist only for const contexts (e.g., default parameter values).

### Riverpod 3 Providers
- `Notifier<T>` + `NotifierProvider` (not the old `StateNotifier`)
- `AsyncValue.value` (not the old `.valueOrNull`)
- Providers defined with `NotifierProvider<N, T>(N.new)` pattern

### Navigation
GoRouter with `context.push()` / `context.pop()` / `context.go()`. Routes defined in `app.dart`.

### Amount Entry
All amount fields use the calculator bottom sheet (`CalculatorAmountField`), not the system keyboard. The `AmountField` widget wraps this automatically.

### Category Selection
Both the assisted flow and classic form use the same `CategorySheet` with: search field, type toggle (Expense/Income), parent/subcategory hierarchy with `CategoryIcon`, keyboard dismiss on scroll. Never use plain chip grids without search.

### Exchange Rate Input
Both forms have a swap button (↕) on the exchange rate field to toggle between "1 USD = X LBP" and "1 LBP = X USD". The `rateInverted` flag tracks direction; `exchangeRateToBase` is stored correctly regardless.

### Error Handling
All `.when()` error handlers use `ErrorRetry` widget with user-friendly messages and expandable technical details.

## Database

### Schema Version: 12
11 tables: households, users, accounts, categories, allocations, transactions, transaction_lines, allocation_ledger, recurring_transactions, transaction_templates, fx_rates.

v9→v10 added `isSubscription` and `priceHistory` columns to `recurring_transactions` for subscription tracking.
v10→v11 added `icon` (nullable TEXT) to `allocations` for envelope emoji icons.
v11→v12 added `deleted` (BOOLEAN, default false) to `transactions` for soft-delete support.

### Migrations
Defined in `app_database.dart` `migration` getter. After schema changes:
1. Increment `schemaVersion`
2. Add migration logic in `onUpgrade`
3. Run `dart run build_runner build --delete-conflicting-outputs`

### Key Columns
Every table has `id` (UUID text primary key). Most have `createdAt`, `lastModified`, `deviceId` for sync support.

## Dependencies (key ones)

Versions below are pubspec.yaml constraints. All packages are at the latest
compatible resolved versions (blocked by riverpod_generator ↔ drift_dev
analyzer conflict — waiting on upstream releases).

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
| confetti | ^0.8.0 | Celebration effects (goal completion) |
| google_mlkit_text_recognition | ^0.15.1 | Offline receipt OCR (bill splitter) |

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

### Home Screen Widget
`SpendingWidget.kt` — shows placeholder spending data. Files in `android/app/src/main/`.

### Google Drive Setup
Requires OAuth client ID configured in Google Cloud Console. Client ID goes in `android/app/src/main/res/values/strings.xml` (or via google-services.json).

## Security

### Google Drive Queries
All Drive API queries use `_escGdql()` to escape single quotes in parameters, preventing GDQL injection. Always use this helper when interpolating values into Drive query strings.

### Biometric Lock
`local_auth` handles authentication. If the device has no biometrics/PIN, the lock screen still calls `authenticate()` (which prompts the user to set up credentials) rather than bypassing.

### Temp File Cleanup
Backup `.db` and export `.csv` files are written to the system temp directory for sharing, then deleted in a `finally` block. Never leave financial data in temp.

### Sync File
The sync file (`PocketPlan_Sync.json`) is plaintext JSON on Google Drive. Not yet encrypted — future improvement.

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
`NotificationService` groups multiple low-envelope alerts into one notification and multiple upcoming-bill alerts into one. Uses fixed notification IDs (1001, 1002) so each check replaces the previous. 6-hour cooldown between checks via SharedPreferences.

### Envelope Currency Handling
- `tx.amount` and `tx.currency` are always in the household's **base currency** — never use them directly for display in envelope contexts.
- For envelope progress/spent calculations, sum **line amounts** that match the envelope's `targetCurrency`, not `tx.amount`.
- Budget summary on the allocations screen only sums base-currency envelopes to avoid mixing currencies.
- The spend button pre-fills the envelope's `targetCurrency`, not `baseCurrency`.
- `AllocationWithBalance.totalInBase` sums raw balances across currencies without conversion — use `balanceByCurrency[currency]` for accurate per-currency display.

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

## Auto Backup

`AutoBackupService` in `lib/core/services/auto_backup_service.dart`:
- Copies `pocketplan.db` to `app_documents/backups/` with timestamped filenames
- Runs on app resume via `AutoBackupService.runIfDue()` in `app.dart`
- User settings: enable/disable, frequency (6h–weekly), retention (3–30 backups)
- Old backups auto-deleted beyond retention limit
- Backup history visible on the Backup & Restore screen with per-file restore/delete

## Linked Transactions

Mixed-type items from the assisted flow (e.g., expense + income in one session) are split into separate transactions but linked via matching `note` + `createdAt` timestamp. The transaction detail screen queries for siblings and shows a "RELATED TRANSACTIONS" section. For transactions with empty notes, the query additionally requires different `type` to avoid false positives.

## Daily Reminder

`DailyReminderService` schedules a daily local notification via `flutter_local_notifications`. Users configure in Settings: toggle on/off, pick time (default 7 PM), optional custom message. If no custom message, rotates between 5 default prompts. Initialized in `main()` via `DailyReminderService.init()` which re-schedules if enabled. Uses `timezone` package for `zonedSchedule` with `matchDateTimeComponents.time`.

### Category Icons
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
- Cards: `BorderRadius.circular(14)`, `AppColors.sf(context)` background
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

OCR service at `lib/shared/utils/ocr_service.dart` — regex parsing of receipt text to extract `(name, amount)` pairs. Filters out non-item lines (totals, tax, headers). Fully offline, no internet needed.

Tip slider (0-30%), per-person summary, "Create Transaction" button pre-fills an expense transaction with split details in the note.

## Customizable Dashboard

`lib/core/providers/dashboard_layout_provider.dart` — `DashboardSection` enum with 6 sections (status, spending, quickActions, money, unallocated, activity). Each section has visibility toggle. Order + visibility persisted to SharedPreferences as JSON. `DashboardLayoutNotifier` provides reorder/toggle/reset methods.

`lib/features/dashboard/dashboard_customize_sheet.dart` — bottom sheet with `ReorderableListView`, drag handles, and visibility switches. Opened via the tune icon in the dashboard header.

## Transaction Selection

Long-press a transaction to enter selection mode. Tap tiles to select/deselect (with checkboxes). Action bar shows count + bulk delete button. Dismissible swipe gestures are disabled during selection mode. Haptic feedback on selection changes.

## Transaction Flash

When adding a transaction via the classic form, the new transaction ID is passed back via `context.pop(txId)`. The transactions screen highlights the matching tile with a 1.5-second accent glow fade-out using `AnimatedContainer`.

## Search Debounce

Transaction search uses a 400ms `Timer` debounce to avoid excessive `setState` calls during typing. Timer is properly disposed.

## Filter Persistence

Transaction type filter (All/Income/Expense/Transfer) is saved to SharedPreferences and restored on screen init. Persists across sessions.

## Confetti Celebration

Savings envelopes trigger a 2-second confetti burst (via `confetti` package) when their balance reaches the target amount. Plays once per screen visit. `ConfettiWidget` overlaid at top-center of the allocation detail screen with explosive blast direction.

## Navigation Bar (5 tabs)
Home | Activity | Budget | Reports | More

Accounts are accessed from More > Accounts.
