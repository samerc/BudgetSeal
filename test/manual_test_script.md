# PocketPlan Manual Test Script

Run through each section before every release build. Mark pass/fail for each item.

---

## 1. ONBOARDING

### Happy Path
- [ ] Fresh install: onboarding appears (3 pages)
- [ ] Enter household name, pick currency, set period day
- [ ] Create account with initial balance
- [ ] Toggle "More options" — categories and entry mode visible
- [ ] Tap "Create & Start" — navigates to dashboard

### Edge Cases
- [ ] Leave household name empty — amber error appears, cleared on typing
- [ ] Leave account name empty — amber error appears
- [ ] Set period day to 1 (first of month)
- [ ] Set period day to 28 (last allowed)
- [ ] Pick a non-USD currency (e.g., LBP, EUR)
- [ ] Tap "Create & Start" with defaults — works with no customization

---

## 2. TRANSACTIONS

### Add Expense (Assisted Flow)
- [ ] Tap + on Activity tab — opens expense form directly
- [ ] Step indicator shows 1/2/3 dots
- [ ] Enter title → auto-suggests categories
- [ ] Pick category → step 2 indicator
- [ ] Enter amount via calculator → save
- [ ] Transaction appears in list with flash highlight

### Add Expense (Classic Form)
- [ ] Switch to classic mode in settings
- [ ] Enter title, amount, category, account
- [ ] Add a note (up to 500 chars — counter appears)
- [ ] Save — appears in list

### Transfers
- [ ] Create transfer between two same-currency accounts
- [ ] Create transfer between different-currency accounts — exchange rate field appears
- [ ] Set exchange rate, swap direction with arrow button
- [ ] Verify both accounts update correctly

