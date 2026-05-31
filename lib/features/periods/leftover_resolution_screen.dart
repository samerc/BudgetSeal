import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/engine/period_engine.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/error_retry.dart';

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

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).leftoverResolveFailed),
            backgroundColor: AppColors.overspent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allocationsAsync = ref.watch(allocationsProvider);
    final textTheme = Theme.of(context).textTheme;

    if (_args == null) {
      return Scaffold(
        appBar: AppBar(title: Text(S.of(context).leftoverTitle)),
        body: Center(
          child: Text(S.of(context).leftoverNoAllocation),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).leftoverTitle)),
      body: allocationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: S.of(context).leftoverLoadError,
          details: '$e',
          onRetry: () => ref.invalidate(allocationsProvider),
        ),
        data: (allocations) {
          final allocation = _findAllocation(allocations);
          if (allocation == null) {
            return Center(child: Text(S.of(context).leftoverNotFound));
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Allocation info card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.sf(context),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: AppColors.accent,
                                    size: 22,
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
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
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
                        const SizedBox(height: 32),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 40,
                                color:
                                    AppColors.th(context).withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                S.of(context).leftoverNoPositive,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.ts(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (hasPositiveBalance) ...[
                        const SizedBox(height: 24),

                        // Currency selector (if multi-currency)
                        if (positiveBalances.length > 1) ...[
                          Text(
                            S.of(context).leftoverCurrencyToResolve,
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.sfv(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
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
                                        '${e.key} — ${formatNumber(e.value)}',
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
                        Text(
                          S.of(context).leftoverWhatToDo,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        _ResolutionOption(
                          icon: Icons.replay_rounded,
                          title: S.of(context).periodReturnUnallocated,
                          subtitle:
                              S.of(context).leftoverReturnSubtitle,
                          value: LeftoverResolution.toUnallocated,
                          groupValue: _resolution,
                          onChanged: (v) => setState(() {
                            _resolution = v;
                            _targetAllocationId = null;
                          }),
                        ),
                        const SizedBox(height: 8),

                        _ResolutionOption(
                          icon: Icons.forward_rounded,
                          title: S.of(context).periodCarryForward,
                          subtitle: S.of(context).leftoverKeepSubtitle,
                          value: LeftoverResolution.keep,
                          groupValue: _resolution,
                          onChanged: (v) => setState(() {
                            _resolution = v;
                            _targetAllocationId = null;
                          }),
                        ),
                        const SizedBox(height: 8),

                        _ResolutionOption(
                          icon: Icons.swap_horiz_rounded,
                          title: S.of(context).leftoverMoveTitle,
                          subtitle:
                              S.of(context).leftoverMoveSubtitle,
                          value: LeftoverResolution.toOtherAllocation,
                          groupValue: _resolution,
                          onChanged: (v) =>
                              setState(() => _resolution = v),
                        ),

                        // Target allocation picker
                        if (_resolution ==
                            LeftoverResolution.toOtherAllocation) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.sfv(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
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
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: FilledButton(
                      onPressed: _saving ||
                              (_resolution ==
                                      LeftoverResolution.toOtherAllocation &&
                                  _targetAllocationId == null)
                          ? null
                          : () => _save(allocation),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CardTokens.radius),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              S.of(context).commonSave,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
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
        ? AppColors.overspentLight
        : isPositive
            ? AppColors.healthyLight
            : AppColors.surfaceVariant;

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
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              formatNumber(amount),
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

// ---------------------------------------------------------------------------
// Resolution option radio card
// ---------------------------------------------------------------------------

class _ResolutionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LeftoverResolution value;
  final LeftoverResolution groupValue;
  final ValueChanged<LeftoverResolution> onChanged;

  const _ResolutionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return Material(
      color: selected
          ? AppColors.accentLight.withValues(alpha: 0.3)
          : AppColors.sf(context),
      borderRadius: BorderRadius.circular(CardTokens.radius),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(CardTokens.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.surfaceVariant,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(CardTokens.radius),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.accent : AppColors.th(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.ts(context),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.th(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? AppColors.accent : AppColors.th(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
