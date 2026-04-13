import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/utils/app_info.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // ── App icon ──────────────────────────────────────────
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

            // ── Title & version ───────────────────────────────────
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
              'v$appVersion',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ts(context),
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────────
            Text(
              'Envelope budgeting app.\nGive every dollar a purpose.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppColors.ts(context),
              ),
            ),
            const SizedBox(height: 28),

            // ── Flutter badge ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.sfv(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FlutterLogo(size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Made with Flutter',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ts(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Privacy statement ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bd(context)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 28,
                    color: AppColors.healthy,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No tracking. No analytics.\nYour data stays on your device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.ts(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Credit ────────────────────────────────────────────
            Text(
              'Built by Samer',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.th(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Open source',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.th(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
