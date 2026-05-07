import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/amount_field.dart';

// ---------------------------------------------------------------------------
// Shared card wrapper
// ---------------------------------------------------------------------------

class TxCard extends StatelessWidget {
  final Widget child;
  const TxCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
      ),
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bd(context)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasCategory
              ? color.withValues(alpha: 0.1)
              : AppColors.bd(context),
          border: Border.all(
            color: hasCategory
                ? color.withValues(alpha: 0.35)
                : AppColors.bd(context),
          ),
          borderRadius: BorderRadius.circular(20),
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
              Icon(Icons.label_outline_rounded,
                  size: 14, color: AppColors.ts(context)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name ?? 'Category',
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
              Icons.expand_more_rounded,
              size: 14,
              color: hasCategory
                  ? color.withValues(alpha: 0.7)
                  : AppColors.ts(context),
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
  double? _originalRate; // stored before first inversion to avoid precision loss

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

  const LineCard({
    super.key,
    required this.line,
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
        'bank' => Icons.account_balance_rounded,
        'credit' => Icons.credit_card_rounded,
        'wallet' => Icons.account_balance_wallet_rounded,
        _ => Icons.money_rounded,
      };

  bool get _showRate => line.currency != baseCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.bd(context)),
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
                        Icon(Icons.account_balance_rounded,
                            size: 16, color: AppColors.th(context)),
                        const SizedBox(width: 8),
                        Text('Select account',
                            style: TextStyle(
                                color: AppColors.th(context), fontSize: 13)),
                      ],
                    ),
                    icon: Icon(Icons.expand_more_rounded,
                        size: 16, color: AppColors.th(context)),
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
              if (canRemove) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.bd(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: AppColors.ts(context)),
                  ),
                ),
              ],
            ],
          ),
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
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onPickCurrency,
                child: CurrencyBadge(currency: line.currency),
              ),
            ],
          ),
          // Exchange rate row (shown when currency differs from base)
          if (_showRate) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.currency_exchange_rounded,
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle:
                            TextStyle(fontSize: 13, color: AppColors.th(context)),
                        border: InputBorder.none,
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
                  GestureDetector(
                    onTap: () {
                      final currentText = line.rateCtrl.text;
                      final currentRate =
                          double.tryParse(currentText.replaceAll(',', ''));

                      if (currentRate != null && currentRate > 0) {
                        if (!line.rateInverted) {
                          // Going from normal → inverted: store original
                          line._originalRate = currentRate;
                          final inverted = 1.0 / currentRate;
                          line.rateCtrl.text = inverted >= 1
                              ? inverted.toStringAsFixed(6)
                              : inverted.toStringAsFixed(6);
                        } else {
                          // Going from inverted → normal: restore original
                          final restored = line._originalRate ?? (1.0 / currentRate);
                          line.rateCtrl.text = restored >= 100
                              ? restored.toStringAsFixed(0)
                              : restored.toStringAsFixed(2);
                          line._originalRate = null;
                        }
                      }
                      line.rateInverted = !line.rateInverted;
                      onChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.swap_vert_rounded,
                          size: 14, color: AppColors.accent),
                    ),
                  ),
                  const Spacer(),
                  if (line.amount > 0)
                    Flexible(
                      child: Text(
                        '= ${line.baseAmount.toStringAsFixed(2)} $baseCurrency',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.bd(context)),
          const SizedBox(height: 8),
          // Per-item note
          TextField(
            controller: line.noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
            decoration: InputDecoration(
              hintText: 'Item note…',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.th(context)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.notes_rounded,
                    size: 14, color: AppColors.th(context)),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        ],
      ),
    );
  }
}
