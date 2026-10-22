# Transactions, Activity & Reports

Developer notes moved out of CLAUDE.md (Oct 2026). Read before changing this area; update when you change it.

## Category Selection
Both the assisted flow and classic form use the same `CategorySheet` (Cashew style): search field, type toggle (Expense/Income), then a 4-column icon grid of parent categories. Tapping a parent that has subcategories opens a subcategory step (back arrow returns); searching shows a flat grid of all matches. Never drop the search field.

## Add/Edit Form & Detail Header
The classic form opens with a Cashew header band (category-pastel colored): an inset pill type selector (Expense/Income/Transfer, sliding white indicator), a 64px category icon with an edit badge and the category name under it (tap → CategorySheet), and a 40pt amount on the right (tap → `showCalculatorSheet()`). The AppBar title states the type ("New expense", "Edit transfer"…). Title, date/time and note share one filled card with dividers; the item/transfer cards use the same filled surface (`sfv`, no shadow). With a single line, `LineCard(compact: true)` hides its category, amount and per-item note, and the account dropdown shows the name only (the currency badge beside it is the currency picker). Transfers have no amount row in the card — the band is the amount. Add item / Scan receipt / Gallery are one row of equal `_ActionChip` tiles. Title suggestions never repeat the text already typed. The save action is a bottom bar whose label steps "Enter amount" → "Add transaction"/"Save". `transaction_detail_screen.dart` uses the same band (name under the icon, type under the amount) so view and edit match, and hides its "Line detail" card when the line only repeats the header's category and note. The calculator is a seamless key grid, LTR in every locale, shows the user's decimal separator, and disables Done at zero (except when clearing an existing value).

## Exchange Rate Input
Both forms have a swap button (↕) on the exchange rate field to toggle between "1 USD = X LBP" and "1 LBP = X USD". The `rateInverted` flag tracks direction; `exchangeRateToBase` is stored correctly regardless.

## Linked Transactions

Mixed-type items from the assisted flow (e.g., expense + income in one session) are split into separate transactions but linked via matching `note` + `createdAt` timestamp. The transaction detail screen queries for siblings and shows a "RELATED TRANSACTIONS" section. For transactions with empty notes, the query additionally requires different `type` to avoid false positives.

## Spending Heatmap

`lib/shared/widgets/spending_heatmap.dart` — GitHub-style activity grid showing daily spending intensity. Green = net positive (income > expense), red = net negative, gray = no activity. Horizontal scroll, month labels, tooltips on tap. Data from `dailySpendingProvider` (SQL query grouped by day). Displayed in Reports Overview tab.

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

## Duplicate Detection

Both the assisted flow and classic form check for duplicate transactions before saving. If a transaction with the same amount, category, and date already exists, a "Possible Duplicate" dialog shows the matched transaction's title, amount, and date so the user can compare before confirming. Skipped when editing existing transactions or for transfers.

## Activity List (BudgetSeal's own, Oct 2026)

