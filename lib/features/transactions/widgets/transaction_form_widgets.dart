import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/widgets/amount_field.dart';
import '../../../shared/widgets/tappable.dart';
import '../../../shared/theme/app_icons.dart';

// ---------------------------------------------------------------------------
// Shared card wrapper
// ---------------------------------------------------------------------------

class TxCard extends StatelessWidget {
  final Widget child;
  const TxCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.card(context),
      child: child,
    );
  }
}

class TxDivider extends StatelessWidget {
  const TxDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: AppColors.bd(context));
}

// ---------------------------------------------------------------------------
// Type chip
// ---------------------------------------------------------------------------

class TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const TypeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color
                : AppColors.pastel(context, color, light: 0.88, dark: 0.78),
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18, color: selected ? AppColors.inkOn(color) : color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.inkOn(color) : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Currency badge
// ---------------------------------------------------------------------------

class CurrencyBadge extends StatelessWidget {
  final String currency;
  const CurrencyBadge({super.key, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sfv(context),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
      ),
      child: Text(
        currency,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ts(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category pill
// ---------------------------------------------------------------------------

class CategoryPill extends StatelessWidget {
  final String? name;
  final Color color;
  final VoidCallback onTap;

  const CategoryPill({
    super.key,
    required this.name,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCategory = name != null;
    final radius = BorderRadius.circular(RadiusTokens.pill);
    return Tappable(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasCategory
              ? AppColors.pastel(context, color, light: 0.85, dark: 0.75)
              : AppColors.sfv(context),
          border: Border.all(
            color: hasCategory ? color : Colors.transparent,
          ),
          borderRadius: radius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCategory)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            else
              Icon(AppIcons.tag,
                  size: 14, color: AppColors.ts(context)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name ?? S.of(context).commonCategory,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: hasCategory ? color : AppColors.ts(context),
                  fontWeight:
                      hasCategory ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              AppIcons.caretDown,
              size: 14,
              color: hasCategory ? color : AppColors.ts(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Line state model
// ---------------------------------------------------------------------------

class LineState {
  final TextEditingController amountCtrl;
  final TextEditingController noteCtrl;
  final TextEditingController rateCtrl;
  String currency;
  String? accountId;
  String? accountName;
  String? categoryId;
  String? categoryName;
  Color categoryColor;
  double exchangeRateToBase;
  bool rateInverted = false;
  String? _originalText; // the typed rate, restored as it was

  LineState({required this.currency})
      : amountCtrl = TextEditingController(),
        noteCtrl = TextEditingController(),
        rateCtrl = TextEditingController(),
        categoryColor = AppColors.textSecondary,
        exchangeRateToBase = 1.0;

  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    rateCtrl.dispose();
  }

  double get amount =>
      double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0.0;

  /// Amount converted to household base currency.
  double get baseAmount => amount * exchangeRateToBase;

  bool get isValid => amount > 0 && accountId != null;
}

// ---------------------------------------------------------------------------
// Line card
// ---------------------------------------------------------------------------

class LineCard extends StatelessWidget {
  final LineState line;
  final bool canRemove;
  final Color typeColor;
  final String baseCurrency;
  final List<Account> accounts;
  final VoidCallback onRemove;
  final VoidCallback onPickCategory;
  final VoidCallback onPickCurrency;
  final ValueChanged<String?> onAccountChanged;
  final VoidCallback onChanged;

  /// Single-line form: category and amount live in the header band, so the
  /// card shows only account, currency, rate and note.
  final bool compact;

  const LineCard({
    super.key,
    required this.line,
    this.compact = false,
    required this.canRemove,
    required this.typeColor,
    required this.baseCurrency,
    required this.accounts,
    required this.onRemove,
    required this.onPickCategory,
    required this.onPickCurrency,
    required this.onAccountChanged,
    required this.onChanged,
  });

  IconData _accountIcon(String type) => switch (type) {
        'bank' => AppIcons.bank,
        'credit' => AppIcons.creditCard,
        'wallet' => AppIcons.wallet,
        _ => AppIcons.money,
      };

  bool get _showRate => line.currency != baseCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Same card surface as the form's field card.
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(RadiusTokens.input),
        boxShadow: AppColors.cardShadow(context),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      padding: CardTokens.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: account picker + remove button
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: line.accountId,
                    isExpanded: true,
                    isDense: true,
                    hint: Row(
                      children: [
                        Icon(AppIcons.bank,
                            size: 16, color: AppColors.th(context)),
                        const SizedBox(width: 8),
                        Text(S.of(context).txWidgetSelectAccount,
                            style: TextStyle(
                                color: AppColors.ts(context), fontSize: 15)),
                      ],
                    ),
                    icon: AppIcons.dropdown,
                    // Selected value: name only — the currency badge beside
                    // it already shows the currency.
                    selectedItemBuilder: (context) => accounts
                        .map((a) => Row(
                              children: [
                                Icon(_accountIcon(a.type),
                                    size: 18,
                                    color: AppColors.ts(context)),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(a.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.tp(context))),
                                ),
                              ],
                            ))
                        .toList(),
                    items: accounts
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Row(
                                children: [
                                  Icon(_accountIcon(a.type),
                                      size: 16,
                                      color: AppColors.ts(context)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(a.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(a.currency,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.th(context),
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: onAccountChanged,
                  ),
                ),
              ),
              if (compact) ...[
                const SizedBox(width: 12),
                Tappable(
                  onTap: onPickCurrency,
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  child: CurrencyBadge(currency: line.currency),
                ),
              ],
              if (canRemove) ...[
                const SizedBox(width: 8),
                Tappable(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.bd(context),
                      borderRadius: BorderRadius.circular(RadiusTokens.sm),
                    ),
                    child: Icon(AppIcons.x,
                        size: 16, color: AppColors.ts(context)),
                  ),
                ),
              ],
            ],
          ),
          if (!compact) ...[
          const SizedBox(height: 8),
          // Category pill
          CategoryPill(
            name: line.categoryName,
            color: line.categoryColor,
            onTap: onPickCategory,
          ),
          const SizedBox(height: 14),
          // Amount + currency
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AmountField(
                  controller: line.amountCtrl,
                  onChanged: onChanged,
                  decimals: currencyDecimals(line.currency),
                ),
              ),
              const SizedBox(width: 12),
              Tappable(
                onTap: onPickCurrency,
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                child: CurrencyBadge(currency: line.currency),
              ),
            ],
          ),
          ],
          // Exchange rate row (shown when currency differs from base)
          if (_showRate) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.pastel(context, AppColors.accent,
                    light: 0.88, dark: 0.8),
                borderRadius: BorderRadius.circular(RadiusTokens.sm),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.currencyCircleDollar,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    line.rateInverted
                        ? '1 ${line.currency} ='
                        : '1 $baseCurrency =',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.ts(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: line.rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle:
                            TextStyle(fontSize: 13, color: AppColors.th(context)),
                        border: InputBorder.none,
        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        final rate =
                            double.tryParse(val.replaceAll(',', ''));
                        if (rate != null && rate > 0) {
                          if (line.rateInverted) {
                            // User entered "1 LINE = X BASE", so rate IS exchangeRateToBase
                            line.exchangeRateToBase = rate;
                          } else {
                            // User entered "1 BASE = X LINE", so exchangeRateToBase = 1/rate
                            line.exchangeRateToBase = 1.0 / rate;
                          }
                        }
                        onChanged();
                      },
                    ),
                  ),
                  Text(
                    line.rateInverted ? baseCurrency : line.currency,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ts(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tappable(
                    borderRadius: BorderRadius.circular(RadiusTokens.sm),
                    onTap: () {
                      final currentText = line.rateCtrl.text;
                      final currentRate =
                          double.tryParse(currentText.replaceAll(',', ''));

                      if (currentRate != null && currentRate > 0) {
                        if (!line.rateInverted) {
                          // Going from normal → inverted: store original
                          line._originalText = currentText;
                          line.rateCtrl.text =
                              formatRateForInput(1.0 / currentRate);
                        } else {
                          // Going from inverted → normal: restore original
                          line.rateCtrl.text = line._originalText ??
                              formatRateForInput(1.0 / currentRate);
                          line._originalText = null;
                        }
                      }
                      line.rateInverted = !line.rateInverted;
                      onChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.pastel(context, AppColors.accent,
                            light: 0.85, dark: 0.78),
                        borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      ),
                      child: Icon(AppIcons.arrowsDownUp,
                          size: 14, color: AppColors.accent),
                    ),
                  ),
                  const Spacer(),
                  if (line.amount > 0)
                    Flexible(
                      child: Text(
                        '= ${formatNumber(line.baseAmount)} $baseCurrency',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentText(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
          // Per-item note — single-line forms use the title/note fields above.
          if (!compact) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.bd(context)),
          const SizedBox(height: 8),
          TextField(
            controller: line.noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
            decoration: InputDecoration(
              hintText: S.of(context).txWidgetItemNote,
              hintStyle: TextStyle(fontSize: 13, color: AppColors.th(context)),
              border: InputBorder.none,
        filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Icon(AppIcons.textAlignLeft,
                    size: 14, color: AppColors.th(context)),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          ],
        ],
      ),
    );
  }
}

/// One-tap date shortcut beside the date field: "Yesterday" while the date
/// is today, otherwise "Today".
class DateQuickChip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onPick;

  const DateQuickChip(
      {super.key, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = selected.year == now.year &&
        selected.month == now.month &&
        selected.day == now.day;
    final target = isToday
        ? DateTime(now.year, now.month, now.day - 1)
        : DateTime(now.year, now.month, now.day);
    final label =
        isToday ? S.of(context).commonYesterday : S.of(context).commonToday;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Tappable(
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        onTap: () => onPick(target),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentText(context))),
        ),
      ),
    );
  }
}
