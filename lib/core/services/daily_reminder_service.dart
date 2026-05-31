import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../l10n/s_lookup.dart';
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

  // Schedule 14 individual notifications (2 weeks), IDs 9900–9913.
  // This is more reliable than a single repeating notification which
  // Android may silently drop on some devices.
  static const _baseNotificationId = 9900;
  static const _scheduleDays = 14;
  static const _channelId = 'pocketplan_daily_reminder';
  static const _channelName = 'Daily Reminder';
  static const _channelDesc = 'Daily reminder to log transactions';

  static const defaultHour = 19; // 7 PM
  static const defaultMinute = 0;
  static const defaultMessage = '';

  static List<String> _defaultMessages() {
    final l = currentS();
    return [
      l.notifReminder1,
      l.notifReminder2,
      l.notifReminder3,
      l.notifReminder4,
      l.notifReminder5,
    ];
  }

  /// Share the same plugin instance as NotificationService to avoid
  /// dual-initialize conflicts on Android.
  static FlutterLocalNotificationsPlugin? _sharedPlugin;

  static FlutterLocalNotificationsPlugin get _plugin {
    _sharedPlugin ??= FlutterLocalNotificationsPlugin();
    return _sharedPlugin!;
  }

  /// Allow NotificationService to inject its already-initialized plugin.
  static void setSharedPlugin(FlutterLocalNotificationsPlugin plugin) {
    _sharedPlugin = plugin;
    _initialized = true;
  }

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
      await _cancelAll();
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

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Request notification permission on Android 13+
    final notifGranted =
        await androidPlugin?.requestNotificationsPermission() ?? true;
    if (!notifGranted) {
      debugPrint('[DailyReminder] Notification permission denied');
      return;
    }

    // Cancel all previously scheduled daily reminders
    await _cancelAll();

    final time = await getTime();
    final customMessage = await getMessage();
    final rand = Random();

    // Schedule one notification per day for the next 14 days.
    // Using dateAndTime (not just time) is more reliable across devices.
    for (int i = 0; i < _scheduleDays; i++) {
      final msgs = _defaultMessages();
      final body = customMessage.isNotEmpty
          ? customMessage
          : msgs[rand.nextInt(msgs.length)];

      final scheduledDate = _dateAtTime(time, dayOffset: i);
      // Skip if in the past (e.g., today's time already passed when i == 0)
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

      await _plugin.zonedSchedule(
        id: _baseNotificationId + i,
        title: currentS().notifReminderTitle,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
    debugPrint('[DailyReminder] Scheduled $_scheduleDays notifications at ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
  }

  static Future<void> _cancelAll() async {
    await _ensureInitialized();
    for (int i = 0; i < _scheduleDays; i++) {
      await _plugin.cancel(id: _baseNotificationId + i);
    }
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

  /// Compute a TZDateTime at the given time, offset by [dayOffset] days from today.
  static tz.TZDateTime _dateAtTime(TimeOfDay time, {int dayOffset = 0}) {
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + dayOffset,
      time.hour,
      time.minute,
    );
  }
}
