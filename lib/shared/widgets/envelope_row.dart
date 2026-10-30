import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/format_number.dart';
import 'category_icon.dart';
import 'seal_mark.dart';
import 'tappable.dart';

/// The currency an envelope is overspent in: its own first, else any other
/// side gone below zero (an LBP or EUR expense with no money in that
/// currency). Null when nothing is below zero.
String? overspentCurrency(Map<String, double> balances, String main) {
  if ((balances[main] ?? 0) < -0.01) return main;
  final others = [
    for (final e in balances.entries)
      if (e.value < -0.01) e.key,
  ]..sort();
  return others.firstOrNull;
}


/// One envelope on the Budget tab: icon, name (with the seal after it when
/// fully funded) and what's left, a thin bar of what's been used, and a line
/// on how it's going. A spending envelope's bar has three states: on track
/// (accent), nearly gone (amber, under 15% left) and done (spent to zero:
/// muted, "Done" in place of $0.00). Rows sit together in one card per section; an overspent one
/// goes in the "Needs attention" card with a Cover button.
class EnvelopeRow extends StatelessWidget {
  final String name;
  final String type;
  final Map<String, double> balanceByCurrency;
  final String baseCurrency;
  final double? targetAmount;
  final String? targetCurrency;

  /// A second target in another currency: its own bar and line.
  final double? secondTargetAmount;
  final String? secondTargetCurrency;

  /// Spent this period in the second target's currency.
  final double secondSpent;
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
    this.secondTargetAmount,
    this.secondTargetCurrency,
    this.secondSpent = 0,
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
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.pastel(context, color, light: 0.55, dark: 0.45),
        shape: BoxShape.circle,
      ),
      child: Center(child: inner),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final cur = targetCurrency ?? baseCurrency;
    final balance = balanceByCurrency[cur] ?? 0;
    final target = (targetAmount ?? 0) > 0 ? targetAmount! : null;
    final overCur = overspentCurrency(balanceByCurrency, cur);
    final over = overCur != null;
    final cur2 = (secondTargetAmount ?? 0) > 0 &&
            secondTargetCurrency != null &&
            secondTargetCurrency != cur
        ? secondTargetCurrency
        : null;
    final otherDebts = balanceByCurrency.entries
        .where((e) =>
            e.key != cur && e.key != cur2 && e.key != overCur && e.value < -0.01)
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
      sub = capitalizedOver(tr,
          formatAmount(-balanceByCurrency[overCur]!, currency: overCur));
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
    // Spent down to zero: done for the period, not a warning.
    final done = !_isFlexible &&
        !over &&
        target != null &&
        balance.abs() < 0.005 &&
        spent > 0.005;
    // Spending envelopes nearly empty (under 15% left) turn amber.
    final low = !_isFlexible &&
        !over &&
        target != null &&
        balance > 0.005 &&
        balance < target * 0.15;
    if (done) {
      sub = tr.allocAllSpent(money(spent));
    } else if (low && sub != null) {
      sub = '${tr.allocNearlyGone} · $sub';
    }
    final extras = <String>[
      if (plannedAmount != null && plannedAmount! > 0)
        '${formatAmount(plannedAmount!, currency: plannedCurrency ?? cur)} ${tr.plannedChipLabel}',
    ];
    if (extras.isNotEmpty) {
      sub = [if (sub != null) sub, ...extras].join(' · ');
    }
    // The second target: its own bar and "left · spent of" line.
    double? used2;
    String? sub2;
    if (cur2 != null) {
      final target2 = secondTargetAmount!;
      final balance2 = balanceByCurrency[cur2] ?? 0;
      String money2(double v) => formatAmount(v, currency: cur2);
      if (_isFlexible) {
        used2 = (balance2 / target2).clamp(0.0, 1.0);
        sub2 = '${money2(balance2)} · '
            '${tr.allocPercentSaved((used2 * 100).round())}';
      } else {
        used2 = (secondSpent / target2).clamp(0.0, 1.0);
        sub2 = '${money2(balance2)} · '
            '${secondSpent > 0.005 ? tr.allocSpentOf(money2(secondSpent), money2(target2)) : tr.allocNothingSpent}';
      }
    }
    final barColor = _isFlexible
        ? AppColors.healthy
        : done
            ? AppColors.th(context)
            : (low ? AppColors.caution : AppColors.accentBright);

    final semantic = <String>[
      name,
      money(balance),
      if (sub != null) sub,
      if (sub2 != null) sub2,
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
                      child: Row(children: [
                        Flexible(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        // The seal follows the name (not stamped on the
                        // icon). Always built, so it's stamped on when
                        // funding seals it (empty space until then).
                        const SizedBox(width: 5),
                        SealStamp(sealed: sealed, size: 15),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    if (!over)
                      Text(done ? tr.allocDone : money(balance),
                          style: TextStyle(
                              fontFamily: TypographyTokens.displayFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: done
                                  ? AppColors.ts(context)
                                  : low
                                      ? AppColors.caution
                                      : null)),
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
                            color: over
                                ? bad
                                : low
                                    ? AppColors.caution
                                    : AppColors.ts(context))),
                  ],
                  if (used2 != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 4,
                        child: Stack(children: [
                          Container(color: AppColors.sfv(context)),
                          FractionallySizedBox(
                            widthFactor: used2,
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(color: barColor),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(sub2!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ts(context))),
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
