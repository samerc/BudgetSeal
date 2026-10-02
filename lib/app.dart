import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/accent_color_provider.dart';
import 'core/providers/arabic_digits_provider.dart';
import 'core/providers/locale_provider.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/providers/accounts_provider.dart';
import 'core/providers/currency_symbol_provider.dart';
import 'core/providers/date_format_provider.dart';
import 'core/providers/database_provider.dart';
import 'core/services/auto_backup_service.dart';
import 'core/services/app_shortcuts_service.dart';
import 'core/services/notification_service.dart';
import 'core/providers/allocations_provider.dart';
import 'core/providers/engine_provider.dart';
import 'core/providers/transactions_provider.dart';
import 'core/services/travel_account_service.dart';
import 'core/providers/number_format_provider.dart';
import 'core/providers/sync_provider.dart';
import 'shared/utils/format_number.dart';
import 'core/providers/biometric_provider.dart';
import 'core/providers/font_provider.dart';
import 'core/providers/household_provider.dart';
import 'core/providers/text_scale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'features/lock/lock_screen.dart';
import 'features/accounts/account_detail_screen.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/allocations/allocation_detail_screen.dart';
import 'features/allocations/funding_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/main/main_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/periods/leftover_resolution_screen.dart';
import 'features/recurring/bill_calendar_screen.dart';
import 'features/recurring/recurring_screen.dart';
import 'features/recurring/upcoming_bills_screen.dart';
import 'features/settings/import_screen.dart';
import 'features/templates/templates_screen.dart';
import 'features/periods/period_transition_screen.dart';
import 'features/reports/export_report_screen.dart';
import 'features/reports/reports_hub_screen.dart';
import 'features/objectives/objectives_screen.dart';
import 'features/objectives/objective_detail_screen.dart';
import 'features/travel/travel_exchange_screen.dart';
import 'features/subscriptions/subscriptions_screen.dart';
import 'features/subscriptions/subscription_detail_screen.dart';
import 'features/settings/about_screen.dart';
import 'features/settings/privacy_screen.dart';
import 'features/settings/help_screen.dart';
import 'features/settings/backup_screen.dart';
import 'features/settings/health_check_screen.dart';
import 'features/premium/upgrade_screen.dart';
import 'features/transactions/bill_splitter_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/transactions/tx_list_settings_screen.dart';
import 'features/web_companion/web_companion_screen.dart';
import 'features/settings/notifications_screen.dart';
import 'features/settings/exchange_rates_screen.dart';
import 'features/settings/export_screen.dart';
import 'features/settings/import_export_screen.dart';
import 'features/settings/sync_screen.dart';
import 'features/planned/planned_payments_screen.dart';
import 'features/planned/plan_payment_screen.dart';
import 'features/transactions/add_transaction_screen.dart';
import 'features/transactions/assisted_transaction_screen.dart';
import 'features/transactions/transaction_detail_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/brand_palette.dart';
import 'shared/utils/page_transitions.dart';
import 'shared/widgets/error_boundary.dart';

class BudgetSealApp extends ConsumerStatefulWidget {
  const BudgetSealApp({super.key});

  @override
  ConsumerState<BudgetSealApp> createState() => _BudgetSealAppState();
}

