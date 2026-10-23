# Budgeting: envelopes, money rules, goals, travel, planned & bills

Developer notes moved out of CLAUDE.md (Oct 2026). Read before changing this area; update when you change it.

## Envelope Budgeting (Allocations)
The primary feature. Money flows: Income → Account → Unallocated pool → Fund envelopes → Spend from envelopes.

Two envelope types: **Spending** (periodic budget, resets each month) and **Flexible** (accumulates, optional target). Legacy `saving` type in DB is treated as `flexible` — no migration needed. Savings goals and debt tracking use the separate **Goals & Loans** feature (`/objectives`), which creates real transactions. Envelopes are virtual budget labels only.

A subcategory with no envelope of its own spends from its parent category's envelope (`recordTransaction` and the Budget tab's planned preview both resolve it). The Budget tab's "Spent" and the envelope hero's "$X spent" come from `periodSpendingProvider` (consumption ledger in the current period, by transaction date — `budgetPeriodFor()` in `period_engine.dart`), never from target − balance.

**Critical rule:** All money writes go through `AllocationEngine`. Screens never write to the database directly for transactions, transfers, or ledger entries.

## Balance Computation
Balances are computed dynamically from the ledger, never stored. Core invariant per currency:
```
Sum(account balances) = Unallocated + Sum(allocation balances)
```
`BalanceCalculator` has batch methods (`allAccountBalances`, `allAllocationBalancesByCurrency`) that compute all balances in ~7 fixed queries regardless of count. Providers use these batch methods — never loop `accountBalance()` per account.

## Transaction Model
- `transactions` table — header (type, amount, account, date)
- `transaction_lines` table — split lines (amount, currency, category, per-line account)
- `allocation_ledger` table — envelope debits/credits linked to transactions
- Each line can reference a different account (multi-account splits)

## Subscriptions
Recurring transactions can be flagged as subscriptions (`isSubscription` column). The `subscriptions/` feature provides a dedicated list and detail view with price history tracking (`priceHistory` JSON column). Subscriptions are still recurring transactions under the hood — the flag enables the separate UI.
- **Status** (`subscriptionStatus()` in `features/recurring/recurring_format.dart`, shared by list and detail): *Cancelled* only once the end (cancellation) date has passed; switched off = *Paused* (grey, same as Recurring); within 30 days of the end date = *Ending soon*; else *Active*. Paused and cancelled ones are left out of the monthly/yearly cost.
- Pause/resume and delete go through `RecurringEngine.toggleEnabled` / `.delete` (soft delete, moves `last_modified`); setting a cancellation date goes through `RecurringEngine.setEndDate` (moves `last_modified`). Recurring items are deleted from the edit sheet's Delete button (`EditRecurringSheet.onDelete` → confirm → `RecurringEngine.delete`). The detail screen's trash button deletes (confirm → SnackBar → pop); payments already posted stay.
- Recurring, Subscriptions, Upcoming bills and Planned share one wording/widget set in `recurring_format.dart`: `recurringFrequencyLabel`, `recurringNextLine` ("Next: {date} · Monthly"), `recurringPriceSuffix` ("/month"), `recurringMonthlyEquivalent`, `SummaryChip`/`SummaryStrip`; `RecurringStatusDot` lives in `recurring_screen.dart`.

## Multi-Currency Amount Safety
When computing base-currency totals (summaries, reports, dashboard), always use `isRealRate()` from `format_number.dart` to skip lines where the currency differs from base but `exchangeRateToBase` is 1.0 (rate not set). Without this check, foreign-currency amounts inflate totals (e.g., LBP 1,200,000 counted as $1,200,000).

**Critical rule:** Never sum `targetAmount` across envelopes without checking `targetCurrency`. Never sum account balances across currencies. Always filter to `baseCurrency` or group by currency before aggregation.

## Running Balances for Transfers
In `_applyTxToRunning()` (transactions_provider.dart), transfer destinations must use `tx.amount * tx.exchangeRateToBase` to convert to the destination currency. Using raw `tx.amount` adds the source currency amount to the destination account's running balance.

