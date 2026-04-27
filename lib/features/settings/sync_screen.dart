import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/sync_provider.dart';
import '../../core/sync/cloud_provider.dart';
import '../../core/sync/google_drive_provider.dart';
import '../../core/sync/invite_code.dart';
import '../../core/sync/sync_encryption.dart';
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
            if (syncState.activeProvider is GoogleDriveProvider)
              _ActionButton(
                icon: Icons.people_outline_rounded,
                label: 'Share Household',
                color: const Color(0xFF7E57C2),
                onTap: () => _showShareSheet(context, notifier),
              ),
            if (syncState.activeProvider is GoogleDriveProvider)
              const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.link_off_rounded,
              label: 'Disconnect',
              color: AppColors.overspent,
              onTap: () => _confirmDisconnect(context, notifier),
            ),
            const SizedBox(height: 16),
            // ── Sync Encryption ──
            _SyncEncryptionCard(),
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

  void _showShareSheet(BuildContext context, SyncNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShareHouseholdSheet(
        googleDrive: notifier.googleDrive,
      ),
    );
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

// ── Share Household Sheet ────────────────────────────────────────────────────

class _ShareHouseholdSheet extends StatefulWidget {
  final GoogleDriveProvider googleDrive;

  const _ShareHouseholdSheet({required this.googleDrive});

  @override
  State<_ShareHouseholdSheet> createState() => _ShareHouseholdSheetState();
}

class _ShareHouseholdSheetState extends State<_ShareHouseholdSheet> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _inviteCode;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.googleDrive.shareFolder(email);
      final folderId = await widget.googleDrive.getFolderId();
      final code = generateInviteCode(folderId);
      setState(() {
        _inviteCode = code;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to share: ${e.toString()}';
      });
    }
  }

  void _shareCode() {
    if (_inviteCode == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: 'Join my PocketPlan household! Enter this code in the app:\n$_inviteCode',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.th(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share Household',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your PocketPlan data with another person. '
              'They will be able to sync to the same file on Google Drive.',
              style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
            ),
            const SizedBox(height: 20),
            if (_inviteCode == null) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Their email address',
                  hintText: 'partner@gmail.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _share,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    _loading ? 'Sharing...' : 'Generate Invite Code',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7E57C2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite Code',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ts(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _inviteCode!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: AppColors.tp(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _shareCode,
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text(
                    'Share Code',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
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
                        _error!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.overspent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
    final has = await SyncEncryption.hasPassword();
    if (mounted) setState(() { _hasPassword = has; _loading = false; });
  }

  Future<void> _setPassword() async {
    final ctrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Sync Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This password encrypts your sync file on Google Drive. '
              'You\'ll need the same password on any other device that syncs '
              'with this household.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter a strong password',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isEmpty) return;
              if (ctrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Passwords don\'t match'),
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }
              Navigator.pop(ctx, ctrl.text);
            },
            child: const Text('Set Password'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await SyncEncryption.setPassword(result);
      await _checkPassword();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sync encryption enabled. Next sync will be encrypted.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _removePassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Encryption?'),
        content: const Text(
          'Future sync files will be unencrypted. '
          'Other devices will need to remove their password too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.overspent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await SyncEncryption.clearPassword();
      await _checkPassword();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sync encryption removed'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasPassword ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 18,
                color: _hasPassword ? AppColors.healthy : AppColors.caution,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sync Encryption',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context))),
                    Text(
                      _hasPassword
                          ? 'Your sync file is encrypted with AES-256'
                          : 'Sync file is not encrypted',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.ts(context)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _hasPassword ? _removePassword : _setPassword,
                child: Text(_hasPassword ? 'Change' : 'Enable'),
              ),
            ],
          ),
          if (!_hasPassword) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.caution),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Anyone with access to your Google Drive can read your financial data',
                    style: TextStyle(fontSize: 11, color: AppColors.caution),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
