import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/app_info.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_icon_hero.dart';
import '../premium/redeem_dialog.dart';

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

            // ── App icon, name + tagline (same hero as Upgrade) ──
            AppIconHero(title: l.appName, subtitle: l.appTaglineAbout),
            const SizedBox(height: Spacing.sm),

            // ── Version + build date ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.sfv(context),
                borderRadius: BorderRadius.circular(RadiusTokens.sm),
              ),
              child: Text(
                appBuildNumber.isEmpty
                    ? 'v$appVersion'
                    : 'v$appVersion ($appBuildNumber)',
                style: TextStyle(
                  fontSize: TypographyTokens.captionSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ts(context),
                ),
              ),
            ),

            const Spacer(flex: 3),

            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: AppIcons.shareNetwork,
                    label: l.aboutShare,
                    onTap: () => SharePlus.instance.share(
                      ShareParams(text: l.aboutShareText),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: AppIcons.envelopeSimple,
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
                      style: const TextStyle(
                          fontSize: TypographyTokens.captionSize)),
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
                      style: const TextStyle(
                          fontSize: TypographyTokens.captionSize)),
                ),
              ],
            ),
            // ── Redeem code ──
            TextButton(
              onPressed: () => showRedeemDialog(context, ref),
              child: Text(
                l.upgradeRedeemCode,
                style: const TextStyle(fontSize: TypographyTokens.captionSize),
              ),
            ),

            // ── Privacy badge ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.shieldCheck,
                    size: 14, color: AppColors.healthy),
                const SizedBox(width: 6),
                // Wraps on narrow phones instead of overflowing.
                Flexible(
                  child: Text(
                    l.aboutPrivacy,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.ts(context),
                    ),
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
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(
        width: double.infinity,
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