The list answers "what did this do to my budget" (no longer Cashew's rows):
- **Month card** (`_MonthBudgetCard`, first sliver unless filters/all months): "<Month> budget" + "$X left"/"over by", gold 8 px bar, "Spent A of B budgeted · income C". Budgeted = targets of **spending** envelopes in the base currency; spent/income = the month's base-currency totals. A past month within budget collapses to "<Month> sealed" with `SealMark`. With filters, `_MonthlySummaryBar` (filtered totals) shows instead.
- **Day cards** (`_DayCard`): one card per day (sf, radius 16, card shadow, clips), `_DateHeaderTile` = Today/Yesterday/weekday in Bricolage 15 + date + day net (grey, follows `dateBannerTotal`), rows split by `bd` hairlines. No sticky headers. Scrolling down hides the title + month strip (`_headerHidden`, `AnimatedAlign` heightFactor so the strip keeps its scroll position; back on scroll up or near the top). The month strip has start/end padding (`_monthStripStartPad/EndPad`) so `_scrollMonthIntoView()` can center any month, including the current one (always last); `_setMonth()` re-centers after the frame. Rows are edge to edge (selection and swipe fills have no radius; the card clips).
- **`TxTile`**: 40 px rounded-square icon, 8 px vertical padding; title = note/payee, else category, else split categories, else type; second line = budget impact from `txEnvelopeImpactProvider` (`core/providers/budget_impact_provider.dart`): one watched query over the household's ledger replayed per envelope+currency in time order (consumption at its transaction's date, other rows at their own time) → "Envelope · **$X** left", red "over by $X" + Cover pill (only on the envelope's latest spending (`isLatest`) while `balanceNow` < 0, not in selection mode; opens `showMoveMoneySheet(cover: true)`), amber "Not budgeted" (expense with no consumption row), income → accent "→ Ready to assign" pill, transfer "Bank → Cash". End column: amount in Bricolage 16 tabular (expense = text color, income green "+", transfer grey), then "Account · balance after" (transfer: destination side), date instead when `showDate` (dashboard), "≈ base" for foreign lines, "No rate" pill. `balanceAccountId` (the Activity account filter) drops the name and shows that account's side of a transfer. `compact` hides the impact line; `showTime` appends the time.

## Faster Logging

- **Last used account**: `LastUsedService` (`core/services/last_used_service.dart`) stores the last account and transfer pair; both forms apply it to new transactions (`_applyAccountDefaults`). `_accountIsDefault` marks a defaulted account so category/title auto-fill may still replace it; picking an account by hand clears the flag. Prefilled lines without an account (a bill split's per-person lines) all get that default, but only line 0 takes the account's usual category; the others are in `_defaultedLines` and move with line 0 when an autofill (`_autofillAccount`) replaces its account.
- **Classic form**: Save & new (`_save(addAnother: true)` → `_resetForNext()`), Undo action on the Saved SnackBar for new transactions (`_undoSaveAction`), ⇅ swap on the transfer card, `DateQuickChip` (Today/Yesterday, shared with assisted), discard guard (`PopScope(canPop: false)` + `_signature()` compared at pop time — typing doesn't rebuild), prefilled foreign lines fetch a rate after the first frame.
- **CategorySheet** takes `initialType` and `recentIds` (`recentCategoryIds()`); the assisted picker shows the same recents as chips.
- **Calculator**: a prefilled amount is highlighted (`_prefilled`) and replaced by the first digit. Mid-calculation ("12 + 5", not "12 +") a "= 17" line shows the running `_amount` under the expression; its 22 px line is always reserved so the keys don't jump.
- **Assisted**: `initialDate`/`initialTitle` params (quick-add title, viewed month), Enter on the title step continues, editable title row on the amount step, × removes the active item chip, the autofilled amount survives `_showAmountScreen()`.
- **Activity tab**: new transactions in a past month are dated its last day (`_newTxDate()`); quick add flashes the new row.
- **Notification/shortcut routing**: payloads are routes; `NotificationService.openRoute` (ValueNotifier) is set by taps (and cold-start launch details) and by `AppShortcutsService` (quick_actions: add transaction, fund envelopes, upcoming bills); `app.dart` pushes it.

## Auto-fill

`lib/core/providers/autofill_provider.dart` + `lib/core/services/autofill_service.dart`. When a category is selected, auto-fills fields from the last transaction with that category. Configurable in Settings > Appearance > Auto-fill: Account (default on), Title (default on), Amount (default off), Category per account (default off), Override existing values (default off). Works in both AF and classic form.

## Calendar

`features/transactions/calendar_screen.dart`, route `/calendar` (More › Money › Calendar and the Recurring screen's calendar button; it replaced the old bill calendar). A month grid (locale's first weekday, `_MonthGrid`): past days show the day's spending in the base currency (`_byDay`: same `isRealRate` rule as Activity's day totals; "+income" on income-only days), today and later show bills due in the Upcoming blue (`_billsByDay`: every occurrence via `advanceRecurringDate` + `recurringAmountOn`, end date respected; the amount when one bill, dots when several — bills can be in other currencies). Today has an accent ring, the selected day an accent fill. Below: one day card (Activity's header + `TxTile` rows + `_BillRow`s with "Due in N days"; a bill row opens Upcoming bills). "Add on this day" (or double-tap a past day) opens the add form with `editDate`; future days can't take a transaction. Months: back freely, forward up to 12 months (bills only).

## Future Months

Transaction list caps month tabs to current month. No future months shown. Right arrow hidden at current month. Swipe-forward blocked. Year picker only shows up to current year.

## Reports Categories Tab

Cashew layout: pill toggle (Top spending / Top transactions) → donut (`_CategoryPie`, total in the center) → `_CategoryRow` entries (real `CategoryIcon`, amount with base-currency symbol, thin `BudgetProgress` share bar, "N% · N transactions", month-over-month change). Repeated colors get distinct shades via `_distinctColors()`. The hub's tab bar uses a pastel pill indicator.

## Reports Month Navigation

All report tabs (Overview, Categories, Insights) have a `_MonthNav` widget with left/right arrows and swipe gesture support. Users can browse any past month. The `reportStatsProvider.monthRange()` accepts an optional `from` parameter so the 6-month trend chart centers around the selected month. `_DailyPaceChart` accepts an optional `month` parameter — for past months it shows full-month data instead of stopping at `now.day`. The Insights tab filters spending velocity, biggest expense, and savings rate to the selected month using proper `monthStart`/`monthEnd` range checks.
