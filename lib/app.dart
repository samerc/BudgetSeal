import 'package:drift/drift.dart' hide Column;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/capture/bank_alerts.dart';
import 'core/capture/share_intake.dart';
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
import 'core/services/daily_reminder_service.dart';
import 'core/services/home_widget_service.dart';
import 'l10n/s_lookup.dart';
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
import 'features/allocations/copy_year_screen.dart';
import 'features/allocations/funding_screen.dart';
import 'features/allocations/month_close_screen.dart';
import 'features/reports/time/report_view.dart';
import 'features/categories/categories_screen.dart';
import 'features/main/main_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/periods/leftover_resolution_screen.dart';
import 'features/recurring/recurring_screen.dart';
import 'features/recurring/upcoming_bills_screen.dart';
import 'features/transactions/calendar_screen.dart';
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
import 'features/settings/change_log_screen.dart';
import 'features/settings/crash_reports_screen.dart';
import 'features/settings/import_export_screen.dart';
import 'features/settings/sync_screen.dart';
import 'features/planned/planned_payments_screen.dart';
import 'features/planned/fund_payment_screen.dart';
import 'features/planned/plan_payment_screen.dart';
import 'features/transactions/add_transaction_screen.dart';
import 'features/transactions/assisted_transaction_screen.dart';
import 'features/accounts/cash_count_screen.dart';
import 'features/capture/bank_alerts_screen.dart';
import 'features/capture/review_screen.dart';
import 'features/capture/statement_check_screen.dart';
import 'features/family/requests_screen.dart';
import 'features/forecast/forecast_screen.dart';
import 'features/settings/members_screen.dart';
import 'features/settings/rules_screen.dart';
import 'features/transactions/pay_with_change_screen.dart';
import 'features/transactions/quick_add_screen.dart';
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
    // Shared from another app (Android): the add form, filled in from it.
    ShareIntake.incoming.addListener(_openShare);
    _openShare();
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
          path: '/allocations/:id/copy-year',
          pageBuilder: (_, state) => slideUpPage(
            child: CopyYearScreen(fundId: state.pathParameters['id']!),
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
            return slideUpPage(
              child: _EntryModeRouter(extra: extra),
              state: state,
            );
          },
        ),
        GoRoute(
          path: '/bank-alerts',
          pageBuilder: (_, state) =>
              slideUpPage(child: const BankAlertsScreen(), state: state),
        ),
        GoRoute(
          path: '/forecast',
          pageBuilder: (_, state) =>
              slideUpPage(child: const ForecastScreen(), state: state),
        ),
        GoRoute(
          path: '/check-screenshot',
          pageBuilder: (_, state) {
            final extra = state.extra as Map<String, dynamic>;
            return slideUpPage(
              child: StatementCheckScreen(
                accountId: extra['accountId'] as String,
                imagePath: extra['path'] as String,
              ),
              state: state,
            );
          },
        ),
        GoRoute(
          path: '/review',
          pageBuilder: (_, state) =>
              slideUpPage(child: const ReviewScreen(), state: state),
        ),
        GoRoute(
          path: '/requests',
          pageBuilder: (_, state) =>
              slideUpPage(child: const RequestsScreen(), state: state),
        ),
        GoRoute(
          path: '/members',
          pageBuilder: (_, state) =>
              slideUpPage(child: const MembersScreen(), state: state),
        ),
        GoRoute(
          path: '/rules',
          pageBuilder: (_, state) =>
              slideUpPage(child: const RulesScreen(), state: state),
        ),
        GoRoute(
          path: '/rules/edit',
          pageBuilder: (_, state) => slideUpPage(
              child: RuleEditScreen(ruleId: state.extra as String?),
              state: state),
        ),
        GoRoute(
          path: '/count-cash',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            return slideUpPage(
              child: CashCountScreen(
                currency: extra['currency'] as String? ?? 'USD',
                balance: extra['balance'] as double?,
              ),
              state: state,
            );
          },
        ),
        GoRoute(
          path: '/pay-with-change',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return slideUpPage(
              child: PayWithChangeScreen(
                initialTitle: extra?['title'] as String?,
                initialCategoryId: extra?['categoryId'] as String?,
                initialDate: extra?['date'] as DateTime?,
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
          path: '/calendar',
          pageBuilder: (_, state) =>
              slideUpPage(child: const CalendarScreen(), state: state),
        ),
        GoRoute(
          path: '/upcoming-bills',
          pageBuilder: (_, state) =>
              slideUpPage(
                  child: UpcomingBillsScreen(
                      openBillId: state.uri.queryParameters['bill']),
                  state: state),
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
          path: '/change-log',
          pageBuilder: (_, state) =>
              slideUpPage(child: const ChangeLogScreen(), state: state),
        ),
        GoRoute(
          path: '/crash-reports',
          pageBuilder: (_, state) =>
              slideUpPage(child: const CrashReportsScreen(), state: state),
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
          path: '/reports/view/:id',
          pageBuilder: (_, state) => slideUpPage(
              child: ReportView(id: state.pathParameters['id']!),
              state: state),
        ),
        GoRoute(
          path: '/month-close',
          pageBuilder: (_, state) =>
              slideUpPage(child: const MonthCloseScreen(), state: state),
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
          path: '/fund-payment',
          pageBuilder: (_, state) {
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            return slideUpPage(
              child: FundPaymentScreen(
                planId: extra['planId'] as String?,
                categoryId: extra['categoryId'] as String?,
              ),
              state: state,
            );
          },
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
    ShareIntake.incoming.removeListener(_openShare);
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
      // Bank alerts that arrived meanwhile go to "To review".
      ref.invalidate(alertInboxProvider);
    } else if (state == AppLifecycleState.paused) {
      _updateHomeWidget();
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

  /// Home-screen widget: Ready to assign and today's spending (base
  /// currency), refreshed whenever the app goes to the background.
  void _updateHomeWidget() {
    try {
      final household = ref.read(householdProvider).value;
      if (household == null) return;
      final base = household.baseCurrency;
      final rta = ref.read(unallocatedProvider).value?[base] ?? 0;
      final now = DateTime.now();
      var spentToday = 0.0;
      for (final e in ref.read(currentMonthTransactionsProvider).value ??
          const <TransactionEntry>[]) {
        final d = e.tx.createdAt.toLocal();
        if (e.tx.type != 'expense' ||
            d.year != now.year ||
            d.month != now.month ||
            d.day != now.day) {
          continue;
        }
        for (final l in e.lines) {
          if (isRealRate(l.currency, base, l.exchangeRateToBase)) {
            spentToday += l.amount * l.exchangeRateToBase;
          }
        }
      }
      final l = currentS();
      // Envelopes widget: spending envelopes in Budget-tab order, each in
      // its own currency.
      final envelopes = <WidgetEnvelope>[
        for (final a in ref.read(allocationsProvider).value ??
            const <AllocationWithBalance>[])
          if (a.data.allocation.type == 'spending' &&
              !a.data.allocation.archived)
            () {
              final cur = a.data.allocation.targetCurrency ?? base;
              final v = a.balanceByCurrency[cur] ?? 0;
              return (
                name: a.data.allocation.name,
                amount: formatAmount(v, currency: cur),
                negative: v < -0.004,
              );
            }(),
      ];
      HomeWidgetService.update(
        title: l.widgetReadyToAssign(formatAmount(rta, currency: base)),
        line: l.widgetSpentToday(formatAmount(spentToday, currency: base)),
        envelopesTitle: l.widgetEnvelopesTitle,
        envelopesEmpty: l.widgetEnvelopesEmpty,
        envelopes: envelopes,
        addLabel: l.widgetAddLabel,
      );
    } catch (e) {
      debugPrint('[HomeWidget] $e');
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

  /// A bank message, receipt photo or screenshot shared into the app opens
  /// the add form, filled in from it (roadmap #2).
  void _openShare() {
    final item = ShareIntake.incoming.value;
    if (item == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ShareIntake.incoming.value != item) return;
      ShareIntake.incoming.value = null;
      final householdId = ref.read(currentHouseholdIdProvider);
      if (householdId == null) return;
      try {
        final db = ref.read(databaseProvider);
        final household = await (db.select(db.households)
              ..where((h) => h.id.equals(householdId)))
            .getSingleOrNull();
        final extra = await shareFormArgs(item,
            db: db,
            householdId: householdId,
            baseCurrency: household?.baseCurrency ?? 'USD');
        if (extra != null && mounted) {
          _router.push('/add-transaction', extra: extra);
        }
      } catch (e) {
        debugPrint('[Share] Opening the form failed: $e');
      }
    });
    // A share reaching the app on screen comes with no new frame.
    WidgetsBinding.instance.scheduleFrame();
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
      // Top up the reminder window; skip today's if something was logged.
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final logged = await (db.select(db.transactions)
            ..where((t) =>
                t.householdId.equals(householdId) &
                t.deleted.equals(false) &
                t.status.isNull() & // planned payments aren't logging
                t.createdBy.equals('recurring').not() &
                t.createdAt.isBiggerOrEqualValue(today))
            ..limit(1))
          .getSingleOrNull();
      await DailyReminderService.refresh(loggedToday: logged != null);
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
    final mode = prefs.getString('entry_mode') ?? 'one';
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

    // Edits and prefilled lines: the one screen when they fit it (one
    // account, one currency), else the classic form. Step by step only
    // starts new ones.
    final extra = widget.extra;
    if (mode == 'one' && QuickAddScreen.canTake(extra)) {
      return QuickAddScreen.fromExtra(extra);
    }
    final prefilled = extra?['editTransactionId'] != null ||
        extra?['editLines'] != null;
    if (mode == 'assisted' && !prefilled) {
      return AssistedTransactionScreen(
        initialType: widget.extra?['editType'] as String?,
        initialDate: widget.extra?['editDate'] as DateTime?,
        initialTitle: widget.extra?['editNote'] as String?,
      );
    }
    return AddTransactionScreen(
      editTransactionId: extra?['editTransactionId'] as String?,
      editType: extra?['editType'] as String?,
      editDate: extra?['editDate'] as DateTime?,
      editNote: extra?['editNote'] as String?,
      editLines: extra?['editLines'] as List<Map<String, dynamic>>?,
      editFromAccountId: extra?['editFromAccountId'] as String?,
      editDestAccountId: extra?['editDestAccountId'] as String?,
      initialReceipts: extra?['editReceipts'] as List<String>?,
      capture: extra?['capture'] as Map<String, dynamic>?,
    );
  }
}
