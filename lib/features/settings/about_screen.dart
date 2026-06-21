import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/premium_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/app_info.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.aboutTitle)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── App icon ──
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2A3F6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),

            // ── Name + tagline ──
            Text(
              'BudgetSeal',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.appTaglineAbout,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.ts(context),
              ),
            ),
            const SizedBox(height: 8),

            // ── Version + build date ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.sfv(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                appBuildNumber.isEmpty
                    ? 'v$appVersion'
                    : 'v$appVersion ($appBuildNumber)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.th(context),
                ),
              ),
            ),

            const Spacer(flex: 3),

            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.share_rounded,
                    label: l.aboutShare,
                    onTap: () => SharePlus.instance.share(
                      ShareParams(text: l.aboutShareText),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.mail_outline_rounded,
                    label: l.aboutContact,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('fancyshark505@gmail.com'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Legal links ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.push('/privacy'),
                  child: Text(l.aboutPrivacyTerms,
                      style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ),
                Text('·', style: TextStyle(color: AppColors.th(context))),
                TextButton(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'BudgetSeal',
                    applicationVersion: 'v$appVersion',
                    applicationLegalese: l.aboutLegalese(DateTime.now().year),
                  ),
                  child: Text(l.aboutLicenses,
                      style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ),
              ],
            ),
            // ── Redeem code ──
            TextButton(
              onPressed: () => _showRedeemDialog(context, ref),
              child: Text(
                l.upgradeRedeemCode,
                style: TextStyle(fontSize: 12, color: AppColors.accent),
              ),
            ),

            // ── Privacy badge ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined,
                    size: 14, color: AppColors.healthy),
                const SizedBox(width: 6),
                Text(
                  l.aboutPrivacy,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ts(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Credit ──
            Text(
              l.aboutCredit,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.th(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Future<void> _showRedeemDialog(
      BuildContext context, WidgetRef ref) async {
    final l = S.of(context);
    final controller = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbCtx, setDialogState) => AlertDialog(
          title: Text(l.upgradeRedeemCode),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: l.upgradeRedeemHint,
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                final code = controller.text.trim();
                if (code.isEmpty) return;
                if (!isValidRedeemCode(code)) {
                  setDialogState(
                      () => errorText = l.upgradeRedeemInvalid);
                  return;
                }
                await ref
                    .read(hasPremiumProvider.notifier)
                    .redeemCode(code);
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.upgradeRedeemSuccess),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(l.upgradeRedeemButton),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(CardTokens.radius),
          border: Border.all(color: AppColors.bd(context)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.accent),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.tp(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
