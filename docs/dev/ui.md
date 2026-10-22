# UI: design, theme, widgets, screens

Developer notes moved out of CLAUDE.md (Oct 2026). Read before changing this area; update when you change it.

## Design Conventions

- **Card radius:** 16 (`CardTokens.radius`), **padding:** 16h / 14v — consistent everywhere. All `BorderRadius.circular()` calls use the token, never hardcoded.
- **Category icons:** 48px circles in lists (`CategoryIconTokens.listSize`), 36px compact, 64px hero.
- **Screen titles:** 28px w800 (`TypographyTokens.screenTitleSize`) — Cashew-inspired large bold.
- **Section headers (Cashew SettingsHeader):** sentence case, 15px w700, accent color, no letter spacing. ARB header strings are stored in sentence case (never ALL CAPS); `SectionHeader` no longer upper-cases. Every English UI string is sentence case — buttons, titles, tiles, feature names ("Goals & loans", "Save changes"); only proper nouns keep capitals (BudgetSeal, Google Drive, Web Companion, CSV, PIN). French/Arabic follow their own rules.
- **Cards (Cashew style, Oct 2026):** warm neutral surface (`AppColors.sf` — white on paper in light, night `#1C1D24` in dark), no border; light mode gets a soft shadow (`AppColors.cardShadow`), black mode a faint white edge (`AppColors.cardBorder`). `AppColors.bd` is a hairline (6% black / 7% white) for dividers.
- **Pastel fills:** use `AppColors.pastel(context, color)` / `lightenPastel` / `darkenPastel` (Cashew's color model) for anything colored by a category/envelope/accent — never `color.withValues(alpha: 0.1)` tints.
- No glassmorphism. No left-border accent bars on cards (looks like a prototype).
- Design target: Cashew's layout grammar (measure real values from github.com/jameskokoska/Cashew, `budget/lib`), with BudgetSeal's own brand on top: gold accent pairs, warm paper/night surfaces, Bricolage Grotesque for titles and hero amounts, the gold "Ready to assign" banner. Measure, never copy Cashew code or assets (GPL-3.0).
- **Display font:** `TypographyTokens.displayFamily` ('BricolageGrotesque', bundled in `assets/fonts/`, SIL OFL) for screen titles (`LargeTitleHeader`, `screenTitleSize` styles, `displaySmall`) and hero amounts (form/detail bands, envelope hero and cards, account/goal balances, dashboard net worth/unallocated, Ready to assign). Body text keeps the user's font.
- "Good morning" greeting removed — user disliked it
- Colors are always theme-aware — never hardcode on adaptive surfaces. On accent fills use `AppColors.onAccent` (not `Colors.white`).

## Category Icons

Users can pick from 120+ curated emojis organized by group, OR type/paste any emoji from the system keyboard via the text field at the top of the picker.

**Category icons are Microsoft Fluent Emoji Flat** (MIT, licence in `assets/categories/LICENSE-FluentEmoji.txt`, registered with `LicenseRegistry` in main.dart): ~150 PNGs (128 px) named by code points without U+FE0F (`1f6d2.png` = 🛒), covering the presets and both pickers; the set is listed in `_fluentEmoji` (category_icon.dart). `categoryIconFile()` resolves: the category's emoji → its PNG; else a name keyword (`_keywordEmoji`, longest first) → emoji → PNG; else null (the widget shows the system emoji or the first letter). Anywhere an emoji of a category/envelope/goal is drawn, use `EmojiGlyph(emoji, size:)` — never `Text(emoji)` — so it looks the same on every device. Adding an emoji to a picker: add its Fluent Flat PNG (render the repo's `_flat.svg` at 128 px) and its key to `_fluentEmoji`. The old Flaticon/Cashew-like PNGs are gone (licence risk).

### UI Icons (Phosphor)
All UI icons are **Phosphor** (phosphor_flutter, MIT) through `AppIcons` (`lib/shared/theme/app_icons.dart`): Regular weight, `…Fill` names for the selected nav tab and filled status marks (`checkCircleFill`, `radioButtonFill`, `warningFill`, `warningCircleFill`). Never use Material `Icons.*`. `AppIcons` declares its own `IconData` (font `PhosphorRegular`/`PhosphorFill`, package `phosphor_flutter`) because `PhosphorIconsRegular` marks every glyph `matchTextDirection` (a check would flip in Arabic); only arrows/carets set it. A new icon: add a line to `AppIcons` with the code point from `phosphor_icons_regular.dart`. The theme's `actionIconTheme` gives the automatic AppBar back/close buttons Phosphor icons too. Every `DropdownButton`/`DropdownButtonFormField` passes `icon: AppIcons.dropdown` (a Phosphor caret) — Flutter's default is Material's `arrow_drop_down` and no theme setting replaces it.

