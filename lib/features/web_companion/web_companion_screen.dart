import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_widget/qr_widget.dart';

import '../../core/providers/web_companion_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import 'web_companion_auth.dart';
import 'web_companion_service.dart';
import '../../shared/utils/dispose_later.dart';

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

  // Browsers: sessions with the page open now, and all signed-in sessions.
  int _connected = 0;
  int _sessions = 0;
  Timer? _browserTimer;

  @override
  void initState() {
    super.initState();
    _checkPin();
    _checkWifiConnectivity();
    _browserTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _refreshBrowsers());
  }

  @override
  void dispose() {
    _browserTimer?.cancel();
    super.dispose();
  }

  void _refreshBrowsers() {
    final service = ref.read(webCompanionServiceProvider);
    final connected = service.isRunning ? service.auth.connectedCount() : 0;
    final sessions = service.isRunning ? service.auth.activeSessionCount : 0;
    if (mounted && (connected != _connected || sessions != _sessions)) {
      setState(() {
        _connected = connected;
        _sessions = sessions;
      });
    }
  }

  void _signOutAll() {
    ref.read(webCompanionServiceProvider).signOutAllBrowsers();
    _refreshBrowsers();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(S.of(context).wcSignedOutAll),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _checkWifiConnectivity() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      final name = await info.getWifiName();
      if (!mounted) return;

      // NetworkInfo().getWifiIP() queries the WiFi interface specifically.
      // It returns null when WiFi is off — no need for BSSID/name checks.
      final connected = ip != null && ip.isNotEmpty && ip != '0.0.0.0';

      // Android hides the network name without location permission (null
      // or "<unknown ssid>"): an unknown name is not evidence of a public
      // network. Keywords are specific — "free"/"open" would flag home
      // routers like "Freebox".
      final cleaned = name?.replaceAll('"', '').trim();
      final known = cleaned != null &&
          cleaned.isNotEmpty &&
          cleaned.toLowerCase() != '<unknown ssid>';
      final lower = known ? cleaned.toLowerCase() : '';
      const publicKeywords = [
        'guest', 'public', 'airport', 'hotel', 'cafe', 'coffee',
        'starbucks', 'mcdonalds', 'restaurant', 'library', 'hospital',
        'free wifi', 'free_wifi', 'freewifi',
      ];
      final isPublic =
          connected && known && publicKeywords.any((k) => lower.contains(k));

      setState(() {
        _hasWifi = connected;
        _wifiWarning = isPublic;
        _wifiName = known ? cleaned : null;
      });
    } catch (_) {
      if (mounted) setState(() => _hasWifi = false);
    }
  }

  Future<void> _checkPin() async {
    // Secure storage can throw (e.g. Keystore reset after a backup restore):
    // treat that as "no PIN" so the user can set a new one.
    bool has;
    try {
      has = await WebCompanionAuth.hasPin();
    } catch (e) {
      debugPrint('[WebCompanion] Reading PIN failed: $e');
      has = false;
    }
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
    // Re-check WiFi right before starting (state may have changed since screen opened)
    await _checkWifiConnectivity();
    if (!_hasWifi) return;

    if (Platform.isAndroid) {
      // Request POST_NOTIFICATIONS on Android 13+ before starting
      final result = await FlutterForegroundTask.requestNotificationPermission();
      if (result != NotificationPermission.granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).wcNotifPermission),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    await service.start();
  }

  // ── PIN management ──────────────────────────────────────────────────────────

  void _showSetPinSheet({VoidCallback? onSuccess}) {
    _showPinInputSheet(
      title: S.of(context).wcSetPinTitle,
      subtitle: S.of(context).wcSetPinSubtitle,
      confirmLabel: S.of(context).wcSetPin,
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
      title: S.of(context).wcChangePinTitle,
      subtitle: S.of(context).wcChangePinSubtitle,
      confirmLabel: S.of(context).wcUpdatePin,
      onConfirm: (pin) async {
        await WebCompanionAuth.setPin(pin);
        // Revoke existing sessions since PIN changed
        ref.read(webCompanionServiceProvider).signOutAllBrowsers();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).wcPinUpdated), behavior: SnackBarBehavior.floating),
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
    // Guards against a double tap saving twice (and popping twice).
    var busy = false;

    final tr = S.of(context);
    final pinSurface = AppColors.sf(context);
    final pinTextPrimary = AppColors.tp(context);
    final pinTextSecondary = AppColors.ts(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: pinSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: TypographyTokens.cardTitleSize,
                          fontWeight: FontWeight.w700,
                          color: pinTextPrimary)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 14,
                          color: pinTextSecondary)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: tr.wc4DigitPin,
                      hintStyle: const TextStyle(
                          fontSize: 15, letterSpacing: 0, fontWeight: FontWeight.w400),
                      errorText: error,
                      counterText: '',
                    ),
                    onChanged: (_) {
                      if (error != null) setModalState(() => error = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy
                          ? null
                          : () async {
                              final pin = controller.text.trim();
                              if (pin.length != 4) {
                                setModalState(
                                    () => error = tr.wcEnter4DigitsError);
                                return;
                              }
                              setModalState(() => busy = true);
                              try {
                                await onConfirm(pin);
                              } catch (e) {
                                debugPrint('[WebCompanion] Saving PIN failed: $e');
                                if (ctx.mounted) {
                                  setModalState(() {
                                    busy = false;
                                    error = tr.commonSomethingWentWrong;
                                  });
                                }
                              }
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
    ).then((_) => disposeAfterRouteAnimation(controller));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webCompanionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).wcTitle)),
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
            _buildBrowsersCard(),
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
    final tr = S.of(context);
    final (statusText, statusColor, statusIcon) = !_hasWifi && !state.isRunning
        ? (tr.wcNoWifi, AppColors.th(context), Icons.wifi_off_rounded)
        : switch (state.status) {
            WebServerStatus.stopped => (tr.wcStopped, AppColors.ts(context), Icons.stop_circle_rounded),
            WebServerStatus.starting => (tr.wcStarting, AppColors.accent, Icons.hourglass_top_rounded),
            WebServerStatus.running => (tr.wcRunning, AppColors.healthy, Icons.check_circle_rounded),
            WebServerStatus.error => (tr.wcError, AppColors.overspent, Icons.error_outline_rounded),
          };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        boxShadow: AppColors.cardShadow(context),
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
                            fontSize: 13, color: AppColors.overspent),
                      ),
                    ] else if (state.isRunning && state.startedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        tr.wcAutoStop,
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
                    child: Text(state.isRunning ? tr.wcStopButton : tr.wcStartButton),
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
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).wcOpenOnLaptop,
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
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                  ),
                  child: Text(
                    url,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentText(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context).wcUrlCopied), behavior: SnackBarBehavior.floating),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                tooltip: S.of(context).wcCopyUrl,
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
                  color: AppColors.accentText(context),
                ),
                const SizedBox(width: 6),
                Text(
                  _showQr ? S.of(context).wcHideQr : S.of(context).wcShowQr,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.accentText(context),
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

  /// How many browsers have the page open, and a way to sign them all out.
  Widget _buildBrowsersCard() {
    final tr = S.of(context);
    final live = _connected > 0;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppColors.accentLight, shape: BoxShape.circle),
                child: Icon(Icons.laptop_mac_rounded,
                    size: 22, color: AppColors.accentText(context)),
              ),
              if (live)
                PositionedDirectional(
                  end: -1,
                  bottom: -1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.healthy,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.sf(context), width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr.wcBrowsersConnected(_connected),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(context))),
                const SizedBox(height: 2),
                Text(tr.wcBrowsersHint,
                    style:
                        TextStyle(fontSize: 13, color: AppColors.ts(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _sessions == 0 ? null : _signOutAll,
            style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
            child: Text(tr.wcSignOutAll),
          ),
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
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).wcSecurityTitle,
            style: TextStyle(
                fontSize: TypographyTokens.cardTitleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context)),
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context).wcPinRequired,
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
                    ? AppColors.healthy
                    : AppColors.caution,
              ),
              const SizedBox(width: 8),
              Text(
                _hasPinSet ? S.of(context).wcPinIsSet : S.of(context).wcNoPin,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _hasPinSet
                      ? AppColors.healthy
                      : AppColors.caution,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _hasPinSet
                    ? _showChangePinSheet
                    : () => _showSetPinSheet(),
                child: Text(_hasPinSet ? S.of(context).wcChangePin : S.of(context).wcSetPin),
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
        color: AppColors.pastel(context, AppColors.caution, light: 0.85, dark: 0.75),
        borderRadius: BorderRadius.circular(CardTokens.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.caution, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).wcIosWarning,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.tp(context),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWifiBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pastel(context, AppColors.overspent, light: 0.88, dark: 0.75),
        borderRadius: BorderRadius.circular(CardTokens.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off_rounded,
                  color: AppColors.overspent,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                S.of(context).wcNoWifiTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.overspent,
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
                    S.of(context).commonRetry,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.overspent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).wcNoWifiDesc,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.tp(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkNotice() {
    final isPublic = _wifiWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPublic
            ? AppColors.pastel(context, AppColors.caution, light: 0.85, dark: 0.75)
            : AppColors.accentLight,
        borderRadius: BorderRadius.circular(CardTokens.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPublic ? Icons.warning_amber_rounded : Icons.shield_rounded,
                color: isPublic ? AppColors.caution : AppColors.accentText(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isPublic ? S.of(context).wcPublicNetwork : S.of(context).wcNetworkSecurity,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isPublic
                      ? AppColors.tp(context)
                      : AppColors.accentText(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPublic
                ? (_wifiName != null && _wifiName!.isNotEmpty
                    ? S.of(context).wcPublicNetworkDescNamed(_wifiName!)
                    : S.of(context).wcPublicNetworkDescUnnamed)
                : S.of(context).wcNetworkSecurityDesc,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isPublic
                  ? AppColors.tp(context)
                  : AppColors.tp(context),
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
        color: AppColors.pastel(context, AppColors.caution, light: 0.85, dark: 0.75),
        borderRadius: BorderRadius.circular(CardTokens.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded,
              color: AppColors.caution, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).wcSecurityWarning,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  _wifiName != null && _wifiName!.isNotEmpty
                      ? S.of(context).wcSecurityWarningNamed(_wifiName!)
                      : S.of(context).wcSecurityWarningUnnamed,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.tp(context),
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
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.wifi_rounded,
              S.of(context).wcInfo1),
          const SizedBox(height: 10),
          _infoRow(Icons.timer_rounded,
              S.of(context).wcInfo2),
          const SizedBox(height: 10),
          _infoRow(Icons.security_rounded,
              S.of(context).wcInfo3),
          const SizedBox(height: 10),
          _infoRow(Icons.lock_outline_rounded,
              S.of(context).wcInfo4),
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
