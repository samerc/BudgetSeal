import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// One envelope row of the envelopes widget.
typedef WidgetEnvelope = ({String name, String amount, bool negative});

/// One button of the templates widget: a template's name and amount.
typedef WidgetTemplate = ({String id, String label});

/// Feeds the Android home-screen widgets — `SpendingWidget.kt` (Ready to
/// assign, spent today), `EnvelopesWidget.kt` (up to [maxEnvelopes]
/// envelopes), `QuickAddWidget.kt` (a button) and `TemplatesWidget.kt` (up
/// to [maxTemplates] templates, `/template/<id>`): text saved in shared
/// preferences, then a redraw through a method channel (`MainActivity.kt`).
/// Called when the app goes to the background. A widget tap opens a route
/// through the same channel ([init]).
class HomeWidgetService {
  static const _channel = MethodChannel('budgetseal/widget');
  static const maxEnvelopes = 4;
  static const maxTemplates = 3;

  /// Widget taps: the one that launched the app, and later ones while it
  /// runs, are routed like a notification tap.
  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is String) {
        NotificationService.openRoute.value = call.arguments as String;
      }
    });
    try {
      final route = await _channel.invokeMethod<String>('launchRoute');
      if (route != null && route.startsWith('/')) {
        NotificationService.openRoute.value = route;
      }
    } catch (e) {
      debugPrint('[HomeWidget] Launch route failed: $e');
    }
  }

  static Future<void> update({
    required String title,
    required String line,
    required String envelopesTitle,
    required String envelopesEmpty,
    required List<WidgetEnvelope> envelopes,
    required String addLabel,
    required List<WidgetTemplate> templates,
    required String templatesEmpty,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_title', title);
      await prefs.setString('widget_line', line);
      await prefs.setString('widget_env_title', envelopesTitle);
      await prefs.setString('widget_env_empty', envelopesEmpty);
      final shown = envelopes.take(maxEnvelopes).toList();
      await prefs.setInt('widget_env_count', shown.length);
      for (var i = 0; i < shown.length; i++) {
        await prefs.setString('widget_env_name_$i', shown[i].name);
        await prefs.setString('widget_env_amount_$i', shown[i].amount);
        await prefs.setBool('widget_env_neg_$i', shown[i].negative);
      }
      await prefs.setString('widget_add_label', addLabel);
      final buttons = templates.take(maxTemplates).toList();
      await prefs.setInt('widget_tmpl_count', buttons.length);
      for (var i = 0; i < buttons.length; i++) {
        await prefs.setString('widget_tmpl_id_$i', buttons[i].id);
        await prefs.setString('widget_tmpl_label_$i', buttons[i].label);
      }
      await prefs.setString('widget_tmpl_empty', templatesEmpty);
      await _channel.invokeMethod('update');
    } catch (e) {
      debugPrint('[HomeWidget] Update failed: $e');
    }
  }
}