### Edge Cases — CRASH TESTS
- [ ] **Enter amount = 0** — should reject, not crash
- [ ] **Enter amount = 999,999,999,999** — should reject (> 1B cap)
- [ ] **Delete all accounts, then try to add transaction** — should show error, not crash
- [ ] **Rapid tap Save button 10 times** — should not create duplicates
- [ ] **Type `%_\` in search bar** — should not cause SQL error
- [ ] **Enter title with 100+ characters** — truncated at maxLength
- [ ] **Enter note with `<script>alert(1)</script>`** — stored as plain text, no XSS
- [ ] **Select a category, then delete it in another tab, come back and save** — should not crash

### Quick Add Bar
- [ ] Type "Coffee 4.50" — opens form with title "Coffee" and amount 4.50
- [ ] Type "Lunch" (no amount) — opens form with title only

### Duplicate Detection
- [ ] Save an expense for $10 in Groceries today
- [ ] Try saving same amount + category + date again — duplicate dialog shows matched transaction
- [ ] Tap "Cancel" — not saved. Tap "Save Anyway" — saved.

---

## 3. ENVELOPES (Budget Tab)

### Create Envelope
- [ ] Tap + on Budget tab
- [ ] Create "Spending" type with $200 target
- [ ] Create "Flexible" type with optional target
- [ ] Verify both appear in list

### Fund Envelope
- [ ] Tap "Fund Envelopes" — bulk funding screen
- [ ] Enter amounts, save — balances update
- [ ] Verify unallocated decreases
- [ ] Fund with cross-currency — expandable currency picker works

### Edge Cases — CRASH TESTS
- [ ] **Fund more than unallocated balance** — over-funding warning dialog appears
- [ ] **Fund with amount = 0** — should reject
- [ ] **Create 50 envelopes** — performance still smooth
- [ ] **Delete an envelope that has transactions** — archive works, transactions unaffected
- [ ] **Period reset with 0 envelopes needing review** — no banner shown

---

## 4. ACCOUNTS

### Happy Path
- [ ] Create Cash, Bank, Credit, Digital accounts
- [ ] View account detail — transactions listed
- [ ] Edit account name

### Edge Cases
- [ ] **Sort by name, balance, type** — each sort works
- [ ] **Show archived accounts** — dimmed section appears
- [ ] **Unarchive an account** — moves back to active
- [ ] **Create account with negative initial balance** (credit card) — works
- [ ] **Delete the only account** — what happens? Should prevent or warn

---

## 5. MULTI-CURRENCY

### Core Flow
- [ ] Create accounts in USD and LBP
- [ ] Add income in USD
- [ ] Add expense in LBP — exchange rate field appears
- [ ] Enter exchange rate, verify conversion
- [ ] Dashboard shows net worth in base currency only

### Edge Cases — CRASH TESTS
- [ ] **Set exchange rate to 0** — should reject, not divide-by-zero
- [ ] **Set exchange rate to negative number** — should reject
- [ ] **Have 5+ currencies** — unallocated shows expandable breakdown
- [ ] **Transaction with currency mismatch** — no rate → amber warning in list

---

## 6. BILL SPLITTER

### Happy Path
- [ ] Open from More > Bill Splitter
- [ ] "Bill in USD" chip visible at top
- [ ] Change currency to LBP — exchange rate field appears in amber card
- [ ] Add items manually — currency symbol prefix shown
- [ ] Add 2+ people, assign items
- [ ] Review: per-person totals with base-currency conversion
- [ ] Save — navigates to transaction form (not back to splitter)

### OCR Scan
- [ ] Scan receipt — items detected
- [ ] Amounts like `765000T` recognized
- [ ] Amounts like `1080000.00` recognized
- [ ] Items with quantity (2x Coffee) — split dialog offered

### Edge Cases — CRASH TESTS
- [ ] **Remove a person with solo items** — reassign dialog appears
- [ ] **0 people** — Next button disabled
- [ ] **All items unassigned** — Save disabled
- [ ] **Very long item name** — truncated in UI, no overflow
- [ ] **Tip = 0%** — no tip added
- [ ] **Tip as fixed amount** — toggle works

---

## 7. GOALS & LOANS

### Happy Path
- [ ] Create a goal with target amount and deadline
- [ ] Add funds via payment sheet
- [ ] Create a loan (I lent) — direction hint text shows
- [ ] Record payment — appears in history

### Edge Cases
- [ ] **Rename a goal** — payment history still linked (by [obj:ID] tag)
- [ ] **Delete a goal** — payments remain as regular transactions
- [ ] **Loan direction default** — "I lent" shown with explanation text

---

## 8. SUBSCRIPTIONS & RECURRING

### Happy Path
- [ ] Create recurring expense
- [ ] Create subscription (+ button on Subscriptions screen)
- [ ] Pause/resume via icon button — tooltip shows action
- [ ] View subscription detail — price history tracked

### Edge Cases
- [ ] **Recurring with end date before start date** — should reject (web API does, verify app)
- [ ] **Subscription with 0 amount** — should reject
- [ ] **100 recurring items** — list performance OK

---

## 9. REPORTS

### Happy Path
- [ ] Overview tab: spending chart, income/expense stats
- [ ] Month navigation — arrows and swipe
- [ ] Categories tab: breakdown by category
- [ ] Heatmap visible, cells have tooltips

### Edge Cases
- [ ] **Month with no transactions** — shows empty state, not crash
- [ ] **Navigate to future month** — blocked (right arrow hidden)
- [ ] **Year boundary (Dec → Jan)** — year increments correctly

---

## 10. WEB COMPANION

### Happy Path
- [ ] Start server — IP + QR shown
- [ ] Open in browser — PIN screen
- [ ] Enter PIN — dashboard loads
- [ ] Add transaction via web — appears in app
- [ ] Edit transaction via web — updates in app

### Security Tests
- [ ] **Wrong PIN 5 times** — lockout message (no attempt count shown)
- [ ] **Send `<script>` in note field** — stored as text, not executed
- [ ] **Send SQL injection in title** — 400 error, not executed
- [ ] **Submit form 15 times in 1 minute** — rate limited after 10
- [ ] **Access from non-private IP** — 403 denied
- [ ] **Expired token** — redirected to PIN screen
- [ ] **Invalid JSON body** — 400 error with generic message

### API Validation Tests
- [ ] **POST /api/transactions with missing accountId** — 400 "accountId is required"
- [ ] **POST /api/transactions with amount = -5** — 400 "amount must be positive"
- [ ] **POST /api/transactions with fake categoryId** — 400 "categoryId does not exist"
- [ ] **POST /api/accounts with currency = "123"** — 400 "currency must be letter code"
- [ ] **PUT /api/categories with invalid colorHex** — 400 "colorHex must be valid hex"

---

## 11. SETTINGS & DATA

### Cloud Sync
- [ ] Connect Google Drive
- [ ] Sync up → sync down — data matches
- [ ] Enable encryption — set password
- [ ] Sync encrypted file — verify it works

### Backup & Restore
- [ ] Create manual backup
- [ ] Restore from backup — safety backup created first
- [ ] Verify restored data

### Health Check
- [ ] Run Level 1 — green invariant check
- [ ] Purge soft-deleted — receipt files also cleaned

### Edge Cases
- [ ] **Import malformed CSV** — error message, not crash
- [ ] **Restore corrupted .db file** — error message, not crash
- [ ] **Change base currency** — existing data unaffected

---

## 12. PERFORMANCE

- [ ] App cold start < 2 seconds
- [ ] Tab switching instant (keep-alive works)
- [ ] Scroll 100+ transactions — smooth 60fps
- [ ] Dashboard rebuild after funding — no jank
- [ ] Search debounce — no lag while typing

---

## 13. ACCESSIBILITY

- [ ] Screen reader: allocation card announces name + balance + progress
- [ ] Screen reader: transaction tile has "Long press for options" hint
- [ ] Screen reader: heatmap cells have date + amount labels
- [ ] Screen reader: donut chart announces spending total

---

## 14. ERROR HANDLING

- [ ] Kill app during save — no data corruption
- [ ] Fill airplane mode → try sync — friendly error, not crash
- [ ] Force low memory — app doesn't leak (no orphan streams)
- [ ] Tap "Try Again" on ErrorRetry — reloads without crash
- [ ] Error details don't show file paths or SQL
