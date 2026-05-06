import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/currency_symbol_provider.dart';
import 'core/services/auto_backup_service.dart';
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
import 'features/settings/import_screen.dart';
import 'features/templates/templates_screen.dart';
import 'features/periods/period_transition_screen.dart';
import 'features/reports/export_report_screen.dart';
import 'features/reports/reports_hub_screen.dart';
import 'features/subscriptions/subscriptions_screen.dart';
import 'features/subscriptions/subscription_detail_screen.dart';
import 'features/settings/about_screen.dart';
import 'features/settings/backup_screen.dart';
import 'features/settings/health_check_screen.dart';
import 'features/transactions/bill_splitter_screen.dart';
import 'features/web_companion/web_companion_screen.dart';
import 'features/settings/notifications_screen.dart';
import 'features/settings/exchange_rates_screen.dart';
import 'features/settings/export_screen.dart';
import 'features/settings/import_export_screen.dart';
import 'features/settings/sync_screen.dart';
import 'features/transactions/add_transaction_screen.dart';
import 'features/transactions/assisted_transaction_screen.dart';
import 'features/transactions/transaction_detail_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/theme/app_theme.dart';
import 'shared/utils/page_transitions.dart';

class PocketPlanApp extends ConsumerStatefulWidget {
  const PocketPlanApp({super.key});

  @override
  ConsumerState<PocketPlanApp> createState() => _PocketPlanAppState();
}

class _PocketPlanAppState extends ConsumerState<PocketPlanApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  bool _showSplash = true;
  bool _showLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
                allocationId: state.pathParameters['id']!),
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
          path: '/bill-splitter',
          pageBuilder: (_, state) => slideUpPage(
              child: const BillSplitterScreen(), state: state),
        ),
        GoRoute(
          path: '/health-check',
          pageBuilder: (_, state) => slideUpPage(
              child: const HealthCheckScreen(), state: state),
        ),
        GoRoute(
          path: '/about',
          pageBuilder: (_, state) => slideUpPage(
              child: const AboutScreen(), state: state),
        ),
        GoRoute(
          path: '/web-companion',
          pageBuilder: (_, state) => slideUpPage(
              child: const WebCompanionScreen(), state: state),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    } else if (state == AppLifecycleState.paused) {
      // Sync on app pause (upload local changes)
      _autoSync();
      // Re-lock if biometric is enabled
      final biometricEnabled = ref.read(biometricLockProvider);
      if (biometricEnabled) {
        setState(() => _showLock = true);
      }
    }
  }

  void _autoSync() {
    final syncState = ref.read(syncProvider);
    if (syncState.activeProvider != null &&
        syncState.status != SyncStatus.syncing) {
      ref.read(syncProvider.notifier).sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.watch(themeModeProvider.notifier);
    final themeMode = themeNotifier.flutterThemeMode;
    final selectedFont = ref.watch(fontProvider);

    // Apply currency symbol overrides and number format whenever they change.
    final symbolOverrides = ref.watch(currencySymbolProvider);
    setCurrencySymbolOverrides(symbolOverrides);
    final numFormat = ref.watch(numberFormatProvider);
    setNumberFormatPrefs(numFormat);

    // Rebuild themes with the selected font (applies to all text styles).
    final lightTheme = buildLightTheme(selectedFont);
    final darkTheme = themeNotifier.isBlackMode
        ? buildBlackTheme(selectedFont)
        : buildDarkTheme(selectedFont);

    if (_showSplash) {
      return MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
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
      title: 'Pocket Plan',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      // Dismiss keyboard when tapping outside any text field (globally).
      // Apply user's text scale preference.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final baseScale = mediaQuery.textScaler.scale(1.0);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(baseScale * textScale),
          ),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: child,
          ),
        );
      },
    );
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
      );
    }
    return AddTransactionScreen(
      editType: widget.extra?['editType'] as String?,
      editNote: widget.extra?['editNote'] as String?,
      editLines: widget.extra?['editLines'] as List<Map<String, dynamic>>?,
    );
  }
}
