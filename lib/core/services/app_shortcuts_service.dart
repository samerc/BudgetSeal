import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../l10n/s_lookup.dart';
import 'notification_service.dart';

/// Long-press launcher shortcuts (Android app shortcuts / iOS quick actions).
/// A chosen shortcut is routed like a notification tap
/// ([NotificationService.openRoute]).
class AppShortcutsService {
  static const _quickActions = QuickActions();

  static Future<void> init() async {
    try {
      await _quickActions.initialize((type) {
        if (type.startsWith('/')) NotificationService.openRoute.value = type;
      });
      await refresh();
    } catch (e) {
      debugPrint('[AppShortcuts] Init failed: $e');
    }
  }

  /// (Re)publish the shortcuts in the current language.
  static Future<void> refresh() async {
    final l = currentS();
    await _quickActions.setShortcutItems([
      ShortcutItem(
          type: NotificationService.routeAddTransaction,
          localizedTitle: l.shortcutAddTransaction),
      ShortcutItem(
          type: NotificationService.routeFunding,
          localizedTitle: l.shortcutFundEnvelopes),
      ShortcutItem(
          type: NotificationService.routeUpcomingBills,
          localizedTitle: l.shortcutUpcomingBills),
    ]);
  }
}
