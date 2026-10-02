import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
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

// ---------------------------------------------------------------------------
// Transaction tile — Cashew transactionEntry layout. Shared by the Activity
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

  /// Show the transaction date in the subtitle (lists without date headers).
  final bool showDate;

  const TxTile({
    super.key,
    required this.entry,
    required this.categoryMap,
    this.onCategoryTap,
    this.onTap,
    this.onLongPress,
    this.showBalance = true,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = entry.tx;
    final txColors = ref.watch(txColorsProvider);
    final listSettings = ref.watch(txListSettingsProvider);
    final isTransfer = tx.type == 'transfer';
    final typeColor = txColors.forType(tx.type);

    // Resolve category
    final cat = _resolveCategory();
    final catName = cat?.name;
    final catColor =
        cat != null ? AppColors.fromHex(cat.colorHex) : AppColors.accent;

    // For transfers, build a Cashew-style 2-line display
    final String displayName;
    final String? note;
    final String? transferFrom;
    final String? transferTo;
    final double? transferDestAmt;
    final String? transferDestCcy;
    if (isTransfer) {
      transferFrom = entry.accountName.isNotEmpty ? entry.accountName : 'account';
      transferTo = entry.destinationAccountName ?? 'account';
      final arrow = Directionality.of(context) == TextDirection.rtl ? '←' : '→';
      displayName = '$transferFrom $arrow $transferTo';
      note = tx.note.isNotEmpty ? visibleNote(tx.note) : null;
      transferDestAmt = tx.amount * tx.exchangeRateToBase;
      transferDestCcy = entry.destinationAccountCurrency ?? tx.currency;
    } else {
      transferFrom = null;
      transferTo = null;
      transferDestAmt = null;
      transferDestCcy = null;
      displayName = _buildDisplayName(context, catName);
      note = _buildNote(catName);
    }
    final notePreview = _buildNotePreview(catName, displayName);

    return Semantics(
      label: '$displayName, ${formatSignedAmount(tx.amount, currency: tx.currency, type: tx.type)}, ${tx.type}',
      hint: S.of(context).txLongPressHint,
      button: true,
      // Cashew transactionEntry: ripple row, radius 12, inner padding 8/10.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () => context.push('/transactions/${tx.id}'),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 10, 8),
          child: Row(
            children: [
              // ── Circular category icon (tap to filter #5) ─────
            if (listSettings.showCategoryIcon) ...[
              if (isTransfer)
                Container(
                  width: CategoryIconTokens.listSize,
                  height: CategoryIconTokens.listSize,
                  decoration: BoxDecoration(
                    color: AppColors.pastel(context, typeColor),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.pastel(context, typeColor,
                        light: 0.5, dark: 0.5, inverse: true),
                    size: 24,
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    final catId = cat?.id;
                    if (catId != null && onCategoryTap != null) {
                      onCategoryTap!(catId, catName ?? 'Unknown');
                    }
                  },
                  child: Hero(
                    tag: 'tx_${tx.id}',
                    child: CategoryIcon(
                      categoryName: catName ?? '',
                      emoji: cat?.icon,
                      color: catColor,
                      size: CategoryIconTokens.listSize,
                      circular: true,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
            ],
            // ── Name + note (or transfer sub-rows) ──────────────
            Expanded(
              child: isTransfer
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title: "AccountA → AccountB"
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Source account line
                        _transferSubRow(
                          context,
                          transferFrom!,
                          tx.amount,
                          tx.currency,
                          txColors.expense,
                        ),
                        const SizedBox(height: 2),
                        // Destination account line
                        _transferSubRow(
                          context,
                          transferTo!,
                          transferDestAmt!,
                          transferDestCcy!,
                          txColors.income,
                        ),
                        if (note != null) ...[
                          const SizedBox(height: 2),
                          Text(note,
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.th(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tp(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!listSettings.compact) ...[
                          if (note != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              note,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.ts(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (notePreview != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              notePreview,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.th(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                        if (showDate) ...[
                          const SizedBox(height: 2),
                          Text(
                            formatDate(tx.createdAt.toLocal()),
                            style: TextStyle(
                                fontSize: 12, color: AppColors.th(context)),
                          ),
                        ],
                        // Account label + time
                        if (!showDate &&
                            (listSettings.showAccount || listSettings.showTime)) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (listSettings.showAccount && entry.accountName.isNotEmpty)
                                entry.accountName,
                              if (listSettings.showTime)
                                '${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}',
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.th(context),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            // ── Receipt indicator ────────────────────────────────
            if (tx.receiptPath != null && tx.receiptPath!.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: () {
                  final receiptCount = parseReceiptPaths(tx.receiptPath).length;
                  if (receiptCount > 1) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 14, color: AppColors.th(context)),
                        PositionedDirectional(
                          top: -6,
                          end: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$receiptCount',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Icon(Icons.receipt_long_rounded,
                      size: 14, color: AppColors.th(context));
                }(),
              ),
            // ── Amount (right-aligned #3) — hidden for transfers (shown inline)
            if (!isTransfer)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildAmountColumn(context, ref, typeColor),
            ),
          ],
        ),
      ),
      ),
      ),
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

  String _buildDisplayName(BuildContext context, String? catName) {
    final tx = entry.tx;
    final lines = entry.lines;

    if (catName != null) return catName;

    // Multi-line: show first category names
    if (lines.length > 1) {
      final names = lines
          .take(2)
          .map((l) =>
              l.categoryId != null ? categoryMap[l.categoryId]?.name : null)
          .whereType<String>()
          .toList();
      if (names.isEmpty) return S.of(context).txNItems(lines.length);
      final extra = lines.length - names.length;
      return extra > 0
          ? '${names.join(', ')} ${S.of(context).txNMore(extra)}'
          : names.join(', ');
    }

    if (tx.note.isNotEmpty) return visibleNote(tx.note);
    return _typeLabel(context, tx.type);
  }

  String? _buildNote(String? catName) {
    final tx = entry.tx;
    final lines = entry.lines;

    // If we have a category name, show note as subtitle (if any)
    if (catName != null && tx.note.isNotEmpty) {
      return visibleNote(tx.note);
    }

    // Show account name as subtitle if we have a display name already
    final involvedAccounts = entry.involvedAccountNames;
    if (involvedAccounts.length > 1) {
      return involvedAccounts.join(' · ');
    }

    // Show single line note if different from display name
    if (lines.isNotEmpty && lines.first.note.isNotEmpty && catName != null) {
      return lines.first.note;
    }

    return null;
  }

  /// Note preview (#7): show tx note as a third line if it isn't already
  /// used as the display name or the subtitle from _buildNote.
  String? _buildNotePreview(String? catName, String displayName) {
    final tx = entry.tx;
    final lines = entry.lines;
    if (tx.note.isEmpty && (lines.isEmpty || lines.first.note.isEmpty)) {
      return null;
    }
    // If note is already the display name, skip
    if (tx.note == displayName) return null;
    // If _buildNote already returns the tx.note as subtitle, skip
    if (catName != null && tx.note.isNotEmpty) return null;
    // Show line-level note if it exists and differs from display
    if (lines.isNotEmpty && lines.first.note.isNotEmpty) {
      final lineNote = lines.first.note;
      if (lineNote != displayName) return lineNote;
    }
    // Show tx note as preview if it exists and not shown elsewhere
    if (tx.note.isNotEmpty) return visibleNote(tx.note);
    return null;
  }

  Widget _transferSubRow(
    BuildContext context,
    String accountName,
    double amount,
    String currency,
    Color dotColor,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            accountName,
            style: TextStyle(fontSize: 13, color: AppColors.ts(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '• ${formatAmount(amount, currency: currency)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.tp(context),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAmountColumn(BuildContext context, WidgetRef ref, Color typeColor) {
    final tx = entry.tx;
    final lines = entry.lines;
    final isTransfer = tx.type == 'transfer';

    String displayCurrency = tx.currency;
    double displayAmount = tx.amount;

    if (lines.length == 1) {
      // Single line: show in the line's native currency
      displayCurrency = lines.first.currency;
      displayAmount = lines.first.amount;
    } else if (lines.length > 1) {
      // Multi-line: check if all lines share the same currency
      final currencies = lines.map((l) => l.currency).toSet();
      if (currencies.length == 1 && currencies.first != tx.currency) {
        // All lines same foreign currency — show total in that currency
        displayCurrency = currencies.first;
        displayAmount = lines.fold(0.0, (s, l) => s + l.amount);
      } else {
        // Mixed currencies: compute base total, skipping lines with unset rate
        double baseTotal = 0;
        for (final l in lines) {
          if (l.currency == tx.currency) {
            baseTotal += l.amount;
          } else if ((l.exchangeRateToBase - 1.0).abs() >= 0.001) {
            baseTotal += l.amount * l.exchangeRateToBase;
          }
        }
        displayAmount = baseTotal;
      }
    }

    // For transfers: show source amount in source currency
    // with destination amount as conversion badge
    final destAmount = isTransfer ? tx.amount * tx.exchangeRateToBase : 0.0;
    final destCurrency = isTransfer
        ? (entry.destinationAccountCurrency ?? tx.currency)
        : tx.currency;

    final baseCurrency = tx.currency;
    final baseAmount = tx.amount;
    // Only show conversion badge if currencies differ AND at least one line
    // has a real exchange rate (not the default 1.0).
    final hasRealConversion = lines.isNotEmpty &&
        lines.any((l) => (l.exchangeRateToBase - 1.0).abs() > 0.001);
    final showConversion =
        !isTransfer && displayCurrency != baseCurrency && hasRealConversion;
    // For transfers: show destination currency if different
    final showTransferConversion = isTransfer &&
        destCurrency != displayCurrency &&
        (tx.exchangeRateToBase - 1.0).abs() > 0.001;

    final effectiveType = tx.type;

    // Show running balance only when a single account is involved
    final isSingleAccount = entry.involvedAccountNames.length <= 1;

    return [
      // Amount right-aligned (#3)
      Text(
        formatSignedAmount(displayAmount, currency: displayCurrency, type: effectiveType),
        textAlign: TextAlign.end,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: typeColor,
        ),
      ),
      // Multi-currency badge (#8) — show pill instead of full conversion text
      if (showConversion)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  displayCurrency,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                formatAmount(baseAmount, currency: baseCurrency),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.th(context),
                ),
              ),
            ],
          ),
        ),
      // Transfer: show destination amount if cross-currency
      if (showTransferConversion)
        Text(
          '→ ${formatAmount(destAmount, currency: destCurrency)}',
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: 11, color: AppColors.th(context)),
        ),
      if (showBalance && (isSingleAccount || isTransfer))
        Text(
          '${entry.accountName}: ${formatAmount(entry.accountBalanceAfter, currency: entry.accountCurrency)}',
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: 11, color: AppColors.th(context)),
        ),
      if (showBalance && !isSingleAccount)
        Text(
          S.of(context).txNAccounts(entry.involvedAccountNames.length),
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.th(context),
          ),
        ),
    ];
  }

  String _typeLabel(BuildContext context, String type) => switch (type) {
        'income' => S.of(context).typeIncome,
        'expense' => S.of(context).typeExpense,
        'transfer' => S.of(context).typeTransfer,
        _ => type,
      };
}
