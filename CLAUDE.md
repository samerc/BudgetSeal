# CLAUDE.md

Guidance for Claude Code in this repository. This file holds the rules that apply everywhere; each feature's details live in `docs/dev/` — **read the matching file before changing that area, and update it when you change the feature.**

## Project

**BudgetSeal** (Dart package `budgetseal`; repo folder and some docs still say PocketPlan) — a YNAB-style envelope budgeting app for Android and iOS. Flutter + Drift (SQLite) + Riverpod 3 + GoRouter. Offline-first: SQLite is the data store, not a cache; the app works fully without internet. Optional file-based cloud sync (Google Drive, or the system file picker), goals & loans, subscriptions, planned payments, travel wallets, bill splitter with receipt OCR, CSV import/export, and a Web Companion (local WiFi server so a laptop browser can manage the budget).

Toolchain: Flutter 3.47.5 / Dart 3.13, iOS target 15.5 (ML Kit), Android minSdk 26.

| Area | Notes |
|------|-------|
| Envelopes, money rules, currencies, period reset, seals, goals & loans, travel, planned payments, bills | [docs/dev/budget.md](docs/dev/budget.md) |
| Add/edit form, Activity list, selection, filters, autofill, reports | [docs/dev/transactions.md](docs/dev/transactions.md) |
| Bill splitter + receipt OCR | [docs/dev/bill-splitter.md](docs/dev/bill-splitter.md) |
| Design conventions, theme, accent, icons, shared widgets, dashboard, More tab, onboarding | [docs/dev/ui.md](docs/dev/ui.md) |
| Database & migrations, cloud sync, backup/restore, soft delete, health check, security, performance | [docs/dev/data.md](docs/dev/data.md) |
| The sync file's public format (for users and other tools; update with any sync field change) | [docs/file-format.md](docs/file-format.md) |
| Web Companion (server, security, SPA, REST API) | [docs/dev/web-companion.md](docs/dev/web-companion.md) |
| i18n, number & date formatting | [docs/dev/i18n.md](docs/dev/i18n.md) |
| Android/iOS config, home widget, notifications, daily reminder, resume work | [docs/dev/platform.md](docs/dev/platform.md) |

## Commands

```bash
flutter pub get
flutter run -d <device>
flutter build apk --debug            # debug app id com.budgetseal.app.debug ("BudgetSeal Dev")
dart run build_runner build --delete-conflicting-outputs   # Drift/Riverpod codegen
dart analyze lib/
flutter test                         # in-memory DB: AppDatabase.forTesting(NativeDatabase.memory())
flutter gen-l10n                     # after ARB changes
dart run flutter_launcher_icons      # artwork: assets/icon/source/app_icon.svg
```

Manual checklists: `test/manual_test_script.md`, `test/web_companion_test_script.md`.

