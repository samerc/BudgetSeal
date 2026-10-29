import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/sync_provider.dart';
import '../../core/sync/cloud_provider.dart';
import '../../core/sync/google_drive_provider.dart';
import '../../core/sync/sync_encryption.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/icon_header_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/settings_row.dart';
import 'join_household_sheet.dart';
import 'share_household_sheet.dart';
import '../../shared/utils/dispose_later.dart';
import '../../core/providers/date_format_provider.dart';
import '../../shared/theme/app_icons.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final notifier = ref.read(syncProvider.notifier);
    final isConnected = syncState.activeProvider != null;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).syncTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // ── Status card ────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusIcon(context, syncState.status, isConnected),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected
                                ? syncState.activeProvider!.displayName
                                : S.of(context).syncNotConnected,
                            style: SettingsRowStyle.title(context),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _statusSubtitle(context, syncState),
                            style: SettingsRowStyle.subtitle(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Error message
                if (syncState.lastError != null &&
                    syncState.status == SyncStatus.error) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.pastel(context, AppColors.overspent,
                          light: 0.85, dark: 0.78),
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.warningCircle,
                            color: AppColors.overspent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            syncState.lastError!,
                            style: const TextStyle(
                              fontSize: TypographyTokens.captionSize,
                              color: AppColors.overspent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // ── Connected actions ──────────────────────────────────
          if (isConnected) ...[
            _ActionButton(
              icon: AppIcons.arrowsClockwise,
              label: S.of(context).syncNow,
              loading: syncState.status == SyncStatus.syncing,
              onTap: syncState.status == SyncStatus.syncing
                  ? null
                  : () => notifier.sync(),
            ),
            const SizedBox(height: 12),
            if (syncState.activeProvider is GoogleDriveProvider)
              _ActionButton(
                icon: AppIcons.users,
                label: S.of(context).syncShareHousehold,
                onTap: () => _showShareSheet(context, notifier),
              ),
            if (syncState.activeProvider is GoogleDriveProvider) ...[
              const SizedBox(height: 12),
              _ActionButton(
                icon: AppIcons.signIn,
                label: S.of(context).onboardJoinHousehold,
                outlined: true,
                onTap: () => _join(context),
              ),
              const SizedBox(height: 12),
            ],
            _ActionButton(
              icon: AppIcons.linkBreak,
              label: S.of(context).syncDisconnect,
              outlined: true,
              onTap: () => _confirmDisconnect(context, notifier),
            ),
            const SizedBox(height: 16),
            // ── Sync Encryption ──
            _SyncEncryptionCard(),
            const SizedBox(height: 24),
          ],

          // ── Was synced to one file before log sync: pick a folder ──
          if (!isConnected)
            FutureBuilder<bool>(
              future: notifier.needsFolderPick(),
              builder: (context, snap) => snap.data != true
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.xl),
                      child: IconHeaderCard(
                        icon: AppIcons.folderOpen,
                        iconColor: SettingsRowStyle.hue(36),
                        title: S.of(context).syncPickFolderTitle,
                        description: S.of(context).syncPickFolderBody,
                        children: [
                          FilledButton(
                            onPressed: () =>
                                _connect(context, ref, notifier.filePicker),
                            child: Text(S.of(context).syncPickFolderButton),
                          ),
                        ],
                      ),
                    ),
            ),

          // ── Provider list ─────────────────────────────────────
          if (!isConnected) ...[
            SectionHeader(S.of(context).syncConnectSection,
                padding: const EdgeInsetsDirectional.only(
                    start: 4, bottom: Spacing.headerToCard)),
            ...notifier.providerOptions.map((option) {
              final isOneDriveOrDropbox =
                  option.iconKey == 'onedrive' || option.iconKey == 'dropbox';
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProviderOptionTile(
                      label: option.label,
                      subtitle: option.subtitle,
                      iconKey: option.iconKey,
                      onTap: () => _connect(context, ref, option.provider),
                    ),
                    if (isOneDriveOrDropbox)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(56, 4, 8, 0),
                        child: Text(
                          S.of(context).syncReceiptComingSoon,
                          style: TextStyle(
                            fontSize: TypographyTokens.overlineSize,
                            fontStyle: FontStyle.italic,
                            color: AppColors.ts(context),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                S.of(context).syncProviderInfo,
                style: TextStyle(
                  fontSize: TypographyTokens.captionSize,
                  color: AppColors.ts(context),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            // Someone shared their budget: join it (Google Drive).
            _ActionButton(
              icon: AppIcons.users,
              label: S.of(context).onboardJoinHousehold,
              outlined: true,
              onTap: () => _join(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusIcon(BuildContext context, SyncStatus status, bool connected) {
    if (status == SyncStatus.syncing) {
      return SizedBox(
        width: SettingsRowStyle.iconSize,
        height: SettingsRowStyle.iconSize,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.accent,
          ),
        ),
      );
    }

    final (IconData icon, Color color) = switch (status) {
      SyncStatus.success => (AppIcons.checkCircleFill, AppColors.healthy),
      SyncStatus.error => (AppIcons.warningCircleFill, AppColors.overspent),
      _ => connected
          ? (AppIcons.cloudCheck, AppColors.accent)
          : (AppIcons.cloudSlash, AppColors.ts(context)),
    };

    return SettingsIcon(icon: icon, color: color);
  }

  String _statusSubtitle(BuildContext context, SyncState state) {
    if (state.status == SyncStatus.syncing) return S.of(context).syncSyncing;
    if (state.status == SyncStatus.error) return S.of(context).syncLastFailed;
    if (state.lastSyncTime != null) {
      final formatted = formatDateTime(state.lastSyncTime!);
      final changes = state.lastChanges ?? 0;
      final changeSuffix = changes > 0 ? S.of(context).syncChangesMerged(changes) : S.of(context).syncUpToDate;
      return S.of(context).syncLastSynced(formatted, changeSuffix);
    }
    if (state.activeProvider != null) return S.of(context).syncNotYet;
    return S.of(context).syncConnectPrompt;
  }

  Future<void> _connect(
      BuildContext context, WidgetRef ref, CloudProvider provider) async {
    final ok =
        await ref.read(syncProvider.notifier).connectProvider(provider);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).syncConnectedTo(provider.displayName)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _firstSync(context, ref, provider);
    } else if (!ok && context.mounted && !provider.connectCanceled) {
      String errorMsg = S.of(context).syncFailedToConnect;
      if (provider is GoogleDriveProvider && provider.lastConnectError != null) {
        errorMsg = provider.lastConnectError!;
      }
      final tr = S.of(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr.syncConnectionFailed),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr.commonOk),
            ),
          ],
        ),
      );
    }
  }

  /// Right after connecting: upload when the provider has no file yet,
  /// merge when it holds this budget, and ask when it holds another one —
  /// merging two separate budgets would mix two households in one database.
  Future<void> _firstSync(
      BuildContext context, WidgetRef ref, CloudProvider provider) async {
    final notifier = ref.read(syncProvider.notifier);
    final RemoteMatch match;
    try {
      match = await notifier.checkRemote();
    } catch (e) {
      // Stays connected; the error shows on this screen until fixed (e.g.
      // the sync password is entered).
      ref.read(syncProvider.notifier).reportError(e);
      return;
    }
    switch (match) {
      case RemoteMatch.none:
        await notifier.initialUpload();
      case RemoteMatch.same:
        await notifier.sync();
      case RemoteMatch.other:
        if (!context.mounted) return;
        final tr = S.of(context);
        // Using the synced budget replaces this device's data; Cancel
        // (labelled Disconnect) keeps it and drops the connection.
        final use = await showConfirmDialog(
          context,
          title: tr.syncOtherBudgetConfirmTitle,
          message: tr.syncOtherBudgetBody,
          confirmLabel: tr.syncUseSyncedBudget,
          cancelLabel: tr.syncDisconnect,
        );
        if (use) {
          await notifier.restoreFromProvider(provider);
          if (context.mounted &&
              ref.read(syncProvider).status == SyncStatus.success) {
            context.go('/');
          }
        } else {
          // Left connected, the next automatic sync would merge the two.
          await notifier.disconnectProvider();
        }
    }
  }

  /// Joining replaces this phone's budget (a backup is saved first).
  Future<void> _join(BuildContext context) async {
    final tr = S.of(context);
    final go = await showConfirmDialog(
      context,
      title: tr.joinReplaceTitle,
      message: tr.joinReplaceBody,
      confirmLabel: tr.onboardJoinButton,
    );
    if (go && context.mounted) await showJoinHouseholdSheet(context);
  }

  void _showShareSheet(BuildContext context, SyncNotifier notifier) {
    showShareHouseholdSheet(context, notifier.googleDrive);
  }

  Future<void> _confirmDisconnect(
      BuildContext context, SyncNotifier notifier) async {
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.syncDisconnectConfirmTitle,
      message: tr.syncDisconnectMsg,
      confirmLabel: tr.syncDisconnect,
    );
    if (!confirmed) return;
    try {
      await notifier.disconnectProvider();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr.syncDisconnectedSnack),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      debugPrint('[Sync] Disconnect failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr.commonSomethingWentWrong),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ── Provider option tile ──────────────────────────────────────────────────────

class _ProviderOptionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String iconKey;
  final VoidCallback onTap;

  const _ProviderOptionTile({
    required this.label,
    required this.subtitle,
    required this.iconKey,
    required this.onTap,
  });

  IconData _iconForKey(String key) => switch (key) {
        'google_drive' => AppIcons.googleDriveLogo,
        'onedrive' => AppIcons.cloud,
        'dropbox' => AppIcons.cloud,
        'local' => AppIcons.folderOpen,
        _ => AppIcons.cloud,
      };

  // Hues of the providers' brand colors, in the settings icon family.
  Color _colorForKey(String key) => switch (key) {
        'google_drive' => SettingsRowStyle.hue(217),
        'onedrive' => SettingsRowStyle.hue(206),
        'dropbox' => SettingsRowStyle.hue(217),
        'local' => SettingsRowStyle.hue(123),
        _ => AppColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SettingsRow(
        icon: _iconForKey(iconKey),
        iconColor: _colorForKey(iconKey),
        title: label,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

/// A full-width theme button (outlined for the secondary Disconnect).
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final bool outlined;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.loading = false,
    this.outlined = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.ts(context)),
          )
        : Icon(icon, size: 20);
    return outlined
        ? OutlinedButton.icon(
            onPressed: onTap, icon: iconWidget, label: Text(label))
        : FilledButton.icon(
            onPressed: onTap, icon: iconWidget, label: Text(label));
  }
}

