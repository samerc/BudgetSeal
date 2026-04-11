import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/backup_reminder_provider.dart';
import '../../shared/theme/app_colors.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _working = false;

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will replace ALL current data with the backup. '
          'This cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _working = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbDir.path, 'pocketplan.db'));

      // Copy backup over current database
      await File(path).copy(dbFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored. Please restart the app.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _working = true);
    try {
      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbDir.path, 'pocketplan.db'));

      if (!dbFile.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database file not found')),
          );
        }
        return;
      }

      // Copy to temp with timestamp
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final backupPath =
          p.join(tempDir.path, 'pocketplan_backup_$timestamp.db');
      await dbFile.copy(backupPath);

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(backupPath)], text: 'Pocket Plan backup'),
        );
        // Record backup date for reminder tracking
        await recordBackupDate();
        ref.invalidate(daysSinceBackupProvider);
        ref.invalidate(showBackupReminderProvider);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Export
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bd(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.backup_rounded,
                          size: 24, color: AppColors.accent),
                      const SizedBox(width: 12),
                      const Text('Backup',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Export your entire database as a backup file. '
                    'Store it in a safe place to restore later.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.ts(context)),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _working ? null : _exportBackup,
                    icon: _working
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.share_rounded, size: 18),
                    label:
                        Text(_working ? 'Exporting...' : 'Export Backup'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Restore
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bd(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restore_rounded,
                          size: 24, color: AppColors.caution),
                      const SizedBox(width: 12),
                      const Text('Restore',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pick a backup .db file to restore. '
                    'This will replace your current data. The app will need to restart.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.ts(context)),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _working ? null : _restoreBackup,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Restore from File'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.caution,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