CI: `.github/workflows/ci.yml` runs on every push to `main` (gen-l10n is current, `dart analyze lib/`, `flutter test`) — keep it green. `test/core/engine/money_model_test.dart` checks every engine change against its own model of the balances; add new money operations to it. `test/scale/big_budget_test.dart` runs the app on three years of data (~10,700 transactions) and times the screens — keep it passing when touching queries. Details: [docs/dev/data.md](docs/dev/data.md#testing-the-money).

## Layout

`lib/app.dart` (routes, lifecycle, auto-sync) · `lib/main.dart` · `lib/core/` (database + DAOs, engines, providers, sync, fx, services) · `lib/features/<feature>/` (screens) · `lib/shared/` (theme, utils, widgets) · `lib/l10n/` (ARBs + generated `S`) · `assets/web/` (Web Companion SPA + `help.html`) · `docs/i18n_strings.csv` (master strings) · `tool/` (i18n + icon scripts).

## Money rules

- **All money writes go through `AllocationEngine`** (`recordTransaction`, `recordTransfer`, `moveMoney`, …). Screens never write transactions, transfers or ledger rows directly.
- Balances are computed from the ledger, never stored. Invariant per currency: `Sum(account balances) = Unallocated + Sum(envelope balances)`. Use the batch methods (`allAccountBalances`, `allAllocationBalancesByCurrency`), never `accountBalance()` in a loop.
- **Never mix currencies**: no summing `targetAmount` or account balances across currencies; group by currency or filter to the base. Base-currency totals skip lines with no real rate (`isRealRate()`).
- **What the columns mean (v23):** every posted income/expense has lines (each in its account's currency, with its own rate); its header `amount`/`currency` is the base-currency total — for display use the lines. A transfer's `amount`/`currency` is what left the source; what arrived is `destinationAmount` — read it as `tx.receivedAmount` (`transfer_amounts.dart`), never `amount × exchangeRateToBase` (that rate is only still written for phones on 0.11). Rows from older versions are converted by `normalizeTransactions()` on open, merge and restore.
- Transaction queries filter `deleted = false` (including `getById()`), and balance/report queries filter `status IS NULL` (planned/upcoming/skipped aren't posted).
- Every change to a shared table is logged by SQLite triggers (`core/sync/op_log.dart`, the base of the coming log sync): don't write shared tables while bypassing them, and never `DROP COLUMN` on one without dropping its triggers. Details: [docs/dev/data.md](docs/dev/data.md#operation-log-sync-step-1-oct-27-2026).
- Never `isIn(ids)` over a list that grows with the history (SQLite binds at most 32,766 values): `TransactionsDao.linesByTransaction()`, `chunked()`, or SQL. New indexes go in `AppDatabase._indexes` (made on every open), not a migration.
- Deletes go through `deleteTransactionsWithUndo()`; every update must move `last_modified` (sync merges by it).

## Code rules

- **Colors**: theme-aware only — `AppColors.tp/ts/th/sf/sfv/bd(context)`, `AppColors.pastel(...)` for category/accent fills, `AppColors.fromHex()` for hex. Text/icons on an accent fill: `AppColors.onAccent`, never `Colors.white`. No hardcoded colors on adaptive surfaces.
- **Icons**: Phosphor through `AppIcons` only (never Material `Icons.*`); dropdowns pass `icon: AppIcons.dropdown`. Category/envelope emoji: `EmojiGlyph`, never `Text(emoji)`.
- **Amounts**: entered with the calculator sheet (`AmountField`/`CalculatorAmountField`), never a numeric keyboard. Shown with `formatAmount()`/`formatNumber()`, never `toStringAsFixed()`. Dates with `formatDate()`, month names with `formatMonth()`, day counts with `calendarDaysBetween()`. Typed/imported amounts parsed with `parseLooseAmount()`.
- **Riverpod 3**: `Notifier` + `NotifierProvider<N, T>(N.new)`, `AsyncValue.value`.
- **Navigation**: GoRouter `context.push/pop/go`; routes in `app.dart`.
- **Errors**: never show `e.toString()` — map to strings (`txSaveErrorText()`, `syncErrorText()`, `biometricErrorText()`) and `debugPrint` the rest. `.when()` errors use `ErrorRetry`. Every async `_load()` is wrapped in try/catch and clears `_loading` in both paths. User actions (save, delete, toggle) show a SnackBar on success and failure.
- **SnackBars**: `SnackBarBehavior.floating`; one with an action (Undo) passes `persist: false` (since Flutter 3.29 an action makes it stay until tapped). No saturated `backgroundColor`.
- **Theme**: don't restate the theme per widget — no sheet handles, no `showModalBottomSheet(backgroundColor:/shape:)`, no `InputDecoration` borders/fills, no `FilledButton.styleFrom` shape/colors. Dialog action buttons use `DialogButtons.filled/.outlined`.
- **RTL**: `EdgeInsetsDirectional` / `AlignmentDirectional`; number-per-character widgets force `TextDirection.ltr`.
- **Strings**: every user-visible string is localized (EN/AR/FR). Every feature change updates `docs/i18n_strings.csv`, the three ARBs (then `flutter gen-l10n`), `assets/web/help.html`, and the matching `docs/dev/` file. English is sentence case. Details and gotchas: [docs/dev/i18n.md](docs/dev/i18n.md).
- **Held-back packages**: go_router 17, google_fonts 8, dynamic_color 1, shimmer 3 stay put (their next majors need the `material_ui` migration); pointycastle stays 3.x for `encrypt`. file_picker 12+: `FilePicker.pickFile()`.
- Don't run `dart format` on whole large files (e.g. `add_transaction_screen.dart` isn't formatted — it rewrites hundreds of lines).

## Known crash patterns

- **Icon pickers — inline only.** `showModalBottomSheet` + `showDialog` = `_dependents.isEmpty` crash (tried 5+ variants). Use an inline expandable emoji grid with a `setState` toggle (`categories_screen.dart`, `allocation_detail_screen.dart`).
- **`S.of(context)` inside a `StatefulBuilder` in a bottom sheet** crashes the same way — capture `final tr = S.of(context)` before opening the sheet.
- **Bill splitter — flat ListView.** Nested `Column + Expanded`, nested Rows with `Expanded`, or `AnimatedSwitcher` with a switch expression = blank screen. Body is one `ListView` with flat `if`/spreads; the `bottomNavigationBar` is a `Material` + `Column(mainAxisSize: min)` with no `Expanded`.
- **Buttons in a Row need a width.** The theme gives Filled/Outlined buttons full width (`Size.fromHeight(52)`); a bare one in a `Row` gets infinite width → blank screen. Wrap in `Expanded` or set `minimumSize: const Size(0, 44)`.
- **FAB long-press**: never wrap `FloatingActionButton` in `GestureDetector(onLongPress:)` — its `InkWell` swallows it (Activity uses a `Material` + `InkWell` circle).
- **`ErrorWidget.builder`**: don't override it (same `_dependents` crash); errors go through `FlutterError.onError`.
- **Data reset**: never close the database and wait for providers — `db.batch()` delete all rows → clear SharedPreferences → `context.go('/onboarding')`.
- **Timezones**: call `tz.setLocalLocation()` after `initializeTimeZones()`, or everything runs as UTC.

## Workflow

- Work on `main` (the `app-redesign` branch was merged into it and deleted on Oct 24 2026). Commit only the paths you changed (the tree has untracked personal files). Commit messages end with the Co-Authored-By line.
- Debug builds install next to the Play Store app with their own data — never uninstall or wipe the Play Store app.
