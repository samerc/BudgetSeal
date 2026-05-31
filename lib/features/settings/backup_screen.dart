import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/backup_reminder_provider.dart';
import '../../core/services/auto_backup_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _working = false;
  bool _autoEnabled = false;
  int _frequencyHours = AutoBackupService.defaultFrequencyHours;
  int _retention = AutoBackupService.defaultRetention;
  List<BackupFile> _backups = [];
  DateTime? _lastAutoBackup;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await AutoBackupService.isEnabled();
    final freq = await AutoBackupService.getFrequencyHours();
    final ret = await AutoBackupService.getRetention();
    final last = await AutoBackupService.getLastBackupTime();
    final backups = await AutoBackupService.listBackups();
    if (mounted) {
      setState(() {
        _autoEnabled = enabled;
        _frequencyHours = freq;
        _retention = ret;
        _lastAutoBackup = last;
        _backups = backups;
      });
    }
  }

  // ── Manual export ──────────────────────────────────────────────

  Future<void> _exportBackup() async {
    setState(() => _working = true);
    String? backupPath;
    try {
      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbDir.path, 'pocketplan.db'));

      if (!dbFile.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).backupDbNotFound)),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      backupPath =
          p.join(tempDir.path, 'pocketplan_backup_$timestamp.db');
      await dbFile.copy(backupPath);

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(backupPath)], text: 'Pocket Plan backup'),
        );
        await recordBackupDate();
        ref.invalidate(daysSinceBackupProvider);
        ref.invalidate(showBackupReminderProvider);
      }
    } finally {
      if (backupPath != null) {
        try {
          final tempFile = File(backupPath);
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _working = false);
    }
  }

  // ── Restore from file ──────────────────────────────────────────

  Future<void> _restoreFromFile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).backupRestoreDialogTitle),
        content: Text(S.of(context).backupRestoreWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: Text(S.of(context).backupRestoreTitle),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _working = true);
    try {
      final result = await FilePicker.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      // Validate the backup file before restoring
      final backupFile = File(path);
      final fileSize = await backupFile.length();
      if (fileSize > 100 * 1024 * 1024) { // 100MB limit
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).backupTooLarge),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      // Check SQLite magic bytes
      final header = await backupFile.openRead(0, 16).first;
      final magic = String.fromCharCodes(header.take(15));
      if (!magic.startsWith('SQLite format 3')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).backupInvalid),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbDir.path, 'pocketplan.db'));
      // Auto-backup current DB before overwriting
      await AutoBackupService.backupNow();
      await backupFile.copy(dbFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).backupRestored),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  // ── Restore from local backup ──────────────────────────────────

  Future<void> _restoreLocalBackup(BackupFile backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).backupRestoreDialogTitle),
        content: Text(
          'From: ${DateFormat.yMMMd().add_jm().format(backup.created)}\n'
          'Size: ${backup.sizeFormatted}\n\n'
          'This will replace your current data. The app will need to restart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: Text(S.of(context).backupRestoreTitle),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AutoBackupService.restoreFromBackup(backup.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).backupRestored),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).backupRestoreFailed),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.overspent,
          ),
        );
      }
    }
  }

  Future<void> _deleteLocalBackup(BackupFile backup) async {
    await AutoBackupService.deleteBackup(backup.path);
    _loadSettings();
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Auto backup card ──
          _card(
            context,
            icon: Icons.schedule_rounded,
            iconColor: AppColors.accent,
            title: S.of(context).backupAutoTitle,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(S.of(context).backupEnable,
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  _autoEnabled
                      ? 'Backing up every ${_frequencyLabel(_frequencyHours)}'
                      : S.of(context).backupDisabled,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.ts(context)),
                ),
                value: _autoEnabled,
                onChanged: (v) async {
                  await AutoBackupService.setEnabled(v);
                  setState(() => _autoEnabled = v);
                },
                activeTrackColor: AppColors.accent,
              ),
              if (_autoEnabled) ...[
                const SizedBox(height: 8),
                // Frequency picker
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 16, color: AppColors.ts(context)),
                    const SizedBox(width: 8),
                    Text(S.of(context).backupFrequency,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _frequencyHours,
                      underline: const SizedBox.shrink(),
                      style: TextStyle(
                          fontSize: 13, color: AppColors.tp(context)),
                      items: [
                        DropdownMenuItem(
                            value: 6, child: Text(S.of(context).backupEvery6h)),
                        DropdownMenuItem(
                            value: 12, child: Text(S.of(context).backupEvery12h)),
                        DropdownMenuItem(
                            value: 24, child: Text(S.of(context).backupDaily)),
                        DropdownMenuItem(
                            value: 72, child: Text(S.of(context).backupEvery3d)),
                        DropdownMenuItem(
                            value: 168, child: Text(S.of(context).backupWeekly)),
                      ],
                      onChanged: (v) async {
                        if (v == null) return;
                        await AutoBackupService.setFrequencyHours(v);
                        setState(() => _frequencyHours = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Retention picker
                Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 16, color: AppColors.ts(context)),
                    const SizedBox(width: 8),
                    Text(S.of(context).backupKeepLast,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _retention,
                      underline: const SizedBox.shrink(),
                      style: TextStyle(
                          fontSize: 13, color: AppColors.tp(context)),
                      items: [
                        DropdownMenuItem(
                            value: 3, child: Text(S.of(context).backupNBackups(3))),
                        DropdownMenuItem(
                            value: 5, child: Text(S.of(context).backupNBackups(5))),
                        DropdownMenuItem(
                            value: 7, child: Text(S.of(context).backupNBackups(7))),
                        DropdownMenuItem(
                            value: 14, child: Text(S.of(context).backupNBackups(14))),
                        DropdownMenuItem(
                            value: 30, child: Text(S.of(context).backupNBackups(30))),
                      ],
                      onChanged: (v) async {
                        if (v == null) return;
                        await AutoBackupService.setRetention(v);
                        setState(() => _retention = v);
                      },
                    ),
                  ],
                ),
                if (_lastAutoBackup != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last auto-backup: ${DateFormat.yMMMd().add_jm().format(_lastAutoBackup!)}',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.th(context)),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Manual backup card ──
          _card(
            context,
            icon: Icons.backup_rounded,
            iconColor: AppColors.accent,
            title: S.of(context).backupManualTitle,
            children: [
              Text(
                S.of(context).backupExportDesc,
                style:
                    TextStyle(fontSize: 13, color: AppColors.ts(context)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _working ? null : _exportBackup,
                  icon: _working
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.share_rounded, size: 18),
                  label:
                      Text(_working ? S.of(context).backupExporting : S.of(context).backupExportShare),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Restore card ──
          _card(
            context,
            icon: Icons.restore_rounded,
            iconColor: AppColors.caution,
            title: S.of(context).backupRestoreTitle,
            children: [
              Text(
                S.of(context).backupRestoreDesc,
                style:
                    TextStyle(fontSize: 13, color: AppColors.ts(context)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _working ? null : _restoreFromFile,
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text(S.of(context).backupRestoreFromFile),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.caution,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Local backup history ──
          if (_backups.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                S.of(context).backupLocalSection,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.th(context),
                ),
              ),
            ),
            ..._backups.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    borderRadius: BorderRadius.circular(CardTokens.radius),
                    border: Border.all(color: AppColors.bd(context)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.storage_rounded,
                          size: 18, color: AppColors.accent),
                    ),
                    title: Text(
                      DateFormat.yMMMd().add_jm().format(b.created),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.tp(context),
                      ),
                    ),
                    subtitle: Text(
                      b.sizeFormatted,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.ts(context)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.restore_rounded,
                              size: 18, color: AppColors.accent),
                          tooltip: S.of(context).backupRestoreTitle,
                          onPressed: () => _restoreLocalBackup(b),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: AppColors.overspent),
                          tooltip: S.of(context).commonDelete,
                          onPressed: () => _deleteLocalBackup(b),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context))),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  String _frequencyLabel(int hours) {
    if (hours <= 6) return '6 hours';
    if (hours <= 12) return '12 hours';
    if (hours <= 24) return 'day';
    if (hours <= 72) return '3 days';
    return 'week';
  }
}
