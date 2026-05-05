import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers/web_companion_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import 'web_companion_auth.dart';
import 'web_companion_service.dart';

class WebCompanionScreen extends ConsumerStatefulWidget {
  const WebCompanionScreen({super.key});

  @override
  ConsumerState<WebCompanionScreen> createState() => _WebCompanionScreenState();
}

class _WebCompanionScreenState extends ConsumerState<WebCompanionScreen> {
  bool _showQr = false;
  bool _hasPinSet = false;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final has = await WebCompanionAuth.hasPin();
    if (mounted) setState(() => _hasPinSet = has);
  }

  Future<void> _toggleServer(WebCompanionState state) async {
    final service = ref.read(webCompanionServiceProvider);

    if (state.isRunning) {
      await service.stop();
      if (mounted) setState(() => _showQr = false);
      return;
    }

    if (!_hasPinSet) {
      _showSetPinSheet(onSuccess: () async {
        await _checkPin();
        await _doStart(service);
      });
      return;
    }

    await _doStart(service);
  }

  Future<void> _doStart(WebCompanionService service) async {
    if (Platform.isAndroid) {
      // Request POST_NOTIFICATIONS on Android 13+ before starting
      final result = await FlutterForegroundTask.requestNotificationPermission();
      if (result != NotificationPermission.granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is needed to keep the server running in the background.'),
          ),
        );
      }
    }
    await service.start();
  }

  // ── PIN management ──────────────────────────────────────────────────────────

  void _showSetPinSheet({VoidCallback? onSuccess}) {
    _showPinInputSheet(
      title: 'Set Web PIN',
      subtitle: 'This PIN protects your budget data. Anyone on the same WiFi will need it to access the web interface.',
      confirmLabel: 'Set PIN',
      onConfirm: (pin) async {
        await WebCompanionAuth.setPin(pin);
        if (mounted) {
          setState(() => _hasPinSet = true);
          Navigator.of(context).pop();
          onSuccess?.call();
        }
      },
    );
  }

  void _showChangePinSheet() {
    _showPinInputSheet(
      title: 'Change PIN',
      subtitle: 'Enter a new 4-digit PIN for your web interface.',
      confirmLabel: 'Update PIN',
      onConfirm: (pin) async {
        await WebCompanionAuth.setPin(pin);
        // Revoke existing sessions since PIN changed
        ref.read(webCompanionServiceProvider).auth.revokeAllSessions();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN updated. All active sessions signed out.')),
          );
        }
      },
    );
  }

  void _showPinInputSheet({
    required String title,
    required String subtitle,
    required String confirmLabel,
    required Future<void> Function(String pin) onConfirm,
  }) {
    final controller = TextEditingController();
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: TypographyTokens.cardTitleSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tp(context))),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.ts(context))),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: '4-digit PIN',
                      errorText: error,
                      counterText: '',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(CardTokens.radius)),
                    ),
                    onChanged: (_) {
                      if (error != null) setModalState(() => error = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final pin = controller.text.trim();
                        if (pin.length != 4) {
                          setModalState(() => error = 'Enter exactly 4 digits');
                          return;
                        }
                        await onConfirm(pin);
                      },
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webCompanionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Web Companion')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // iOS warning banner
          if (Platform.isIOS) ...[
            _buildIosWarning(),
            const SizedBox(height: 16),
          ],

          // Status card
          _buildStatusCard(state),
          const SizedBox(height: 16),

          // Connection info (shown when running)
          if (state.isRunning) ...[
            _buildConnectionCard(state),
            const SizedBox(height: 16),
          ],

          // PIN management
          _buildPinSection(),
          const SizedBox(height: 16),

          // Info card
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(WebCompanionState state) {
    final (statusText, statusColor, statusIcon) = switch (state.status) {
      WebServerStatus.stopped => ('Server stopped', AppColors.ts(context), Icons.stop_circle_outlined),
      WebServerStatus.starting => ('Starting...', const Color(0xFF0EA5E9), Icons.hourglass_top_rounded),
      WebServerStatus.running => ('Server running', const Color(0xFF059669), Icons.check_circle_rounded),
      WebServerStatus.error => ('Error', const Color(0xFFDC2626), Icons.error_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tp(context),
                      ),
                    ),
                    if (state.status == WebServerStatus.error &&
                        state.errorMessage != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        state.errorMessage!,
                        style: TextStyle(
                            fontSize: 13, color: const Color(0xFFDC2626)),
                      ),
                    ] else if (state.isRunning && state.startedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Stops automatically after 6 hours',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.ts(context)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: state.isStarting
                ? const LinearProgressIndicator()
                : FilledButton(
                    onPressed: () => _toggleServer(state),
                    style: state.isRunning
                        ? FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error)
                        : null,
                    child: Text(state.isRunning ? 'Stop Server' : 'Start Server'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(WebCompanionState state) {
    final url = state.url ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Open on your laptop',
            style: TextStyle(
                fontSize: TypographyTokens.cardTitleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context)),
          ),
          const SizedBox(height: 12),
          // URL row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2563EB).withValues(alpha: 0.4)
                          : const Color(0xFF93C5FD),
                    ),
                  ),
                  child: Text(
                    url,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Copy URL',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // QR code toggle
          GestureDetector(
            onTap: () => setState(() => _showQr = !_showQr),
            child: Row(
              children: [
                Icon(
                  _showQr
                      ? Icons.qr_code_2_rounded
                      : Icons.qr_code_rounded,
                  size: 18,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                Text(
                  _showQr ? 'Hide QR code' : 'Show QR code',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (_showQr) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security',
            style: TextStyle(
                fontSize: TypographyTokens.cardTitleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'A PIN is required to access the web interface.',
            style: TextStyle(fontSize: 14, color: AppColors.ts(context)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _hasPinSet
                    ? Icons.lock_rounded
                    : Icons.lock_open_rounded,
                size: 18,
                color: _hasPinSet
                    ? const Color(0xFF059669)
                    : const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Text(
                _hasPinSet ? 'PIN is set' : 'No PIN set',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _hasPinSet
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _hasPinSet
                    ? _showChangePinSheet
                    : () => _showSetPinSheet(),
                child: Text(_hasPinSet ? 'Change PIN' : 'Set PIN'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIosWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Keep PocketPlan in the foreground while the server is running. iOS does not support background servers — locking your screen will stop it.',
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF92400E),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
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
          _infoRow(Icons.wifi_rounded,
              'Only accessible on the same WiFi network'),
          const SizedBox(height: 10),
          _infoRow(Icons.timer_outlined,
              'Server stops automatically after 6 hours'),
          const SizedBox(height: 10),
          _infoRow(Icons.security_rounded,
              '5 failed PIN attempts locks the interface for 30 minutes'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.ts(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
        ),
      ],
    );
  }
}