// ── Sync Encryption Card ────────────────────────────────────────────────────

class _SyncEncryptionCard extends StatefulWidget {
  @override
  State<_SyncEncryptionCard> createState() => _SyncEncryptionCardState();
}

class _SyncEncryptionCardState extends State<_SyncEncryptionCard> {
  bool _hasPassword = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPassword();
  }

  Future<void> _checkPassword() async {
    var has = false;
    try {
      has = await SyncEncryption.hasPassword();
    } catch (e) {
      debugPrint('[SyncEncryption] Reading password failed: $e');
    }
    if (mounted) setState(() { _hasPassword = has; _loading = false; });
  }

  Future<void> _setPassword() async {
    final ctrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    try {
    final tr = S.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.syncSetPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr.syncPasswordDesc,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr.syncPasswordLabel,
                hintText: tr.syncPasswordHint,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr.syncConfirmPassword,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).commonCancel),
          ),
          FilledButton(
            style: DialogButtons.filled,
            onPressed: () {
              if (ctrl.text.isEmpty) return;
              if (ctrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(S.of(context).syncPasswordsDontMatch),
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }
              Navigator.pop(ctx, ctrl.text);
            },
            child: Text(S.of(context).syncSetPasswordButton),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await SyncEncryption.setPassword(result);
      await _checkPassword();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).syncEncryptionEnabled),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    } catch (e) {
      // Secure storage (Keystore/Keychain) can fail; say so instead of
      // pretending encryption is on.
      debugPrint('[SyncEncryption] Setting password failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).commonSomethingWentWrong),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      disposeAfterRouteAnimation(ctrl);
      disposeAfterRouteAnimation(confirmCtrl);
    }
  }

  Future<void> _removePassword() async {
    final tr = S.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: tr.syncRemoveEncryptionTitle,
      message: tr.syncRemoveEncryptionMsg,
      confirmLabel: tr.commonRemove,
    );

    if (confirmed && mounted) {
      try {
        await SyncEncryption.clearPassword();
      } catch (e) {
        debugPrint('[SyncEncryption] Clearing password failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr.commonSomethingWentWrong),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      await _checkPassword();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr.syncEncryptionRemoved),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return IconHeaderCard(
      icon: _hasPassword ? AppIcons.lock : AppIcons.lockOpen,
      iconColor: _hasPassword ? AppColors.healthy : AppColors.caution,
      title: S.of(context).syncEncryptionTitle,
      description: _hasPassword
          ? S.of(context).syncEncrypted
          : S.of(context).syncNotEncrypted,
      trailing: TextButton(
        onPressed: _hasPassword ? _removePassword : _setPassword,
        child: Text(_hasPassword
            ? S.of(context).commonRemove
            : S.of(context).commonEnable),
      ),
      children: [
        if (!_hasPassword)
          Row(
            children: [
              Icon(AppIcons.warning, size: 14, color: AppColors.caution),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  S.of(context).syncGdriveWarning,
                  style: const TextStyle(
                      fontSize: TypographyTokens.overlineSize,
                      color: AppColors.caution),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
