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
- Supports Google Drive (OAuth) and system file picker (Dropbox/OneDrive/local)
- Auto-syncs on app resume and pause via `WidgetsBindingObserver`
- Restore from sync file during onboarding
- Optional AES-256-CBC encryption with PBKDF2 key derivation (user-set password)

## Sync Encryption
`lib/core/sync/sync_encryption.dart` — optional end-to-end encryption for the sync file on Google Drive. User sets a sync password in Cloud Sync settings. The password is stored in Flutter Secure Storage (Android Keystore / iOS Keychain). PBKDF2 derives a 256-bit key (100,000 iterations, SHA-256). Encrypted format: `ENC:1:<salt>:<IV>:<ciphertext>`. Backward compatible — unencrypted files are auto-detected and read normally. Both devices in a shared household must use the same password.

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
v20→v21 added `behindMode` (nullable TEXT) to `allocations`: how a sinking fund catches up (`spread` / `topup`, null = ask; synced).
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
`AnimatedAmount` is wrapped in `RepaintBoundary` to isolate its repaints from parent widget trees.

## Auto Backup

`AutoBackupService` in `lib/core/services/auto_backup_service.dart`:
- Copies `pocketplan.db` to `app_documents/backups/` with timestamped filenames
- Runs on app resume AND pause (exit) via `AutoBackupService.runIfDue()` in `app.dart`
- User settings: enable/disable, frequency (6h–weekly), retention (3–30 backups)
- Old backups auto-deleted beyond retention limit
- Backup history visible on the Backup & Restore screen with per-file restore/delete

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
