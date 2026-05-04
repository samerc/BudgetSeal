import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Schedules a daily local notification reminding the user to log transactions.
///
/// Settings stored in SharedPreferences:
/// - `daily_reminder_enabled` (bool)
/// - `daily_reminder_hour` (int, 0-23)
/// - `daily_reminder_minute` (int, 0-59)
/// - `daily_reminder_message` (String, custom message)
class DailyReminderService {
  static const _prefEnabled = 'daily_reminder_enabled';
  static const _prefHour = 'daily_reminder_hour';
  static const _prefMinute = 'daily_reminder_minute';
  static const _prefMessage = 'daily_reminder_message';

  static const _notificationId = 9999;
  static const _channelId = 'pocketplan_daily_reminder';
  static const _channelName = 'Daily Reminder';
  static const _channelDesc = 'Daily reminder to log transactions';

  static const defaultHour = 19; // 7 PM
  static const defaultMinute = 0;
  static const defaultMessage = '';

  static const _defaultMessages = [
    'How did you spend today? Tap to record.',
    "Don't forget to log today's transactions!",
    'Stay on track — record today\'s spending.',
    'A minute now saves hours later. Log your day!',
    'Keep your budget honest — add today\'s transactions.',
  ];

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  // ── Settings ────────────────────────────────────────────────────

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabled) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, enabled);
    if (enabled) {
      await _schedule();
    } else {
      await _cancel();
    }
  }

  static Future<TimeOfDay> getTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: prefs.getInt(_prefHour) ?? defaultHour,
      minute: prefs.getInt(_prefMinute) ?? defaultMinute,
    );
  }

  static Future<void> setTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefHour, time.hour);
    await prefs.setInt(_prefMinute, time.minute);
    if (await isEnabled()) {
      await _schedule();
    }
  }

  static Future<String> getMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefMessage) ?? defaultMessage;
  }

  static Future<void> setMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefMessage, message.trim());
    if (await isEnabled()) {
      await _schedule();
    }
  }

  // ── Init (call on app start) ────────────────────────────────────

  /// Re-schedule the notification if enabled. Call this from main().
  static Future<void> init() async {
    try {
      if (await isEnabled()) {
        await _schedule();
      }
    } catch (e) {
      debugPrint('[DailyReminder] Init failed: $e');
    }
  }

  // ── Core ────────────────────────────────────────────────────────

  static Future<void> _schedule() async {
    await _ensureInitialized();
    await _ensureTz();

    // Request notification permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final time = await getTime();
    final customMessage = await getMessage();

    // Pick message: use custom if set, otherwise rotate defaults
    final body = customMessage.isNotEmpty
        ? customMessage
        : _defaultMessages[Random().nextInt(_defaultMessages.length)];

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'PocketPlan',
      body: body,
      scheduledDate: _nextInstanceOfTime(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _cancel() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _notificationId);
  }

  /// Ensure timezone data is loaded and local timezone is set.
  static bool _tzInitialized = false;
  static Future<void> _ensureTz() async {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } catch (_) {
        // Fallback: tz.local stays UTC — better than crashing
      }
      _tzInitialized = true;
    }
  }

  /// Compute the next occurrence of the given time today or tomorrow.
  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
