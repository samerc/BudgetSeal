import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feeds the Android home-screen widget (`SpendingWidget.kt`): two lines of
/// text saved in shared preferences, then a redraw through a method channel
/// (`MainActivity.kt`). Called when the app goes to the background.
class HomeWidgetService {
  static const _channel = MethodChannel('budgetseal/widget');

  static Future<void> update({
    required String title,
    required String line,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_title', title);
      await prefs.setString('widget_line', line);
      await _channel.invokeMethod('update');
    } catch (e) {
      debugPrint('[HomeWidget] Update failed: $e');
    }
  }
}
