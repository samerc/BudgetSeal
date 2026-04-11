# Mobile App Development Plan

## Overview

This document outlines the plan for building iOS and Android mobile apps for the Expense Tracker application.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | **React Native + Expo** | Reuse React skills, single codebase for iOS/Android |
| Local Database | **WatermelonDB** | Built for React Native, offline-first, lazy loading |
| Sync Strategy | **Offline-first with server sync** | Works without internet, syncs when online |
| Conflict Resolution | **Last-write-wins with version tracking** | Simple, uses existing `version` field |
| Distribution | **Manual first, then App Stores** | Start with APK/IPA sharing, later publish |

---

## Requirements

### 1. Mobile-Specific UX (Not a Web Port)

The mobile app will have a completely different UI designed for touch:

- **Drag & drop categories** instead of dropdown selects
- **Swipe gestures** for edit/delete actions
- **Bottom sheets** for quick-add flows
- **Haptic feedback** for interactions
- **Pull to refresh** for sync
- **FAB (Floating Action Button)** for quick transaction entry

**Libraries:**
- `react-native-gesture-handler` - Touch gestures
- `react-native-reanimated` - Smooth animations
- `expo-haptics` - Vibration feedback
- `@gorhom/bottom-sheet` - Bottom sheets

### 2. Offline-First Architecture

```
┌─────────────────┐         ┌─────────────────┐
│   Mobile App    │   sync  │     Server      │
│  ┌───────────┐  │  ←───→  │  ┌───────────┐  │
│  │ WatermelonDB │         │  │ PostgreSQL│  │
│  │  (SQLite)  │  │         │  │           │  │
│  └───────────┘  │         │  └───────────┘  │
└─────────────────┘         └─────────────────┘
```

**How it works:**
1. All data stored locally in SQLite via WatermelonDB
2. App works fully offline
3. When online, sync changes to server
4. Server merges changes and returns updates
5. Local DB updated with server response

### 3. Multi-Device Household Sync

Multiple household members on different devices need to stay in sync.

**Conflict Scenarios:**
```
Device A: Edits "Groceries" expense → $50
Device B: Edits same expense → $55
Both sync → Which wins?
```

**Resolution Strategy:**
- Each record has `modified_at`, `version`, and `device_id`
- **Last-write-wins** based on `modified_at` timestamp
- Server detects conflicts (same record, different versions)
- Optional: Flag conflicts for user resolution

**Sync Flow:**
1. App comes online (or user triggers sync)
2. Push local changes with `device_id` and `version`
3. Server checks for conflicts
4. Server responds with merged data + new changes from other devices
5. App updates local DB

### 4. Distribution Plan

**Phase 1 - Development/Testing:**
- Android: Build APK, share directly
- iOS: TestFlight or direct IPA (requires Mac)

**Phase 2 - App Stores:**
- Apple App Store: $99/year developer account
- Google Play: $25 one-time fee
- Use Expo EAS Build + Submit for automated builds

---

## Project Structure

```
expense-tracker/
├── server/                 # Existing backend
│   └── src/
│       └── routes/
│           └── syncRoutes.js    # NEW: Sync API endpoints
├── web-admin/              # Existing web app
├── mobile/                 # NEW: Expo React Native app
│   ├── app.json            # Expo configuration
│   ├── src/
│   │   ├── screens/        # Mobile-specific screens
│   │   │   ├── HomeScreen.tsx
│   │   │   ├── TransactionsScreen.tsx
│   │   │   ├── AddTransactionScreen.tsx
│   │   │   ├── AccountsScreen.tsx
│   │   │   ├── CategoriesScreen.tsx
│   │   │   ├── AllocationsScreen.tsx
│   │   │   └── SettingsScreen.tsx
│   │   ├── components/     # Touch-optimized components
│   │   │   ├── CategoryPicker.tsx      # Drag-to-select
│   │   │   ├── SwipeableRow.tsx        # Swipe actions
│   │   │   ├── AmountInput.tsx         # Number pad
│   │   │   └── TransactionCard.tsx
│   │   ├── db/             # WatermelonDB setup
│   │   │   ├── schema.ts   # Database schema
│   │   │   ├── models/     # Model definitions
│   │   │   └── sync.ts     # Sync logic
│   │   ├── services/       # API & sync
│   │   │   ├── api.ts      # API client
│   │   │   └── syncService.ts
│   │   ├── navigation/     # React Navigation
│   │   │   └── AppNavigator.tsx
│   │   ├── hooks/          # Custom hooks
│   │   ├── context/        # Auth, sync state
│   │   └── utils/          # Helpers
│   └── package.json
└── shared/                 # Optional: Shared TypeScript types
    └── types/
        ├── transaction.ts
        ├── account.ts
        └── category.ts
```

---

## Backend Changes Required

### New Sync API Endpoints

```
POST /api/sync/push
  - Receives local changes from device
  - Body: { deviceId, lastSyncAt, changes: [...] }
  - Returns: { conflicts: [...], serverChanges: [...] }

GET /api/sync/pull?since=<timestamp>&deviceId=<id>
  - Returns changes since last sync
  - Response: { changes: [...], serverTimestamp }

POST /api/sync/resolve-conflict
  - User-resolved conflict
  - Body: { recordId, recordType, chosenVersion }
```

