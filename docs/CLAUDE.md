# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PocketPlan** — A YNAB-style envelope budgeting app for Android and iOS. Offline-first, built in Flutter with Drift (SQLite), Riverpod state management, and GoRouter navigation. Single-user consumer app with optional cloud sync via Google Drive or system file picker (Dropbox/OneDrive).

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
│   │   ├── app_database.dart   # Drift database definition (schema v9)
│   │   ├── app_database.g.dart # Generated code (do not edit)
│   │   ├── daos/               # Data access objects (accounts, transactions, allocations, ledger)
│   │   └── tables/             # Table definitions (11 tables)
│   ├── engine/
│   │   ├── allocation_engine.dart   # Central money flow engine (all writes go through here)
│   │   ├── balance_calculator.dart  # Computes balances dynamically from ledger
│   │   ├── period_engine.dart       # Period transitions and leftover resolution
│   │   └── recurring_engine.dart    # Auto-posts recurring transactions
│   ├── providers/              # Riverpod providers
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
│   │   └── ...
│   ├── sync/
│   │   ├── sync_engine.dart         # JSON export/import/merge
│   │   ├── cloud_provider.dart      # Abstract cloud storage interface
│   │   ├── google_drive_provider.dart
│   │   └── file_picker_provider.dart
│   ├── fx/                     # Currency exchange rates
│   └── services/
│       └── notification_service.dart
├── features/                   # Screen-level code, one folder per feature
│   ├── dashboard/
│   ├── transactions/           # List, add, detail, assisted flow
│   ├── allocations/            # Envelopes: list, detail, funding
│   ├── accounts/
│   ├── categories/
│   ├── reports/                # Hub with 4 tabs: Overview, Categories, History, Cumulative
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
    │   └── page_transitions.dart
    └── widgets/                # Reusable widgets
        ├── allocation_card.dart
        ├── amount_field.dart         # Opens calculator sheet (not keyboard)
        ├── calculator_amount_field.dart
        ├── category_icon.dart        # Maps category names to PNG icons
        ├── empty_state.dart
        ├── error_retry.dart
        ├── skeleton_loader.dart
        ├── staggered_list.dart
        └── ...
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

### Transaction Model
- `transactions` table — header (type, amount, account, date)
- `transaction_lines` table — split lines (amount, currency, category, per-line account)
- `allocation_ledger` table — envelope debits/credits linked to transactions
- Each line can reference a different account (multi-account splits)

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

### Riverpod 3 Providers
- `Notifier<T>` + `NotifierProvider` (not the old `StateNotifier`)
- `AsyncValue.value` (not the old `.valueOrNull`)
- Providers defined with `NotifierProvider<N, T>(N.new)` pattern

### Navigation
GoRouter with `context.push()` / `context.pop()` / `context.go()`. Routes defined in `app.dart`.

### Amount Entry
All amount fields use the calculator bottom sheet (`CalculatorAmountField`), not the system keyboard. The `AmountField` widget wraps this automatically.

### Error Handling
All `.when()` error handlers use `ErrorRetry` widget with user-friendly messages and expandable technical details.

## Database

### Schema Version: 9
11 tables: households, users, accounts, categories, allocations, transactions, transaction_lines, allocation_ledger, recurring_transactions, transaction_templates, fx_rates.

### Migrations
Defined in `app_database.dart` `migration` getter. After schema changes:
1. Increment `schemaVersion`
2. Add migration logic in `onUpgrade`
3. Run `dart run build_runner build --delete-conflicting-outputs`

### Key Columns
Every table has `id` (UUID text primary key). Most have `createdAt`, `lastModified`, `deviceId` for sync support.

## Dependencies (key ones)

| Package | Version | Purpose |
|---------|---------|---------|
| drift | ^2.31 | SQLite ORM |
| flutter_riverpod | ^3.1 | State management |
| go_router | ^17.2 | Navigation |
| fl_chart | ^1.2 | Charts (pie, line, bar) |
| google_sign_in | ^6.2 | Google Drive auth |
| googleapis | ^14.0 | Google Drive API |
| local_auth | ^3.0 | Biometric lock |
| flutter_local_notifications | ^18.0 | Bill/envelope alerts |
| shared_preferences | ^2.5 | Simple key-value settings |

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

## Navigation Bar (5 tabs)
Home | Activity | Budget | Reports | More

Accounts are accessed from More > Accounts.
