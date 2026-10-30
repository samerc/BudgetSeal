import 'package:flutter/material.dart';
import 'package:qr_widget/qr_widget.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/sync/household_key.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/sheet_title.dart';

/// The household's invite: its key as a QR (scanned in Join a household)
/// and as text to send. Whoever has it can open the budget.
Future<void> showHouseholdInviteSheet(BuildContext context, HouseholdKey key) {
  final tr = S.of(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _InviteSheet(code: key.code, tr: tr),
  );
}

/// The QR first (scanning needs no typing); the long code only on request —
/// it is the household's key, which is why it's long.
class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.code, required this.tr});

  final String code;
  final S tr;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  bool _showCode = false;

  @override
  Widget build(BuildContext context) {
    final tr = widget.tr;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(tr.householdInviteTitle,
                subtitle: tr.householdInviteBody,
                padding: const EdgeInsetsDirectional.only(bottom: 16)),
            // White in every theme on purpose: scanners need dark modules
            // on a light quiet zone.
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                ),
                child: QrImageView(
                    data: widget.code, version: QrVersions.auto, size: 220),
              ),
            ),
            const SizedBox(height: 10),
            Text(tr.syncShareScanHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tp(context))),
            const SizedBox(height: 24),
            Text(tr.inviteCantScan,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: TypographyTokens.captionSize,
                    color: AppColors.ts(context))),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => SharePlus.instance
                  .share(ShareParams(text: tr.syncShareInviteText(widget.code))),
              icon: const Icon(AppIcons.shareNetwork, size: 20),
              label: Text(tr.syncShareCode),
            ),
            if (_showCode) ...[
              const SizedBox(height: 12),
              SelectableText(
                widget.code,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: AppColors.tp(context),
                ),
              ),
            ] else
              TextButton(
                onPressed: () => setState(() => _showCode = true),
                child: Text(tr.inviteShowCode),
              ),
          ],
        ),
      ),
    );
  }
}
