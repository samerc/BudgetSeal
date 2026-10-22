import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/premium_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_icon_hero.dart';
import 'redeem_dialog.dart';

class UpgradeScreen extends ConsumerWidget {
  final String? featureName;

  const UpgradeScreen({super.key, this.featureName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = S.of(context);

    final features = <_FeatureItem>[
      _FeatureItem(AppIcons.arrowsClockwise, l.upgradeFeatureSync),
      _FeatureItem(AppIcons.laptop, l.upgradeFeatureWebCompanion),
      _FeatureItem(AppIcons.receipt, l.upgradeFeatureBillSplitter),
      _FeatureItem(AppIcons.airplane, l.upgradeFeatureTravelExchange),
      _FeatureItem(AppIcons.calendarDots, l.upgradeFeaturePlannedPayments),
      _FeatureItem(
          AppIcons.infinity, l.upgradeFeatureUnlimitedItems),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.x),
          onPressed: () => context.pop(),
        ),
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Spacing.xl),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

              // ── App icon, title + subtitle (same hero as About) ──
              AppIconHero(title: l.upgradeTitle, subtitle: l.upgradeSubtitle),
              const SizedBox(height: Spacing.xxl),

              // ── Feature list ──
              AppCard(
                child: Column(
                  children: [
                    for (int i = 0; i < features.length; i++) ...[
                      if (i > 0) const SizedBox(height: Spacing.md),
                      _buildFeatureRow(context, features[i]),
                    ],
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // ── Price ──
              Text(
                l.upgradePrice,
                style: TextStyle(
                  fontSize: TypographyTokens.amountLargeSize,
                  fontWeight: TypographyTokens.amountLargeWeight,
                  color: AppColors.tp(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.upgradePriceSubtitle,
                style: TextStyle(
                  fontSize: TypographyTokens.captionSize,
                  color: AppColors.ts(context),
                ),
              ),
              const SizedBox(height: Spacing.xl),

              // ── Upgrade button ──
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.upgradeComingSoon),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(l.upgradeButton),
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // ── Redeem code + Restore ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => showRedeemDialog(context, ref,
                        onRedeemed: () {
                      if (context.mounted) context.pop();
                    }),
                    child: Text(
                      l.upgradeRedeemCode,
                      style: const TextStyle(
                          fontSize: TypographyTokens.captionSize),
                    ),
                  ),
                  Text('·',
                      style: TextStyle(color: AppColors.th(context))),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(hasPremiumProvider.notifier)
                          .restorePurchases();
                      if (!context.mounted) return;
                      final hasPremium = ref.read(hasPremiumProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(hasPremium
                              ? l.upgradeRestoreSuccess
                              : l.upgradeRestoreNone),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      if (hasPremium) context.pop();
                    },
                    child: Text(
                      l.upgradeRestorePurchase,
                      style: const TextStyle(
                          fontSize: TypographyTokens.captionSize),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
            ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, _FeatureItem item) {
    return Row(
      children: [
        Icon(item.icon, size: 20, color: AppColors.accent),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: AppColors.tp(context),
            ),
          ),
        ),
        Icon(AppIcons.check, size: 18, color: AppColors.healthy),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  const _FeatureItem(this.icon, this.label);
}
