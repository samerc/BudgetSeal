import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/date_format_provider.dart';
import '../../core/providers/objectives_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/utils/format_number.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../l10n/generated/app_localizations.dart';

class ObjectivesScreen extends ConsumerWidget {
  const ObjectivesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectivesAsync = ref.watch(objectivesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      S.of(context).objTitle,
                      style: TextStyle(
                        fontSize: TypographyTokens.screenTitleSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tp(context),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push('/objectives/new'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(S.of(context).commonAdd),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: objectivesAsync.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorRetry(
          message: S.of(context).objFailedToLoad,
          details: e.toString(),
          onRetry: () => ref.invalidate(objectivesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.flag_rounded,
              title: S.of(context).objNoTitle,
              subtitle: S.of(context).objIntro,
              actionLabel: S.of(context).objCreateFirst,
              onAction: () => context.push('/objectives/new'),
            );
          }

          final goals = items.where((o) => o.type == 'goal').toList();
          final loans = items.where((o) => o.type == 'loan').toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(objectivesProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Short explanation of what this screen tracks
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    S.of(context).objIntro,
                    style: TextStyle(
                        fontSize: 12, height: 1.4, color: AppColors.th(context)),
                  ),
                ),
                if (goals.isNotEmpty) ...[
                  _SectionHeader(title: S.of(context).objGoalsSection, count: goals.length),
                  const SizedBox(height: 8),
                  ...goals.map((o) => _ObjectiveCard(objective: o)),
                  const SizedBox(height: 20),
                ],
                if (loans.isNotEmpty) ...[
                  _SectionHeader(title: S.of(context).objLoansSection, count: loans.length),
                  const SizedBox(height: 8),
                  ...loans.map((o) => _ObjectiveCard(objective: o)),
                ],
              ],
            ),
          );
        },
              ),
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
        Text(title,
            style: TextStyle(
              fontSize: TypographyTokens.sectionHeaderSize,
              fontWeight: TypographyTokens.sectionHeaderWeight,
              letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
              color: AppColors.ts(context),
            )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.sfv(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
    final pctText = '${(progress * 100).toStringAsFixed(0)}%';
    final isLoan = o.type == 'loan';
    final isLent = o.direction == 'lent';

    return AppCard(
      onTap: () => context.push('/objectives/${o.id}'),
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + name + amount
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: o.icon != null && o.icon!.isNotEmpty
                        ? Text(o.icon!, style: const TextStyle(fontSize: 20))
                        : Icon(
                            isLoan ? Icons.handshake_rounded : Icons.flag_rounded,
                            color: color, size: 20),
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
                            fontSize: TypographyTokens.cardTitleSize,
                            fontWeight: TypographyTokens.cardTitleWeight,
                            color: AppColors.tp(context),
                          )),
                      if (isLoan && o.contactName != null)
                        Text(
                          isLent ? S.of(context).objLentTo(o.contactName!) : S.of(context).objBorrowedFrom(o.contactName!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
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
                        fontSize: TypographyTokens.amountRegularSize,
                        fontWeight: TypographyTokens.amountRegularWeight,
                        color: AppColors.tp(context),
                      ),
                    ),
                    if (o.targetAmount > 0)
                      Text(
                        'of ${formatAmount(o.targetAmount, currency: o.targetCurrency)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.th(context),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Progress bar
            if (o.targetAmount > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.bd(context),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(pctText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      )),
                ],
              ),
            ],
            // Deadline
            if (o.endDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
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
    );
  }

}
