import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lastBackupKey = 'last_backup_date';
const _snoozedUntilKey = 'backup_reminder_snoozed_until';
const _reminderThresholdDays = 14;

/// How many days since the last backup, or -1 if never backed up.
final daysSinceBackupProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(_lastBackupKey);
  if (stored == null) return -1;
  final lastBackup = DateTime.tryParse(stored);
  if (lastBackup == null) return -1;
  return DateTime.now().difference(lastBackup).inDays;
});

/// Whether the backup reminder banner should be visible.
final showBackupReminderProvider = FutureProvider<bool>((ref) async {
  final days = await ref.watch(daysSinceBackupProvider.future);
  final needsReminder = days == -1 || days > _reminderThresholdDays;
  if (!needsReminder) return false;

  // Check snooze
  final prefs = await SharedPreferences.getInstance();
  final snoozedUntil = prefs.getString(_snoozedUntilKey);
  if (snoozedUntil != null) {
    final until = DateTime.tryParse(snoozedUntil);
    if (until != null && DateTime.now().isBefore(until)) {
      return false;
    }
  }
  return true;
});

/// Call after a successful backup export to record the date.
Future<void> recordBackupDate() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
  // Clear any snooze when a real backup happens
  await prefs.remove(_snoozedUntilKey);
}

/// Snooze the reminder for 7 days.
Future<void> snoozeBackupReminder() async {
  final prefs = await SharedPreferences.getInstance();
  final until = DateTime.now().add(const Duration(days: 7));
  await prefs.setString(_snoozedUntilKey, until.toIso8601String());
}
