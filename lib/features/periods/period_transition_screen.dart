import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/engine/period_engine.dart';
import '../../core/providers/allocations_provider.dart';
import '../../core/providers/engine_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../core/providers/household_provider.dart';
import '../../core/providers/period_reset_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/error_retry.dart';
import '../../core/providers/date_format_provider.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/bottom_action_bar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../allocations/option_card.dart';

/// Tracks the user's chosen resolution for a single allocation + currency pair.
class _AllocationResolution {
  final String allocationId;
  final String allocationName;
  final String currency;
  final double balance;
  final bool rolloverDefault;
  LeftoverResolution resolution;
  String? targetAllocationId;

  _AllocationResolution({
    required this.allocationId,
    required this.allocationName,
    required this.currency,
    required this.balance,
    required this.rolloverDefault,
  }) : resolution = rolloverDefault
            ? LeftoverResolution.keep
            : LeftoverResolution.toUnallocated;
}

class PeriodTransitionScreen extends ConsumerStatefulWidget {
  const PeriodTransitionScreen({super.key});

  @override
  ConsumerState<PeriodTransitionScreen> createState() =>
      _PeriodTransitionScreenState();
}

class _PeriodTransitionScreenState
    extends ConsumerState<PeriodTransitionScreen> {
  List<_AllocationResolution> _resolutions = [];
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _buildResolutions();
  }

  void _buildResolutions() {
    // Defer to after first frame so providers are available.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Only envelopes waiting for this period's review (manual reset) —
      // auto-reset ones were handled at launch, and an envelope reviewed
      // already (or opened mid-period) must not lose its funding.
      final List<String> pending;
      try {
        pending = await ref.read(pendingResetProvider.future);
      } catch (_) {
        return;
      }
      if (!mounted) return;
      final allocationsAsync = ref.read(visibleAllocationsProvider);
      allocationsAsync.whenData((allocations) {
        final items = <_AllocationResolution>[];
        for (final a in allocations) {
          if (!pending.contains(a.data.allocation.id)) continue;

          for (final entry in a.balanceByCurrency.entries) {
            // Leftovers and overspending (negative) both need a decision.
            if (entry.value.abs() > 0.005) {
              items.add(_AllocationResolution(
                allocationId: a.data.allocation.id,
                allocationName: a.data.allocation.name,
                currency: entry.key,
                balance: entry.value,
                rolloverDefault: a.data.allocation.rollover,
              ));
            }
          }
        }
        if (mounted) setState(() => _resolutions = items);
      });
    });
  }

  Future<void> _completeTransition() async {
    setState(() => _completing = true);
    try {
      final engine = ref.read(periodEngineProvider);

      // All choices or none: a failure halfway must not leave some
      // envelopes reviewed and others not.
      await engine.inTransaction(() async {
        for (final r in _resolutions) {
          await engine.resolveLeftover(
            allocationId: r.allocationId,
            currency: r.currency,
            leftoverAmount: r.balance,
            resolution: r.resolution,
            deviceId: 'local',
            targetAllocationId: r.targetAllocationId,
          );
        }
      });

      ref.invalidate(allocationsProvider);
      ref.invalidate(unallocatedProvider);
      ref.invalidate(pendingResetProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(S.of(context).periodTransitionDone),
          ),
        );
        context.pop(); // close period transition
        context.push('/funding'); // open funding as a new route
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(S.of(context).periodTransitionFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(householdProvider);
    final allocationsAsync = ref.watch(visibleAllocationsProvider);
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).periodNewTitle),
        automaticallyImplyLeading: true,
      ),
      body: allocationsAsync.when(
        loading: () => const SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 8),
              child: SkeletonList()),
        error: (e, _) => ErrorRetry(
          message: S.of(context).periodError,
          details: '$e',
          onRetry: () => ref.invalidate(allocationsProvider),
        ),
        data: (_) => Column(
          children: [
            // Header banner
            Builder(builder: (_) {
              final household = householdAsync.value;
              final startDay = household?.periodStartDay ?? 1;
              final periodStart = budgetPeriodFor(startDay, now).start;
              return AppCard(
                margin: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: CategoryIconTokens.compactSize,
                      height: CategoryIconTokens.compactSize,
                      decoration: BoxDecoration(
                        color: AppColors.pastel(context, AppColors.accent,
                            light: 0.85, dark: 0.78),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(AppIcons.calendarBlank,
                          color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.of(context).periodNewTitle,
                              style: TextStyle(
                                color: AppColors.tp(context),
                                fontSize: TypographyTokens.sheetTitleSize,
                                fontWeight: TypographyTokens.sheetTitleWeight,
                              )),
                          const SizedBox(height: 3),
                          Text(
                            S.of(context).periodStartsEachMonth(formatDate(periodStart), startDay),
                            style: TextStyle(
                              color: AppColors.ts(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Subheading
            SectionHeader(
              S.of(context).periodResolveLeftovers,
              padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 4),
              trailing: Text(
                S.of(context).periodNItems(_resolutions.length),
                style: textTheme.bodySmall,
              ),
            ),

            // Allocation list
            Expanded(
              child: _resolutions.isEmpty
                  ? EmptyState(
                      icon: AppIcons.checkCircle,
                      title: S.of(context).periodNoLeftovers,
                      subtitle: S.of(context).periodAllZero,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _resolutions.length,
                      itemBuilder: (context, i) => _ResolutionCard(
                        resolution: _resolutions[i],
                        allAllocations: ref.read(visibleAllocationsProvider)
                                .value
                                ?.where((a) =>
                                    a.data.allocation.id !=
                                    _resolutions[i].allocationId)
                                .toList() ??
                            [],
                        onChanged: () => setState(() {}),
                      ),
                    ),
            ),

            // Bottom action area
            BottomActionBar(
              children: [
                FilledButton(
                  // Every "Move to" needs its envelope chosen first.
                  onPressed: _completing ||
                          _resolutions.any((r) =>
                              r.resolution ==
                                  LeftoverResolution.toOtherAllocation &&
                              r.balance > 0 &&
                              r.targetAllocationId == null)
                      ? null
                      : _completeTransition,
                  child: _completing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.onAccent,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(S.of(context).periodCompleteButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Resolution card for a single allocation + currency
// ---------------------------------------------------------------------------

class _ResolutionCard extends StatelessWidget {
  final _AllocationResolution resolution;
  final List<AllocationWithBalance> allAllocations;
  final VoidCallback onChanged;

  const _ResolutionCard({
    required this.resolution,
    required this.allAllocations,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final overspent = resolution.balance < 0;

    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: name + balance
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolution.allocationName,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        resolution.rolloverDefault
                            ? S.of(context).periodRollover
                            : S.of(context).periodPeriodic,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.pastel(context,
                        overspent ? AppColors.overspent : AppColors.healthy,
                        light: 0.85, dark: 0.75),
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  ),
                  child: Text(
                    formatAmount(resolution.balance, currency: resolution.currency),
                    style: TextStyle(
                      color: overspent ? AppColors.overspent : AppColors.healthy,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Resolution options
            OptionCard(
              icon: AppIcons.arrowCounterClockwise,
              title: overspent
                  ? S.of(context).periodCoverFromRta
                  : S.of(context).periodReturnUnallocated,
              subtitle: overspent
                  ? S.of(context).periodCoverFromRtaDesc
                  : S.of(context).periodReturnDesc,
              selected:
                  resolution.resolution == LeftoverResolution.toUnallocated,
              onTap: () {
                resolution.resolution = LeftoverResolution.toUnallocated;
                resolution.targetAllocationId = null;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            OptionCard(
              icon: AppIcons.arrowBendUpRight,
              title: overspent
                  ? S.of(context).periodCarryDebt
                  : S.of(context).periodCarryForward,
              subtitle: overspent
                  ? S.of(context).periodCarryDebtDesc
                  : S.of(context).periodCarryDesc,
              selected: resolution.resolution == LeftoverResolution.keep,
              onTap: () {
                resolution.resolution = LeftoverResolution.keep;
                resolution.targetAllocationId = null;
                onChanged();
              },
            ),
            if (!overspent) ...[
              const SizedBox(height: 8),
              OptionCard(
                icon: AppIcons.arrowsLeftRight,
                title: S.of(context).periodMoveTo,
                subtitle: S.of(context).periodMoveDesc,
                selected: resolution.resolution ==
                    LeftoverResolution.toOtherAllocation,
                onTap: () {
                  resolution.resolution = LeftoverResolution.toOtherAllocation;
                  onChanged();
                },
              ),
            ],

            // Target allocation picker
            if (resolution.resolution == LeftoverResolution.toOtherAllocation)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.sfv(context),
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      icon: AppIcons.dropdown,
                      isExpanded: true,
                      hint: Text(S.of(context).periodSelectAllocation),
                      value: resolution.targetAllocationId,
                      items: allAllocations
                          .map((a) => DropdownMenuItem(
                                value: a.data.allocation.id,
                                child: Text(a.data.allocation.name),
                              ))
                          .toList(),
                      onChanged: (id) {
                        resolution.targetAllocationId = id;
                        onChanged();
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
