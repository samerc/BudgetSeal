import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_widget/qr_widget.dart';

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
  bool _wifiWarning = false;
  bool _hasWifi = true; // assume yes until checked
  String? _wifiName;

  @override
  void initState() {
    super.initState();
    _checkPin();
    _checkWifiConnectivity();
  }

  Future<void> _checkWifiConnectivity() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      final name = await info.getWifiName();
      if (!mounted) return;

      final connected = ip != null && ip.isNotEmpty && ip != '0.0.0.0';

      // Check if the network name suggests a public network
      final lower = (name ?? '').replaceAll('"', '').toLowerCase();
      final publicKeywords = [
        'guest', 'public', 'free', 'open', 'airport', 'hotel',
        'cafe', 'coffee', 'starbucks', 'mcdonalds', 'restaurant',
        'library', 'hospital', 'mall', 'shop', 'store',
      ];
      final isPublic = connected && (name == null ||
          name.isEmpty ||
          publicKeywords.any((k) => lower.contains(k)));

      setState(() {
        _hasWifi = connected;
        _wifiWarning = isPublic;
        _wifiName = name?.replaceAll('"', '');
      });
    } catch (_) {
      if (mounted) setState(() => _hasWifi = false);
    }
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
    ).then((_) => controller.dispose());
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

          // No WiFi banner — blocks starting
          if (!_hasWifi && !state.isRunning) ...[
            _buildNoWifiBanner(),
            const SizedBox(height: 16),
          ],

          // Network security notice — visible before starting when WiFi is available
          if (_hasWifi && !state.isRunning) ...[
            _buildNetworkNotice(),
            const SizedBox(height: 16),
          ],

          // Public WiFi warning — elevated alert when network looks public
          if (_wifiWarning && state.isRunning) ...[
            _buildWifiWarning(),
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
    final (statusText, statusColor, statusIcon) = !_hasWifi && !state.isRunning
        ? ('No WiFi', AppColors.th(context), Icons.wifi_off_rounded)
        : switch (state.status) {
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
                    onPressed: (!state.isRunning && !_hasWifi)
                        ? null
                        : () => _toggleServer(state),
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

  Widget _buildNoWifiBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3B1111) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off_rounded,
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                  size: 20),
              const SizedBox(width: 8),
              Text(
                'No WiFi Connection',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 30,
                child: TextButton(
                  onPressed: _checkWifiConnectivity,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your phone to a WiFi network to use Web Companion. The server needs WiFi to let your laptop access the budget.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark
                  ? const Color(0xFFFCA5A5).withValues(alpha: 0.8)
                  : const Color(0xFFDC2626).withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkNotice() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPublic = _wifiWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPublic
            ? const Color(0xFFFEF3C7)
            : isDark
                ? const Color(0xFF172554)
                : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(
          color: isPublic
              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
              : isDark
                  ? const Color(0xFF1E40AF).withValues(alpha: 0.4)
                  : const Color(0xFF93C5FD).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPublic ? Icons.warning_amber_rounded : Icons.shield_outlined,
                color: isPublic ? const Color(0xFF92400E) : const Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isPublic ? 'Public Network Detected' : 'Network Security',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isPublic
                      ? const Color(0xFF92400E)
                      : isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPublic
                ? 'You appear to be on a public network${_wifiName != null && _wifiName!.isNotEmpty ? ' ("$_wifiName")' : ''}. '
                  'Do not start the server — your data will be transmitted unencrypted and could be intercepted by others on the same network.'
                : 'Web Companion uses HTTP (unencrypted). Only use it on your private home or office WiFi. '
                  'Never start the server on public networks (hotels, airports, cafes) — anyone on the same network could see your data.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isPublic
                  ? const Color(0xFF92400E)
                  : isDark
                      ? const Color(0xFF93C5FD).withValues(alpha: 0.8)
                      : const Color(0xFF1E40AF).withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              color: Color(0xFF92400E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security Warning',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 4),
                Text(
                  _wifiName != null && _wifiName!.isNotEmpty
                      ? 'Network "$_wifiName" may be public. Traffic is unencrypted — avoid using Web Companion on public WiFi, as others on the same network could intercept your data.'
                      : 'Could not detect your WiFi network name. If you\'re on a public network, avoid using Web Companion — traffic is unencrypted and could be intercepted.',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF92400E),
                      height: 1.4),
                ),
              ],
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
          const SizedBox(height: 10),
          _infoRow(Icons.lock_outline_rounded,
              'Use only on trusted private networks — traffic is not encrypted'),
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
