import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/home_tab_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/haptics.dart';
import '../allocations/allocations_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../reports/reports_hub_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _currentIndex;
  late final PageController _pageController;
  bool _initialized = false;

  static const _tabs = <Widget>[
    DashboardScreen(),
    TransactionsScreen(),
    AllocationsScreen(),
    ReportsHubScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    hapticLight();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    // Read the preferred home tab and jump to it once on first build.
    final homeTab = ref.watch(homeTabProvider);
    if (!_initialized && homeTab > 0 && homeTab < _tabs.length) {
      _initialized = true;
      _currentIndex = homeTab;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(homeTab);
        }
      });
    } else if (!_initialized) {
      _initialized = true;
    }

    final canGoBack = GoRouter.of(context).canPop();

    return PopScope(
      canPop: canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Back goes to the preferred home tab, not always index 0
        if (_currentIndex != homeTab) {
          _onTabTapped(homeTab);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).navPressBackToExit),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: _tabs,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: S.of(context).tabHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.swap_vert),
              selectedIcon: const Icon(Icons.swap_vert_rounded),
              label: S.of(context).tabActivity,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
              label: S.of(context).tabBudget,
            ),
            NavigationDestination(
              icon: const Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: const Icon(Icons.pie_chart_rounded),
              label: S.of(context).tabReports,
            ),
            NavigationDestination(
              icon: const Icon(Icons.grid_view),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: S.of(context).tabMore,
            ),
          ],
        ),
      ),
    );
  }
}