class _BudgetSealAppState extends ConsumerState<BudgetSealApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  bool _showSplash = true;
  bool _showLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.openRoute.addListener(_openNotificationRoute);
    // Launched by a notification tap (set before the app was built).
    _openNotificationRoute();
    _router = GoRouter(
      redirect: (context, state) {
        final householdId = ref.read(currentHouseholdIdProvider);
        final onOnboarding = state.matchedLocation == '/onboarding';
        if (householdId == null && !onOnboarding) return '/onboarding';
        if (householdId != null && onOnboarding) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          pageBuilder: (_, state) =>
              fadePage(child: const OnboardingScreen(), state: state),
        ),
        GoRoute(
          path: '/',
          pageBuilder: (_, state) =>
              fadePage(child: const MainScreen(), state: state),
        ),
        GoRoute(
          path: '/accounts',
          pageBuilder: (_, state) => slideUpPage(
            child: const AccountsScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/accounts/:id',
          pageBuilder: (_, state) => slideUpPage(
            child: AccountDetailScreen(
                accountId: state.pathParameters['id']!),
            state: state,
          ),
        ),
        GoRoute(
          path: '/allocations/:id',
          pageBuilder: (_, state) => slideUpPage(
            child: AllocationDetailScreen(
              allocationId: state.pathParameters['id']!,
              openCover: (state.extra as Map?)?['cover'] == true,
            ),
            state: state,
          ),
        ),
        GoRoute(
          path: '/funding',
          pageBuilder: (_, state) =>
              slideUpPage(child: const FundingScreen(), state: state),
        ),
        GoRoute(
          path: '/add-transaction',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            // If editing or has pre-fill data, always use classic form.
            final hasEditData = extra != null &&
                (extra.containsKey('editTransactionId') ||
                    extra.containsKey('editLines'));

            if (!hasEditData) {
              // Check entry mode preference.
              // We can't use ref here directly, read from container.
              // For simplicity, check if assisted mode via the route.
              return slideUpPage(
                child: _EntryModeRouter(extra: extra),
                state: state,
              );
            }

            return slideUpPage(
              child: AddTransactionScreen(
                editTransactionId:
                    extra['editTransactionId'] as String?,
                editType: extra['editType'] as String?,
                editNote: extra['editNote'] as String?,
                editDate: extra['editDate'] as DateTime?,
                editLines:
                    extra['editLines'] as List<Map<String, dynamic>>?,
                editFromAccountId:
                    extra['editFromAccountId'] as String?,
                editDestAccountId:
                    extra['editDestAccountId'] as String?,
              ),
              state: state,
            );
          },
        ),
        GoRoute(
          path: '/transactions/:id',
          pageBuilder: (_, state) => slideUpPage(
            child: TransactionDetailScreen(
                transactionId: state.pathParameters['id']!),
            state: state,
          ),
        ),
        GoRoute(
          path: '/categories',
          pageBuilder: (_, state) =>
              slideUpPage(child: const CategoriesScreen(), state: state),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (_, state) =>
              slideUpPage(child: const ReportsHubScreen(), state: state),
        ),
        GoRoute(
          path: '/export-report',
          pageBuilder: (_, state) => slideUpPage(
              child: const ExportReportScreen(), state: state),
        ),
        GoRoute(
          path: '/exchange-rates',
          pageBuilder: (_, state) => slideUpPage(
              child: const ExchangeRatesScreen(), state: state),
        ),
        GoRoute(
          path: '/travel-exchange',
          pageBuilder: (_, state) => slideUpPage(
              child: const TravelExchangeScreen(), state: state),
        ),
        GoRoute(
          path: '/recurring',
          pageBuilder: (_, state) =>
              slideUpPage(child: const RecurringScreen(), state: state),
        ),
        GoRoute(
          path: '/bill-calendar',
          pageBuilder: (_, state) =>
              slideUpPage(child: const BillCalendarScreen(), state: state),
        ),
        GoRoute(
          path: '/upcoming-bills',
          pageBuilder: (_, state) =>
              slideUpPage(child: const UpcomingBillsScreen(), state: state),
        ),
        GoRoute(
          path: '/templates',
          pageBuilder: (_, state) =>
              slideUpPage(child: const TemplatesScreen(), state: state),
        ),
        GoRoute(
          path: '/import',
          pageBuilder: (_, state) =>
              slideUpPage(child: const ImportScreen(), state: state),
        ),
        GoRoute(
          path: '/import-export',
          pageBuilder: (_, state) =>
              slideUpPage(child: const ImportExportScreen(), state: state),
        ),
        GoRoute(
          path: '/backup',
          pageBuilder: (_, state) =>
              slideUpPage(child: const BackupScreen(), state: state),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (_, state) =>
              slideUpPage(child: const NotificationsScreen(), state: state),
        ),
        GoRoute(
          path: '/export',
          pageBuilder: (_, state) => slideUpPage(
              child: const ExportScreen(), state: state),
        ),
        GoRoute(
          path: '/sync',
          pageBuilder: (_, state) => slideUpPage(
              child: const SyncScreen(), state: state),
        ),
        GoRoute(
          path: '/period-transition',
          pageBuilder: (_, state) => slideUpPage(
              child: const PeriodTransitionScreen(), state: state),
        ),
        GoRoute(
          path: '/leftover-resolution',
          pageBuilder: (_, state) => slideUpPage(
              child: const LeftoverResolutionScreen(), state: state),
        ),
        GoRoute(
          path: '/subscriptions',
          pageBuilder: (_, state) => slideUpPage(
              child: const SubscriptionsScreen(), state: state),
        ),
        GoRoute(
          path: '/subscriptions/:id',
          pageBuilder: (_, state) => slideUpPage(
            child: SubscriptionDetailScreen(
                subscriptionId: state.pathParameters['id']!),
            state: state,
          ),
        ),
        GoRoute(
          path: '/objectives',
          pageBuilder: (_, state) => slideUpPage(
              child: const ObjectivesScreen(), state: state),
        ),
        GoRoute(
          path: '/objectives/:id',
          pageBuilder: (_, state) => slideUpPage(
            child: ObjectiveDetailScreen(
                objectiveId: state.pathParameters['id']!),
            state: state,
          ),
        ),
        GoRoute(
          path: '/bill-splitter',
          pageBuilder: (_, state) => slideUpPage(
              child: const BillSplitterScreen(), state: state),
        ),
        GoRoute(
          path: '/planned-payments',
          pageBuilder: (_, state) => fadePage(
              child: const PlannedPaymentsScreen(), state: state),
        ),
        GoRoute(
          path: '/plan-payment',
          pageBuilder: (_, state) => slideUpPage(
              child: PlanPaymentScreen(
                  editTx: state.extra as Map<String, dynamic>?),
              state: state),
        ),
        GoRoute(
          path: '/health-check',
          pageBuilder: (_, state) => slideUpPage(
              child: const HealthCheckScreen(), state: state),
        ),
        GoRoute(
          path: '/upgrade',
          pageBuilder: (_, state) => slideUpPage(
              child: UpgradeScreen(
                  featureName: state.extra as String?),
              state: state),
        ),
        GoRoute(
          path: '/about',
          pageBuilder: (_, state) => slideUpPage(
              child: const AboutScreen(), state: state),
        ),
        GoRoute(
          path: '/privacy',
          pageBuilder: (_, state) => slideUpPage(
              child: const PrivacyScreen(), state: state),
        ),
        GoRoute(
          path: '/web-companion',
          pageBuilder: (_, state) => slideUpPage(
              child: const WebCompanionScreen(), state: state),
        ),
        GoRoute(
          path: '/tx-list-settings',
          pageBuilder: (_, state) => slideUpPage(
              child: const TxListSettingsScreen(), state: state),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (_, state) => slideUpPage(
              child: const SettingsDetailScreen(), state: state),
        ),
        GoRoute(
          path: '/help',
          pageBuilder: (_, state) {
            final section = state.uri.queryParameters['section'];
            return slideUpPage(
                child: HelpScreen(section: section), state: state);
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.openRoute.removeListener(_openNotificationRoute);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Sync on app resume (download remote changes)
      _autoSync();
      // Auto-backup if due
      AutoBackupService.runIfDue();
      // Auto-archive travel wallets at zero balance
      _checkTravelAccounts();
      // Post bills that fell due while the app sat in memory, then alerts.
      _processDueWork();
    } else if (state == AppLifecycleState.paused) {
      // Sync on app pause (upload local changes)
      _autoSync();
      // Auto-backup if due (runs on exit as well as resume)
      AutoBackupService.runIfDue();
      // Re-lock if biometric is enabled
      final biometricEnabled = ref.read(biometricLockProvider);
      if (biometricEnabled) {
        setState(() => _showLock = true);
      }
    }
  }

  /// A tapped notification (or app shortcut) asked for a screen.
  void _openNotificationRoute() {
    final route = NotificationService.openRoute.value;
    if (route == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (NotificationService.openRoute.value == null) return;
      NotificationService.openRoute.value = null;
      if (ref.read(currentHouseholdIdProvider) == null) return;
      _router.push(route);
    });
  }

  Future<void> _processDueWork() async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null || AutoBackupService.restorePending) return;
    try {
      final posted = await ref.read(recurringEngineProvider).processRecurring();
      if (posted > 0) {
        ref.invalidate(transactionEntriesProvider);
        ref.invalidate(monthlyTransactionsProvider);
        ref.invalidate(accountsWithBalanceProvider);
        ref.invalidate(allocationsProvider);
        ref.invalidate(unallocatedProvider);
      }
      await NotificationService.runChecks(
          ref.read(databaseProvider), householdId);
    } catch (e) {
      debugPrint('[Resume] Due work failed: $e');
    }
  }

  void _checkTravelAccounts() {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    final db = ref.read(databaseProvider);
    TravelAccountService.checkAndAutoArchive(db, householdId).then((changed) {
      if (changed) {
        ref.invalidate(accountsProvider);
        ref.invalidate(accountsWithBalanceProvider);
      }
    }).catchError((e) {
      debugPrint('[Travel] Auto-archive check failed: $e');
    });
  }

  void _autoSync() {
    // A restored backup replaces the DB on next launch — don't sync the old one.
    if (AutoBackupService.restorePending) return;
    final syncState = ref.read(syncProvider);
    if (syncState.activeProvider != null &&
        syncState.status != SyncStatus.syncing) {
      ref.read(syncProvider.notifier).sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the state (String) to rebuild on changes, read notifier for helpers
    ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final themeMode = themeNotifier.flutterThemeMode;
    final selectedFont = ref.watch(fontProvider);

    // Accent: a palette pair (deep tone in light, bright in dark) or the
    // Material You color.
    ref.watch(accentColorProvider);
    final accentPair = ref.read(accentColorProvider.notifier).pair;

    // Apply currency symbol overrides and number format whenever they change.
    final symbolOverrides = ref.watch(currencySymbolProvider);
    setCurrencySymbolOverrides(symbolOverrides);
    final numFormat = ref.watch(numberFormatProvider);
    setNumberFormatPrefs(numFormat);
    final dateFormat = ref.watch(dateFormatProvider);
    setDateFormatPattern(dateFormat);

    // Helper to build themes with resolved accent color
    ThemeData buildLight(Color accent) =>
        buildLightTheme(selectedFont, accent, accentPair?.lightFill);
    ThemeData buildDark(Color accent) => themeNotifier.isBlackMode
        ? buildBlackTheme(selectedFont, accent, accentPair?.darkFill)
        : buildDarkTheme(selectedFont, accent, accentPair?.darkFill);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    // System accent without Material You support falls back to Gold.
    final systemColor = lightDynamic?.primary;
    final pair = accentPair ??
        (systemColor == null ? brandPalette.first : null);
    // Global AppColors.accent: resolved per mode here for the splash/lock
    // apps, and again in the MaterialApp builder below once the actual
    // theme brightness is known.
    AppColors.setAccent(pair, system: systemColor);
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    AppColors.applyMode(themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformDark));

    final lightTheme = pair != null
        ? buildLightTheme(selectedFont, pair.deep, pair.lightFill)
        : buildLight(systemColor!);
    final darkTheme = pair != null
        ? (themeNotifier.isBlackMode
            ? buildBlackTheme(selectedFont, pair.bright, pair.darkFill)
            : buildDarkTheme(selectedFont, pair.bright, pair.darkFill))
        : buildDark(AppColors.lightenPastel(systemColor!, 0.3));

    // Resolve locale early — needed by splash, lock, and main screens.
    final localeCode = ref.watch(localeProvider);
    final locale = localeCode != null ? Locale(localeCode) : null;
    final resolvedLocale = localeCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (Intl.defaultLocale != resolvedLocale) {
      Intl.defaultLocale = resolvedLocale;
      AppShortcutsService.refresh().catchError((_) {});
    }
    // Arabic-Indic digits: only when locale is Arabic AND user opted in
    final useArabic = ref.watch(arabicDigitsProvider);
    setUseArabicDigits(resolvedLocale == 'ar' && useArabic);

    if (_showSplash) {
      return MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: locale,
        home: SplashScreen(
          onComplete: () async {
            final prefs = await SharedPreferences.getInstance();
            final biometricEnabled = prefs.getBool('biometric_lock_enabled') ?? false;
            if (mounted) {
              setState(() {
                _showSplash = false;
                _showLock = biometricEnabled;
              });
            }
          },
        ),
      );
    }

    if (_showLock) {
      return MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: locale,
        home: LockScreen(
          onUnlocked: () {
            setState(() => _showLock = false);
            _autoSync();
          },
        ),
      );
    }

    final textScale = ref.watch(textScaleProvider);

    return MaterialApp.router(
      title: 'BudgetSeal',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: locale,
      // Dismiss keyboard when tapping outside any text field (globally).
      // Apply user's text scale preference.
      builder: (context, child) {
        AppColors.applyMode(Theme.of(context).brightness == Brightness.dark);
        final mediaQuery = MediaQuery.of(context);
        final baseScale = mediaQuery.textScaler.scale(1.0);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
                baseScale * textScale * fontOpticalScale(selectedFont)),
          ),
          // Edge-to-edge: transparent system bars whose icons follow the
          // theme, so the tinted background runs behind them (Cashew style).
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppColors.isDark
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                  ),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ErrorBoundary(child: child ?? const SizedBox.shrink()),
            ),
          ),
        );
      },
    );
      },
    ); // DynamicColorBuilder
  }
}

/// Routes to either assisted or classic transaction entry based on user preference.
class _EntryModeRouter extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra;
  const _EntryModeRouter({this.extra});

  @override
  ConsumerState<_EntryModeRouter> createState() => _EntryModeRouterState();
}

class _EntryModeRouterState extends ConsumerState<_EntryModeRouter> {
  String? _resolvedMode;

  @override
  void initState() {
    super.initState();
    _resolveMode();
  }

  Future<void> _resolveMode() async {
    // Read directly from SharedPreferences to avoid the provider race.
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('entry_mode') ?? 'assisted';
    if (mounted) setState(() => _resolvedMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final mode = _resolvedMode;
    if (mode == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (mode == 'assisted') {
      return AssistedTransactionScreen(
        initialType: widget.extra?['editType'] as String?,
        initialDate: widget.extra?['editDate'] as DateTime?,
        initialTitle: widget.extra?['editNote'] as String?,
      );
    }
    return AddTransactionScreen(
      editType: widget.extra?['editType'] as String?,
      editDate: widget.extra?['editDate'] as DateTime?,
      editNote: widget.extra?['editNote'] as String?,
      editLines: widget.extra?['editLines'] as List<Map<String, dynamic>>?,
    );
  }
}