## Per-Line Currency in Assisted Flow
Each `_LineItem` stores its own `currency`, `accountId`, and `exchangeRateToBase` — captured via `_captureLineContext()` when adding another item or saving. The save logic uses each item's stored values, not the global `_selectedCurrency`.

## Per-Line Account in TransactionEntry
`_buildEntry()` in `transactions_provider.dart` uses the line's `accountId` (not the header's `tx.accountId`) for single-line transactions where the line has a per-line account. This ensures the transaction list and detail screen show the correct account name, currency, and running balance.

## Envelope Detail Layout
The envelope detail screen shows: balance hero card (pastel of the linked category color, `BudgetProgress` bar with percent + pace marker, theme Fund button; label reads "$X spent" for spending envelopes and "$X to go" for flexible ones) → settings form (hidden, via 3-dot menu) → recent activity (`LedgerDao.watchByAllocation`: spending dated and sorted by its transaction's date, rows of deleted transactions left out) → spending history. Settings, withdraw, revalue, archive, and delete are in the 3-dot menu. No duplicate transaction lists.

## Multi-Currency Envelopes
Envelopes can hold balances in multiple currencies. The fund sheet offers a currency picker showing all available unallocated currencies. The balance hero card shows the target currency balance prominently, with other currencies as `+ $50`. The allocation card does the same.

## Moving Money Between Envelopes
`AllocationEngine.moveMoney(fromAllocationId?, toAllocationId?, amount, currency)` — null side = Ready to assign; envelope↔envelope rows use entryType `'transfer'`, RTA→envelope `'funding'`, envelope→RTA `'withdrawal'`; one db transaction; an envelope source must hold the amount (StateError). UI: `showMoveMoneySheet()` (`features/allocations/move_money_sheet.dart`) from the envelope ⋮ menu (Move money; becomes Cover when overspent), the red **Cover** pill on overspent `AllocationCard`s (`onCover`), and the Saved SnackBar (`envelopeAfterSave()` in `widgets/save_feedback.dart` reads the consumption row → "X left" / "over by X" + Cover → `/allocations/:id` with extra `{'cover': true}` opens the sheet).

## Funding & Period Helpers
- Funding screen presets: Quick Fill (to target), Same as last period (`LedgerDao.fundedInPeriod`: funding + incoming moves by ledger date), What I spent last period (`watchSpendingInPeriod(...).first`), Clear. Fund All runs in one db transaction; funded rows keep their input.
- Envelope fund sheet chips: To target, All available.
- Budget tab: `PeriodSummaryCard` (first 7 days of a period, dismissed per period via `period_summary_dismissed`); ⋮ → Reorder envelopes (`allocations.sortOrder`, schema v20, `AllocationsDao.saveOrder`; `watchAll` orders sortOrder nulls-last, then name).
- Shared pieces in this area: `OptionCard` (`features/allocations/option_card.dart`) is the one single-choice card (new-envelope type, both leftover screens); `InlineEmojiGrid` + `emojiPickerGroups()` (`features/categories/emoji_groups.dart`) are the one localized emoji picker for envelopes and categories. Envelope delete: with linked categories a Cancel / Archive instead / Delete dialog, else `showConfirmDialog`; archive is a non-destructive `showConfirmDialog`.
- Period review includes negative balances: `resolveLeftover` with a negative amount → `toUnallocated` writes a covering `funding` row, `keep` a `carry_forward` marker. Pending detection counts any non-zero balance.
- Categories: envelope badge + long-press → Envelope (`category_envelope_sheet.dart`: link/unlink/create envelope named after the category).
- Goals: `_monthlyPace` = remaining / months left (started month counts) shown as "Needed per month".

## Withdrawal Validation
`withdrawFromAllocation()` checks sufficient balance before debiting. Throws `StateError` if the allocation doesn't have enough in the requested currency. Callers must catch and show an error.

## Notification Grouping
`NotificationService` groups multiple low-envelope alerts into one notification and multiple upcoming-bill alerts into one. Uses fixed notification IDs (1001, 1002) so each check replaces the previous. 24-hour cooldown between checks via SharedPreferences. Overspent detection checks each currency independently (never sums across currencies).

## Envelope Currency Handling
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

## Bills, Reports & Around the App (Oct 2026)

- `RecurringEngine.postNow(id, {on})` (record today — or on the day picked in "Paid on another day", at noon, never after today — keyed on the occurrence it pays, then advance) / `skipNext(id)` (advance only) from Upcoming Bills (tap a bill). `RecurringEngine.postedNotice` (ValueNotifier) counts auto-posted items; `MainScreen` shows "N recurring items posted".
- Reports: `reportsByPeriodProvider` (pref `reports_budget_period`) → `reportsStartDayProvider` (null unless the period start day ≠ 1); `reportBucketFor()` / `reportRangeFor()` in report_stats_provider.dart; the hub sets module-level `_reportsStartDay` and all month getters use `_reportMonth()`. Toggle: calendar icon by the Reports title.
- Reconcile (account ⋮ → Reconcile balance): live difference preview, "matches" just marks reconciled; last date in prefs `reconciled_<accountId>`.
- CSV import: Debit/Credit roles (`_rowAmount` = credit − debit), duplicate skip (account|day|amount|type vs existing lines), category guess from past titles contained in the description.
- Settings Cloud Sync tile subtitle reflects `syncProvider` (syncing / failed / "Synced <when>"). Onboarding base currency defaults to the region currency (`_localeCurrency`).
- Daily reminder: `DailyReminderService.refresh(loggedToday:)` on resume refills the 14-day window and cancels today's when a non-recurring transaction exists for today.
- Home widget: `HomeWidgetService.update()` writes `widget_title`/`widget_line` to shared_preferences (Android reads `FlutterSharedPreferences` → `flutter.widget_*` in `SpendingWidget.kt`) and calls the `budgetseal/widget` method channel (`MainActivity.kt`) to redraw; app.dart calls it on pause.

## Seal Moments

The brand's wax seal (`shared/widgets/seal_mark.dart`: `SealMark` painted scalloped disc in `accentBright` with an ink check like the app icon; `inverse: true` = ink seal with a gold check for use on the gold banner) marks finished budgeting — calm, no confetti:
- **Fully funded envelope**: `sealedEnvelopesProvider` (`core/providers/seal_provider.dart`) = envelopes with a target where, in the target currency, spending envelopes received ≥ target this period (`fundedInPeriod`; spending afterwards keeps the seal) and flexible ones hold ≥ target. `AllocationCard(sealed:)` puts a 20 px seal on the icon; the envelope hero shows "Fully funded" + a 30 px seal.
- **All sealed**: `ReadyToAssignBanner` with nothing left to assign in any currency, envelopes present, `anyFunded` (some envelope holds money) and no envelope below zero (`anyOverspent`) turns into "All sealed — Every bit of your money has a job." with the inverse seal and no Assign button.
- **"<Month> sealed"**: `PeriodSummaryCard` (first week of a period) is titled with the closed period's month (its middle day, capitalized) and the seal — only when it stayed within budget (budgeted − spent ≥ 0); over budget it reads "<Month> budget" without the seal, like the Activity month card. Its **See the recap** opens the month close.
- **Month close** (`/month-close`, `features/allocations/month_close_screen.dart`, Oct 2026): the last period closed. Numbers come from `envelopePeriodStats()` (`core/engine/budget_history.dart`, base currency): per envelope funded (`fundedInPeriod`), spent (`watchSpendingInPeriod`) and the closing balance (`LedgerDao.balancesAt(end)`: rows dated before the end, spending at its transaction date) → `EnvelopeOutcome` held (≥ 0) / over (< 0) / idle. **Budgeted = Σ(closing + spent)** — what the envelopes had to spend, money funded before the period included (the card uses the same). Screen: a `DatedSeal` ("OCT" / "2026", stamped on with a scale-in) when within budget, else a calendar circle; "<Month> sealed" / "<Month> is done"; a story line (kept / over + all held / one / n over); Budgeted · Spent · Kept|Over; "N envelopes held" + one row per overspent envelope ("Over by"); What was left (`resetReturnedSince(current.start)`: what the period reset sent back to Ready to assign, else "stays there"), Review N envelopes when manual resets are pending (`/period-transition`); **Plan <new month>** → `/funding`; **Share recap** renders the top part (`RepaintBoundary`) to a PNG and shares it (`share_plus`).
- `SealStamp(sealed:)` stamps the seal on (scale 1.8→1, slight twist, light haptic) only when it turns sealed while on screen (`didUpdateWidget`, or `stampOnMount` when the parent swaps layouts); already sealed = shown still.

## Over-funding Warning

Both the funding screen (bulk) and envelope detail screen (single fund) check if the funding amount exceeds unallocated balance. Shows a warning dialog: "Your unallocated balance will go negative. Continue anyway?" with Cancel/Fund Anyway options.

## Period Reset

`lib/core/services/period_reset_service.dart` + `lib/core/providers/period_reset_provider.dart`. At app launch, `periodResetCheckProvider` checks all periodic envelopes whose period has elapsed.

- Envelopes with `autoReset = true` (default): automatically zeroed out via ledger entry on period start
- Envelopes with `autoReset = false`: flagged as "pending manual reset" — shown with amber glow on the Budget tab and a banner prompting the user to review
- Toggle per-envelope in the envelope detail screen settings (3-dot menu)
- "Pending" (`PeriodResetService.getPendingManualIds`) = manual, periodic, created before the current period start, positive balance, and no `period_reset`/`carry_forward` ledger row since the period start — reviewing (the `carry_forward` marker counts) clears it until the next period. The Review screen (`/period-transition`) lists only pending envelopes and invalidates `pendingResetProvider` when done.
- `PeriodResetService.checkAndAutoReset()` runs once per app launch, tracked via SharedPreferences timestamp. The first run on an install only records the period (never empties envelopes mid-period). Reset ledger rows use the deterministic id `reset:<allocId>:<periodStart yyyy-MM-dd>:<currency>` inserted with `insertOrIgnore`, so two synced devices can't reset the same envelope twice. Period bounds come from `budgetPeriodFor()` (clamped start day).

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

### Money logic (`TravelAccountService`, core/services/travel_account_service.dart)
- `activeWallet()` / `archivedWallet()`: newest by `lastModified`, `limit(1)` — there can be several archived wallets per currency ("Create new"), a `getSingleOrNull()` there threw and blocked every later exchange.
- An **open** wallet in the target currency gets the money (top-up mid-trip; the button reads "Exchange & add to wallet"); only without one is an archived wallet offered.
- `exchange()`: create/unarchive the wallet + `recordTransfer` (rate = received / amount) in one db transaction. New wallets are named `travelWalletName`. More than the source holds → warning dialog, allowed.
- `convertBack()`: reads the balance inside the db transaction; if it isn't the `expectedBalance` shown in the sheet → `TravelBalanceChangedException` and nothing happens (archiving with money left drops it out of every balance); else transfers it all and archives. Same-currency destination prefills the amount received.
- `zeroThreshold(currency)` = half a unit of the last decimal (auto-archive and the checks above).

### Key Rules
- Travel accounts have `isTravel = true` — visually distinguished with a plane badge
- Auto-archive threshold is currency-aware: 0.5 for JPY (0 decimals), 0.005 for USD (2 decimals), 0.0005 for KWD (3 decimals)
- Same-currency exchange is blocked (no point creating a travel wallet in your own currency)
- Regular account creation never suggests archived travel wallets

## Per-Account Decimal Precision

`accounts.decimalPlaces` (nullable int) — overrides the default decimal display for a currency.

- **Auto-detect**: `currencyDecimals()` in `format_number.dart` returns ISO 4217 defaults (0 for JPY/KRW, 3 for BHD/KWD, 2 for everything else) — plus **LBP, SYP, IRR, IQD = 0** (user decision Oct 2026: their minor units are unused; mirrored in `ZERO_DEC` in app.js)
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
- **One engine** (`lib/core/engine/planned_engine.dart`, `PlannedEngine`), used by the phone screens and the Web Companion: `save()` creates or replaces (`replaceId`: lines deleted + old row soft-deleted) in one db transaction; `post()` fetches rates first (`RateLookup` — phone: `getRateWithCache`, web: `latestCachedRate`), then records the payment and deletes the plan in one db transaction.
- **Posting**: swipe right or tap "Post". The posted transaction's id is `PlannedEngine.postedId(planId)` = `planned:<planId>`, so a double tap, Post all after Post, or two synced devices posting the same plan give one transaction (a plan already gone returns that id). Dated on the planned date, or **today when the plan is still in the future** (paid early — a future-dated row would move balances but stay hidden in Activity). A cross-currency transfer without a rate throws `CurrencyConversionException` and the plan stays.
- **Post All**: month header button posts all planned items for that month in batch
- **Transaction list**: planned items appear dimmed at top of target month, excluded from daily totals
- **Envelope preview**: Budget tab shows `$X planned` on envelope cards when planned expenses exist for linked categories
- Routes: `/planned-payments`, `/plan-payment`

## Upcoming Bills

`lib/features/recurring/upcoming_bills_screen.dart` — shows all enabled recurring transactions sorted by next due date.

- **Urgency indicators**: Cashew blues — indigo `#6577E0` "Overdue by N days", blue `#58A4C2` "Due today/tomorrow/in N days" (lighter variants in dark mode). No red/amber/green alarm colors.
- Displays frequency, amount, type icon per bill
- Route: `/upcoming-bills`, accessible from More > Upcoming Bills

## Archived Envelopes

`recordTransaction()` ignores archived/deleted envelopes when resolving category → envelope (the line stays unbudgeted). Budget tab ⋮ menu → **Archived envelopes** (`archived_envelopes_sheet.dart`) lists them with Unarchive (`AllocationsDao.unarchive`). Envelope cards resolve their category through `categories.allocationId` (top-level category first), falling back to the legacy `allocations.categoryId` join.

## Exchange Rates Screen

`/exchange-rates` (Settings › Preferences › Exchange rates) lists every currency used by accounts, recurring items and manual rates. Refresh calls `getRateWithCache(forceRefresh: true)`. Tapping a currency sets a **manual rate** (`fx_rates.source = 'manual'`, `FxService.saveManualRate/clearManualRate`); `manualRate()` is checked first by `getRateWithCache()` and `latestCachedRate()` in either direction, so it wins until cleared. Lines saved without a user rate use `rateToBaseOrOne()` (live → cached → 1.0); a foreign line still at 1.0 shows an amber "No rate" tag in `TxTile`.

## Archived Accounts

An account can only be archived at a zero balance (`_canArchive()` in account_detail_screen.dart) — archived accounts drop out of every balance, so archiving one with money would silently pull it out of Unallocated. Accounts screen has a 3-dot menu with "Show Archived" / "Hide Archived" toggle. Archived accounts appear in a separate "ARCHIVED" section below active ones, dimmed at 60% opacity with an archive badge. Each has an unarchive icon button that opens a confirmation dialog, sets `archived: false` + `lastModified: now`, and refreshes the provider.

## Unallocated Multi-Currency Display

The Ready to assign banner (unallocated money) on the Budget tab shows only the base currency amount by default. If the user has unallocated funds in other currencies, a "+ N other currencies" link and chevron arrow appear. Tapping expands an animated breakdown showing each currency with its amount. This avoids the anti-pattern of converting/summing across currencies with unreliable exchange rates. Single-currency users see no extra UI.
