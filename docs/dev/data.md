# Data: database, sync, backup, security, performance

Developer notes moved out of CLAUDE.md (Oct 2026). Read before changing this area; update when you change it.

## Cloud Sync
Single-file sync approach (`PocketPlan_Sync.json`):
- Exports all 12 tables as JSON
- Merge by `lastModified` timestamp (newer row wins). `_mergeTable` is told each table's own timestamp column (`column:` — `last_modified`, ledger `created_at`, fx `fetched_at`); transaction lines have none and are insert-only (edits always make a new transaction). Dates are written in UTC (`…Z`); `_parseDate` reads them back as local and still accepts older zone-less files. Two-device tests: `test/core/sync/sync_engine_test.dart`.
- **Recurring occurrences have fixed ids**: `RecurringEngine.occurrenceId()` = `rec:<recurringId>:<due yyyy-MM-dd>` (Post now keys on the occurrence it pays, not today). `recordTransaction`/`recordTransfer(id:)` then use `<id>:line<n>` / `<id>:debit<n>` and return early if the id already exists (deleted rows included), so a bill due on two devices before they sync posts once.
- `SyncNotifier`: `sync()`, `restoreFromProvider()` and `initialUpload()` run one at a time (`_exclusive` — a second call waits for the running one). Restore runs `AutoBackupService.backupNow()` first and stops if that fails. `lastError` is always `syncErrorText(e)` (localized: wrong/missing password via `SyncPasswordException`, corrupt file, signed out via `CloudAuthException`/401/403, network, generic) — never `e.toString()`; `copyWith(clearError: true)` on success.
- **Merge details**: same-second tie (times are whole seconds) → a remote `deleted = true` wins. A remote transaction that is deleted and unknown locally (never received, or purged in Health Check) is skipped with its lines/ledger rows, so purges stay purged. After every merge `LedgerDao.deleteForDeletedTransactions()` runs (the other device's file still carries ledger rows this one removed). Rows are written with one `insertAllOnConflictUpdate` batch per table. Screens on Drift streams redraw by themselves; `_refreshAfterMerge()` invalidates the one-shot providers (objectives, daily spending, age of money, pending resets).
- **Every update moves `last_modified`**: `AppDatabase._ensureSyncTriggers()` (run in `beforeOpen`, idempotent, no schema version) puts an `AFTER UPDATE` trigger `bump_last_modified_<table>` on every table in `AppDatabase.syncedTables`; an update that leaves the stamp unchanged (raw SQL, a companion without `lastModified`) gets the current time, so it reaches other devices. Writes that set a new stamp (merge, explicit) are untouched. `test/core/database/sync_triggers_test.dart` fails if a table with `last_modified` lacks its trigger. Before a migration drops or renames `last_modified`, drop that table's trigger.
- **Off the UI thread**: JSON encode/decode (`_readFile`) and AES run in `Isolate.run`; PBKDF2 keys are derived in an isolate and cached by salt+password (`_keyFor`, up to 4 — a sync reads with the other device's salt and writes with ours).
- **Connecting** (sync screen `_firstSync`): `SyncNotifier.checkRemote()` → `RemoteMatch.none` → `initialUpload()`, `.same` (file holds the current household id) → `sync()`, `.other` → dialog "Use the synced budget" (`restoreFromProvider`, then `context.go('/')`) or Disconnect (staying connected would merge two households).
- **Google Drive**: `_retryIfGone` forgets cached file/folder ids on a 404 and retries once (not a joined shared folder); duplicates resolve deterministically (folder: oldest `createdTime`, sync file: newest `modifiedTime`); receipts are listed once per sync with paging (`_receiptFiles`).
- Supports Google Drive (OAuth) and the system file picker ("Local file"; it can reach Dropbox/OneDrive apps). The OneDrive and Dropbox rows are hidden in `providerOptions` until they get their own providers.
- Auto-syncs on app resume and pause via `WidgetsBindingObserver`
- Restore from sync file during onboarding
- Restore from a backup file during onboarding (Oct 24 2026; Restore my budget sheet › "Restore a backup file"): `AutoBackupService.backupHouseholdId(path)` checks size, the SQLite header and reads `households.id` read-only (package `sqlite3`, already in the tree via drift, now a direct dependency); `restoreForNewInstall()` stages the file like Settings › Backup (swapped in on the next launch) and saves `current_household_id`, so the next launch opens the restored budget instead of onboarding. Android closes the app; iOS asks the user to.
- Optional AES-256-CBC encryption with PBKDF2 key derivation (user-set password)

## Sync Encryption
`lib/core/sync/sync_encryption.dart` — optional end-to-end encryption for the sync file on Google Drive. User sets a sync password in Cloud Sync settings. The password is stored in Flutter Secure Storage (Android Keystore / iOS Keychain). PBKDF2 derives a 256-bit key (100,000 iterations, SHA-256). Encrypted format: `ENC:1:<salt>:<IV>:<ciphertext>`. Backward compatible — unencrypted files are auto-detected and read normally. Both devices in a shared household must use the same password.

## Database

### Schema Version: 23
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
v20→v21 added `behindMode` (nullable TEXT) to `allocations`: how a sinking fund catches up (`spread` / `topup`, null = ask; synced).
v21→v22 added `askFirst` (BOOL, default false) and `remindDays` (nullable INT; null = default 2 days, -1 = off) to `recurring_transactions` (both synced).

**Public file format:** [docs/file-format.md](../file-format.md) documents the sync file for people reading their own data (every list and field, the balance rules, decryption, writing a file to merge). Its two Python examples were checked against real export output (plain + encrypted). **A change to the sync file's fields, their meaning, or the encryption updates it** (and its "format version" line).

v22→v23 added `transactions.destinationAmount` (nullable REAL, synced as `destinationAmount`): what a transfer delivered, in the destination's currency. **One meaning per column** from v23: a posted income/expense always has lines (account currency, own rate) and its header holds the base total; a transfer holds sent (`amount`, source currency) and received (`destinationAmount`). Older rows are converted by `normalizeTransactions()` (`core/database/normalize_transactions.dart`) — on every open (`beforeOpen`, so upgrades and restored `.db` backups), and inside `mergeFromJson`/`restoreFromJson` (files from phones still on 0.11): a posted transfer without it gets `amount × exchangeRateToBase`; a posted income/expense with no line gets one, id `<txId>:acct` (the header amount on the header account in its currency), and the header becomes the base total (0 without a rate) with rate 1. Deterministic ids and values, so two phones converting the same row agree; the updates move `last_modified` (trigger) and sync out. **0.11 compatibility:** the transfer's `exchangeRateToBase` is still written (0.11 reads it); 0.11 ignores the new key (its `_transactionFromMap` reads known keys only) and reads a converted row through its line. A 0.11 edit of a transfer arrives without `destinationAmount` → null → refilled from the rate. Tested: `migration_test.dart` (v22 file), `money_model_test.dart` (merging and restoring a 0.11-style file must keep every balance).
v18→v19 added `anchorDay` (nullable INT) to `recurring_transactions`: the day of month a series was set up on. `advanceRecurringDate()` (recurring_engine.dart) clamps monthly/yearly dates to short months and returns to the anchor (Jan 31 → Feb 28 → Mar 31); legacy rows get the anchor filled from their due day the next time they post.

### Migrations
Defined in `app_database.dart` `migration` getter. The sync triggers (see Cloud Sync) are recreated in `beforeOpen`; a migration that drops/renames a `last_modified` column must drop `bump_last_modified_<table>` first. After schema changes:
1. Increment `schemaVersion`
2. Add migration logic in `onUpgrade`
3. Run `dart run build_runner build --delete-conflicting-outputs`

### Key Columns
Every table has `id` (UUID text primary key). Most have `createdAt`, `lastModified`, `deviceId` for sync support.

Notable additions:
- `accounts.decimalPlaces` — nullable INT, overrides currency decimal display
- `accounts.isTravel` — BOOLEAN, marks temporary travel wallets (auto-archive at zero)
- `transactions.status` — nullable TEXT ('upcoming', 'skipped', or null for posted)

## Testing the money

`Sum(accounts) = Unallocated + Sum(envelopes)` holds by construction (`unallocatedByCurrency` is the difference), so `checkInvariant()` can't catch a wrong balance — it only flags a negative Ready to assign. The real check is **`test/core/engine/money_model_test.dart`**: a model-based test that keeps its own plain map of every account and envelope balance, runs random operations through `AllocationEngine` (income; expenses incl. subcategory → parent envelope, an archived envelope, unlinked categories and lines typed in another currency; splits over accounts; cross-currency transfers; fund; `moveMoney` incl. refused moves; delete; recategorise and move-to-account via `rewriteTransaction`) and compares after every step. Each run ends with merging its own sync file (must change 0 rows), restoring it into a fresh DB (same balances) and `changeBaseCurrency` (no balance moves). 25 seeds × 60 steps, ~8 s. A failure prints the seed and the step log; rerun with `--plain-name "seed N"`. When adding a money operation, add it to the test's switch with its expected effect. Proven to catch a broken cross-currency transfer (Oct 27 2026).

**At scale: `test/scale/big_budget_test.dart`** (tag `scale`, ~45 s). `BigBudget` (`test/scale/big_budget.dart`) writes 36 months through the engines — ~10,700 live transactions: daily purchases over the onboarding categories (weighted accounts, 1 in 25 typed in another currency), splits, salary, monthly funding (ledger rows back-dated to the month), card payments, ATM and USD→LBP exchanges, envelope moves, edits and deletes, eight bills posted by the recurring catch-up, planned payments, goals, templates — keeping the same kind of model as the money test. Checks: balances = model; the Activity history's running balances end at each balance; a month on its own agrees with the whole history; search, autofill, change log, report stats, period stats, age of money; Web Companion list/search/dashboard/envelopes/reports; sync export (10 MB), merge-own = 0, restore, base change; a save refreshes the list; 40,000 batch-inserted transactions (past the bound-variable cap); and 16 screens (Home, Activity, Budget, Fund, Accounts, details, Change log, every report) build at 360 dp with no exception. Timings print at the end; limits are loose (5 s) and only catch the unusable. `BIG_BUDGET_MONTHS=60` for more; `BIG_BUDGET_DB=path` also writes the database to a file — push it to the debug app (`app_flutter/budgetseal.db`, and set `flutter.current_household_id` to `big-hh` in the prefs) to try it on a phone. It found the missing indexes, the 32,766 cap and two overflows (Ready to assign's "+ 2 other currencies", Fund's "Fill LBP 20,000,000").

CI (`.github/workflows/ci.yml`, ubuntu, Flutter 3.47.5): gen-l10n leaves `lib/l10n/generated` unchanged, `dart analyze lib/`, `flutter test`. The repo is public, so Actions minutes are free. The timing-based Web Companion "sign out all" test has `retry: 2`.

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

## Performance

### Batch Balance Computation
`BalanceCalculator.allAccountBalances()` (and `accountBalance()`) sums every account's movements in one SQL `UNION ALL … GROUP BY` (`_movements()`): lines on their own account, header-only income/expense on the header account, transfers out by `amount` and in by `destinationAmount` (falling back to `amount × exchangeRateToBase` for a not-yet-converted row). Nothing is loaded into Dart; 82 ms for 10,700 transactions on a PC (it used to load every line and transaction, 711 ms). `allAllocationBalancesByCurrency()` uses a single query via `LedgerDao.getAllBalances()`. Providers (`accountsWithBalanceProvider`, `allocationsProvider`) use these batch methods.

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

### Database Indexes
`AppDatabase._indexes`, created on **every open** (`beforeOpen` → `_ensureIndexes()`, `CREATE INDEX IF NOT EXISTS`): transactions by (household_id, created_at), (household_id, deleted), account_id and destination_account_id; transaction_lines by transaction_id and account_id; allocation_ledger by allocation_id and source_transaction_id; allocations and categories by household_id; categories by allocation_id. Until Oct 27 2026 they were only made by the v16/v17 upgrade steps — `onCreate` (`createAll()`) makes none — so every install made at v16+ (all current testers; the A02 had `[]`) scanned whole tables. A new index goes in `_indexes`, not a migration step.

### Long Histories (SQLite's bound-variable cap)
One query binds at most 32,766 values. Never `isIn(ids)` over a list that grows with the history (all transactions, an account's transactions, soft-deleted rows): use `TransactionsDao.linesByTransaction(ids)` (lines grouped by transaction, read in chunks of 500), loop `chunked(ids)` (`transactions_dao.dart`), or a subquery/join. Before the fix, balances threw "too many SQL variables" past ~32,700 expenses — Home, Budget and Activity stopped loading. Bounded lists (one month, one page, the 300-row change log, a plan's lines) may bind directly.

### Allocation Engine Batching
`recordTransaction()` pre-fetches all category→allocation mappings and allocation currencies in 3 batched queries before the line loop, instead of 2 queries per line (N+1 → O(1) per write).

### Transaction List Filtering
All filters (date range, type, category, amount, search) applied in a single `.where()` pass instead of 5 sequential `.toList()` copies. Reduces allocations and iteration from O(5N) to O(N).

### RepaintBoundary on Animations
`AnimatedAmount` is wrapped in `RepaintBoundary` to isolate its repaints from parent widget trees.

## Auto Backup

`AutoBackupService` in `lib/core/services/auto_backup_service.dart`:
- Copies `pocketplan.db` to `app_documents/backups/` with timestamped filenames
- Runs on app resume AND pause (exit) via `AutoBackupService.runIfDue()` in `app.dart`
- User settings: enable/disable, frequency (6h–weekly), retention (3–30 backups)
- Old backups auto-deleted beyond retention limit
- Backup history visible on the Backup & Restore screen with per-file restore/delete

## Crash reports (Oct 27 2026)

Opt-in, offline: `CrashReports` (`core/services/crash_reports.dart`). Off by default (pref `crash_reports_enabled`). `main.dart`'s three handlers — `FlutterError.onError` (`flutter`), the `runZonedGuarded` callback (`async`), `PlatformDispatcher.instance.onError` (`platform`) — call `CrashReports.record()`, which does nothing when off. When on it appends to `crash_reports.json` in the app support folder (not synced, not in backups): time, source, error text (≤1,000 chars), stack (≤30 lines), app version (build), OS + version; newest first, at most 50; a repeat of the newest (same error and top frame) bumps its `count` instead. Writes are queued (bursts) and never throw. Settings › Data › Crash reports (`/crash-reports`, `settings/crash_reports_screen.dart`): the switch (turning off deletes the file), the reports (tap to expand, selectable, LTR), Share (system share sheet, plain text via `shareText()`) and Clear. The Settings row says Off / On · N saved (`CrashReports.changes`). Only uncaught errors land here — errors the app catches and maps to a message are not reports. Tests: `test/core/services/crash_reports_test.dart`.

## Change history (Oct 24 2026)

Settings › Data › Change history (`/change-log`, `settings/change_log_screen.dart`; model and `loadChangeLog()` in `core/engine/change_log.dart`, shared with the Web Companion's `GET /api/change-log`) — no log table: `buildChangeLog()` reads the newest 300 transaction rows (posted, or deleted) by `last_modified` (= when a row was saved, or deleted). An edit saves a new row and soft-deletes the old one moments later, so a deleted row and a live row of the same type within 10 s pair into one "Edited". Rows say Added/Edited/Deleted + time, "for <date>" when the transaction's own date differs, and the source ("recurring bill" for `rec:` ids, "from the Web Companion" for `deviceId == 'web'`) and, in a shared budget, "by <name>" (see Member names). Amounts per line currency (never summed across currencies). Purge Deleted (Health Check) removes deleted rows from the history.

## Member names (Oct 24 2026)

Who added what in a shared budget (`core/services/household_members.dart`):
- `DeviceIdentity`: a per-install id `dev-<uuid>` in prefs `device_id` (made in `main()`; a data reset makes a new one). The engines stamp it on new transaction rows: `DeviceIdentity.stamp(deviceId)` turns the default `'local'` into this device and keeps `'web'`, `'period-reset'`… (`AllocationEngine`'s 4 inserts, `PlannedEngine` plans). Rows from before stay `'local'` = nobody. Other tables keep `'local'`.
- Names live in the existing synced `users` table (id = device id, `name`), merged by `last_modified` like everything else. `memberNamesProvider` (live, device id → name); `memberNameFor(names, deviceId)` returns null unless someone other than this device is named, so a single-user budget never shows names.
- Asking (`HouseholdMembers.shouldAsk`): no own row, and the budget is shared — another device named itself or saved entries (`dev-%` ≠ mine), or this device took a budget from the cloud (`markJoined()` in `SyncNotifier._restore`: onboarding restore and "use the synced budget"). "Just me" (`skip()`) stores how many others were named and asks again only when that grows. `MainScreen._askName()` runs after the first-launch tips and after each sync that turns `success`; one dialog at a time (`member_name_dialog.dart`, not dismissable on the first ask).
- Shown: Change history "· by X" (not for deletes — the deleted row is the old one — nor `rec:` bills), the transaction page "Saved by X" (the last edit's device), Web Companion `GET /api/change-log` `by`. Settings › Your name (rename; visible once the budget syncs or someone is named).

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
