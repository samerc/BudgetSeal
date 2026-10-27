# BudgetSeal file format

Your budget belongs to you. This document describes the file BudgetSeal syncs and backs up, so you can read your data without the app: to check it, convert it, or move it somewhere else.

It covers the two kinds of file Cloud Sync keeps in its folder (on Google Drive, or a folder you pick):

- **`BudgetSeal_Sync.json`** — the whole budget as it stood, rewritten at most once a day. This is the one to read. Most of this page is about it.
- **`log-<phone>-<number>.json`** — each phone's changes, which is how phones actually sync. See [Change logs](#change-logs).

The app's own backup (`.db`) is a SQLite database with the same tables and fields, written in `snake_case` (`account_id` for `accountId`).

This describes format version 1 as written by the app versions after 0.11 (database schema 23).

## The file

The file is UTF-8 JSON, unless you set a sync password (see [Encrypted files](#encrypted-files)).

```json
{
  "version": 1,
  "exportedAt": "2026-10-27T12:00:00.000Z",
  "households": [ ... ],
  "users": [ ... ],
  "accounts": [ ... ],
  "categories": [ ... ],
  "allocations": [ ... ],
  "transactions": [ ... ],
  "transactionLines": [ ... ],
  "allocationLedger": [ ... ],
  "recurringTransactions": [ ... ],
  "transactionTemplates": [ ... ],
  "fxRates": [ ... ],
  "objectives": [ ... ]
}
```

Conventions for every list:

- **Ids** are text: random UUIDs, or ids built from other ids (a bill's payment is `rec:<billId>:2026-10-03`).
- **Times** are ISO 8601 in UTC (`…Z`). Files from early versions have local times with no zone; read those as local time.
- **Amounts** are JSON numbers in the units of their currency (`12.5` dollars, `450000` lira), never in cents.
- **Currencies** are ISO 4217 codes (`USD`, `EUR`, `LBP`).
- **Deleted rows stay in the file** with `"deleted": true`, so that every synced phone learns about the deletion. Skip them when reading.
- **New fields may appear** in later versions. A reader should ignore keys it doesn't know; BudgetSeal does the same.

Most rows carry `lastModified`. When two phones sync, the newer row wins. Transaction lines are never edited: changing a transaction makes a new transaction and deletes the old one.

## Lists and fields

### households

One budget. A file normally holds one household.

| Field | Meaning |
|---|---|
| `id`, `name` | |
| `baseCurrency` | The currency totals and reports are shown in. |
| `periodStartDay` | Day of the month a budget period starts (1–28). |
| `baseHistory` | Null, or every change of `baseCurrency` as a JSON list in a string: `[{"from": "USD", "to": "EUR", "rate": 0.9}]` (1 `from` = `rate` `to`). An income or expense whose `currency` is an earlier base was recorded before a change; convert it with these rates. |
| `createdByDeviceId`, `createdAt`, `lastModified` | |

### users

The people sharing the budget.

| Field | Meaning |
|---|---|
| `id`, `householdId` | |
| `displayName` | |
| `role` | `owner` or `member`. |
| `deviceId`, `createdAt`, `lastModified` | |

### accounts

Where money is: a bank account, a card, a wallet.

| Field | Meaning |
|---|---|
| `id`, `householdId`, `name` | |
| `type` | `bank`, `cash`, `credit` or `wallet` (older files may have others, such as `checking`). |
| `currency` | Every amount on this account is in this currency. |
| `initialBalance` | The balance when the account was added. |
| `decimalPlaces` | Digits to show after the point; null means the currency's usual digits. |
| `isTravel` | A travel wallet. |
| `archived` | Hidden from lists and left out of balances and Ready to assign. |
| `deviceId`, `createdAt`, `lastModified`, `deleted` | |

### categories

What money is spent on or earned from.

| Field | Meaning |
|---|---|
| `id`, `householdId`, `name` | |
| `parentId` | The group it belongs to (null: it is a group). |
| `transactionType` | `expense` or `income`. |
| `allocationId` | The envelope it spends from. A subcategory with none spends from its group's envelope. |
| `defaultAccountId` | Account picked first when adding a transaction. |
| `icon` | An emoji. |
| `colorHex` | `#RRGGBB`. |
| `archived`, `createdAt`, `lastModified`, `deleted` | |

### allocations (envelopes)

| Field | Meaning |
|---|---|
| `id`, `householdId`, `name` | |
| `categoryId` | The category the envelope was made for. |
| `type` | `spending`, `saving`, `flexible` or `sinking` (saved monthly for scheduled payments). |
| `periodicity` | `periodic` (starts again each period) or `permanent` (keeps adding up). |
| `rollover` | Whether what is left carries into the next period. |
| `targetAmount`, `targetCurrency` | What the envelope should get each period. |
| `icon` | An emoji. |
| `autoReset` | Whether it is reset automatically at the start of a period. |
| `sortOrder` | Position on the Budget tab (null: after the others, by name). |
| `behindMode` | For a sinking fund that is behind: `spread`, `topup`, or null (ask each time). |
| `archived`, `deviceId`, `createdAt`, `lastModified`, `deleted` | |

### transactions

One income, expense or transfer. Its amounts per account and category are in `transactionLines`.

| Field | Meaning |
|---|---|
| `id`, `householdId` | |
| `type` | `income`, `expense` or `transfer`. |
| `accountId` | Income/expense: the main account (each line has its own). Transfer: where the money left. |
| `destinationAccountId` | Transfer: where the money arrived. Otherwise null. |
| `categoryId` | The category when there is only one line. Otherwise null. |
| `amount`, `currency` | Income/expense: the total in the household's base currency. Lines with no exchange rate are left out of it, so a total can be 0. Transfer: the amount that left, in that account's currency. |
| `destinationAmount` | Transfer: the amount that arrived, in the destination account's currency. |
| `exchangeRateToBase` | Income/expense: `1`. Transfer: `destinationAmount ÷ amount`, kept for older versions of the app. |
| `note` | The title. It may contain `[obj:<objectiveId>\|<amount>]`, which links a goal or loan payment; strip it for display. |
| `receiptPath` | Receipt photo file names as a JSON array in a string (`"[\"a.jpg\"]"`), or one bare name in old files. The photos themselves are not in the file. |
| `status` | null: posted. `planned`: a planned payment that hasn't happened, so it doesn't count in balances. Older files may also have `upcoming` or `skipped`, which don't count either. |
| `createdBy`, `deviceId` | |
| `createdAt` | When it happened (the date the user picked). |
| `lastModified`, `deleted` | |
| `revision` | Null until the transaction's lines are edited. Then the lines and envelope ledger rows of the current version have ids starting `<id>:<revision>:`; any others for this transaction are leftovers of an older version — skip them. |

Files written by app version 0.11 or earlier have no `destinationAmount`; for them it is `amount × exchangeRateToBase`. Those files may also have an income or expense with **no lines**: its `amount` is then in `currency`, which is its account's currency.

### transactionLines

The parts of a transaction: one line, or several for a split.

| Field | Meaning |
|---|---|
| `id`, `transactionId` | |
| `accountId` | The account this part was paid from or into. |
| `categoryId` | Its category. |
| `amount`, `currency` | The amount, in the account's currency. |
| `exchangeRateToBase` | Base-currency units per 1 unit of `currency`. A value within 0.001 of `1` for a currency other than the base means no rate was known. |
| `note` | The item's own note (split lines). |

### allocationLedger

Every movement of money into or out of an envelope. An envelope's balance is the sum of its rows.

| Field | Meaning |
|---|---|
| `id`, `allocationId` | |
| `entryType` | `funding` (from Ready to assign), `withdrawal` (back to it), `transfer` (between envelopes: a negative and a positive row), `consumption` (spending, negative), and also `period_reset`, `carry_forward`, `adjustment`, `revaluation`. |
| `amount`, `currency` | Signed: positive adds to the envelope. |
| `sourceTransactionId` | The expense that consumed it (for `consumption`). |
| `sourceAccountId` | That expense's account. |
| `exchangeRateToBase`, `note`, `deviceId` | |
| `createdAt` | When the row was written. A row is never edited. |

### recurringTransactions (bills and subscriptions)

| Field | Meaning |
|---|---|
| `id`, `householdId`, `type`, `title`, `note` | `type` as for transactions. |
| `amount`, `currency`, `accountId`, `destinationAccountId`, `categoryId` | What each payment records. |
| `frequency`, `interval` | `daily`, `weekly`, `monthly` or `yearly`, every `interval` of them. |
| `nextDueDate` | The next payment. |
| `anchorDay` | Day of the month it is due (a 31st is paid on the month's last day). |
| `endDate`, `lastGeneratedDate` | |
| `enabled` | Paused when false. |
| `isSubscription` | Shown under Subscriptions. |
| `priceHistory` | JSON array in a string: `[{"from": "2026-03-01", "amount": 17.99}]`. From each date on, that amount replaces `amount`. |
| `askFirst` | Waits for the user to confirm the amount before posting. |
| `remindDays` | Reminder this many days before; null means 2, `-1` means off. |
| `createdAt`, `lastModified`, `deleted` | |

### transactionTemplates

Saved transactions for one-tap entry: `id`, `householdId`, `title`, `type`, `amount`, `currency`, `accountId`, `categoryId`, `useCount`, `lastUsedAt`, `createdAt`, `lastModified`, `deleted`.

### fxRates

Exchange rates the app has fetched or that were typed in: `id`, `baseCurrency`, `targetCurrency`, `rate` (1 `baseCurrency` = `rate` `targetCurrency`), `fetchedAt`.

### objectives (goals and loans)

| Field | Meaning |
|---|---|
| `id`, `householdId`, `name`, `icon`, `colorHex` | |
| `type` | `goal` or `loan`. |
| `targetAmount`, `targetCurrency` | The goal, or the loan's total. |
| `currentAmount` | Saved or repaid so far. |
| `endDate` | Optional deadline. |
| `contactName`, `direction` | Loans: the other person, and `lent` (they owe you) or `borrowed` (you owe them). |
| `archived`, `deviceId`, `createdAt`, `lastModified`, `deleted` | |

## Computing balances

Balances are not stored; they are computed from the rows above. Skip rows with `deleted: true` and transactions whose `status` isn't null.

**An account's balance** is its `initialBalance` plus the sum of these:

- each income line on the account: `+amount`;
- each expense line on the account: `−amount`;
- each transfer from the account: `−amount`;
- each transfer to the account: `+destinationAmount`.

The result is in the account's currency. For an older file: an income or expense with no lines counts its own `amount` on `accountId`, and a transfer without `destinationAmount` brings in `amount × exchangeRateToBase`.

**An envelope's balance** in a currency is the sum of its `allocationLedger` rows in that currency. Leave out rows whose `sourceTransactionId` points to a deleted transaction. An envelope can hold more than one currency.

**Ready to assign** in a currency is the total of the non-archived accounts in that currency, minus the total of the non-archived envelopes in that currency.

Currencies are never added together. To show a total in the base currency, convert each line with its `exchangeRateToBase`, and leave out lines that have no rate.

### Example: account balances in Python

```python
import json
from collections import defaultdict

data = json.load(open("BudgetSeal_Sync.json", encoding="utf-8"))
live = lambda rows: [r for r in rows if not r.get("deleted")]

accounts = [a for a in live(data["accounts"]) if not a["archived"]]
balance = defaultdict(float, {a["id"]: a["initialBalance"] for a in accounts})
lines = defaultdict(list)
for line in data["transactionLines"]:
    lines[line["transactionId"]].append(line)

for t in live(data["transactions"]):
    if t.get("status"):
        continue  # planned: not real yet
    if t["type"] == "transfer":
        received = t.get("destinationAmount")
        if received is None:  # file from 0.11 or earlier
            received = t["amount"] * t["exchangeRateToBase"]
        balance[t["accountId"]] -= t["amount"]
        balance[t["destinationAccountId"]] += received
        continue
    sign = 1 if t["type"] == "income" else -1
    for line in lines[t["id"]] or [{"accountId": t["accountId"], "amount": t["amount"]}]:
        balance[line["accountId"] or t["accountId"]] += sign * line["amount"]

for a in accounts:
    print(f'{a["name"]}: {balance[a["id"]]:,.2f} {a["currency"]}')
```

## Change logs

Each phone records every change it makes and writes them to its own files: `log-<phone id>-00000.json`, `log-<phone id>-00001.json` and so on, 1,000 changes per file, oldest first. A phone only ever writes its own files. They are encrypted like the sync file when a sync password is set.

```json
{
  "format": "budgetseal-log",
  "version": 1,
  "device": "dev-1b2c…",
  "chunk": 0,
  "entries": [
    {"hlc": "1793108333123-00000000-dev-1b2c…", "seq": 1, "table": "accounts",
     "row": "acc-1", "kind": "insert", "data": {"id": "acc-1", "name": "Bank", …}},
    {"hlc": "1793108400456-00000000-dev-1b2c…", "seq": 2, "table": "accounts",
     "row": "acc-1", "kind": "update", "data": {"name": "Main bank"}, "old": {"name": "Bank"}}
  ]
}
```

| Field | Meaning |
|---|---|
| `hlc` | When the change was made: milliseconds since 1970, a counter, and the phone. Compared as text, it puts every phone's changes in one order. |
| `seq` | The phone's own count of its changes (negative for the starting entries a phone writes for data it had before change logs). |
| `table`, `row` | The list and the row's `id`. Tables and columns are those of the `.db` backup (`snake_case`). |
| `kind` | `insert` (`data` is the whole row), `update` (`data` holds only the changed columns, `old` their previous values), or `delete` (`old` is the row). |

To rebuild a budget from the logs, take every entry for a row from all phones' files: each column takes its value from the entry with the latest `hlc` that set it, and the row exists if its latest `insert` or `delete` is an `insert`. Values are as stored in the database: dates in seconds since 1970, true/false as 1/0.

## Encrypted files

With a sync password set, the file is one line of text:

```
ENC:1:<salt>:<iv>:<ciphertext>
```

All three parts are Base64. To decrypt:

1. Derive a 32-byte key with PBKDF2-HMAC-SHA256 from the password (UTF-8), using the salt and 100,000 iterations.
2. Decrypt the ciphertext with AES-256-CBC, using that key and the IV. The padding is PKCS#7.

The result is the JSON above (or a change log). A file that doesn't start with `ENC:` is not encrypted.

```python
import base64, hashlib
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding

_, version, salt, iv, data = open("BudgetSeal_Sync.json").read().strip().split(":")
key = hashlib.pbkdf2_hmac("sha256", PASSWORD.encode(), base64.b64decode(salt), 100_000, 32)
decryptor = Cipher(algorithms.AES(key), modes.CBC(base64.b64decode(iv))).decryptor()
padded = decryptor.update(base64.b64decode(data)) + decryptor.finalize()
unpadder = padding.PKCS7(128).unpadder()
json_text = (unpadder.update(padded) + unpadder.finalize()).decode("utf-8")
```

## Writing changes for BudgetSeal

The app syncs from the change logs, not from `BudgetSeal_Sync.json`, so editing the snapshot changes nothing. A tool can add its own changes as a log of its own: a `log-<your tool's id>-00000.json` file in the same folder, with entries stamped later than the changes they follow. Follow the rules above for new rows:

- every income or expense has at least one line;
- a transfer has `destinationAmount`;
- to change a transaction's lines, delete all its lines and envelope ledger rows, add the new ones with ids `<transaction id>:<new revision>:line0`, `…:line1`, … (`…:debit0`, … for the ledger), and set the transaction's `revision` and total in the same go. Header fields like the note or date can be updated on their own.

Back up first.
