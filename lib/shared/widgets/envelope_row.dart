import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/format_number.dart';
import 'category_icon.dart';
import 'seal_mark.dart';
import 'tappable.dart';

/// One envelope on the Budget tab: icon (with the seal when fully funded),
/// name and what's left, a thin bar of what's been used, and a line on how
/// it's going. Rows sit together in one card per section; an overspent one
/// goes in the "Needs attention" card with a Cover button.
class EnvelopeRow extends StatelessWidget {
  final String name;
  final String type;
  final Map<String, double> balanceByCurrency;
  final String baseCurrency;
  final double? targetAmount;
  final String? targetCurrency;
  final String? envelopeIcon;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColorHex;

  /// Spent this period in the target currency.
  final double spent;
  final double? plannedAmount;
  final String? plannedCurrency;
  final bool needsReview;
  final bool sealed;
  final VoidCallback? onTap;

  /// Shown while overspent: move money in to bring it back to zero.
  final VoidCallback? onCover;

  const EnvelopeRow({
    super.key,
    required this.name,
    required this.type,
    required this.balanceByCurrency,
    required this.baseCurrency,
    this.targetAmount,
    this.targetCurrency,
    this.envelopeIcon,
    this.categoryName,
    this.categoryIcon,
    this.categoryColorHex,
    this.spent = 0,
    this.plannedAmount,
    this.plannedCurrency,
    this.needsReview = false,
    this.sealed = false,
    this.onTap,
    this.onCover,
  });

  bool get _isFlexible => type == 'flexible' || type == 'saving';

  Widget _icon(BuildContext context, Color color) {
    final Widget inner;
    if (envelopeIcon != null && envelopeIcon!.isNotEmpty) {
      inner = EmojiGlyph(envelopeIcon!, size: 20);
    } else if (categoryIcon != null &&
        categoryIcon!.isNotEmpty &&
        categoryIcon != 'category') {
      inner = EmojiGlyph(categoryIcon!, size: 20);
    } else if (_isFlexible) {
      inner = Icon(
          (targetAmount ?? 0) > 0 ? AppIcons.target : AppIcons.piggyBank,
          size: 19,
          color: AppColors.pastel(context, color,
              light: 0.5, dark: 0.5, inverse: true));
    } else {
      inner = Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.pastel(context, color,
                  light: 0.5, dark: 0.5, inverse: true)));
    }
    return SizedBox.square(
      dimension: 38,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.pastel(context, color, light: 0.55, dark: 0.45),
            shape: BoxShape.circle,
          ),
          child: Center(child: inner),
        ),
        PositionedDirectional(
          end: -4,
          bottom: -4,
          child: SealStamp(sealed: sealed, size: 18),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final cur = targetCurrency ?? baseCurrency;
    final balance = balanceByCurrency[cur] ?? 0;
    final target = (targetAmount ?? 0) > 0 ? targetAmount! : null;
    final over = balance < -0.01;
    final otherDebts = balanceByCurrency.entries
        .where((e) => e.key != cur && e.value < -0.01)
        .length;
    final color = categoryColorHex != null
        ? AppColors.fromHex(categoryColorHex!)
        : AppColors.accent;
    final bad = AppColors.isDark
        ? AppColors.lightenPastel(AppColors.overspent, 0.35)
        : AppColors.overspent;
    String money(double v) => formatAmount(v, currency: cur);

    // How much of the bar is used, and the line under it.
    double? used;
    String? sub;
    if (over) {
      sub = capitalizedOver(tr, money(-balance));
    } else if (_isFlexible) {
      if (target != null) {
        used = (balance / target).clamp(0.0, 1.0);
        sub = tr.allocPercentSaved((used * 100).round());
      }
    } else if (target != null) {
      used = (spent / target).clamp(0.0, 1.0);
      sub = spent > 0.005
          ? tr.allocSpentOf(money(spent), money(target))
          : tr.allocNothingSpent;
    }
    final extras = <String>[
      if (plannedAmount != null && plannedAmount! > 0)
        '${formatAmount(plannedAmount!, currency: plannedCurrency ?? cur)} ${tr.plannedChipLabel}',
    ];
    if (extras.isNotEmpty) {
      sub = [if (sub != null) sub, ...extras].join(' · ');
    }
    // Spending envelopes nearly empty turn the bar amber.
    final low = !_isFlexible &&
        target != null &&
        balance > 0 &&
        balance < target * 0.1;
    final barColor = _isFlexible
        ? AppColors.healthy
        : (low ? AppColors.caution : AppColors.accentBright);

    final semantic = <String>[
      name,
      money(balance),
      if (sub != null) sub,
      if (needsReview) tr.a11yNeedsReview,
    ].join(', ');

    return Semantics(
      label: semantic,
      button: onTap != null,
      excludeSemantics: true,
      child: Tappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            _icon(context, color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (needsReview) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.caution, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    if (!over)
                      Text(money(balance),
                          style: const TextStyle(
                              fontFamily: TypographyTokens.displayFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                  ]),
                  if (used != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 5,
                        child: Stack(children: [
                          Container(color: AppColors.sfv(context)),
                          FractionallySizedBox(
                            widthFactor: used,
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(color: barColor),
                          ),
                        ]),
                      ),
                    ),
                  ],
                  if (sub != null) ...[
                    const SizedBox(height: 4),
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: over ? bad : AppColors.ts(context))),
                  ],
                  if (otherDebts > 0)
                    Text(tr.allocOtherCurrencies(otherDebts),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.caution)),
                ],
              ),
            ),
            if (over && onCover != null) ...[
              const SizedBox(width: 10),
              Material(
                color: AppColors.overspent,
                shape: const StadiumBorder(),
                child: Tappable(
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  haptic: true,
                  onTap: onCover,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text(tr.allocCoverButton,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkOn(AppColors.overspent))),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  /// "Over by $X", capitalized for the start of a line.
  static String capitalizedOver(S tr, String amount) {
    final s = tr.quickOverBy(amount);
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }
}
