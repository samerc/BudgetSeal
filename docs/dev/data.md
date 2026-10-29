# Data: database, sync, backup, security, performance

Developer notes moved out of CLAUDE.md (Oct 2026). Read before changing this area; update when you change it.

## Cloud Sync
**Log sync (Oct 27 2026, roadmap #1 step 2)** — phones exchange change logs, not rows. Each phone's changes are recorded by the operation log (see [Operation log](#operation-log-sync-step-1-oct-27-2026)); `LogSync` (`core/sync/log_sync.dart`) moves them through the provider's folder:
- **Files**: `log-<device>-<nnnnn>.json` — this phone's entries in `seq` order (starting entries first), `chunkSize` = 1,000 per file; content `{"format":"budgetseal-log","version":1,"device","chunk","entries":[{hlc, seq, table, row, kind, data?, old?}]}`, encrypted like the old file (`SyncEncryption`). Only a phone writes its own files, so phones never overwrite each other. `push()` rewrites only files holding entries past `sync_meta.pushed_seq_<device>`; `pull()` reads only other phones' files whose version (Drive `md5Checksum`, folder: size+mtime) differs from `sync_files`.
- **Merging** (`apply()` → `_merge()` → `mergeRow()`): new entries (by device+seq) are stored in `sync_ops` and the rows they touch are rebuilt from all their entries — each column from the newest entry (stamp order) that set it; the row exists if its newest insert/delete is an insert (so a delete newer than an edit wins, and a later edit to a deleted row is ignored); an update whose insert hasn't arrived waits. Order-independent → every phone ends the same (`test/core/sync/log_sync_test.dart`: join, different fields both kept, later same-field edit wins, delete vs edit, 3 phones recording money offline syncing in shuffled orders → identical databases and the expected balances, only changed files written, encryption). Applied with `sync_clock.applying = 1` (not logged, no stamp bump); the clock then moves to the newest stamp seen, so an edit made after seeing a change sorts after it.
- `SyncNotifier.sync()` = `LogSync.sync()` + `_snapshotIfDue()`: **`BudgetSeal_Sync.json` is still written, at most once a day** (`exportToJson`, pref `sync_last_snapshot`) — the readable copy [docs/file-format.md](../file-format.md) describes; sync never reads it, except connecting to a folder from before log sync (no log files): `checkRemote()` then reads its household ids and `restoreFromProvider()` restores it (`restoreFromJson` — its rows are logged as this phone's, then pushed).
- **Joining / "Use the synced budget"**: `restoreFromProvider()` backs up, then `LogSync.replaceFrom()` empties the shared tables, `sync_ops`, `sync_files`, `sync_meta` (unlogged) and pulls everything. `initialUpload()` (empty folder) = `push()` + snapshot.
- **No compatibility with 0.11** (user's decision: everyone switches at once; only testers). The row merge (`SyncEngine.mergeFromJson`) was removed in step 4; `SyncEngine` only exports and restores the readable snapshot.
- **Snapshots (step 4)**: when the log has grown by `snapshotEvery` (10,000) entries since this phone's last one (`sync_meta.snapshot_entries`), `sync()` writes `log-snapshot-<device>.json` (`writeSnapshot`): every entry it holds, compacted by `compactOps()` — per row the newest insert/delete, and per column only the newest entry that set it, cut down to the columns it wins, `old` dropped (each entry's device is the end of its stamp) — plus `covers` {device: how many of that device's entries it holds}. `mergeRow` gives the same rows from a compacted log, now and with entries still to come (`log_sync_test.dart` checks it on 200 random histories). `replaceFrom()` (joining) reads every snapshot, applies the one covering most, marks that device's full files below `covers` as read (a full file never changes) and pulls the rest. Scale test (3 years): 37 log files 16.1 MB, snapshot 15.8 MB (mostly inserts, so not smaller — the gain is 2 downloads instead of 37, and size once edits pile up); join ≈ 4.5 s on a PC either way. A phone that joined from a snapshot has the compacted entries in its Change history for that period (no before-values). Log files are never deleted.
- **Folder provider** (`file_picker_provider.dart`, shown as "Folder"): `FilePicker.getDirectoryPath()`, pref `file_sync_folder`; log files written to a temp name and renamed. A phone that had the old single-file setting (`file_sync_path`) shows "Pick a folder for sync" on the Cloud sync screen (`needsFolderPick()`).
- **Joining a household** (Oct 29 2026): Share household (`share_household_sheet.dart`) shares the folder with an email (writer) and shows the invite `PP-<base64url folder id>` as text + QR. Join (`join_household_sheet.dart`, `showJoinHouseholdSheet()`; welcome screen, and Cloud Sync after a confirm since it replaces this phone's budget) takes a typed or scanned code (`/scan-invite`, `scan_invite_screen.dart`, mobile_scanner with Play's unbundled model). `connectToSharedFolder()`: the drive.file scope can't open a folder another account created (404), so it opens **Google's Drive picker** (`DrivePicker`, Android `DrivePicker.kt`: `AuthorizationRequest` + `PICKER_OAUTH_TRIGGER`, the folder preselected via `PICKER_FILE_IDS`), then keeps the folder id in pref `drive_joined_folder_id` (a restart used to fall back to a name search that found or made the phone's own folder; cleared on Disconnect). Then `useConnectedProvider()` (no second sign-in) + `restoreFromProvider()`. **Open question (Oct 29): whether picking the folder also gives access to the files in it, including later ones from the other phone** — hidden test screen `drive_picker_test_screen.dart` (`--dart-define=PICKER_TEST=true`, TEMP). iOS has no native picker: joining there still fails.
- **Google Drive**: log files live in the `BudgetSeal` folder (shared for a household) beside the snapshot and `receipts/`; `listLogFiles()` pages through `name contains 'log-'` and remembers name → id; `_retryIfGone` forgets cached ids on a 404 and retries once (not a joined shared folder); duplicate folders resolve to the oldest.
- **Edits in place (step 3)**: an edit keeps the transaction's id — `recordTransaction`/`recordTransfer(editing: id)` update the header (status cleared, as the old re-record did; receipts stay), and `rewriteTransaction()` (bulk edit) goes through it. A transaction's lines and envelope debits are one unit: when the lines change (any field, or the type), the edit drops them all and writes new ones with ids `<txId>:<revision>:line<n>` / `debit<n>` under a new `transactions.revision` (8 hex); a note/date-only edit leaves them (and the revision) alone, so it doesn't undo another phone's category change. After every merge `settleTransactions()` (log_sync.dart, run muted) makes each touched transaction whole: only lines/debits with the current revision's prefix stay, and the header's derived fields (base total — summed in line order like the engine, `isRealRate`; category when one line; account from line 0) are recomputed from them. So two phones rewriting one transaction keep one, the newer rewrite's lines whole, and the money adds up; fields only one side changed (note, date) are both kept. An edit against a delete: it stays deleted (the edit never touches `deleted`). Tests: `log_sync_test.dart` "one transaction edited on two phones offline"; `money_model_test.dart` step "edit an expense in the form".
- **Recurring occurrences have fixed ids**: `RecurringEngine.occurrenceId()` = `rec:<recurringId>:<due yyyy-MM-dd>`; `recordTransaction`/`recordTransfer(id:)` then use `<id>:line<n>` / `<id>:debit<n>` and return early if the id exists, so a bill due on two phones posts once (both phones' entries carry the same ids and values).
- `SyncNotifier`: `sync()`, `restoreFromProvider()` and `initialUpload()` run one at a time (`_exclusive`). Restore runs `AutoBackupService.backupNow()` first and stops if that fails. `lastError` is always `syncErrorText(e)` — never `e.toString()`. Screens on Drift streams redraw by themselves; `_refreshAfterMerge()` invalidates the one-shot providers (objectives, daily spending, age of money, pending resets).
- **`last_modified` triggers**: `bump_last_modified_<table>` on `AppDatabase.syncedTables` stamp an update that leaves the stamp unchanged (skipping no-op updates and log replays). `last_modified` no longer decides sync (stamps do) but Change history and the snapshot use it. `test/core/database/sync_triggers_test.dart`.
- **Off the UI thread**: snapshot JSON and AES run in `Isolate.run`; PBKDF2 keys are cached by salt+password.
- **Connecting** (sync screen `_firstSync`): `checkRemote()` (household ids from the logs' `households` inserts) → `none` → `initialUpload()`, `same` → `sync()`, `other` → "Use the synced budget" (`restoreFromProvider`) or Disconnect.
- Auto-syncs on app resume and pause; restore from the cloud or a backup file during onboarding (`AutoBackupService.backupHouseholdId` / `restoreForNewInstall`).

## Sync Encryption
`lib/core/sync/sync_encryption.dart` — optional end-to-end encryption for the sync file on Google Drive. User sets a sync password in Cloud Sync settings. The password is stored in Flutter Secure Storage (Android Keystore / iOS Keychain). PBKDF2 derives a 256-bit key (100,000 iterations, SHA-256). Encrypted format: `ENC:1:<salt>:<IV>:<ciphertext>`. Backward compatible — unencrypted files are auto-detected and read normally. Both devices in a shared household must use the same password.

## Database

### Schema Version: 29
15 tables: households, users, accounts, categories, allocations, transactions, transaction_lines, allocation_ledger, recurring_transactions, transaction_templates, fx_rates, objectives, capture_rules, money_requests, month_reviews.

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

v23→v24 added `transactions.revision` (nullable TEXT, synced as `revision`): set by an edit that rewrote the lines; that edit's lines and debits have ids starting `<id>:<revision>:` (see Cloud Sync "Edits in place").

v24→v25 added `households.baseHistory` (nullable TEXT, synced as `baseHistory`): every base-currency change `[{from, to, rate}]`, so a transaction recorded against an old base on another phone is converted when it arrives (see budget.md "Changing the base currency").

v25→v26 added `allocations.secondTargetAmount` / `secondTargetCurrency` (nullable; synced): an optional second envelope target in another currency (see budget.md).

v26→v27 created `capture_rules` (synced, in `opLogTables` and `syncedTables`; snapshot key `captureRules`): rules for captured payments (see transactions.md "Rules").

v27→v28 added `allocations.ownerDeviceId` and `allocations.isPrivate` (synced): whose envelope it is, and private (hidden on the other members' phones; see budget.md "Family").

v28→v29 created `money_requests` and `month_reviews` (synced; in `opLogTables`, `syncedTables`, the snapshot as `moneyRequests`/`monthReviews` in Drift's JSON): family money requests and the monthly review (see budget.md "Family").
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

`Sum(accounts) = Unallocated + Sum(envelopes)` holds by construction (`unallocatedByCurrency` is the difference), so `checkInvariant()` can't catch a wrong balance — it only flags a negative Ready to assign. The real check is **`test/core/engine/money_model_test.dart`**: a model-based test that keeps its own plain map of every account and envelope balance, runs random operations through `AllocationEngine` (income; expenses incl. subcategory → parent envelope, an archived envelope, unlinked categories and lines typed in another currency; splits over accounts; cross-currency transfers; fund; `moveMoney` incl. refused moves; delete; recategorise and move-to-account via `rewriteTransaction`; a form edit in place with new lines, maybe a split) and compares after every step. Each run ends with merging its own sync file (must change 0 rows), restoring it into a fresh DB (same balances) and `changeBaseCurrency` (no balance moves). 25 seeds × 60 steps, ~8 s. A failure prints the seed and the step log; rerun with `--plain-name "seed N"`. When adding a money operation, add it to the test's switch with its expected effect. Proven to catch a broken cross-currency transfer (Oct 27 2026).

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

### Incremental history (Oct 28 2026)
`transactionEntriesProvider` (every posted transaction with running balances — Activity, reports, autofill) no longer re-reads the whole history on each save. It watches a cheap signal (`COUNT(*)`, `MAX(last_modified)` for the household) and, on a change, reads only rows with `last_modified` ≥ the newest it saw (stamps are whole seconds, so the same second is re-read) plus their lines, merging them into its rows (deleted or no longer posted → dropped). Fewer rows than before (Health Check purge) → full reload. A sync merge can change rows without moving the stamp (`settleTransactions`, applied with the log muted), so `SyncNotifier._refreshAfterMerge` invalidates it. Order: `createdAt`, then id. 3-year scale test: saving one expense → Activity updated **97 ms** (was ~450 ms; the full re-query alone was ~300 ms). Test: `test/core/providers/transaction_entries_test.dart` (new, edited in place, deleted; balances).

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

## Operation log (sync step 1, Oct 27 2026)

Roadmap #1 replaces row-merge sync with an exchange of change logs (decisions: everyone switches at once — no old-file dual write; local-file sync will pick a folder; the same field edited on two phones → the later edit wins and Change history shows both; undo stays local). **Step 1 (done): the log is recorded locally. Step 2 (done): sync exchanges it — see [Cloud Sync](#cloud-sync).** `core/sync/op_log.dart`:

- `ensureOpLog()` runs first in `beforeOpen`: tables `sync_ops` (n, hlc, device, seq, tbl, row_id, kind, data, old) and one-row `sync_clock` (device, ms, counter, seq, applying), then AFTER INSERT/UPDATE/DELETE triggers `oplog_<kind>_<table>` on the 12 `opLogTables` (every shared table, incl. lines, ledger and fx rates) — recreated on every open so they follow the schema. Raw SQL tables, not Drift ones, and no schema version.
- Insert → `data` = the whole row; update → `data`/`old` = only the changed columns (no entry when nothing changed); delete → `old` = the row. Values are raw column values (dates in Unix seconds, booleans 0/1).
- Stamp `hlc` = `printf('%013d-%08d-%s', ms, counter, device)`: wall-clock ms that never goes back (counter within a ms), sorts the same on every phone; `seq` counts this device's entries. The device is `DeviceIdentity.id`.
- An empty log with data (first open after updating) logs every existing row once, stamp `0000000000000-00000000-<device>`, negative seq — older than any real change.
- `replayOps()` applies entries in stamp order with `applying = 1` (no new entries, no `last_modified` bump): insert = INSERT OR REPLACE, update = set the changed fields, delete. Replaying the whole log into an empty database rebuilds it exactly (`test/core/sync/op_log_test.dart`; the 3-year scale test: 36,600 entries, 10.9 MB of JSON, replay 1.4 s on a PC). Writes are ~10–15 % slower.
- The `bump_last_modified_*` triggers now skip updates that change nothing and the replay.
- **Never `DROP COLUMN` on a shared table without dropping its triggers first** (SQLite refuses a column a trigger names; `migration_test.dart` drops all triggers before rewinding a schema). Reset everything also deletes `sync_ops` (it holds a copy of every row).
- Step 4: snapshots + removing the row merge — done (Cloud Sync "Snapshots").
- Step 3: transaction edits in place and Change history from the log — done (see Cloud Sync "Edits in place", [Change history](#change-history-oct-24-2026)); shared base-currency change done (budget.md). Step 4 — compaction and removing the row merge.

## Crash reports (Oct 27 2026)

Opt-in, offline: `CrashReports` (`core/services/crash_reports.dart`). Off by default (pref `crash_reports_enabled`). `main.dart`'s three handlers — `FlutterError.onError` (`flutter`), the `runZonedGuarded` callback (`async`), `PlatformDispatcher.instance.onError` (`platform`) — call `CrashReports.record()`, which does nothing when off. When on it appends to `crash_reports.json` in the app support folder (not synced, not in backups): time, source, error text (≤1,000 chars), stack (≤30 lines), app version (build), OS + version; newest first, at most 50; a repeat of the newest (same error and top frame) bumps its `count` instead. Writes are queued (bursts) and never throw. Settings › Data › Crash reports (`/crash-reports`, `settings/crash_reports_screen.dart`): the switch (turning off deletes the file), the reports (tap to expand, selectable, LTR), Share (system share sheet, plain text via `shareText()`) and Clear. The Settings row says Off / On · N saved (`CrashReports.changes`). Only uncaught errors land here — errors the app catches and maps to a message are not reports. Tests: `test/core/services/crash_reports_test.dart`.

## Change history (Oct 24 2026)

Settings › Data › Change history (`/change-log`, `settings/change_log_screen.dart`; model and `loadChangeLog()` in `core/engine/change_log.dart`, shared with the Web Companion's `GET /api/change-log`) — **read from the operation log** (sync step 3), so every phone's changes are in it. `loadChangeLog()` takes the newest 300 `transactions` entries with real stamps (not the `last_modified`-only bumps, not purges; index `idx_sync_ops_tbl_hlc`) and groups each with the entries that follow it on the same device and belong to the same save (`_partOf`: the transaction's lines and envelope rows, the bump, receipts attached within 2 s); another change to the transaction is a save of its own. Kinds: insert → Added (a planned payment's insert is skipped; planned → paid reads Added), `deleted` 0→1 → Deleted, 1→0 → **Restored** (Undo), otherwise Edited. An edit lists what it changed (`FieldChange`): type; amount per currency, category ids and account ids from the lines it removed vs wrote (transfers: header amount and from/to accounts); date (`created_at`); note. **Replaced**: an edit whose field (type, note, date, `revision` = the lines, a transfer's amount/accounts) a later entry from another device changed *with a different "before" value* — i.e. made without seeing it — is marked `replacedBy` that device ("Replaced by Sara's later edit"); an edit made after syncing isn't. `by` = the device that made the change (deletes now name who deleted; a bill posting itself names no one); `source` 'web' from the row's `device_id` as of that save (an edit stamps it), 'bill' for a `rec:` insert. Amounts are as of the change (the lines written; else the current lines). Changes from before the log (rows whose `last_modified` is older than the first real stamp) still come from `buildChangeLog()` (an edit was then a new row + the old one deleted within 10 s). Rows purged by Health Check drop out. Tests: `test/features/change_log_test.dart` (one save = one entry, field changes, restore, the two-phone replaced case, pre-log rows), `web_companion_api_test.dart`.

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
Every delete/undo write also bumps `lastModified` (Change history and the snapshot read it). If the app dies before the SnackBar closes, `main.dart` runs `LedgerDao.deleteForDeletedTransactions()` at startup; balance queries ignore ledger rows of deleted transactions anyway.
