import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/sync_provider.dart';
import '../../core/sync/cloud_provider.dart';
import '../../core/sync/google_drive_provider.dart';
import '../../shared/theme/app_colors.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final notifier = ref.read(syncProvider.notifier);
    final isConnected = syncState.activeProvider != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Sync')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // ── Status card ────────────────────────────────────────
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
                    _statusIcon(syncState.status, isConnected),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected
                                ? syncState.activeProvider!.displayName
                                : 'Not connected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tp(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _statusSubtitle(syncState),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.ts(context),
                            ),
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
                      color: AppColors.overspent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.overspent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            syncState.lastError!,
                            style: const TextStyle(
                              fontSize: 12,
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
          const SizedBox(height: 24),

          // ── Connected actions ──────────────────────────────────
          if (isConnected) ...[
            _ActionButton(
              icon: Icons.sync_rounded,
              label: 'Sync Now',
              color: AppColors.accent,
              loading: syncState.status == SyncStatus.syncing,
              onTap: syncState.status == SyncStatus.syncing
                  ? null
                  : () => notifier.sync(),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.link_off_rounded,
              label: 'Disconnect',
              color: AppColors.overspent,
              onTap: () => _confirmDisconnect(context, notifier),
            ),
            const SizedBox(height: 24),
          ],

          // ── Provider list ─────────────────────────────────────
          if (!isConnected) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'CONNECT A PROVIDER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.ts(context),
                ),
              ),
            ),
            ...notifier.providerOptions.map((option) {
              final isOneDriveOrDropbox =
                  option.iconKey == 'onedrive' || option.iconKey == 'dropbox';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                        padding: const EdgeInsets.fromLTRB(56, 4, 8, 0),
                        child: Text(
                          'Receipt sync coming soon for this provider',
                          style: TextStyle(
                            fontSize: 11,
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
                'OneDrive and Dropbox open the system file picker, which can '
                'access those services when their apps are installed on your device. '
                'Google Drive requires a Google Cloud project with OAuth configured.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ts(context),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusIcon(SyncStatus status, bool connected) {
    if (status == SyncStatus.syncing) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.accent,
          ),
        ),
      );
    }

    final (IconData icon, Color color) = switch (status) {
      SyncStatus.success => (Icons.check_circle_rounded, AppColors.healthy),
      SyncStatus.error => (Icons.error_rounded, AppColors.overspent),
      _ => connected
          ? (Icons.cloud_done_rounded, AppColors.accent)
          : (Icons.cloud_off_rounded, AppColors.textSecondary),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _statusSubtitle(SyncState state) {
    if (state.status == SyncStatus.syncing) return 'Syncing...';
    if (state.status == SyncStatus.error) return 'Last sync failed';
    if (state.lastSyncTime != null) {
      final formatted = DateFormat.yMMMd().add_jm().format(state.lastSyncTime!);
      return 'Last synced $formatted';
    }
    if (state.activeProvider != null) return 'Not yet synced';
    return 'Connect a cloud provider to sync your data';
  }

  Future<void> _connect(
      BuildContext context, WidgetRef ref, CloudProvider provider) async {
    final ok =
        await ref.read(syncProvider.notifier).connectProvider(provider);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${provider.displayName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!ok && context.mounted) {
      String errorMsg = 'Failed to connect';
      if (provider is GoogleDriveProvider && provider.lastConnectError != null) {
        errorMsg = provider.lastConnectError!;
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Connection Failed'),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmDisconnect(
      BuildContext context, SyncNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text(
          'Your data will remain on your device, but automatic '
          'sync will stop. You can reconnect at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.disconnectProvider();
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
        'google_drive' => Icons.add_to_drive_rounded,
        'onedrive' => Icons.cloud_rounded,
        'dropbox' => Icons.cloud_circle_rounded,
        'local' => Icons.folder_open_rounded,
        _ => Icons.cloud_outlined,
      };

  Color _colorForKey(String key) => switch (key) {
        'google_drive' => const Color(0xFF4285F4),
        'onedrive' => const Color(0xFF0078D4),
        'dropbox' => const Color(0xFF0061FF),
        'local' => const Color(0xFF66BB6A),
        _ => AppColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    final icon = _iconForKey(iconKey);
    final color = _colorForKey(iconKey);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.ts(context))),
        trailing: Icon(Icons.chevron_right_rounded,
            size: 18, color: AppColors.th(context)),
        onTap: onTap,
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
