# Web Companion

Developer notes moved out of CLAUDE.md (Oct 2026). Read before changing this area; update when you change it.

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
- **Wi-Fi only**: `WebCompanionService.wifiIp()` (used by the screen and by `start()`) accepts an address only when it sits on a Wi-Fi interface — Android `wlan*`, or the hotspot `swlan*`/`ap*`/`softap*`; iOS `en0`/`bridge*`. On Android 12+ `NetworkInfo().getWifiIP()` returns the *active* network's address, so with Wi-Fi off and mobile data on it handed back the 4G address and the server started. While running, a 10 s watchdog re-checks `wifiIp()`; two misses in a row (~20 s, so a roam doesn't trip it) stop the server and show `wcStoppedNoWifi`.
- **WiFi security warning**: Phone screen shows a network security notice before the Start button. Detects public networks by WiFi name keywords (guest, public, airport, hotel, cafe, free wifi…) and shows an elevated amber warning. An unknown name (null / `<unknown ssid>` — Android hides it without location permission) is NOT treated as public, and there are no bare `free`/`open` keywords (they flagged home routers like "Freebox").
- **No inline scripts or handlers in the SPA**: the CSP is `script-src 'self'`. Clicks go through `data-action` attributes and one delegated listener (`actions` map in app.js); forms wire their own `addEventListener`s. Never put user text inside a JS string in an attribute — HTML-decoding turns `&#39;` back into `'` before the JS runs (this broke account names with an apostrophe). `esc()` escapes every user value placed in markup; `safeHex()` validates colors used in `style`.
- **LIKE with escaped input** needs the escape character declared: `ESCAPE '\'` in raw SQL, `like(pattern, escapeChar: r'\')` in Drift — without it `\_` matches nothing (subscription/goal names with `_` or `%` lost their payments).
- **Search** is the app's matcher (`SearchQuery` / `foldForSearch` from `shared/utils/search_match.dart`, `_matchesSearch()` in `transactions_handler.dart`): folded words over note, account, category and line text, amount terms on the own-currency amount. Folding isn't SQL, so a search reads every candidate row (other filters still in SQL), matches in Dart and pages after matching; lines are read in chunks of 500 (`_linesByTx`). Capped at 200 characters.
- **FK validation** checks household ownership: `validateIdExists()` verifies the referenced ID belongs to the authenticated user's household, preventing IDOR attacks.
- **Input validation** on all POST/PUT endpoints: type checks, string length limits (kMaxNameLength=100, kMaxNoteLength=500), amount bounds (>0, ≤1B), enum validation, FK existence + household checks. Invalid data returns 400 with clear error message.
- **Error sanitization**: `ErrorRetry` widget auto-strips exception types, file paths, SQL details, and stack traces. All SnackBars use generic messages. No `console.log/error/warn` in web SPA.

### Multi-Currency in Web Companion
- Transaction list handler returns `lineCurrency`, `lineAmount`, `lineExchangeRate` from the first transaction line alongside the header data. The frontend displays the native currency amount, not the base currency header amount. Transfers also carry `destinationAmount` (what arrived, in `destinationCurrency`; `tx.receivedAmount`) — the SPA shows it, falling back to `amount × exchangeRateToBase`.
- `isRealRate` check: both `cashflowReportHandler` and `byCategoryReportHandler` skip lines where currency differs from base but `exchangeRateToBase` is ~1.0 (rate not set). Same logic as `isRealRate()` in `format_number.dart`.
- Transactions with missing exchange rates show an amber "No rate" warning in the list.

