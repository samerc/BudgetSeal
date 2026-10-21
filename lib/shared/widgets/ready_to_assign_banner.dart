import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/brand_palette.dart';
import '../theme/design_tokens.dart';
import '../utils/format_number.dart';
import 'currency_display.dart';
import 'seal_mark.dart';
import 'tappable.dart';

/// The gold "Ready to assign" banner (Budget tab and Home): money not yet
/// in an envelope, base currency first with the others behind a toggle,
/// and the ink Assign pill → /funding.
class ReadyToAssignBanner extends StatefulWidget {
  final Map<String, double> unallocated;
  final String baseCurrency;
  final bool hasAllocations;

  const ReadyToAssignBanner({
    super.key,
    required this.unallocated,
    required this.baseCurrency,
    this.hasAllocations = false,
    this.anyFunded = false,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 8),
  });

  final EdgeInsetsGeometry margin;

  /// Some envelope holds money. With nothing left to assign this makes the
  /// banner "All sealed" (a budget that was never funded isn't sealed).
  final bool anyFunded;

  @override
  State<ReadyToAssignBanner> createState() => _ReadyToAssignBannerState();
}

class _ReadyToAssignBannerState extends State<ReadyToAssignBanner>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animController;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _sealed =>
      widget.hasAllocations &&
      widget.anyFunded &&
      widget.unallocated.values.every((v) => v.abs() < 0.005);

  // Set when the banner turns sealed while on screen → stamp the seal on.
  bool _stampNext = false;

  @override
  void didUpdateWidget(ReadyToAssignBanner old) {
    super.didUpdateWidget(old);
    final was = old.hasAllocations &&
        old.anyFunded &&
        old.unallocated.values.every((v) => v.abs() < 0.005);
    if (_sealed && !was) _stampNext = true;
  }

  Widget _buildSealed(BuildContext context, Color fill) {
    final l = S.of(context);
    const ink = brandInk;
    final stamp = _stampNext;
    _stampNext = false;
    return Container(
      margin: widget.margin,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(RadiusTokens.dialog - 5),
      ),
      child: Row(
        children: [
          SealStamp(
              sealed: true, size: 46, stampOnMount: stamp, inverse: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.sealAllSealed,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 24,
                      fontFamily: TypographyTokens.displayFamily,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Text(l.sealAllSealedBody,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    final baseAmount = widget.unallocated[widget.baseCurrency] ?? 0.0;
    final hasOtherCurrencies = widget.unallocated.length > 1;
    // The brand banner: the bright accent in every theme, dark ink on it.
    const ink = brandInk;
    final fill = AppColors.accentBright;
    if (_sealed) return _buildSealed(context, fill);

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(RadiusTokens.dialog - 5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.allocReadyToAssign,
                        style: TextStyle(
                          color: ink.withValues(alpha: 0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Large amounts shrink to one line instead of wrapping.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: CurrencyDisplay(
                          amount: baseAmount,
                          currency: widget.baseCurrency,
                          amountStyle: const TextStyle(
                            color: ink,
                            fontSize: 30,
                            fontFamily: TypographyTokens.displayFamily,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (hasOtherCurrencies)
                        Tappable(
                          onTap: _toggle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _expanded
                                      ? l.allocHideOtherCurrencies
                                      : l.allocOtherCurrencies(
                                          widget.unallocated.length - 1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ink,
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _expanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 250),
                                  child: const Icon(AppIcons.caretDown,
                                      color: ink, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: widget.hasAllocations
                      ? () => context.push('/funding')
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: ink,
                    foregroundColor: fill,
                    disabledBackgroundColor: ink.withValues(alpha: 0.15),
                    disabledForegroundColor: ink.withValues(alpha: 0.45),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    l.allocAssign,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),

          // -- Expandable currency breakdown --
          SizeTransition(
            sizeFactor: _expandAnim,
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightenPastel(fill, 0.35),
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                ),
                child: Column(
                  children: widget.unallocated.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: ink.withValues(alpha: 0.7),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatAmount(e.value, currency: e.key),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: e.value < 0
                                  ? AppColors.darkenPastel(
                                      AppColors.overspent, 0.2)
                                  : ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
