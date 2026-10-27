# Budgeting: envelopes, money rules, goals, travel, planned & bills

Developer notes moved out of CLAUDE.md (Oct 2026). Read before changing this area; update when you change it.

## Envelope Budgeting (Allocations)
The primary feature. Money flows: Income → Account → Unallocated pool → Fund envelopes → Spend from envelopes.

Three envelope types: **Spending** (periodic budget, resets each month), **Flexible** (accumulates, optional target) and **Sinking fund** (`sinking`: permanent, saves monthly for a payment schedule — see [Sinking Funds](#sinking-funds)). Legacy `saving` type in DB is treated as `flexible` — no migration needed. Code that only branches on `type == 'spending'` treats a sinking fund like a flexible envelope (Web Companion too). Savings goals and debt tracking use the separate **Goals & Loans** feature (`/objectives`), which creates real transactions. Envelopes are virtual budget labels only.

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
- Recurring, Subscriptions, Upcoming bills and Planned share one wording/widget set in `recurring_format.dart`: `recurringFrequencyLabel`, `recurringNextLine` ("Next: {date} · Monthly"), `recurringPriceSuffix` ("/month"), `recurringMonthlyEquivalent`, `SummaryChip`/`SummaryStrip`, and `RecurringRow` (the Recurring and Subscriptions card row: name + amount on top — the amount capped at 150 dp and scaled down, so LBP 1,800,000 never squeezes the name — then "Next: … · Monthly" at full width, a status line only when not simply active, and the pause/resume button); `RecurringStatusDot` lives in `recurring_screen.dart`. Planned payments show "Overdue" (indigo) in place of the date once the day has passed. Insights' "Recurring transactions … /month" counts base-currency expenses only (not salary or transfers).

## Multi-Currency Amount Safety
When computing base-currency totals (summaries, reports, dashboard), always use `isRealRate()` from `format_number.dart` to skip lines where the currency differs from base but `exchangeRateToBase` is 1.0 (rate not set). Without this check, foreign-currency amounts inflate totals (e.g., LBP 1,200,000 counted as $1,200,000).

**Critical rule:** Never sum `targetAmount` across envelopes without checking `targetCurrency`. Never sum account balances across currencies. Always filter to `baseCurrency` or group by currency before aggregation.

## Running Balances for Transfers
A transfer's destination receives `tx.receivedAmount` (`destinationAmount`, in the destination's currency; `core/database/transfer_amounts.dart`) — in running balances, balances, tiles and the receipt. Never raw `tx.amount` (the source currency) and never `amount × exchangeRateToBase` (the source→destination rate, still written only for phones on 0.11; the getter falls back to it for a just-synced old row).

## Per-Line Currency in Assisted Flow
Each `_LineItem` stores its own `currency`, `accountId`, and `exchangeRateToBase` — captured via `_captureLineContext()` when adding another item or saving. The save logic uses each item's stored values, not the global `_selectedCurrency`.

## Per-Line Account in TransactionEntry
`_buildEntry()` in `transactions_provider.dart` uses the line's `accountId` (not the header's `tx.accountId`) for single-line transactions where the line has a per-line account. This ensures the transaction list and detail screen show the correct account name, currency, and running balance.

