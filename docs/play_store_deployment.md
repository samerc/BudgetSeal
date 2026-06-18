# BudgetSeal — Play Store Deployment Guide

Step-by-step for the first upload to **Internal Testing**. Work top to bottom.

---

## 0. Pre-flight (do these first)

| Item | Status | Notes |
|------|--------|-------|
| Signed AAB built | ⏳ | `build/app/outputs/bundle/release/app-release.aab` |
| Keystore backed up | ❗ | **CRITICAL** — back up `android/budgetseal.jks` + `key.properties` somewhere safe (password manager / cloud). Losing it = can never update the app. |
| Privacy policy hosted | ☐ | Needs a public URL (see §1) |
| Contact email decided | ✅ | `fancyshark505@gmail.com` |
| App ID locked in | ✅ | `com.budgetseal.app` — **can never change** after first upload |

---

## 1. Host the privacy policy (required)

Google requires a public URL. Easiest: GitHub Pages on the existing repo.

1. Go to `https://github.com/samerc/BudgetSeal` → **Settings** → **Pages**
2. Source: **Deploy from a branch** → Branch: `main` → Folder: `/docs` → **Save**
3. Wait ~1 min. URL will be:
   `https://samerc.github.io/BudgetSeal/privacy-policy.html`
4. Open it in a browser to confirm it loads.

(If you'd rather not make the repo's /docs public, host the single HTML file anywhere — e.g. a free Netlify drop.)

---

## 2. Create the app in Play Console

1. `https://play.google.com/console` → **Create app**
2. App name: **BudgetSeal**
3. Default language: **English (United States)**
4. App or game: **App**
5. Free or paid: **Free**
6. Check both declarations (Developer Program Policies, US export laws) → **Create app**

---

## 3. Dashboard → "Set up your app" checklist

Work through each. Answers below match BudgetSeal (offline, no accounts, no ads).

### App access
- **All functionality is available without special access** (no login required). Select this.

### Ads
- **No, my app does not contain ads.**

### Content rating
- Start questionnaire → Category: **Finance** (or Utility)
- Answer **No** to all violence/sexual/profanity/drugs/gambling questions
- Result will be **Everyone / PEGI 3**

### Target audience and content
- Target age group: **18+** (recommended for a finance app — avoids the stricter child-data rules). 13+ is also fine.
- Is the app appealing to children? **No**

### Data safety
- Does your app collect or share user data? **No**
  - BudgetSeal stores everything on-device. Optional Cloud Sync goes to the *user's own* Google Drive — you never receive it, so it is not "collected" by you.
- Data encrypted in transit: N/A (no collection). If asked about the optional sync, note it's user-controlled and optionally AES-256 encrypted.

### Government apps
- **No**

### Financial features
- BudgetSeal is a **personal budgeting / money-management tool**. It does **not**: handle payments, lending, banking, crypto, or investments.
- Declare: **My app does not provide any financial features** (it's a tracker, not a financial product). If the form forces a category, pick **Personal finance management / budgeting** with no transactions processed.

### Privacy policy
- Paste the URL from §1.

---

## 4. Store listing

### App name
```
BudgetSeal
```

### Short description (max 80 chars)
```
Envelope budgeting that keeps every dollar on your phone. Offline. Private.
```

### Full description (max 4000 chars) — draft
```
BudgetSeal is a private, offline-first budgeting app built around the proven
envelope method: give every dollar a job, and always know where your money is.

No account. No sign-up. No data leaves your phone. Your finances are yours alone.

— ENVELOPE BUDGETING —
Fund envelopes like Groceries, Rent, and Savings, then spend from them. Two
envelope types: Spending (resets each period) and Flexible (accumulates toward
a target). Watch your budget fill up and see exactly what's left.

— TRACK EVERYTHING —
• Multiple accounts and currencies
• Income, expenses, and transfers
• Split transactions across categories and accounts
• Recurring transactions and bill reminders
• Subscription tracker with price history
• Goals & loans tracking

— UNDERSTAND YOUR MONEY —
• Clear dashboard with spending insights
• Reports: cash flow, categories, balance sheet, age-of-money
• Spending heatmap and trends

— POWERFUL EXTRAS —
• Bill Splitter with offline receipt scanning
• Travel Exchange wallets for trips abroad
• Web Companion — manage your budget from a laptop browser over WiFi
• CSV import and export
• Biometric lock

— YOUR DATA, YOUR CONTROL —
• Works 100% offline
• Optional cloud sync to your own Google Drive (with optional AES-256 encryption)
• Automatic local backups
• Available in English, Arabic, and French

BudgetSeal is designed to be fast, beautiful, and completely private. Start
budgeting in two minutes — no learning curve, no tracking, no strings attached.
```

### Graphics needed
| Asset | Size | Notes |
|-------|------|-------|
| App icon | 512 × 512 PNG | 32-bit, no alpha for Play. Derive from `assets/icon/app_icon.png` |
| Feature graphic | 1024 × 500 PNG/JPG | Required. Banner shown at top of listing |
| Phone screenshots | min 2, up to 8 | 9:16 portrait, e.g. 1080×1920. Capture Dashboard, Budget/envelopes, Add transaction, Reports |
| (Optional) 7" / 10" tablet shots | | Only if you want tablet placement |

### Categorization
- App category: **Finance**
- Tags: budgeting, personal finance, money manager

### Contact details
- Email: `fancyshark505@gmail.com`
- Website / phone: optional

---

## 5. Internal Testing release

1. **Testing → Internal testing → Create new release**
2. Play App Signing: **accept** (Google manages the upload key signing — recommended)
3. Upload `app-release.aab`
4. Release name: `0.9.0 (1)`
5. Release notes:
   ```
   <en-US>
   First beta build. Please test core flows: add transactions, fund envelopes,
   check reports. Report any crashes or odd behavior. Thank you!
   </en-US>
   ```
6. **Save → Review release → Start rollout to Internal testing**

### Add testers
1. Internal testing → **Testers** tab → create an email list → add up to 100 tester Gmail addresses
2. Copy the **opt-in URL** (the "Copy link" under "How testers join your test")
3. Send testers that link + the guide in `docs/beta_tester_guide.md`
4. Testers open the link on their phone → Accept → install from Play Store

---

## 6. After rollout

- Internal testing releases are available within minutes (no review wait).
- For the eventual **production** launch you'll need full review (can take days) + a 14-day testing period with 12+ testers if this is a new personal developer account (Google's 2023+ requirement).
- Bump `version:` in `pubspec.yaml` for every new build (e.g. `0.9.1+2`). The `+N` is the versionCode and must always increase.

---

## Quick rebuild command
```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```
