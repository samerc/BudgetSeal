import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/backup_reminder_provider.dart';
import '../../core/services/auto_backup_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/icon_header_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/settings_row.dart';
import '../../core/providers/date_format_provider.dart';
import '../../shared/theme/app_icons.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _working = false;
  // Settings load before the cards show, so the switch doesn't flash its
  // default and flip.
  bool _loading = true;
  bool _loadFailed = false;
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
    try {
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
          _loading = false;
          _loadFailed = false;
        });
      }
    } catch (e) {
      debugPrint('[BackupScreen] Failed to load backup settings: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  /// Saves one auto-backup setting and reports the outcome.
  Future<void> _saveSetting(
      Future<void> Function() save, VoidCallback apply, String success) async {
    try {
      await save();
      if (!mounted) return;
      setState(apply);
      _snack(success);
    } catch (e) {
      debugPrint('[BackupScreen] Saving a setting failed: $e');
      if (mounted) _snack(S.of(context).commonSomethingWentWrong);
    }
  }

  // ── Manual export ──────────────────────────────────────────────

  Future<void> _exportBackup() async {
    setState(() => _working = true);
    String? backupPath;
    try {
      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbDir.path, 'budgetseal.db'));

      if (!dbFile.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).backupDbNotFound),
              behavior: SnackBarBehavior.floating,
            ),
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
          p.join(tempDir.path, 'budgetseal_backup_$timestamp.db');
      await dbFile.copy(backupPath);

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(backupPath)], text: 'BudgetSeal backup'),
        );
        await recordBackupDate();
        // The share sheet can stay open long enough for the screen to be
        // dismissed; re-check before touching ref.
        if (!mounted) return;
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
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.backupRestoreConfirmTitle,
      message: tr.backupRestoreWarning,
      confirmLabel: tr.backupRestoreTitle,
    );
    if (!confirmed) return;

    setState(() => _working = true);
    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      final path = file?.path;
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

      // Staged: swapped in on the next launch, before the DB opens. It
      // refuses a cut-off or foreign database (InvalidBackupException).
      await AutoBackupService.restoreFromBackup(path);
      if (mounted) await _showRestartDialog();
    } catch (e) {
      debugPrint('[Backup] Restore failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is InvalidBackupException
              ? S.of(context).backupInvalid
              : S.of(context).backupRestoreFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  // ── Restore from local backup ──────────────────────────────────

  Future<void> _restoreLocalBackup(BackupFile backup) async {
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.backupRestoreConfirmTitle,
      message: tr.backupRestoreDialogBody(
          formatDateTime(backup.created), backup.sizeFormatted),
      confirmLabel: tr.backupRestoreTitle,
    );
    if (!confirmed) return;

    try {
      await AutoBackupService.restoreFromBackup(backup.path);
      if (mounted) await _showRestartDialog();
    } catch (e) {
      debugPrint('[Backup] Local restore failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is InvalidBackupException
                ? S.of(context).backupInvalid
                : S.of(context).backupRestoreFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// The restored file replaces the database on the next launch. Android can
  /// close the app for the user; iOS apps can't quit themselves.
  Future<void> _showRestartDialog() async {
    final tr = S.of(context);
    final canClose = Platform.isAndroid;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(tr.backupRestoreTitle),
        content: Text(tr.backupRestored),
        actions: [
          if (canClose)
            FilledButton(
              style: DialogButtons.filled,
              onPressed: () => SystemNavigator.pop(),
              child: Text(tr.backupCloseApp),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr.commonOk),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteLocalBackup(BackupFile backup) async {
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.backupDeleteTitle,
      message: tr.backupDeleteBody,
      confirmLabel: tr.commonDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      await AutoBackupService.deleteBackup(backup.path);
      _snack(tr.backupDeleted);
    } catch (e) {
      debugPrint('[Backup] Delete failed: $e');
      _snack(tr.backupDeleteFailed);
    }
    _loadSettings();
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).backupTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? ErrorRetry(onRetry: () {
                  setState(() => _loading = true);
                  _loadSettings();
                })
              : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Auto backup card ──
          IconHeaderCard(
            icon: AppIcons.clock,
            title: S.of(context).backupAutoTitle,
            children: [
              SettingsSwitchRow(
                title: S.of(context).backupEnable,
                subtitle: _autoEnabled
                    ? S.of(context).backupAutoEvery(_frequencyLabel(context, _frequencyHours))
                    : S.of(context).backupDisabled,
                value: _autoEnabled,
                onChanged: (v) => _saveSetting(
                    () => AutoBackupService.setEnabled(v),
                    () => _autoEnabled = v,
                    v
                        ? S.of(context).backupAutoOnSnack
                        : S.of(context).backupAutoOffSnack),
              ),
              if (_autoEnabled) ...[
                const SizedBox(height: 8),
                // Frequency picker
                Row(
                  children: [
                    Icon(AppIcons.timer,
                        size: 16, color: AppColors.ts(context)),
                    const SizedBox(width: 8),
                    Text(S.of(context).backupFrequency,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                    const Spacer(),
                    DropdownButton<int>(
                      icon: AppIcons.dropdown,
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
                      onChanged: (v) {
                        if (v == null) return;
                        _saveSetting(
                            () => AutoBackupService.setFrequencyHours(v),
                            () => _frequencyHours = v,
                            S.of(context).backupSettingsSaved);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Retention picker
                Row(
                  children: [
                    Icon(AppIcons.folder,
                        size: 16, color: AppColors.ts(context)),
                    const SizedBox(width: 8),
                    Text(S.of(context).backupKeepLast,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ts(context))),
                    const Spacer(),
                    DropdownButton<int>(
                      icon: AppIcons.dropdown,
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
                      onChanged: (v) {
                        if (v == null) return;
                        _saveSetting(
                            () => AutoBackupService.setRetention(v),
                            () => _retention = v,
                            S.of(context).backupSettingsSaved);
                      },
                    ),
                  ],
                ),
                if (_lastAutoBackup != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    S.of(context).backupLastAutoBackup(formatDateTime(_lastAutoBackup!)),
                    style: TextStyle(
                        fontSize: TypographyTokens.overlineSize,
                        color: AppColors.ts(context)),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: Spacing.md),

          // ── Manual backup card ──
          IconHeaderCard(
            icon: AppIcons.cloudArrowUp,
            title: S.of(context).backupManualTitle,
            description: S.of(context).backupExportDesc,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _working ? null : _exportBackup,
                  icon: _working
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AppColors.onAccent, strokeWidth: 2))
                      : const Icon(AppIcons.shareNetwork, size: 18),
                  label:
                      Text(_working ? S.of(context).backupExporting : S.of(context).backupExportShare),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // ── Restore card ──
          IconHeaderCard(
            icon: AppIcons.clockCounterClockwise,
            iconColor: AppColors.caution,
            title: S.of(context).backupRestoreTitle,
            description: S.of(context).backupRestoreDesc,
            children: [
              // Secondary to Export: outlined, and the confirm dialog
              // carries the warning.
              OutlinedButton.icon(
                onPressed: _working ? null : _restoreFromFile,
                icon: const Icon(AppIcons.fileArrowUp, size: 18),
                label: Text(S.of(context).backupRestoreFromFile),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sectionGap),

          // ── Local backup history ──
          if (_backups.isNotEmpty) ...[
            SectionHeader(S.of(context).backupLocalSection,
                padding: const EdgeInsetsDirectional.only(
                    start: 4, bottom: Spacing.headerToCard)),
            ..._backups.map((b) => AppCard(
                  margin: const EdgeInsets.only(bottom: Spacing.sm),
                  padding: EdgeInsets.zero,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      contentPadding: const EdgeInsetsDirectional.fromSTEB(
                          14, 2, 4, 2),
                      leading: SettingsIcon(
                          icon: AppIcons.database, color: AppColors.accent),
                      title: Text(
                        formatDateTime(b.created),
                        style: SettingsRowStyle.title(context),
                      ),
                      subtitle: Text(
                        b.sizeFormatted,
                        style: SettingsRowStyle.subtitle(context),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(AppIcons.clockCounterClockwise,
                                size: 18, color: AppColors.accent),
                            tooltip: S.of(context).backupRestoreTitle,
                            onPressed: () => _restoreLocalBackup(b),
                          ),
                          IconButton(
                            icon: Icon(AppIcons.trash,
                                size: 18, color: AppColors.overspent),
                            tooltip: S.of(context).commonDelete,
                            onPressed: () => _deleteLocalBackup(b),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _frequencyLabel(BuildContext context, int hours) {
    final s = S.of(context);
    if (hours <= 6) return s.backupEvery6h;
    if (hours <= 12) return s.backupEvery12h;
    if (hours <= 24) return s.backupDaily;
    if (hours <= 72) return s.backupEvery3d;
    return s.backupWeekly;
  }
}
