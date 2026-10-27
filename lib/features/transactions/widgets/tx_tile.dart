import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/budget_impact_provider.dart';
import '../../../core/providers/date_format_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../core/providers/tx_colors_provider.dart';
import '../../../core/providers/tx_list_settings_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/utils/format_number.dart';
import '../../../shared/utils/receipt_helper.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/utils/note_text.dart';
import '../../../shared/theme/app_icons.dart';
import '../../allocations/move_money_sheet.dart';
import '../../../core/database/transfer_amounts.dart';

// ---------------------------------------------------------------------------
// Transaction row — BudgetSeal's own: what the transaction did to the budget.
// Title, then its budget impact ("Food & drink · $142.80 left", over by +
// Cover, Not budgeted, → Ready to assign, Bank → Cash); on the end the
// amount and the account's balance right after it. Shared by the Activity
// list and the dashboard's recent transactions.
// ---------------------------------------------------------------------------

class TxTile extends ConsumerWidget {
  final TransactionEntry entry;
  final Map<String, Category> categoryMap;
  final void Function(String catId, String catName)? onCategoryTap;

  /// Overrides the default tap (open detail) — used by selection mode.
  final VoidCallback? onTap;

  /// Long-press handler (enters selection mode, Cashew-style).
  final VoidCallback? onLongPress;

  /// Show the account's running balance under the amount. Off on the
  /// dashboard, where balances are only approximate.
  final bool showBalance;

  /// Show the transaction date under the amount (lists without date headers).
  final bool showDate;

  /// The list shows one account (account filter): its balance is shown
  /// without the account's name, and a transfer shows that side.
  final String? balanceAccountId;

  const TxTile({
    super.key,
    required this.entry,
    required this.categoryMap,
    this.onCategoryTap,
    this.onTap,
    this.onLongPress,
    this.showBalance = true,
    this.showDate = false,
    this.balanceAccountId,
  });

  static const _tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final tx = entry.tx;
    final txColors = ref.watch(txColorsProvider);
    final listSettings = ref.watch(txListSettingsProvider);
    final isTransfer = tx.type == 'transfer';
    final isIncome = tx.type == 'income';
    final impact = tx.type == 'expense'
        ? ref.watch(txEnvelopeImpactProvider.select((m) => m.value?[tx.id]))
        : null;

    final cat = _resolveCategory();
    final catName = cat?.name;
    final catColor =
        cat != null ? AppColors.fromHex(cat.colorHex) : AppColors.accent;
    final title = _title(s, catName);
    final amount = _displayAmount();

    // Expenses in the normal text color (red is kept for overspending),
    // income green with a "+", transfers grey.
    final amountColor = isIncome
        ? txColors.income
        : isTransfer
            ? AppColors.ts(context)
            : AppColors.tp(context);
    final amountText = isIncome
        ? bidiSafeAmount('+${formatAmount(amount.value, currency: amount.currency)}')
        : formatAmount(amount.value, currency: amount.currency);

