import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/premium_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/dispose_later.dart';

class UpgradeScreen extends ConsumerWidget {
  final String? featureName;

  const UpgradeScreen({super.key, this.featureName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = S.of(context);

    final features = <_FeatureItem>[
      _FeatureItem(Icons.sync_rounded, l.upgradeFeatureSync),
      _FeatureItem(Icons.laptop_rounded, l.upgradeFeatureWebCompanion),
      _FeatureItem(Icons.receipt_long_rounded, l.upgradeFeatureBillSplitter),
      _FeatureItem(Icons.flight_rounded, l.upgradeFeatureTravelExchange),
      _FeatureItem(Icons.event_note_rounded, l.upgradeFeaturePlannedPayments),
      _FeatureItem(
          Icons.all_inclusive_rounded, l.upgradeFeatureUnlimitedItems),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const SizedBox.shrink(),
        elevation: 0,
        backgroundColor: Colors.transparent,
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

              // ── App icon ──
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset('assets/icon/app_icon.png',
                    width: 84, height: 84),
              ),
              const SizedBox(height: Spacing.xl),

              // ── Title ──
              Text(
                l.upgradeTitle,
                style: TextStyle(
                  fontSize: TypographyTokens.screenTitleSize,
                  fontFamily: TypographyTokens.displayFamily,
                  fontWeight: TypographyTokens.screenTitleWeight,
                  color: AppColors.tp(context),
                ),
              ),
              const SizedBox(height: Spacing.sm),

              // ── Subtitle ──
              Text(
                l.upgradeSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: AppColors.ts(context),
                ),
              ),
              const SizedBox(height: Spacing.xxl),

              // ── Feature list ──
              Container(
                padding: CardTokens.padding,
                decoration: BoxDecoration(
                  color: AppColors.sf(context),
                  borderRadius: CardTokens.borderRadius,
                  boxShadow: AppColors.cardShadow(context),
                ),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                  ),
                  child: Text(
                    l.upgradeButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // ── Redeem code + Restore ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _showRedeemDialog(context, ref),
                    child: Text(
                      l.upgradeRedeemCode,
                      style: TextStyle(
                        fontSize: TypographyTokens.captionSize,
                        color: AppColors.accent,
                      ),
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
                      style: TextStyle(
                        fontSize: TypographyTokens.captionSize,
                        color: AppColors.accent,
                      ),
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
        Icon(Icons.check_rounded, size: 18, color: AppColors.healthy),
      ],
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
                context.pop();
              },
              child: Text(l.upgradeRedeemButton),
            ),
          ],
        ),
      ),
    );
    disposeAfterRouteAnimation(controller);
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  const _FeatureItem(this.icon, this.label);
}
