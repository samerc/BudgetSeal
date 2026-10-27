import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/engine/period_engine.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/bottom_action_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/theme/app_icons.dart';
import '../allocations/option_card.dart';

/// Data passed to the [LeftoverResolutionScreen] via GoRouter extras.
class LeftoverResolutionArgs {
  final String allocationId;
  final String allocationName;

  const LeftoverResolutionArgs({
    required this.allocationId,
    required this.allocationName,
  });
}

class LeftoverResolutionScreen extends ConsumerStatefulWidget {
  const LeftoverResolutionScreen({super.key});

  @override
  ConsumerState<LeftoverResolutionScreen> createState() =>
      _LeftoverResolutionScreenState();
}

class _LeftoverResolutionScreenState
    extends ConsumerState<LeftoverResolutionScreen> {
  LeftoverResolution _resolution = LeftoverResolution.toUnallocated;
  String? _targetAllocationId;
  String? _selectedCurrency; // null means resolve all currencies
  bool _saving = false;

  LeftoverResolutionArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= GoRouterState.of(context).extra as LeftoverResolutionArgs?;
  }

  AllocationWithBalance? _findAllocation(List<AllocationWithBalance> list) {
    if (_args == null) return null;
    try {
      return list.firstWhere(
        (a) => a.data.allocation.id == _args!.allocationId,
      );
    } catch (e) {
      debugPrint('Allocation not found: $e');
      return null;
    }
  }

  Future<void> _save(AllocationWithBalance allocation) async {
    setState(() => _saving = true);
    try {
      final engine = ref.read(periodEngineProvider);

      final currencies = _selectedCurrency != null
          ? {_selectedCurrency!: allocation.balanceByCurrency[_selectedCurrency!] ?? 0.0}
          : Map<String, double>.from(allocation.balanceByCurrency);

      for (final entry in currencies.entries) {
        if (entry.value <= 0) continue;

        await engine.resolveLeftover(
          allocationId: allocation.data.allocation.id,
          currency: entry.key,
          leftoverAmount: entry.value,
          resolution: _resolution,
          deviceId: 'local',
          targetAllocationId: _targetAllocationId,
        );
      }

      ref.invalidate(allocationsProvider);
      ref.invalidate(unallocatedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(S.of(context).leftoverResolved),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(S.of(context).leftoverResolveFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allocationsAsync = ref.watch(visibleAllocationsProvider);
    final textTheme = Theme.of(context).textTheme;

    if (_args == null) {
      return Scaffold(
        appBar: AppBar(title: Text(S.of(context).leftoverTitle)),
        body: EmptyState(
          icon: AppIcons.piggyBank,
          title: S.of(context).leftoverNoAllocation,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).leftoverTitle)),
      body: allocationsAsync.when(
        loading: () => const SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 8),
              child: SkeletonList()),
        error: (e, _) => ErrorRetry(
          message: S.of(context).leftoverLoadError,
          details: '$e',
          onRetry: () => ref.invalidate(allocationsProvider),
        ),
        data: (allocations) {
          final allocation = _findAllocation(allocations);
          if (allocation == null) {
            return EmptyState(
              icon: AppIcons.piggyBank,
              title: S.of(context).leftoverNotFound,
            );
          }

          final otherAllocations = allocations
              .where((a) =>
                  a.data.allocation.id != allocation.data.allocation.id)
              .toList();

          final positiveBalances = allocation.balanceByCurrency.entries
              .where((e) => e.value > 0)
              .toList();

          final hasPositiveBalance = positiveBalances.isNotEmpty;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Allocation info card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: CategoryIconTokens.compactSize,
                                  height: CategoryIconTokens.compactSize,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    AppIcons.wallet,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _args!.allocationName,
                                        style: textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        allocation.data.allocation.rollover
                                            ? S.of(context).periodRollover
                                            : S.of(context).periodPeriodic,
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            // Balance breakdown
                            Text(
                              S.of(context).leftoverCurrentBalance,
                              style: TextStyle(
                                fontSize: TypographyTokens.captionSize,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ts(context),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (allocation.balanceByCurrency.isEmpty)
                              Text(
                                S.of(context).leftoverNoBalance,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.th(context),
                                ),
                              )
                            else
                              ...allocation.balanceByCurrency.entries
                                  .map((entry) => _BalanceRow(
                                        currency: entry.key,
                                        amount: entry.value,
                                      )),
                          ],
                        ),
                      ),

                      if (!hasPositiveBalance) ...[
                        const SizedBox(height: 16),
                        EmptyState(
                          icon: AppIcons.info,
                          title: S.of(context).leftoverNoPositive,
                        ),
                      ],

                      if (hasPositiveBalance) ...[
                        const SizedBox(height: 24),

                        // Currency selector (if multi-currency)
                        if (positiveBalances.length > 1) ...[
                          SectionHeader(
                            S.of(context).leftoverCurrencyToResolve,
                            padding: const EdgeInsetsDirectional.only(
                                start: 4, bottom: Spacing.headerToCard),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.sfv(context),
                              borderRadius:
                                  BorderRadius.circular(RadiusTokens.md),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                icon: AppIcons.dropdown,
                                isExpanded: true,
                                value: _selectedCurrency,
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(S.of(context).leftoverAllCurrencies),
                                  ),
                                  ...positiveBalances.map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                        formatAmount(e.value, currency: e.key),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedCurrency = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Resolution choices
                        SectionHeader(
                          S.of(context).leftoverWhatToDo,
                          padding: const EdgeInsetsDirectional.only(
                              start: 4, bottom: Spacing.headerToCard),
                        ),

                        OptionCard(
                          icon: AppIcons.arrowCounterClockwise,
                          title: S.of(context).periodReturnUnallocated,
                          subtitle:
                              S.of(context).leftoverReturnSubtitle,
                          selected: _resolution ==
                              LeftoverResolution.toUnallocated,
                          onTap: () => setState(() {
                            _resolution = LeftoverResolution.toUnallocated;
                            _targetAllocationId = null;
                          }),
                        ),
                        const SizedBox(height: 8),

                        OptionCard(
                          icon: AppIcons.arrowBendUpRight,
                          title: S.of(context).periodCarryForward,
                          subtitle: S.of(context).leftoverKeepSubtitle,
                          selected: _resolution == LeftoverResolution.keep,
                          onTap: () => setState(() {
                            _resolution = LeftoverResolution.keep;
                            _targetAllocationId = null;
                          }),
                        ),
                        const SizedBox(height: 8),

                        OptionCard(
                          icon: AppIcons.arrowsLeftRight,
                          title: S.of(context).leftoverMoveTitle,
                          subtitle:
                              S.of(context).leftoverMoveSubtitle,
                          selected: _resolution ==
                              LeftoverResolution.toOtherAllocation,
                          onTap: () => setState(() => _resolution =
                              LeftoverResolution.toOtherAllocation),
                        ),

                        // Target allocation picker
                        if (_resolution ==
                            LeftoverResolution.toOtherAllocation) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.sfv(context),
                                borderRadius:
                                    BorderRadius.circular(RadiusTokens.md),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  icon: AppIcons.dropdown,
                                  isExpanded: true,
                                  hint: Text(S.of(context).periodSelectAllocation),
                                  value: _targetAllocationId,
                                  items: otherAllocations
                                      .map((a) => DropdownMenuItem(
                                            value: a.data.allocation.id,
                                            child: Text(
                                                a.data.allocation.name),
                                          ))
                                      .toList(),
                                  onChanged: (id) => setState(
                                      () => _targetAllocationId = id),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom save button
              if (hasPositiveBalance)
                BottomActionBar(
                  children: [
                    FilledButton(
                      onPressed: _saving ||
                              (_resolution ==
                                      LeftoverResolution.toOtherAllocation &&
                                  _targetAllocationId == null)
                          ? null
                          : () => _save(allocation),
                      child: _saving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.onAccent,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(S.of(context).commonSave),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balance row widget
// ---------------------------------------------------------------------------

class _BalanceRow extends StatelessWidget {
  final String currency;
  final double amount;

  const _BalanceRow({required this.currency, required this.amount});

  @override
  Widget build(BuildContext context) {
    final isPositive = amount > 0;
    final color = amount < 0
        ? AppColors.overspent
        : isPositive
            ? AppColors.healthy
            : AppColors.ts(context);
    final bgColor = amount < 0
        ? AppColors.pastel(context, AppColors.overspent,
            light: 0.85, dark: 0.75)
        : isPositive
            ? AppColors.pastel(context, AppColors.healthy,
                light: 0.85, dark: 0.75)
            : AppColors.sfv(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            currency,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
            ),
            child: Text(
              formatAmount(amount, currency: currency),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