## UI Consistency

### Screen Design Patterns
- **Tab screens** (Dashboard, Activity, Budget, Reports, More): no back button. Home, Budget and More use `LargeTitleHeader` (`lib/shared/widgets/large_title_header.dart`) as the first sliver — Cashew's PageFrame title that shrinks from 28pt into a pinned 56px bar on scroll (actions stay top-end, optional subtitle fades). It pads for the status bar itself — no SafeArea around it.
- **Sub-screens** (Recurring, Subscriptions, Templates, Categories): Custom SafeArea header, 24px bold title, back IconButton, filter chips, summary banner, pull-to-refresh
- **Detail/form screens** (Account detail, Allocation detail, etc.): Standard AppBar with auto back

### Standard Widgets
- Loading: `SkeletonList` (Cashew ghost rows: circle + bars, theme-aware shimmer) for lists, `CircularProgressIndicator` for detail screens (list screens never show a bare centered spinner: in a sliver list `SliverToBoxAdapter(child: SkeletonList())`, in a box body a non-scrolling `SingleChildScrollView(child: SkeletonList())`)
- Empty: `EmptyState` widget everywhere (icon in a 96px pastel circle, 18/w700 title, theme `FilledButton` action). Don't add an action that repeats a visible FAB/+ (Activity's empty state has none; Budget hides its FAB while there are no envelopes).
- Error: `ErrorRetry` widget everywhere
- Cards: use `AppCard`, or `CardTokens.radius` (16) + `CardTokens.padding` (16h, 14v) + `AppColors.sf(context)` + `AppColors.cardShadow(context)` (no border — see Design Conventions)
- Section headers: Use `SectionHeader` widget or `TypographyTokens.sectionHeaderSize/Weight/LetterSpacing`
- Screen titles: `TypographyTokens.screenTitleSize` (28) + `TypographyTokens.screenTitleWeight` (w800)
- Chips: Pill-shaped (20px radius), colored border+bg when selected
- SnackBars: Always `behavior: SnackBarBehavior.floating`. A SnackBar with an `action` (Undo) must pass `persist: false` — since Flutter 3.29 an action makes it stay until tapped (no theme setting), which left Undo bars covering buttons and delayed `deleteTransactionsWithUndo`'s final delete. The theme makes them Cashew popups (popup surface, dark text, accent action) — don't pass a saturated `backgroundColor` (the theme's dark text would be unreadable on it); errors use the same style.
- Accent-colored text (section headers, links): `AppColors.accentText(context)` — lifted in dark mode for contrast.
- All list screens have `RefreshIndicator`

### Navigation
- `MainScreen` uses a lazy `IndexedStack` (tabs built on first visit, then kept alive) — tab switches are instant like Cashew. Re-tapping the active tab scrolls its `PrimaryScrollController` to the top.
- `PopScope` checks `GoRouter.canPop()` so pushed routes (funding, accounts, etc.) pop correctly instead of exiting the app

## Animation Widgets

### AnimatedAmount
`lib/shared/widgets/animated_amount.dart` — count-up/down effect for currency amounts using `IntTween` on cents for smooth integer stepping. `lazyFirstRender: true` (default) skips animation on first build — only animates on subsequent value changes. Used on dashboard totals (income, expense, net worth, unallocated).

### AnimatedCircularProgress
`lib/shared/widgets/animated_circular_progress.dart` — custom-painted circular progress ring with overspend indicator. Main arc (0-100%) in `color`, second arc overlay in `overspendColor` for values > 100%. AnimationController at 1500ms with `easeInOutCubicEmphasized`. Used on allocation cards for envelopes with targets.

### RollingNumber
`lib/shared/widgets/rolling_number.dart` — odometer-style rolling digit animation. Each digit scrolls independently (rightmost fastest, leftmost slowest). Non-digit characters (currency symbols, separators) crossfade. Wraps around 0↔9 via shortest path. Used on dashboard net worth and unallocated amounts.

### Tappable
`lib/shared/widgets/tappable.dart` — Cashew-style touch wrapper. iOS: opacity fade to 0.5. Android: InkSparkle ripple. Defaults are calm (`scaleFactor: 1.0`, `haptic: false`) for cards and rows; pass a scale < 1 and `haptic: true` only for button-like surfaces (quick actions, templates, keypad). Long-press always fires a heavy haptic.

### FadedEdges
`lib/shared/widgets/faded_edges.dart` — ShaderMask-based gradient fade at scroll boundaries. Supports top/bottom/start/end fades. Used on transaction month tabs for smooth horizontal scroll fade.

### ErrorBoundary
`lib/shared/widgets/error_boundary.dart` — wraps child subtree; shows friendly fallback ("Something went wrong" + Try Again + Go Back) when `_hasError` is set. Does NOT override `ErrorWidget.builder` (that causes `_dependents.isEmpty` crash). Error catching handled by `FlutterError.onError` in main.dart.

### BreathingWidget
`lib/shared/widgets/breathing_widget.dart` — pulsing scale animation (1.0→1.15, 2500ms, repeating). Set `active: false` to render statically.

## Customizable Dashboard

`lib/core/providers/dashboard_layout_provider.dart` — `DashboardSection` enum with 5 sections (budget, quickActions, spending, money, activity); a saved layout without `budget` gets it inserted first. Each section has visibility toggle. Order + visibility persisted to SharedPreferences as JSON. `DashboardLayoutNotifier` provides reorder/toggle/reset methods.

**Get started checklist** (`widgets/getting_started_card.dart`, always first): Record income → Create envelopes → Fund → Log an expense. `gettingStartedProvider` (`core/providers/getting_started_provider.dart`) is one watched SQL `EXISTS` query (posted income/expense, a live envelope, a `funding` ledger row); steps tick themselves and tap through to the screen. Once all four are done — or the user taps × — `gettingStartedHiddenProvider` stores `getting_started_hidden` and the card never returns. While it shows, the empty recent-activity card drops its "Record your income" button.

Home is **budget-first**. Dashboard flow: Your budget (`widgets/budget_focus.dart` `BudgetFocus`: the shared `ReadyToAssignBanner` (`shared/widgets/ready_to_assign_banner.dart`, also the Budget tab's banner) when there are envelopes or unassigned money → "N envelopes overspent" card (target-currency balance < 0, rows open the envelope, red Cover pill → `showMoveMoneySheet(cover: true)`) → Cashew Upcoming/Overdue bill boxes from `widgets/bills_boxes.dart`) → Quick Actions → Spending Overview (donut + income/expense/net + spending insight) → Your Money (net worth card) → Activity (templates + recent transactions). Bill boxes: Upcoming = enabled recurring due within 7 days; the Overdue box only appears when something is past due (the recurring engine normally posts due bills at launch); only base-currency amounts are summed. Donut slices that share a color (subcategories inherit the parent's) get shifted shades. Status card and envelope health were removed — those live in Reports > Insights and Budget tab respectively.

`lib/features/dashboard/dashboard_customize_sheet.dart` — bottom sheet with `ReorderableListView`, drag handles, and visibility switches. Opened via the tune icon in the dashboard header.

## Theme System

`buildLightTheme(fontName, [accentColor])`, `buildDarkTheme(fontName, [accentColor])`, and `buildBlackTheme(fontName, [accentColor])` in `app_theme.dart` generate full ThemeData. `buildBlackTheme` derives from dark with pure black overrides. Font selection is dynamic via `fontProvider`. Default font: Nunito Sans (`defaultAppFont`, closest to Cashew's Avenir). Available: Plus Jakarta Sans, DM Sans, Inter, Poppins, Nunito, Rubik, Space Grotesk.

All three themes come from one `_buildTheme()`; surfaces are fixed warm neutrals (paper `#F7F5F1`/white in light, night `#121318`/`#1C1D24` in dark, pure black in black) — not accent-tinted — exposed through the `SurfaceColors` theme extension, which `AppColors.bg/sf/sfv/popup/bd` read. The accent lives in fills, text, buttons and the brand banner. Inputs are borderless filled (radius 15), dialogs radius 25, sheets radius 20 with no drag handle, buttons radius 20 (`RadiusTokens`). Don't restate or fight these per widget: no hand-drawn sheet handles, no `showModalBottomSheet(backgroundColor:/shape:)` overrides — a self-decorated sheet uses `AppColors.popup` + `RadiusTokens.sheet` (like `category_sheet.dart`); no `border:`/`enabledBorder:`/`focusedBorder:` or `fillColor: sfv` on an `InputDecoration`; no `shape`/`backgroundColor: accent`/height in `FilledButton.styleFrom` (`minimumSize: Size(0, N)` for buttons in a Row is fine). Filled/Outlined buttons in a dialog's actions (next to Cancel) use `style: DialogButtons.filled` / `.outlined` (design_tokens.dart: 44 high, compact padding) so they sit side by side; the dialog theme's `actionsPadding` leaves room for them.

**Theme modes:** `themeModeProvider` stores a String (`'system'`/`'light'`/`'dark'`/`'black'`). `flutterThemeMode` getter maps black → dark for Flutter's ThemeMode. `isBlackMode` getter for AMOLED-specific logic. `app.dart` must `ref.watch(themeModeProvider)` for the state (not `.notifier`) to rebuild on theme change.

### Design Tokens
`lib/shared/theme/design_tokens.dart` defines the single source of truth:
- **Spacing**: xs(4), sm(8), md(12), lg(16), xl(24), xxl(32), sectionGap(16), headerToCard(8)
- **CardTokens**: radius(16), paddingH(16), paddingV(14), borderRadius, padding
- **RadiusTokens**: sm(8), md(12), lg(16), pill(20), sheet(20), input(15), button(20), fab(18), dialog(25), snackbar(13)
- **Durations**: fast(150ms), standard(250ms), emphasis(350ms) — animation timing
- **CategoryIconTokens**: listSize(48), compactSize(36), heroSize(64)
- **TypographyTokens**: screenTitle(28/w800), sectionHeader(15/w700/ls0), cardTitle(15/w600), amountLarge(24/w700), amountDisplay(18/w800), amountRegular(15/w700), amountSmall(13/w600), body(14/w400), caption(12/w500), overline(11/w600), mini(10/w500), txTitle(15/w600), txSubtitle(12/w400), dateHeader(14/w600)
- **InputLimits**: nameMaxLength(100), noteMaxLength(500), maxAmount(1e9)

### Color Palette
- Accent: user-selectable pair from `brandPalette` (`lib/shared/theme/brand_palette.dart`), default **Gold** (bright `#E3AD45` / deep `#8A5E0F`)
- Expense/Overspent: `#DC2626` (Deep Red)
- Income/Healthy: `#059669` (Deep Emerald)
- Caution: `#D97706` (Deep Amber)
- Light bg: `#F7F5F1` (paper), Dark bg: `#121318` (night), Black bg: `#000000`
- Text: light `#1C1A16` / `#6B655B`, dark `#F2EEE6` / `#A8A49B` (warm neutrals)

### Shared Layout Widgets
- `SectionHeader` (`lib/shared/widgets/section_header.dart`): sentence case, 15px w700, accent color, optional trailing action
- `AppCard` (`lib/shared/widgets/app_card.dart`): theme-aware bg/border, radius 16, standard padding, optional onTap

## More Tab Structure

The More tab is split into two screens:

**More page** (tab) — feature hub:
- Grouped list (`_MoreGroup` cards of `_MoreRow`s with dividers): **Money** (Accounts, Categories, Recurring & Bills, Subscriptions, Planned Payments), **Tools** (Goals & Loans, Bill Splitter, Travel Exchange, Web Companion), **App** (Settings, Help, About). Rows: icon circle, name, one-line description, chevron. Icon colors come from `HSLColor` hues at one shared saturation/lightness — don't hand-pick hex colors (they turn muddy as pastels).
- Backup reminder: one slim amber row (message · Backup Now · dismiss) above the groups
- App group: Settings & Customization → navigates to `/settings`
- Help Guide → navigates to `/help` (WebView loading bundled `assets/web/help.html`)
- About PocketPlan
- Household name + currency shown as subtitle under "More" header (no separate card)

Bill Splitter is also accessible from: Dashboard quick actions ("Split" button) and long-press on the Activity tab FAB.

**Settings screen** (`/settings`) — all configuration. Rows are flat Cashew `SettingsContainer`s (`_SettingsTile`: transparent Material + ListTile, 42px pastel icon circle, 16/w700 title) — never wrap a ListTile in a colored DecoratedBox (hides the ripple).
- **APPEARANCE**: Theme (System/Light/Dark/Black), Colors, Entry Mode, Auto-fill, Start Screen, Font, Text Size, Transaction List layout
- **DATA**: Cloud Sync, Share Household, Backup & Restore, Import & Export, Notifications, Health Check
- **PREFERENCES**: Household Name, Base Currency, Period Start Day, Currency Symbols, Number Format, Date Format
- **SECURITY**: Biometric Lock


## Onboarding

3-page flow on the app's own theme (paper/night surfaces, theme-aware colors, status bar icons follow the brightness): Welcome (the seal app icon `assets/icon/splash_logo.png` as on the splash, how-it-works card; Get started / Restore my budget / Join a household are pinned under the scrolling content so they're reachable at any text size) → Setup (household name, currency, period day; first account name, type chips, opening balance; "Add suggested categories" switch) → Done (next step: income → envelopes). Inputs use the theme's filled style (`CurrencyPickerField` and the opening balance `InputDecorator` match the TextFields); buttons are theme Filled/Outlined/Text with no overrides; sheets use the theme sheet (radius 20, no handle) and show `syncErrorText(e)`, never `e.toString()`. The account name follows the type chip while it still equals the previous type's label. Back on Setup returns to Welcome (`PopScope` + an app-bar back arrow); back on Done goes to `/`. Setup uses `db.batch()` for atomic account + category creation; with "Create envelopes for main categories" on (default, shown only with suggested categories) it also creates a spending envelope per group in `kEnvelopeGroupKeys` (category_presets.dart) and links the group via `categories.allocationId`. Validation errors (theme error style) clear on typing, and the page scrolls to the first one (`Scrollable.ensureVisible` on the field's GlobalKey). With no accounts yet, `CurrencySheet` pins the chosen currency under "Selected".

## Navigation Bar (5 tabs)

Home | Activity | Budget | Reports | More

Accounts are accessed from More > Accounts.

## Accent Color (brand palette)

`lib/shared/theme/brand_palette.dart` + `lib/core/providers/accent_color_provider.dart`.

- **8 tuned pairs** (`AccentPair`): Gold (default), Wax red, Copper, Sage, Teal, Sapphire, Plum, Rose. Each has a `bright` tone (dark/black mode, and filled brand surfaces in every mode), a `deep` tone (light-mode text/icons/buttons — bright tones fail contrast on white), and a `lightFill`/`darkFill`. Plus `'system'` (Material You via `DynamicColorBuilder`; falls back to Gold when unavailable).
- The provider stores the pair id (`accent_color` pref). Old values ('default' Royal Blue or a hex) migrate to the nearest pair by hue on load.
- **`AppColors.accent` is mutable and mode-dependent**: `AppColors.setAccent(pair, system:)` + `applyMode(isDark)` (called in app.dart's build and again in the MaterialApp builder once the real brightness is known) set `accent` (deep/bright), `accentLight` (fill), `accentBright`, `onAccent`. `accentText(context)` is just `accent` for pairs.
- Light and dark `ThemeData` are built with different accents (`buildLightTheme(font, pair.deep, pair.lightFill)`, `buildDarkTheme(font, pair.bright, pair.darkFill)`); `colorScheme.onPrimary`, FilledButton and FAB foregrounds use `AppColors.inkOn(accent)`.
- **Ready to assign banner** (Budget tab and Home, `ReadyToAssignBanner`): `accentBright` fill with `brandInk` text in every mode, ink pill "Assign" button → `/funding`. It's the signature brand element — don't make it dark in light mode (user rejected that).
- Settings > Appearance > Accent Color: 4-column grid of split swatches (bright | deep halves) + System row.

## Fonts

Default font: **Nunito Sans** (closest to Cashew's Avenir). Available: Plus Jakarta Sans, DM Sans, Inter, Poppins, Nunito, Rubik, Space Grotesk. These are body fonts; titles and hero amounts always use the bundled display face **Bricolage Grotesque** (`TypographyTokens.displayFamily`).

## Help Guide

`assets/web/help.html` — comprehensive user guide bundled in the app. 17 sections covering every feature with step-by-step instructions. Responsive (desktop sidebar + mobile hamburger), dark mode support, screenshot placeholders.

**In-app delivery:** `lib/features/settings/help_screen.dart` — `WebView` loads the HTML from `rootBundle`. Injects dark mode CSS variables based on current app theme. Supports deep-linking to sections via `?section=` query parameter (e.g., `context.push('/help?section=envelopes')`).

Route: `/help`, accessible from More > Help Guide.
