import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/objectives_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/budget_progress.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/tappable.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/widgets/category_icon.dart';

class ObjectivesScreen extends ConsumerWidget {
  const ObjectivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectivesAsync = ref.watch(objectivesProvider);

    final tr = S.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: tr.objNewTitle,
        onPressed: () => context.push('/objectives/new'),
        child: const Icon(AppIcons.plus),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(objectivesProvider.future),
        child: CustomScrollView(
          slivers: [
            LargeTitleHeader(title: tr.objTitle, back: true),
            ...objectivesAsync.when(
              loading: () => const [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SkeletonList(),
                  ),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorRetry(
                    message: tr.objFailedToLoad,
                    details: e.toString(),
                    onRetry: () => ref.invalidate(objectivesProvider),
                  ),
                ),
              ],
              data: (items) {
                if (items.isEmpty) {
                  // No action button: the FAB already adds one.
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        art: true,
                        icon: AppIcons.flag,
                        title: tr.objNoTitle,
                        subtitle: tr.objIntro,
                      ),
                    ),
                  ];
                }

                final goals = items.where((o) => o.type == 'goal').toList();
                final loans = items.where((o) => o.type == 'loan').toList();

                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Short explanation of what this screen tracks
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            tr.objIntro,
                            style: TextStyle(
                                fontSize: TypographyTokens.captionSize,
                                height: 1.4,
                                color: AppColors.ts(context)),
                          ),
                        ),
                        if (goals.isNotEmpty) ...[
                          _SectionHeader(
                              title: tr.objGoalsSection, count: goals.length),
                          const SizedBox(height: Spacing.headerToCard),
                          ...goals.map((o) => _ObjectiveCard(objective: o)),
                          const SizedBox(height: Spacing.sectionGap),
                        ],
                        if (loans.isNotEmpty) ...[
                          _SectionHeader(
                              title: tr.objLoansSection, count: loans.length),
                          const SizedBox(height: Spacing.headerToCard),
                          ...loans.map((o) => _ObjectiveCard(objective: o)),
                        ],
                      ]),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SectionHeader(title),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.sfv(context),
            borderRadius: BorderRadius.circular(RadiusTokens.pill),
          ),
          child: Text('$count',
              style: TextStyle(
                fontSize: TypographyTokens.overlineSize,
                fontWeight: TypographyTokens.overlineWeight,
                color: AppColors.ts(context),
              )),
        ),
      ],
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  final Objective objective;
  const _ObjectiveCard({required this.objective});

  @override
  Widget build(BuildContext context) {
    final o = objective;
    final color = AppColors.fromHex(o.colorHex);
    final progress = o.targetAmount > 0
        ? (o.currentAmount / o.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final isLoan = o.type == 'loan';
    final isLent = o.direction == 'lent';

    // Cashew objective card: tinted with the goal's color, big type, thick bar.
    final radius = BorderRadius.circular(RadiusTokens.hero);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tappable(
        onTap: () => context.push('/objectives/${o.id}'),
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.pastel(context, color, light: 0.88, dark: 0.8),
            borderRadius: radius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + name + amount
            Row(
              children: [
                Container(
                  width: CategoryIconTokens.listSize,
                  height: CategoryIconTokens.listSize,
                  decoration: BoxDecoration(
                    color: AppColors.pastel(context, color,
                        light: 0.55, dark: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: o.icon != null && o.icon!.isNotEmpty
                        ? EmojiGlyph(o.icon!, size: 26)
                        : Icon(
                            isLoan ? AppIcons.handshake : AppIcons.flag,
                            color: AppColors.pastel(context, color,
                                light: 0.5, dark: 0.5, inverse: true),
                            size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tp(context),
                          )),
                      if (isLoan && o.contactName != null)
                        Text(
                          isLent ? S.of(context).objLentTo(o.contactName!) : S.of(context).objBorrowedFrom(o.contactName!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: TypographyTokens.captionSize,
                            color: AppColors.ts(context),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(o.currentAmount, currency: o.targetCurrency),
                      style: TextStyle(
                        fontSize: TypographyTokens.amountDisplaySize,
                        fontWeight: TypographyTokens.amountDisplayWeight,
                        color: AppColors.tp(context),
                      ),
                    ),
                    if (o.targetAmount > 0)
                      Text(
                        S.of(context).objOfTarget(formatAmount(o.targetAmount,
                            currency: o.targetCurrency)),
                        style: TextStyle(
                          fontSize: TypographyTokens.captionSize,
                          color: AppColors.ts(context),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Progress bar
            if (o.targetAmount > 0) ...[
              const SizedBox(height: 14),
              BudgetProgress(
                progress: progress,
                color: color,
                height: 20,
                showPercent: true,
              ),
            ],
            // Deadline
            if (o.endDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(AppIcons.calendarBlank,
                      size: 13, color: AppColors.th(context)),
                  const SizedBox(width: 6),
                  Text(
                    S.of(context).objDue(formatDate(o.endDate!)),
                    style: TextStyle(
                      fontSize: 12,
                      color: () {
                        final today = DateTime.now();
                        return o.endDate!.isBefore(DateTime(today.year, today.month, today.day))
                            ? AppColors.overspent
                            : AppColors.th(context);
                      }(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
          ),
        ),
      ),
    );
  }

}