### Database Additions

```sql
-- Add to existing tables if not present
ALTER TABLE transactions ADD COLUMN device_id VARCHAR(50);
ALTER TABLE accounts ADD COLUMN device_id VARCHAR(50);
ALTER TABLE categories ADD COLUMN device_id VARCHAR(50);
ALTER TABLE allocations ADD COLUMN device_id VARCHAR(50);

-- Sync tracking
CREATE TABLE sync_checkpoints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    device_id VARCHAR(50) NOT NULL,
    last_sync_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, device_id)
);
```

---

## Mobile App Screens (Wireframe Concepts)

### Home Screen
```
┌─────────────────────────────────┐
│  ☰  Expense Tracker    [sync]  │
├─────────────────────────────────┤
│                                 │
│   Total Balance                 │
│   $12,450.00                    │
│                                 │
│  ┌─────────┐  ┌─────────┐      │
│  │ Income  │  │ Expense │      │
│  │ +$5,200 │  │ -$3,100 │      │
│  └─────────┘  └─────────┘      │
│                                 │
│  Recent Transactions            │
│  ┌─────────────────────────┐   │
│  │ 🛒 Groceries    -$85.50 │ ← │ Swipe for actions
│  │ ⛽ Gas          -$45.00 │   │
│  │ 💰 Salary    +$2,600.00 │   │
│  └─────────────────────────┘   │
│                                 │
│              [+]                │  ← FAB for quick add
└─────────────────────────────────┘
```

### Add Transaction (Category Drag)
```
┌─────────────────────────────────┐
│  ←  Add Expense                 │
├─────────────────────────────────┤
│                                 │
│   Amount                        │
│   ┌─────────────────────────┐   │
│   │      $  85.50           │   │
│   └─────────────────────────┘   │
│                                 │
│   Drag a category:              │
│   ┌─────┐ ┌─────┐ ┌─────┐      │
│   │ 🛒  │ │ 🍔  │ │ ⛽  │      │
│   │Groc │ │Food │ │ Gas │      │
│   └─────┘ └─────┘ └─────┘      │
│   ┌─────┐ ┌─────┐ ┌─────┐      │
│   │ 🎬  │ │ 💡  │ │ 🏠  │      │
│   │Ent. │ │Util │ │Home │      │
│   └─────┘ └─────┘ └─────┘      │
│                                 │
│   ┌─ Drop here ──────────────┐  │
│   │                          │  │
│   └──────────────────────────┘  │
│                                 │
│   Account: [Checking ▼]         │
│   Date:    [Today ▼]            │
│   Notes:   [Optional...]        │
│                                 │
│   [        Save Transaction   ] │
└─────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Initialize Expo project
- [ ] Set up WatermelonDB with schema
- [ ] Implement authentication (JWT storage)
- [ ] Basic navigation structure
- [ ] Home screen with local data

### Phase 2: Core Features (Week 3-4)
- [ ] Add transaction screen with category drag
- [ ] Transaction list with swipe actions
- [ ] Accounts management
- [ ] Categories management
- [ ] Allocations/budgets view

### Phase 3: Sync (Week 5-6)
- [ ] Build sync API endpoints on server
- [ ] Implement push/pull sync in app
- [ ] Conflict detection and resolution
- [ ] Sync status indicator
- [ ] Background sync

### Phase 4: Polish (Week 7-8)
- [ ] Haptic feedback
- [ ] Animations and transitions
- [ ] Error handling and offline indicators
- [ ] Settings and preferences
- [ ] Dark mode

### Phase 5: Distribution (Week 9+)
- [ ] Testing on real devices
- [ ] Build APK for Android testing
- [ ] TestFlight for iOS testing
- [ ] App Store submission
- [ ] Play Store submission

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | Expo SDK 52+ |
| Language | TypeScript |
| Navigation | React Navigation 6 |
| Local Database | WatermelonDB |
| State Management | React Context + useReducer |
| Gestures | react-native-gesture-handler |
| Animations | react-native-reanimated |
| UI Components | Custom + react-native-paper |
| Icons | expo-vector-icons |
| Secure Storage | expo-secure-store |

---

## App Store Requirements

### iOS (Apple App Store)
- Apple Developer Account: $99/year
- App icons (1024x1024)
- Screenshots for various device sizes
- Privacy policy URL
- App description and metadata

### Android (Google Play)
- Google Play Developer Account: $25 one-time
- App icons (512x512)
- Feature graphic (1024x500)
- Screenshots for phone and tablet
- Privacy policy URL
- Content rating questionnaire

---

## Notes

- The mobile app is NOT a port of the web app - it's designed specifically for touch
- Offline-first is critical - the app must work without internet
- Sync happens automatically when online, with manual trigger option
- Household members see real-time updates when synced
- Start with core features, add advanced features iteratively

---

## Next Steps

1. Set up the Expo project structure
2. Design the sync API endpoints
3. Create detailed screen mockups
4. Begin Phase 1 implementation

---

*Document created: January 2026*
*Last updated: January 2026*
