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

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.code, required this.tr});

  final String code;
  final S tr;

  @override
  Widget build(BuildContext context) {
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
                child: QrImageView(data: code, version: QrVersions.auto, size: 200),
              ),
            ),
            const SizedBox(height: 8),
            Text(tr.syncShareScanHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: TypographyTokens.captionSize,
                    color: AppColors.ts(context))),
            const SizedBox(height: 16),
            SelectableText(
              code,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => SharePlus.instance
                  .share(ShareParams(text: tr.syncShareInviteText(code))),
              icon: const Icon(AppIcons.shareNetwork, size: 20),
              label: Text(tr.syncShareCode),
            ),
          ],
        ),
      ),
    );
  }
}
