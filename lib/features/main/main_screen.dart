import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/home_tab_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
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
  bool _initialized = false;

  /// Tabs are built lazily on first visit, then kept alive by the
  /// IndexedStack (Cashew's LazyIndexedStack behaviour).
  final Set<int> _visited = {};

  /// One primary scroll controller per tab so re-tapping the active tab can
  /// scroll it back to the top.
  final List<ScrollController> _scrollControllers =
      List.generate(_tabs.length, (_) => ScrollController());

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
  }

  @override
  void dispose() {
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Re-tap the active tab: scroll it back to the top.
      final c = _scrollControllers[index];
      if (c.hasClients && c.offset > 0) {
        c.animateTo(0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubicEmphasized);
      }
      return;
    }
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
    } else if (!_initialized) {
      _initialized = true;
    }

    _visited.add(_currentIndex);
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
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  _visited.contains(i)
                      ? PrimaryScrollController(
                          controller: _scrollControllers[i],
                          child: _tabs[i],
                        )
                      : const SizedBox.shrink(),
              ],
            ),
            // Edge-to-edge: keep scrolled content from running under the
            // status bar icons (Cashew pins a background strip there).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.paddingOf(context).top,
              child: IgnorePointer(
                child: ColoredBox(color: AppColors.bg(context)),
              ),
            ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          // Cashew's sharp shadow above the bar (light mode only).
          decoration: BoxDecoration(
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? const [
                    BoxShadow(
                        color: Color(0x1E5A5A5A),
                        blurRadius: 2,
                        spreadRadius: 2),
                  ]
                : const [],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            animationDuration: const Duration(milliseconds: 1000),
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
      ),
    );
  }
}
