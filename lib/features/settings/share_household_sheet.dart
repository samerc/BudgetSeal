import 'package:flutter/material.dart';
import 'package:qr_widget/qr_widget.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/sync/google_drive_provider.dart';
import '../../core/sync/invite_code.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/sheet_title.dart';

/// Opens the "Share household" sheet (Settings and the Sync screen both use
/// it): share the Drive folder with an email, then hand over an invite code.
void showShareHouseholdSheet(
    BuildContext context, GoogleDriveProvider googleDrive) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => ShareHouseholdSheet(googleDrive: googleDrive),
  );
}

class ShareHouseholdSheet extends StatefulWidget {
  final GoogleDriveProvider googleDrive;

  const ShareHouseholdSheet({super.key, required this.googleDrive});

  @override
  State<ShareHouseholdSheet> createState() => _ShareHouseholdSheetState();
}

class _ShareHouseholdSheetState extends State<ShareHouseholdSheet> {
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
      setState(() => _error = S.of(context).syncValidEmailError);
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
      if (!mounted) return;
      setState(() {
        _inviteCode = code;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[ShareHousehold] Failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = S.of(context).shareHouseholdFailed;
      });
    }
  }

  void _shareCode() {
    if (_inviteCode == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: S.of(context).syncShareInviteText(_inviteCode!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(tr.syncShareHousehold,
                  subtitle: tr.syncShareDesc,
                  padding: const EdgeInsetsDirectional.only(bottom: 16)),
              if (_inviteCode == null) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: tr.syncTheirEmail,
                    hintText: tr.syncEmailHint,
                    prefixIcon: const Icon(AppIcons.envelopeSimple),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _share,
                  icon: _loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.onAccent),
                        )
                      : const Icon(AppIcons.shareNetwork, size: 20),
                  label: Text(
                      _loading ? tr.syncSharing : tr.syncGenerateInvite),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.pastel(context, AppColors.accent,
                        light: 0.88, dark: 0.8),
                    borderRadius: CardTokens.borderRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.syncInviteCode,
                        style: TextStyle(
                          fontSize: TypographyTokens.captionSize,
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
                // White in every theme on purpose: scanners need dark
                // modules on a light quiet zone.
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    child: QrImageView(
                      data: _inviteCode!,
                      version: QrVersions.auto,
                      size: 180,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(tr.syncShareScanHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: TypographyTokens.captionSize,
                        color: AppColors.ts(context))),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _shareCode,
                  icon: const Icon(AppIcons.shareNetwork, size: 20),
                  label: Text(tr.syncShareCode),
                ),
              ],
              if (_error != null) ...[
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
      ),
    );
  }
}
