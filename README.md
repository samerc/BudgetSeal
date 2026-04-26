# PocketPlan

A YNAB-style envelope budgeting app for Android and iOS. Offline-first, built with Flutter.

## What is PocketPlan?

PocketPlan helps you take control of your money using the **envelope budgeting** method. Every dollar gets a job: income flows into your accounts, you allocate funds into envelopes (Groceries, Rent, Savings, etc.), and spending draws from the right envelope. You always know exactly where your money is.

### Key Features

- **Envelope Budgeting** -- Create spending, saving, and flexible envelopes. Fund them from income. Spend with confidence knowing each envelope tracks its own balance.
- **Multi-Currency** -- Track accounts and envelopes in different currencies. Cross-currency transfers with exchange rate support.
- **Multi-Account** -- Bank accounts, cash wallets, credit cards -- all in one place with real-time balances.
- **Offline-First** -- Everything runs locally on your device. No account required, no internet needed.
- **Cloud Sync** -- Optional sync via Google Drive or file picker (Dropbox/OneDrive). Share a household with family members.
- **Bill Splitter** -- Scan a receipt with your camera, assign items to people, and split the bill. Offline OCR, no internet needed.
- **Subscription Tracker** -- Track recurring subscriptions with price history, cancellation dates, and upcoming payment alerts.
- **Reports & Analytics** -- Spending heatmap, category breakdown (pie/bar/line charts), budget velocity, age-of-money metric, and savings rate.
- **Customizable Dashboard** -- Reorder and toggle dashboard sections. Choose your font. Light and dark mode.
- **Recurring Transactions** -- Set up repeating income or expenses that auto-post on schedule.
- **Templates** -- Save frequent transactions for one-tap entry.
- **Bill Calendar** -- Visual calendar of upcoming recurring bills.
- **Health Check** -- Diagnose and repair balance inconsistencies. Export diagnostic reports.
- **Biometric Lock** -- Protect your financial data with fingerprint or face unlock.
- **CSV Import/Export** -- Import transactions from other apps or export for spreadsheets.
- **Daily Reminders** -- Configurable push notification to remind you to log transactions.
- **Auto Backup** -- Scheduled local database backups with restore support.

## Screenshots

*Coming soon*

## Architecture

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Database | SQLite via [Drift](https://drift.simonbinder.eu/) |
| State Management | [Riverpod](https://riverpod.dev/) 3 |
| Navigation | [GoRouter](https://pub.dev/packages/go_router) |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) |
| OCR | [Google ML Kit](https://pub.dev/packages/google_mlkit_text_recognition) (offline) |
| Sync | Google Drive API / file picker |

### Offline-First Design

SQLite is the primary data store, not a cache. The app works 100% without internet. Cloud sync is optional and file-based -- it exports/imports a single JSON file containing all data.

### Envelope Budgeting Flow

```
Income --> Account --> Unallocated Pool --> Fund Envelopes --> Spend from Envelopes
```

All money writes go through the `AllocationEngine`. Balances are computed dynamically from an append-only ledger -- never stored as a single number.

## Getting Started

### Prerequisites

- Flutter SDK 3.3+
- Android Studio or Xcode
- A physical device or emulator

### Setup

```bash
# Clone the repo
git clone https://github.com/samerc/PocketPlan.git
cd PocketPlan

# Install dependencies
flutter pub get

# Run code generation (Drift + Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device
flutter run
```

### Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

## Project Structure

```
lib/
├── app.dart                     # Routes, app lifecycle, auto-sync
├── main.dart                    # Entry point
├── core/
│   ├── database/                # Drift tables, DAOs, migrations
│   ├── engine/                  # AllocationEngine, BalanceCalculator
│   ├── providers/               # Riverpod providers (~20 files)
│   ├── sync/                    # Cloud sync engine
│   ├── fx/                      # Currency exchange rates
│   └── services/                # Notifications, backup, reminders
├── features/                    # One folder per screen/feature
│   ├── dashboard/               # Home screen + customization
│   ├── transactions/            # List, add, detail, assisted flow, bill splitter
│   ├── allocations/             # Envelopes: list, detail, funding
│   ├── accounts/                # Account management
│   ├── categories/              # Category management with emoji picker
│   ├── subscriptions/           # Subscription tracker
│   ├── reports/                 # Charts, heatmap, insights
│   ├── recurring/               # Recurring transactions
│   ├── templates/               # Transaction templates
│   ├── settings/                # Settings, sync, backup, health check
│   └── onboarding/              # First-launch setup
└── shared/
    ├── theme/                   # Colors, typography
    ├── utils/                   # Formatting, OCR, helpers
    └── widgets/                 # Reusable components
```

## License

This project is private and not licensed for redistribution.

## Author

Built by Samer.