## Envelope Detail Layout
The envelope detail screen shows: balance hero card (pastel of the linked category color, `BudgetProgress` bar with percent + pace marker, theme Fund button; label reads "$X spent" for spending envelopes and "$X to go" for flexible ones) → settings form (hidden, via 3-dot menu) → recent activity (`LedgerDao.watchByAllocation`: spending dated and sorted by its transaction's date, rows of deleted transactions left out) → spending history. Settings, withdraw, revalue, archive, and delete are in the 3-dot menu. No duplicate transaction lists.

## Multi-Currency Envelopes
Envelopes can hold balances in multiple currencies. The fund sheet offers a currency picker showing all available unallocated currencies. The balance hero card shows the target currency balance prominently, with other currencies as `+ $50`. The allocation card does the same.

## Moving Money Between Envelopes
`AllocationEngine.moveMoney(fromAllocationId?, toAllocationId?, amount, currency)` — null side = Ready to assign; envelope↔envelope rows use entryType `'transfer'`, RTA→envelope `'funding'`, envelope→RTA `'withdrawal'`; one db transaction; an envelope source must hold the amount (StateError). UI: `showMoveMoneySheet()` (`features/allocations/move_money_sheet.dart`) from the envelope ⋮ menu (Move money; becomes Cover when overspent), the red **Cover** pill on overspent `EnvelopeRow`s (`onCover`), and the Saved SnackBar (`envelopeAfterSave()` in `widgets/save_feedback.dart` reads the consumption row → "X left" / "over by X" + Cover → `/allocations/:id` with extra `{'cover': true}` opens the sheet).

## Funding & Period Helpers
- Funding screen presets: Quick Fill (to target), Same as last period (`LedgerDao.fundedInPeriod`: funding + incoming moves by ledger date), What I spent last period (`watchSpendingInPeriod(...).first`), Average spending (`averageSpending()` / `recentAverageSpending()` in `core/engine/spending_average.dart` over the last 3 budget periods, counted from the first with spending for that envelope, rounded up to whole units; each envelope row also shows "Usually spends $X a month" — tap fills it), Clear. Fund All runs in one db transaction; funded rows keep their input.
- Envelope fund sheet chips: To target, All available.
- Budget tab layout (Oct 2026): Ready to assign banner → one line "$X budgeted · $Y spent" + "N days left" (base-currency envelopes, `periodSpendingProvider`, `calendarDaysBetween(now, period.end)`) → Goals & loans → **Needs attention** (overspent envelopes — `overspentCurrency()` in `envelope_row.dart`: the target currency below 0, else any other currency side below 0, e.g. a EUR expense with no euros funded; Cover moves money in that currency; in a red-tinted card; not while searching; Home's overspent card uses the same rule) → one white card per section of compact `EnvelopeRow`s (`shared/widgets/envelope_row.dart`: 38 px icon + seal, name + what's left, 5 px used bar = spent / target (flexible: balance / target, green; amber under 10 % left), "$X spent of $Y" / "Nothing spent yet" / "N% saved", planned amount, other-currency debt, amber dot when a manual reset is pending; overspent rows show "Over by $X" + Cover). The cart button left the list: the envelope screen has **Spend** next to Fund (prefills its linked category).
- Budget tab: `PeriodSummaryCard` (first 7 days of a period, dismissed per period via `period_summary_dismissed`); ⋮ → Reorder envelopes (`allocations.sortOrder`, schema v20, `AllocationsDao.saveOrder`; `watchAll` orders sortOrder nulls-last, then name).
- Shared pieces in this area: `OptionCard` (`features/allocations/option_card.dart`) is the one single-choice card (new-envelope type, both leftover screens); `InlineEmojiGrid` + `emojiPickerGroups()` (`features/categories/emoji_groups.dart`) are the one localized emoji picker for envelopes and categories. Envelope delete: with linked categories a Cancel / Archive instead / Delete dialog, else `showConfirmDialog`; archive is a non-destructive `showConfirmDialog`.
- Period review includes negative balances: `resolveLeftover` with a negative amount → `toUnallocated` writes a covering `funding` row, `keep` a `carry_forward` marker. Pending detection counts any non-zero balance.
- Categories: envelope badge + long-press → Envelope (`category_envelope_sheet.dart`: link/unlink/create envelope named after the category).
- Goals: `_monthlyPace` = remaining / months left (started month counts) shown as "Needed per month".

## Withdrawal Validation
`withdrawFromAllocation()` checks sufficient balance before debiting. Throws `StateError` if the allocation doesn't have enough in the requested currency. Callers must catch and show an error.

## Notification Grouping
`NotificationService` groups multiple low-envelope alerts into one notification (fixed id 1001, budget warnings 1003; 24-hour cooldown per check via SharedPreferences). Overspent detection checks each currency independently (never sums across currencies).

## Bill reminders
`NotificationService.scheduleBills()` (runs in `runChecks` at launch/resume, and via `rescheduleBillReminders(ref)` after a bill is added, edited, posted or skipped) gives each enabled bill its own notification on channel `budgetseal_bills`, id `billNotifId(billId)` (20000 + FNV hash):
- Lead time per bill: `recurring_transactions.remindDays` (null = `billRemindDefault` 2 days, 0 = on the day, -1 = off; choices in `billRemindChoices`), at 09:00 local via `zonedSchedule` (inexact).
- Each occurrence is reminded once: SharedPreferences `notif_bill_state` maps bill → `{due, at, t, b, snooze?}`. A reminder whose time passed without firing (app closed, bill just added) shows at once, unless the bill is more than 7 days overdue.
- Buttons: **Log it** (opens `/upcoming-bills?bill=<id>`, which opens that bill's sheet) and **Remind me tomorrow** — `snoozeBill()`, run by the top-level `notificationTapBackground` entry point in a background isolate (no UI): it reschedules the same text at the same clock time tomorrow (UTC, from the saved labels `notif_bill_labels`) and marks the state `snooze` so the next `scheduleBills` keeps it. iOS uses the `bill` notification category.

## Envelope Currency Handling
- **Line currency = account currency**: `recordTransaction()` runs `_toAccountCurrencies()` first — a line entered in another currency (€50 on a USD account) is converted with its own rate or the latest cached rate (`latestCachedRate()` in fx_service.dart) and the original amount is appended to the line note. No rate at all → `CurrencyConversionException` (UI text via `txSaveErrorText()` in `shared/utils/save_errors.dart`). Account balances sum line amounts, so they never mix currencies.
- **Envelope debit in the spent currency**: the consumption ledger entry uses the line's currency, never a conversion into the envelope's currency (that broke the per-currency invariant). A foreign debit shows as cross-currency debt on the envelope (`hasCrossDebt`).
- **Scheduled items get today's rate**: recurring bills post with `latestCachedRate()` (cache only — runs before `runApp`, must not hit the network); a cross-currency recurring transfer without a rate stays due. Planned payments fetch a rate (`fxServiceProvider`) when the user posts them.
- **Goal payment tags** are `[obj:ID|amount]` (amount in the objective's currency, since the line is stored in the account's currency); `visibleNote()` (`shared/utils/note_text.dart`) hides the tag wherever a note is displayed — keep the raw note when editing.
- An income/expense's `tx.amount`/`tx.currency` are the **base-currency** total (every posted one has lines since v23 — `recordIncome`/`recordExpense`/`forceCommitExpense` write one too) — never use them directly for display in envelope contexts. A transfer's are what left the source account.
- **Changing the base currency** (Settings › Base currency → `changeBaseCurrencyFlow`, `features/settings/base_currency_flow.dart`): with transactions recorded it asks for one rate (1 old = r new; latest known, editable via the calculator — the dialog closes for the sheet and reopens) and runs `changeBaseCurrency()` (`core/engine/base_currency_change.dart`) in one DB transaction. Line and ledger `exchangeRateToBase` → `convertedRateToBase()` (line in new base → 1; in old base → r; no rate stays no rate; a result inside the 1.0 "no rate" band is nudged to 1.0011/0.9989). Transactions whose lines all carry `accountId` (recordTransaction's kind) get `amount` re-summed from the converted lines in the new currency (rate 1); header-only income/expense (none left after v23's conversion, but the branch stays) keep `amount` and convert only their rate; **transfers are untouched** (they hold account-currency amounts: sent and `destinationAmount`). Account balances are unchanged (test `base_currency_change_test.dart`). **Shared budgets (sync step 3):** allowed — every update it makes is logged and syncs field by field; the dialog adds "It changes for everyone who shares this budget" (`hasOthers`). The change is appended to `households.baseHistory` (v25, JSON `[{from,to,rate}]`); after each merge `convertToCurrentBase()` (log_sync.dart) converts any posted income/expense whose header `currency` isn't the base (another phone recorded it against the old base before syncing) along `basePath()` (the changes from the last one leaving its currency; none → left alone), lines' and its debits' rates via `convertedRateToBase`, total re-summed. That conversion is **logged** (each phone writes the same values), else merging the line again from its insert would bring the old rate back. Not converted: ledger rows without a transaction (funding) recorded offline against the old base, and two phones changing the base at once (the later change's rows and base win). Test: `log_sync_test.dart` "base currency changed on one phone while another records offline".
- For envelope progress/spent calculations, sum **line amounts** that match the envelope's `targetCurrency`, not `tx.amount`.
- Budget summary on the allocations screen only sums base-currency envelopes to avoid mixing currencies.
- The spend button pre-fills the envelope's `targetCurrency`, not `baseCurrency`.
- `AllocationWithBalance.totalInBase` sums raw balances across currencies without conversion — use `balanceByCurrency[currency]` for accurate per-currency display.
- **Allocation card multi-currency display**: `isTargetOverspent` (target currency negative) shows red border/amount. `hasCrossDebt` (other currency negative) shows amber border + debt amount in amber text. Progress bar stays green when target is met even with cross-currency debt.

## Bills, Reports & Around the App (Oct 2026)

- **Ask before posting** (`recurring_transactions.askFirst`): `processRecurring()` skips these, so a due one waits; Upcoming bills labels it "Confirm the amount" and its first action is "Confirm amount and post", which opens the calculator on the usual amount and calls `postNow(id, amount:)` (that payment only; the bill's amount stays). Set in the add/edit bill sheet (`BillOptionsFields` in `recurring_format.dart`, with the "Remind me" picker); `RecurringEngine.setBillOptions()` for code.
- `RecurringEngine.postNow(id, {on, amount})` (record today — or on the day picked in "Paid on another day", at noon, never after today — keyed on the occurrence it pays, then advance) / `skipNext(id)` (advance only) from Upcoming Bills (tap a bill). `RecurringEngine.postedNotice` (ValueNotifier) counts auto-posted items; `MainScreen` shows "N recurring items posted".
- Reports: `reportsByPeriodProvider` (pref `reports_budget_period`) → `reportsStartDayProvider` (null unless the period start day ≠ 1); `reportBucketFor()` / `reportRangeFor()` in report_stats_provider.dart; the hub sets module-level `_reportsStartDay` and all month getters use `_reportMonth()`. Toggle: calendar icon by the Reports title.
- Reconcile (account ⋮ → Reconcile balance): live difference preview, "matches" just marks reconciled; last date in prefs `reconciled_<accountId>`.
- CSV import: Debit/Credit roles (`_rowAmount` = credit − debit), duplicate skip (account|day|amount|type vs existing lines), category guess from past titles contained in the description.
- Settings Cloud Sync tile subtitle reflects `syncProvider` (syncing / failed / "Synced <when>"). Onboarding base currency defaults to the region currency (`_localeCurrency`).
- Daily reminder: `DailyReminderService.refresh(loggedToday:)` on resume refills the 14-day window and cancels today's when a non-recurring transaction exists for today.
- Home widget: `HomeWidgetService.update()` writes `widget_title`/`widget_line` to shared_preferences (Android reads `FlutterSharedPreferences` → `flutter.widget_*` in `SpendingWidget.kt`) and calls the `budgetseal/widget` method channel (`MainActivity.kt`) to redraw; app.dart calls it on pause.

## Seal Moments

The brand's wax seal (`shared/widgets/seal_mark.dart`: `SealMark` painted scalloped disc in `accentBright` with an ink check like the app icon; `inverse: true` = ink seal with a gold check for use on the gold banner) marks finished budgeting — calm, no confetti:
- **Fully funded envelope**: `sealedEnvelopesProvider` (`core/providers/seal_provider.dart`) = envelopes with a target where, in the target currency, spending envelopes received ≥ target this period (`fundedInPeriod`; spending afterwards keeps the seal) and flexible ones hold ≥ target — and never below zero (an overspent envelope loses the seal; same rule in the Web Companion via `isEnvelopeSealed`). `EnvelopeRow(sealed:)` puts an 18 px seal on the icon; the envelope hero shows "Fully funded" + a 30 px seal.
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

- **Entry**: More > Planned Payments > + FAB opens `plan_payment_screen.dart` (one amount). Plans with a part per currency (sinking funds) are made and edited in `fund_payment_screen.dart` — see [Sinking Funds](#sinking-funds)
- **Form fields**: type, amount (calculator), account, category, title/note, target month + optional exact date
- **Storage**: normal transaction with `status = 'planned'`, excluded from all balance/report queries
- **One engine** (`lib/core/engine/planned_engine.dart`, `PlannedEngine`), used by the phone screens and the Web Companion: `save()` creates, or edits in place (`replaceId`: same id; header updated, lines rewritten as `<id>:<revision>:line<n>` under a new `revision`, so two phones editing one plan keep one — sync's `settleTransactions()` keeps the newer revision's lines and leaves a plan's header as merged) in one db transaction; `post()` fetches rates first (`RateLookup` — phone: `getRateWithCache`, web: `latestCachedRate`), then records the payment and deletes the plan in one db transaction.
- **Posting**: swipe right or tap "Post". The posted transaction's id is `PlannedEngine.postedId(planId)` = `planned:<planId>`, so a double tap, Post all after Post, or two synced devices posting the same plan give one transaction (a plan already gone returns that id). Dated on the planned date, or **today when the plan is still in the future** (paid early — a future-dated row would move balances but stay hidden in Activity). A cross-currency transfer without a rate throws `CurrencyConversionException` and the plan stays.
- **Post All**: month header button posts all planned items for that month in batch
- **Transaction list**: planned items appear dimmed at top of target month, excluded from daily totals
- **Envelope preview**: Budget tab shows `$X planned` on envelope cards when planned expenses exist for linked categories
- Routes: `/planned-payments`, `/plan-payment`

## Sinking Funds

A sinking fund is an envelope with `type = 'sinking'` (periodicity `permanent`, no target of its own). Its **schedule** is not stored on the envelope: it is every planned expense (`status = 'planned'`) and every enabled yearly / every-3+-months recurring expense (`isFundBill()`) whose category spends from the fund (`envelopeForCategory()`), plus what was already paid from it (its consumption ledger rows, one payment per transaction). Monthly and shorter bills are left out (`fundBillDates()` returns nothing for them).

- **Engine** (`core/engine/sinking_fund.dart`, pure): `planSinkingFund()` levels each currency on its own — for each payment ahead, (cumulative due − saved) / fundings left before it (the period it falls in counts: money goes in at the period start); the share is the max over payments, rounded **up** to the currency's decimals. Periods follow the household's start day (`budgetPeriodFor`). An unpaid payment whose date has passed is due now. A payment already made this period stays in this period's sums, with `balanceAtStart` = the raw balance at the period start (before it was paid).
- **Behind**: the ideal path is simulated from the fund's first period (at most a year back) with the balance then, funding the level share every period and paying what was paid; behind = ideal balance now − actual balance at the period start − what went in this period (only above 1 % of the share / one unit). `spread` = the share from the actual balance; `topUp` = shortfall at the period start + the steady share from the ideal balance. `FundPlan.remaining(mode)` = share − funded this period. `steps(mode)` = runs of equal monthly amounts up to the last payment (this period counts at least what was funded).
- **Catch-up setting**: `allocations.behindMode` (schema v21, synced): `null` = ask, `'spread'`, `'topup'` (`BehindMode`). `SinkingFund.mustChoose` = behind + ask + this period not funded yet → the Budget row says "Behind by X · choose how to catch up" and the fund's button opens the catch-up sheet (`showCatchUpSheet`: Spread / Top up, "Always do this" saves the mode).
- **Provider** (`core/providers/sinking_fund_provider.dart`): `sinkingFundsProvider` (fund id → `SinkingFund`: plan, paid in the past year, `history` for the copy) via `loadSinkingFunds()` (one plans query, one lines query, one recurring query, one ledger query for all funds). Re-runs on `allocationsProvider` (ledger and transaction writes), categories, and recurring-table updates.
- **Multi-currency payments**: `PlannedEngine.save(parts: [PlanPart(amount, currency, accountId)])` writes one line per part (each in its account's currency at rate 1.0; the header takes the first part). Posting already records every line. The Planned list stacks the parts and its month totals count every base-currency line; tapping a plan with several parts opens `/fund-payment` (keeps the parts) instead of `/plan-payment`.
- **Screens** (`features/allocations/sinking_fund_widgets.dart`, `copy_year_screen.dart`, `features/planned/fund_payment_screen.dart`):
  - Budget tab: a **Sinking funds** section first (`_typeOrder`), `SinkingFundRow` (next due date, a bar per currency of what's saved toward the next payment via `savedToward()`, status line `fundStatusLine()`), section line "$X + LBP Y this month" (sum of `thisPeriod` per currency). An overspent fund still goes to Needs attention as an `EnvelopeRow`.
  - Envelope screen: `SinkingFundPanel` replaces the balance hero (next payment, saved per currency, this month + Fund this month / Catch up, Monthly plan, Payments — paid (dimmed, a year back), planned (tap → `/fund-payment` with `planId`), bills (tap → `/recurring`) — Add payment, Copy from last year, When behind). Settings hide Cycle and Target for a fund; saving forces `permanent` and no target. A new fund without a linked category gets a category of its own (same name, expense, linked), then opens on its screen.
  - `/fund-payment` (`FundPaymentScreen`): name, due date, one part per currency (account picker → currency; one part per currency), the fund's category; edit / delete (`deleteTransaction`).
  - `/allocations/:id/copy-year` (`CopyYearScreen`, "Copy from last year"): `copyFromLastYear()` takes the fund's paid payments of the past year and its planned ones, a year later (day clamped), drops ones that would be in the past, unticks those within 14 days of an existing plan ("already planned"); a raise % per currency; saves each as a plan in the fund's category, each part from last year's account (or any live account in that currency). Nothing is copied automatically: the user runs it when the new schedule is decided.
  - Fund screen (`funding_screen.dart`): sinking funds in their own group, one amount per currency (`_fundAmounts`), Fill = this period's remaining share. **Quick fill** fills spending envelopes as before, then each fund's share, soonest due first, out of what Ready to assign has left per currency.
  - Subscriptions: a card lists active yearly / quarterly subscriptions no fund saves for (no fund's upcoming has their `recurringId`) with about a month's share; **Save monthly** → `createFundForBill()`: a fund named after the bill + its own subcategory (under the bill's category, same icon/color) linked to the fund, and the bill moved to it (`lastModified` moved). A subscription a fund saves for shows a chip under its row (`RecurringRow.extra`): "Saving · $X of $Y" toward its next payment (+ "catching up" when behind); tap → the fund.
  - Web Companion: same plan through `fundToJson()` — see [web-companion.md](web-companion.md).

## Upcoming Bills

`lib/features/recurring/upcoming_bills_screen.dart` — shows all enabled recurring transactions sorted by next due date.

- **Urgency indicators**: Cashew blues — indigo `#6577E0` "Overdue by N days", blue `#58A4C2` "Due today/tomorrow/in N days" (lighter variants in dark mode). No red/amber/green alarm colors.
- Displays frequency, amount, type icon per bill
- Route: `/upcoming-bills` (`?bill=<id>` opens that bill's actions — the reminder's Log it), accessible from More > Upcoming Bills
- Edit opens the bill's edit sheet in place (subscriptions open their detail screen)

## Archived Envelopes

`recordTransaction()` ignores archived/deleted envelopes when resolving category → envelope (the line stays unbudgeted). Budget tab ⋮ menu → **Archived envelopes** (`archived_envelopes_sheet.dart`) lists them with Unarchive (`AllocationsDao.unarchive`). Envelope cards resolve their category through `categories.allocationId` (top-level category first), falling back to the legacy `allocations.categoryId` join.

## Exchange Rates Screen

`/exchange-rates` (Settings › Preferences › Exchange rates) lists every currency used by accounts, recurring items and own rates. Refresh calls `getRateWithCache(forceRefresh: true, liveOnly: true)`. **Rate source per pair** (roadmap #3, user's decision Oct 27): tapping a currency offers *Live rate* / *Last rate you got* / *Your fixed rate* (with each one's value and date; fixed is typed with the calculator after the dialog closes). `RateSource` in `fx_service.dart`: fixed = a `fx_rates.source = 'manual'` row exists (`saveManualRate/clearManualRate`); got/live = `households.settingsJson` → `rateSources["A/B"]` (alphabetical pair; synced, so a shared budget agrees; `setRateSource()`). The rate got is `source = 'got'`, one row per pair (`noteRateGot()` replaces it), written by `recordTransfer(rateGot: true)` when the two accounts' currencies differ — every transfer saved from a form (classic, one screen, assisted, Web Companion) — and by payments with change. `getRateWithCache()` and `latestCachedRate()` check `_ownRate()` first (fixed, else the rate got when chosen and known), then fetched rows only (`source IN ('api','mock')` — a got/manual row never passes for a live one). Tests: `test/core/fx/rate_source_test.dart`. Lines saved without a user rate use `rateToBaseOrOne()` (live → cached → 1.0); a foreign line still at 1.0 shows an amber "No rate" tag in `TxTile`.

## Archived Accounts

An account can only be archived at a zero balance (`_canArchive()` in account_detail_screen.dart) — archived accounts drop out of every balance, so archiving one with money would silently pull it out of Unallocated. Accounts screen has a 3-dot menu with "Show Archived" / "Hide Archived" toggle. Archived accounts appear in a separate "ARCHIVED" section below active ones, dimmed at 60% opacity with an archive badge. Each has an unarchive icon button that opens a confirmation dialog, sets `archived: false` + `lastModified: now`, and refreshes the provider.

## Unallocated Multi-Currency Display

The Ready to assign banner (unallocated money) on the Budget tab shows only the base currency amount by default. If the user has unallocated funds in other currencies, a "+ N other currencies" link and chevron arrow appear. Tapping expands an animated breakdown showing each currency with its amount. This avoids the anti-pattern of converting/summing across currencies with unreliable exchange rates. Single-currency users see no extra UI.
