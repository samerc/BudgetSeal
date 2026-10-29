import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/sync/invite_code.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/empty_state.dart';

/// Scans the QR of a household invite (`/scan-invite`); pops the code.
/// Other QR codes are ignored.
class ScanInviteScreen extends StatefulWidget {
  const ScanInviteScreen({super.key});

  @override
  State<ScanInviteScreen> createState() => _ScanInviteScreenState();
}

class _ScanInviteScreenState extends State<ScanInviteScreen> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final value = b.rawValue?.trim();
      if (value != null && decodeInviteCode(value) != null) {
        _done = true;
        context.pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.joinScanTitle)),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, _) => EmptyState(
                icon: AppIcons.camera,
                title: s.joinScanNoCamera,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              s.joinScanHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ts(context), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