    return Semantics(
      label: '$title, $amountText, ${_typeLabel(s, tx.type)}',
      hint: s.txLongPressHint,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap ?? () => context.push('/transactions/${tx.id}'),
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
                16,
                listSettings.compact ? 6 : 8,
                16,
                listSettings.compact ? 6 : 8),
            child: Row(
              children: [
                if (listSettings.showCategoryIcon) ...[
                  _icon(context, cat, catName, catColor, isTransfer,
                      txColors.forType(tx.type)),
                  const SizedBox(width: 12),
                ],
                // Two aligned lines: title | amount, impact | balance.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tp(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tx.receiptPath != null &&
                              tx.receiptPath!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                  start: 6, end: 8),
                              child: _receiptMark(context),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            amountText,
                            style: TextStyle(
                              fontFamily: TypographyTokens.displayFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: amountColor,
                              fontFeatures: _tabular,
                            ),
                          ),
                        ],
                      ),
                      ..._secondLine(context, ref, s, impact, catName, title,
                          listSettings, amount),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Icon: 40 px rounded square, category pastel ─────────────────
  Widget _icon(BuildContext context, Category? cat, String? catName,
      Color catColor, bool isTransfer, Color typeColor) {
    const size = 40.0;
    if (isTransfer) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.pastel(context, typeColor),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        child: Icon(
          AppIcons.arrowsLeftRight,
          color: AppColors.pastel(context, typeColor,
              light: 0.5, dark: 0.5, inverse: true),
          size: 20,
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        final catId = cat?.id;
        if (catId != null && onCategoryTap != null) {
          onCategoryTap!(catId, catName ?? S.of(context).commonUncategorized);
        }
      },
      child: Hero(
        tag: 'tx_${entry.tx.id}',
        child: CategoryIcon(
          categoryName: catName ?? '',
          emoji: cat?.icon,
          color: catColor,
          size: size,
        ),
      ),
    );
  }

  // ── Second line: the budget impact ──────────────────────────────
  Widget _impactLine(
      BuildContext context,
      WidgetRef ref,
      S s,
      EnvelopeImpact? impact,
      String? catName,
      String title,
      TxListSettings settings) {
    final tx = entry.tx;
    final ts = AppColors.ts(context);
    final base = TextStyle(fontSize: 12.5, color: ts);
    final time = settings.showTime
        ? TimeOfDay.fromDateTime(tx.createdAt.toLocal()).format(context)
        : null;
    final children = <Widget>[];

    if (tx.type == 'transfer') {
      final arrow = Directionality.of(context) == TextDirection.rtl ? '←' : '→';
      final from = entry.accountName;
      final to = entry.destinationAccountName ?? '';
      var text = '$from $arrow $to';
      final destCcy = entry.destinationAccountCurrency ?? tx.currency;
      if (destCcy != _displayAmount().currency) {
        text += ' · ${formatAmount(tx.receivedAmount, currency: destCcy)}';
      }
      children.add(Flexible(
        child: Text(text,
            style: base, maxLines: 1, overflow: TextOverflow.ellipsis),
      ));
    } else if (tx.type == 'income') {
      children.add(Flexible(
          child: _pill(
        context,
        fill: AppColors.accentLight,
        ink: AppColors.accentText(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.arrowRight,
                size: 11, color: AppColors.accentText(context)),
            const SizedBox(width: 3),
            Flexible(child: Text(s.allocReadyToAssign)),
          ],
        ),
      )));
    } else if (impact != null) {
      final amt =
          formatAmount(impact.balanceAfter.abs(), currency: impact.currency);
      final name = impact.envelopeCount > 1
          ? '${impact.name} +${impact.envelopeCount - 1}'
          : impact.name;
      final color = impact.overspent ? AppColors.overspent : ts;
      children
        ..add(Icon(AppIcons.envelopeSimple, size: 13, color: color))
        ..add(const SizedBox(width: 5));
      if (impact.overspent) {
        children.add(Flexible(
          child: Text('$name · ${s.txImpactOver(amt)}',
              style: base.copyWith(color: color, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ));
        if (impact.stillOverspent && impact.isLatest && onTap == null) {
          children
            ..add(const SizedBox(width: 6))
            ..add(_pill(
              context,
              fill: AppColors.overspent,
              ink: AppColors.inkOn(AppColors.overspent),
              child: Text(s.allocCoverButton),
              onTap: () => showMoveMoneySheet(context, ref,
                  toId: impact.allocationId,
                  currency: impact.currency,
                  amount: -impact.balanceNow,
                  cover: true),
            ));
        }
      } else {
        // "Food & drink · $142.80 left" with the amount in bold.
        final left = s.txImpactLeft(amt);
        final at = left.indexOf(amt);
        children.add(Flexible(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$name · '),
              if (at >= 0) ...[
                TextSpan(text: left.substring(0, at)),
                TextSpan(
                    text: amt,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(context))),
                TextSpan(text: left.substring(at + amt.length)),
              ] else
                TextSpan(text: left),
            ]),
            style: base,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ));
      }
    } else {
      // An expense no envelope paid for.
      if (catName != null && catName != title) {
        children
          ..add(Flexible(
            child: Text(catName,
                style: base, maxLines: 1, overflow: TextOverflow.ellipsis),
          ))
          ..add(const SizedBox(width: 6));
      }
      children.add(Flexible(
        child: _pill(
          context,
          fill: AppColors.pastel(context, AppColors.caution,
              light: 0.85, dark: 0.78),
          ink: AppColors.caution,
          child: Text(s.txImpactNotBudgeted),
        ),
      ));
    }

    if (time != null) {
      children.add(Text(' · $time', style: base));
    }
    return Row(children: children);
  }

  Widget _pill(BuildContext context,
      {required Color fill,
      required Color ink,
      required Widget child,
      VoidCallback? onTap}) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
      child: DefaultTextStyle.merge(
        style:
            TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: ink),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: child,
      ),
    );
    return Material(
      color: fill,
      shape: const StadiumBorder(),
      child: onTap == null
          ? body
          : InkWell(
              customBorder: const StadiumBorder(), onTap: onTap, child: body),
    );
  }

  /// Impact on the start, balance after (or date) on the end; then the
  /// base-currency value and "No rate" under the amount when they apply.
  List<Widget> _secondLine(
      BuildContext context,
      WidgetRef ref,
      S s,
      EnvelopeImpact? impact,
      String? catName,
      String title,
      TxListSettings settings,
      ({double value, String currency}) amount) {
    final under = _underAmount(context, s, amount);
    final end = under.isEmpty ? null : under.first;
    final showImpact = !settings.compact;
    if (!showImpact && !showBalance && !showDate) return const [];
    return [
      const SizedBox(height: 3),
      LayoutBuilder(
          builder: (context, box) => Row(
                children: [
                  if (showImpact)
                    Expanded(
                      child: _impactLine(
                          context, ref, s, impact, catName, title, settings),
                    )
                  else
                    const Spacer(),
                  if (end != null) ...[
                    const SizedBox(width: 8),
                    // Long balances (LBP) give way before the impact does.
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: box.maxWidth * 0.4),
                      child: DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: end,
                      ),
                    ),
                  ],
                ],
              )),
      for (final w in under.skip(1))
        Align(alignment: AlignmentDirectional.centerEnd, child: w),
    ];
  }

  // ── Under the amount: balance after / date / conversion ─────────
  List<Widget> _underAmount(
      BuildContext context, S s, ({double value, String currency}) amount) {
    final tx = entry.tx;
    final lines = entry.lines;
    final isTransfer = tx.type == 'transfer';
    final small = TextStyle(
        fontSize: 11.5, color: AppColors.ts(context), fontFeatures: _tabular);
    final out = <Widget>[];

    // A foreign line saved without a rate is left out of totals and reports
    // — flag it so the user can open it and add one.
    final missingRate = !isTransfer &&
        lines.any(
            (l) => !isRealRate(l.currency, tx.currency, l.exchangeRateToBase));

    if (showDate) {
      out.add(Text(formatDate(tx.createdAt.toLocal()), style: small));
    } else if (!showBalance) {
      out.add(const SizedBox.shrink());
    } else {
      final single = entry.involvedAccountNames.length <= 1;
      if (isTransfer || single) {
        // A transfer shows the destination (where the money is now),
        // unless the list is filtered to the source account.
        final dest = isTransfer &&
            entry.destinationAccountBalanceAfter != null &&
            balanceAccountId != tx.accountId;
        final name = dest ? entry.destinationAccountName : entry.accountName;
        final bal = formatAmount(
            dest
                ? entry.destinationAccountBalanceAfter!
                : entry.accountBalanceAfter,
            currency: dest
                ? (entry.destinationAccountCurrency ?? tx.currency)
                : entry.accountCurrency);
        out.add(_BalanceText(
            name: balanceAccountId != null ? null : name,
            balance: bal,
            style: small));
      } else {
        out.add(Text(s.txNAccounts(entry.involvedAccountNames.length),
            style: small));
      }
    }

    // Foreign amount: its value in the base currency.
    final hasRealConversion =
        lines.any((l) => (l.exchangeRateToBase - 1.0).abs() > 0.001);
    if (!isTransfer && amount.currency != tx.currency && hasRealConversion) {
      out.add(Text('≈ ${formatAmount(tx.amount, currency: tx.currency)}',
          style: small));
    }
    if (missingRate) {
      out.add(Padding(
        padding: const EdgeInsets.only(top: 2),
        child: _pill(
          context,
          fill: AppColors.pastel(context, AppColors.caution,
              light: 0.85, dark: 0.78),
          ink: AppColors.caution,
          child: Text(s.txNoRate, style: const TextStyle(fontSize: 9.5)),
        ),
      ));
    }
    return out;
  }

  Widget _receiptMark(BuildContext context) {
    final count = parseReceiptPaths(entry.tx.receiptPath).length;
    final icon = Icon(AppIcons.receipt, size: 14, color: AppColors.th(context));
    if (count <= 1) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        PositionedDirectional(
          top: -6,
          end: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onAccent),
            ),
          ),
        ),
      ],
    );
  }

  Category? _resolveCategory() {
    final tx = entry.tx;
    final lines = entry.lines;
    if (lines.isNotEmpty && lines.first.categoryId != null) {
      return categoryMap[lines.first.categoryId];
    }
    if (tx.categoryId != null) {
      return categoryMap[tx.categoryId];
    }
    return null;
  }

  /// The payee/note when there is one ("Carrefour"), else the category,
  /// else the split's categories, else the type.
  String _title(S s, String? catName) {
    final tx = entry.tx;
    final lines = entry.lines;
    final note = visibleNote(tx.note).trim();
    if (note.isNotEmpty) return note;
    if (lines.length == 1 && lines.first.note.trim().isNotEmpty) {
      return lines.first.note.trim();
    }
    if (tx.type == 'transfer') return s.typeTransfer;
    if (lines.length > 1) {
      final names = lines
          .map((l) =>
              l.categoryId != null ? categoryMap[l.categoryId]?.name : null)
          .whereType<String>()
          .toSet()
          .take(2)
          .toList();
      if (names.isEmpty) return s.txNItems(lines.length);
      final extra = lines.length - names.length;
      return extra > 0
          ? '${names.join(', ')} ${s.txNMore(extra)}'
          : names.join(', ');
    }
    return catName ?? _typeLabel(s, tx.type);
  }

  /// The amount in the line's own currency (all lines in one foreign
  /// currency → their total; mixed → base total of lines with a rate).
  ({double value, String currency}) _displayAmount() {
    final tx = entry.tx;
    final lines = entry.lines;
    if (tx.type == 'transfer' || lines.isEmpty) {
      return (value: tx.amount, currency: tx.currency);
    }
    if (lines.length == 1) {
      return (value: lines.first.amount, currency: lines.first.currency);
    }
    final currencies = lines.map((l) => l.currency).toSet();
    if (currencies.length == 1) {
      return (
        value: lines.fold(0.0, (s, l) => s + l.amount),
        currency: currencies.first,
      );
    }
    double baseTotal = 0;
    for (final l in lines) {
      if (l.currency == tx.currency) {
        baseTotal += l.amount;
      } else if ((l.exchangeRateToBase - 1.0).abs() >= 0.001) {
        baseTotal += l.amount * l.exchangeRateToBase;
      }
    }
    return (value: baseTotal, currency: tx.currency);
  }

  String _typeLabel(S s, String type) => switch (type) {
        'income' => s.typeIncome,
        'expense' => s.typeExpense,
        'transfer' => s.typeTransfer,
        _ => type,
      };
}

/// "Bank · $5,260.80" when it fits; when space is short the account name
/// goes first and the amount stays whole as long as it can.
class _BalanceText extends StatelessWidget {
  final String? name;
  final String balance;
  final TextStyle style;
  const _BalanceText(
      {required this.name, required this.balance, required this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final full = name == null || name!.isEmpty ? balance : '$name · $balance';
      final painter = TextPainter(
        // Measure in the font the Text will use (the app's, not the default).
        text: TextSpan(
            text: full, style: DefaultTextStyle.of(context).style.merge(style)),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final fits = painter.width <= box.maxWidth;
      painter.dispose();
      if (fits) return Text(full, style: style, maxLines: 1);
      // Without the name; a balance that still doesn't fit (LBP) shrinks
      // rather than losing digits.
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Text(balance, style: style, maxLines: 1),
      );
    });
  }
}
