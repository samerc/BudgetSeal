import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Automatic local backup service.
///
/// Copies the database file to a local backups directory on a user-chosen
/// schedule. Runs on app resume — if enough time has passed since the last
/// backup, a new one is created automatically.
class AutoBackupService {
  static const _prefEnabled = 'auto_backup_enabled';
  static const _prefFrequency = 'auto_backup_frequency'; // hours
  static const _prefRetention = 'auto_backup_retention'; // max files to keep
  static const _prefLastAutoBackup = 'auto_backup_last';

  /// Default frequency: every 24 hours.
  static const defaultFrequencyHours = 24;

  /// Default retention: keep last 7 backups.
  static const defaultRetention = 7;

  // ── Settings ────────────────────────────────────────────────────

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabled) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, enabled);
  }

  static Future<int> getFrequencyHours() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefFrequency) ?? defaultFrequencyHours;
  }

  static Future<void> setFrequencyHours(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefFrequency, hours);
  }

  static Future<int> getRetention() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefRetention) ?? defaultRetention;
  }

  static Future<void> setRetention(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefRetention, count);
  }

  static Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefLastAutoBackup);
    return s != null ? DateTime.tryParse(s) : null;
  }

  // ── Core ────────────────────────────────────────────────────────

  /// Check if a backup is due and perform it if needed.
  /// Call this on app resume.
  static Future<bool> runIfDue() async {
    try {
      if (!await isEnabled()) return false;

      final lastBackup = await getLastBackupTime();
      final frequencyHours = await getFrequencyHours();

      if (lastBackup != null) {
        final elapsed = DateTime.now().difference(lastBackup);
        if (elapsed.inHours < frequencyHours) return false;
      }

      await _performBackup();
      return true;
    } catch (e) {
      debugPrint('[AutoBackup] Error: $e');
      return false;
    }
  }

  /// Force a backup regardless of schedule.
  static Future<void> backupNow() async {
    await _performBackup();
  }

  static Future<void> _performBackup() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(appDir.path, 'pocketplan.db'));
    if (!dbFile.existsSync()) return;

    final backupDir = await _backupDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final backupFile =
        File(p.join(backupDir.path, 'backup_$timestamp.db'));

    await dbFile.copy(backupFile.path);

    // Record time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefLastAutoBackup, DateTime.now().toIso8601String());

    // Enforce retention
    await _enforceRetention();

    debugPrint('[AutoBackup] Created: ${backupFile.path}');
  }

  /// Delete oldest backups beyond retention limit.
  static Future<void> _enforceRetention() async {
    final retention = await getRetention();
    final backupDir = await _backupDirectory();
    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync())); // newest first

    if (files.length > retention) {
      for (final old in files.skip(retention)) {
        try {
          await old.delete();
          debugPrint('[AutoBackup] Deleted old: ${old.path}');
        } catch (_) {}
      }
    }
  }

  // ── Queries ─────────────────────────────────────────────────────

  /// List all local backups, newest first.
  static Future<List<BackupFile>> listBackups() async {
    final backupDir = await _backupDirectory();
    if (!backupDir.existsSync()) return [];
    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    return files.map((f) {
      final stat = f.statSync();
      return BackupFile(
        path: f.path,
        name: p.basename(f.path),
        size: stat.size,
        created: stat.modified,
      );
    }).toList();
  }

  /// Delete a specific backup.
  static Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Restore from a local backup.
  static Future<void> restoreFromBackup(String backupPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(appDir.path, 'pocketplan.db'));

    // Safety: auto-backup current DB before overwriting
    if (dbFile.existsSync()) {
      try {
        final dir = await _backupDirectory();
        final safetyName = 'pre_restore_${DateTime.now().millisecondsSinceEpoch}.db';
        await dbFile.copy(p.join(dir.path, safetyName));
        debugPrint('[AutoBackup] Safety backup created: $safetyName');
      } catch (e) {
        debugPrint('[AutoBackup] Safety backup failed: $e');
        // Continue with restore — the user confirmed they want to proceed
      }
    }

    await File(backupPath).copy(dbFile.path);
  }

  // ── Helpers ─────────────────────────────────────────────────────

  static Future<Directory> _backupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'backups'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }
}

class BackupFile {
  final String path;
  final String name;
  final int size;
  final DateTime created;

  const BackupFile({
    required this.path,
    required this.name,
    required this.size,
    required this.created,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