### Web SPA (assets/web: index.html, styles.css, app.js)
- **Design = the app's**: warm paper/night surfaces, the user's accent pair (from `/auth/config`, set as `--acc-*` CSS variables), Bricolage Grotesque for titles/amounts (served from `assets/fonts` at `/fonts/`), Nunito Sans (bundled `nunito-sans*.woff2`, OFL in `assets/fonts/OFL-NunitoSans.txt`), pastel category chips with the app's PNG icons (`/icons/<file>`, name from `categoryIconFile()` in category_icon.dart, sent as `categoryIconFile`/`iconFile`), the gold Ready-to-assign banner, borderless filled inputs, pill buttons, radius-25 dialogs, Cashew-style popup toasts. Logical CSS properties only, so `dir="rtl"` mirrors everything.
- **Same standard as the app (ui.md "The standard", Oct 23 2026)** — styles.css tokens: radii `--r-card` 16, `--r-hero` 20 (Ready-to-assign banner), `--r-md` 12, `--r-sm` 8, `--r-pill` 20, `--r-input` 15, `--r-dialog` 25, `--r-button` 20, `--card-pad` 14/16 — no literal radii. Colors: `--income`/`--expense`/`--transfer` are the app's `txColors` defaults (`#059669`/`#DC2626`/`#6577E0`, dark `#10B981`/`#EF4444`/`#8395FF`) and only color amounts *by type* (`typeCls()`; the transaction list keeps expense plain / transfer grey like `TxTile`); status — overspent, negative balances, errors, destructive buttons — uses `--overspent`/`--healthy` (`.overspent`). `/auth/config` sends `txColors` — only the colors the user picked in Settings (`TxColors.custom*`) — and `loadConfig()` sets them on `:root` inline, overriding both light and dark defaults like the phone does. Bills: `--bill-upcoming` / `--bill-overdue` on the due label (`dueSpan()`). One chip style (`.pill` and `.seg button` = AppChip: quiet `--container` pill, selected = pastel fill + 1.5px colored edge; `.seg button[data-type]` takes the type's color). Modal titles 18/700 in the body font; section headers 15/700 accent.
- **Dialogs, empty, errors**: `confirmDialog(title?, msg, label, danger)` is the one confirm (`openModal({ confirm: true })`: narrow, Cancel outlined + action side by side, red for destructive, accent otherwise) — also used for the import check and "delete goal with payments". Every modal's Cancel is `.btn-outlined`; a form's Delete extra is red text (`extra.danger`). `emptyState()` = 96px pastel circle + 18/700 title + optional primary button; a search or type filter with nothing gets "no match" text (`web_tx_no_match` / `web_filter_no_match`), never "nothing yet". A page whose data fails to load shows `errorState()` (same layout, warning icon, `web_load_failed`, Retry → `refresh()`; the transaction list's Retry reloads just the list) instead of hanging on the skeleton or showing the empty state; quiet (live/after-save) redraws that fail keep the page as it was. `refs()` reports `failed` so Bulk/Import don't mistake a failed load for "no accounts".
- **Subscriptions status**: cancelled = `endDate` has passed (red tag, own "Cancelled" section, left out of the monthly cost); paused = switched off (grey tag, "Paused" section) — the app's rule. Delete uses the existing `DELETE /api/subscriptions/:id`.
- **No internet needed**: Chart.js is bundled (`assets/web/chart.umd.min.js`, MIT) and fonts are local; the CSP allows only `'self'`. Assets in `assets/web/` must sit directly in that folder (pubspec lists the folder, not subfolders). `.woff2`/`.min.js`, `/icons`, `/fonts`, `/brand` get a 7-day cache; the SPA's own files stay `no-store`.
- **`GET /auth/config`** (no token — the PIN screen needs it): `locale` (from `Intl.defaultLocale`, en/ar/fr), `accent` (bright/deep/fills of the chosen pair; Material You falls back to Gold), `txColors` (custom income/expense/transfer hex, only those set), `number` = `numberFormatSpec()` (format_number.dart: separators, parentheses negatives, Arabic digits, symbol map). `fmt()` in app.js mirrors `formatAmount()` and wraps every amount in a left-to-right isolate (`\u2066…\u2069`, plus `\u200E` after an Arabic symbol) so signs/digits never reorder next to "ل.ل" or on an Arabic page.
- **Strings**: every visible string is `t('web_…')` / `data-i18n`; keys live in the ARBs + CSV and are generated into `locale_*.json` by `tool/csv_to_web_json.dart` (web keys must exist in the ARBs). Placeholders are plain `{n}` (no ICU plurals in web strings — Arabic uses "label: {n}" phrasing). The Oct 23 pass added `web_load_failed`, `web_load_failed_sub`, `web_filter_no_match`, `web_filter_no_match_sub`, `web_sub_cancelled` straight to the three `locale_*.json` — they still need adding to the ARBs + CSV, or the next `csv_to_web_json.dart` run drops them.
- **Dates**: the browser sends the user's calendar day `YYYY-MM-DD` (`dayKey()`, never `toISOString()` — UTC shifts the day). `parseWebDate()` (transactions_handler.dart) keeps the time of day when editing, uses now for today, noon otherwise.
- **Icons**: Phosphor, like the app — `assets/web/icons.js` (`PH`, path data) is generated by `tool/web_icons.py` from the phosphor_flutter fonts in the pub cache (`pip install fonttools`; add a name to `ICONS` and rerun). `ph(name, size)` in app.js draws one; index.html uses `<i data-ph="name">` placeholders that app.js swaps in at start (no inline scripts). Select arrows in styles.css are a data-URI of `caretDown`.
- **Budget-first Home** (`renderHome`): `gettingStartedCard()` (dashboard `gettingStarted` = `gettingStartedQuery()` steps, left out once all done or closed; × → `POST /api/getting-started/hide`, the app's `getting_started_hidden` pref) → `rtaBanner(…, envelopes)` (turns into "All sealed" with the ink `sealSvg(…, true)` under the same rule as the app) + net worth → overspent envelopes (Cover) and bills due within 7 days (`/api/upcoming?days=7`, occurrence 0) → envelopes + recent → accounts. Envelopes carry `sealed` (`isEnvelopeSealed()` in seal_provider.dart, from `budgetSnapshot`); `envIcon()` puts `sealSvg()` on the chip.
- **Transactions**: the app's list — `monthCard()` (from the list's `summary` = `_rangeSummary()`: base-currency spent/income in the range, spending-envelope targets; only for a month with no type/search filter; past month within budget = "<Month> sealed"), one `.day-card` per day (name, date, `dayNet()`), `txRow()` = title | amount (Bricolage; expense plain, income green `fmtPlus`, transfer grey), impact line | balance after. Rows get `impact` and `balanceAfter` from `txRowExtras()` (`api/_running.dart`: `envelopeImpactQuery()` — the app's `txEnvelopeImpactProvider` replay — and `allAccountsRunning()`), on the list and the dashboard's recent rows. Cover on a row only for the envelope's latest spending while it's still below zero (`cover` action loads `/api/envelopes` first when needed). "Load more" paging (`hasMore` from a limit+1 query), filters (type, year/month — "Whole year", search, account page). Row click = edit dialog; row buttons duplicate/delete. **Delete waits 5 s for Undo** (`pendingDeletes`, flushed with `keepalive` on `pagehide`/sign-out). Split transactions: lines shown read-only, amount/category hidden ("edited on your phone"). The form remembers the last account/type (`localStorage`), has Save & add another, Today/Yesterday chips, a category `<select>` filtered by type with subcategories indented.
- **Bulk entry** (`#/bulk`, "Add several" on Transactions; `renderBulk()`/`saveBulk()`): expense/income grid (date, type, account, category, title, amount in the account's currency). Tab across, Enter down (adds a row copying date/type/account), Ctrl+Enter saves; paste (TSV or CSV lines) recognises dates (`parseLooseDate`, day-first unless impossible or en-US), amounts (minus/parentheses → expense), category and account names; the rest is the title. Draft in `sessionStorage` (`bs_bulk`). Saved via `POST /api/transactions/bulk`; a 400 carries `row` and that row is highlighted.
- **CSV import** (`#/import`, "Import CSV" on Transactions): the browser parses the file (`parseCsv`: quotes, `,`/`;`/tab), guesses column roles (`guessRoles`: date/description/amount or debit+credit/category, header words in EN/FR/AR + sample rows), shows a mapper + preview, and sends `{date: YYYY-MM-DD, description, amount (signed), category}` rows in chunks of 500 to `POST /api/import` — first `dryRun` (counts for the confirm dialog), then for real. Day-first vs month-first is decided once per file (any first field > 12), as in the app. Server rules = `import_screen.dart`: skip rows already on the account (`day|amount|type`, also within the file), category by name else guessed from past titles, `recordTransaction` in the account's currency at `latestCachedRate()`, all rows in one db transaction.
- **Currencies in the form**: an expense/income line in a non-base currency shows a rate field ("1 EUR = ? USD"); empty → the server uses `latestCachedRate()` (no network in a request), else 1.0 + "No rate". A transfer between accounts in different currencies asks for the **amount received**; the server passes `received / sent` to `recordTransfer` (source → destination, as the app does), which stores the received amount as `destinationAmount` and refuses a cross-currency transfer without it.
- **Budget**: `budgetSnapshot()` (`api/_budget.dart`, shared by dashboard + envelopes) returns envelopes in the Budget tab's order (sortOrder nulls-last, then name) with `spentByCurrency` (period consumption from `watchSpendingInPeriod().first`) and the linked category's color, plus `unallocated` per currency and the current `period`. Fund dialog: To target / All available chips, plus **Usually spends** (`GET /api/envelopes/average-spending` → `recentAverageSpending()`, the app's 3-period average; shown for the chosen currency when > 0, fetched quietly); over-funding warns inline and the second submit goes ahead. Move dialog (`openMove()`, ⇄ on every card; overspent cards show **Cover** instead of Fund): From/To selects (Ready to assign = `''`), currency, "Overspent amount" / "All of it" chips; Cover takes from Ready to assign, or the richest envelope when RTA can't cover it. An envelope source can't give more than it holds (client + server); RTA may go negative after the second submit.
- **Sinking funds**: `budgetSnapshot()` adds `fund` to each sinking envelope (`fundToJson()`, from `loadSinkingFunds()` — the phone's plan: `thisMonth`, `spreadNow`/`topUpNow`/`steady`, `behind`, `mustChoose`, `mode`, `next` with `saved`, `steps`, `payments` (paid a year back + ahead), `copy` candidates, the fund's `categoryId`). The Budget page lists them first in their own section (`fundCard()`: next date, a bar per currency, status line, **Schedule** + **Fund this month** / **Catch up**). `POST /api/envelopes/:id/fund-month {mode?, always?}` funds this period's remaining share in each currency in one db transaction (`always` saves the mode); `PUT /api/envelopes/:id/behind-mode {mode: ask|spread|topup}`. Dialogs: `openFundDetail` (plan, payments, When behind select), `openCatchUp`, `openFundPayment` (name, date, one account+amount row per currency → `POST/PUT /api/planned` with `parts`; delete), `openCopyYear` (raise % per currency, ticks; one `POST /api/planned` per copy).
- **Account page** (`#/accounts/<id>`): `GET /api/transactions?accountId=` adds `accountAmount` (the row's signed effect on that account, in its currency) and `runningBalance` (balance right after it) from `accountRunning()` (`api/_running.dart`: replays the account's posted history from `initialBalance`, oldest first by createdAt then id, with `_applyTxToRunning()`'s rules; the list orders by createdAt desc, id desc to match). Header: balance, "Reconciled <date>" (pref `reconciled_<id>`, shared with the app), Edit (name, type, starting balance, decimal places; currency is fixed), Reconcile (actual balance → "Balance adjustment" income/expense via `recordTransaction`, then marks reconciled). Archive only at zero (half a unit of the last decimal, 400 `code: not_zero` otherwise); Accounts page lists archived accounts (`?archived=1`) with Unarchive.
- **Upcoming** (`#/upcoming`, `api/upcoming_handler.dart`): bills = enabled, non-deleted recurring + subscriptions, every occurrence in the 7/30/90-day window (`advanceRecurringDate`, `recurringAmountOn`, stops at `endDate`); only `occurrence: 0` opens the Post now / Skip dialog (`RecurringEngine.postNow/skipNext`). Planned payments are stored exactly like `plan_payment_screen.dart` (status `'planned'`, account currency, rate 1.0, one line — or one per currency with `parts: [{accountId, amount}]`, expenses only, one part per currency; edit = delete lines + soft-delete + insert). `GET /api/planned` gives a multi-part plan its `parts`; the Upcoming page stacks them and its Edit opens the fund payment form (the plain form would drop parts) and saved and posted with `PlannedEngine` (see Planned Payments; `latestCachedRate()`; a cross-currency transfer without a rate fails alone). `PUT /api/transactions/:id` refuses a plan (400) — re-recording it there would post it.
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

GET  /api/dashboard                    → household, period, accounts, envelopes (+ sealed), unallocated, 8 recent transactions (+ impact, balanceAfter), gettingStarted?
POST /api/getting-started/hide         → close the checklist (app pref getting_started_hidden)
GET  /api/transactions?page=&limit=    → { items (+ impact, balanceAfter), hasMore, summary? (page 1 with from+to) } (type, accountId incl. per-line accounts, from, to, search)
POST /api/transactions                 → create (transfer: exchangeRateToBase = source → destination)
GET  /api/changes?since=N              → { version, tables } — long-poll (≤25 s) for any database change
POST /api/import                       → { accountId, dryRun?, rows[≤1000] } → { imported, ready, categorized, duplicates, skipped }
POST /api/transactions/bulk            → { items: [create payload…] } ≤100 rows, all validated, then written in one db transaction → { ids, count } | 400 { error, row }
GET  /api/transactions/:id             → single + lines
PUT  /api/transactions/:id             → update in place (type can change; returns the same id)
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
GET  /api/envelopes/average-spending  → { items: { envelopeId: { currency: amount } } } (last 3 budget periods)
GET  /api/change-log                   → { limit, items: [{ kind added|edited|deleted|restored, at, txId, type, date, note, categoryName, amounts: [{currency, amount}], by (member name or null), source bill|web|null, changes: [{ field type|amount|category|account|date|note, from, to }] (amount: [{currency, amount}]; category/account: names, null = uncategorized; date ISO), replaced (bool), replacedBy (member name or null) }] } — from the operation log (see data.md Change history)
POST /api/envelopes/:id/fund           → add funding
POST /api/envelopes/move               → { fromId?, toId?, amount, currency } (null side = Ready to assign; AllocationEngine.moveMoney; 400 if the source envelope lacks it)

GET  /api/upcoming?days=30             → bill occurrences (recurring + subscriptions) with dueDate, daysUntil, occurrence, amount on that date
POST /api/recurring/:id/post-now       → { amount? } RecurringEngine.postNow (records today, advances; amount = an ask-first bill's confirmed amount)
(recurring/subscription create + PUT also take askFirst (bool) and remindDays (null | -1 | 0–30); recurringToJson returns both)
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
#/                Home (getting started, Ready to assign / All sealed, overspent + Cover, bills this week, envelopes, recent, accounts)
#/transactions    Month budget card, day cards, budget-impact rows, search, type + month filters, CSV export
#/history         Change history (from the Transactions page; rows open the edit dialog, deleted ones crossed out; an edit lists what it changed, a replaced edit says so)
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
