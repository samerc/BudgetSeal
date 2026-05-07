import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/app_info.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
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
              'PocketPlan',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.tp(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Envelope budgeting, simplified.',
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
                'v$appVersion · $appBuildTimestamp',
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
                    label: 'Share',
                    onTap: () => SharePlus.instance.share(
                      ShareParams(
                          text:
                              'Check out PocketPlan — envelope budgeting made simple!'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.mail_outline_rounded,
                    label: 'Contact',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('samer@pocketplan.app'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Privacy ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined,
                    size: 14, color: AppColors.healthy),
                const SizedBox(width: 6),
                Text(
                  'No tracking. Your data stays on your device.',
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
              'Made by Samer',
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
