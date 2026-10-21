import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/getting_started_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/widgets/app_card.dart';

/// Home's checklist for a new budget: record income → create envelopes →
/// fund them → log an expense. Each step ticks itself from real data
/// ([gettingStartedProvider]); the card goes away for good once all four
/// are done or the user closes it.
class GettingStartedCard extends ConsumerWidget {
  const GettingStartedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(gettingStartedHiddenProvider)) return const SizedBox.shrink();
    final progress = ref.watch(gettingStartedProvider).value;
    if (progress == null) return const SizedBox.shrink();
    if (progress.allDone) {
      // Done once = done: don't bring the card back if data is deleted.
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(gettingStartedHiddenProvider.notifier).hide());
      return const SizedBox.shrink();
    }

    final s = S.of(context);
    final steps = [
      (
        done: progress.income,
        title: s.gsIncomeTitle,
        body: s.gsIncomeBody,
        go: () => context.push('/add-transaction',
            extra: {'editType': 'income'}),
      ),
      (
        done: progress.envelopes,
        title: s.gsEnvelopesTitle,
        body: s.gsEnvelopesBody,
        go: () => context.push('/allocations/new'),
      ),
      (
        done: progress.funded,
        title: s.gsFundTitle,
        body: s.gsFundBody,
        go: () => context.push('/funding'),
      ),
      (
        done: progress.expense,
        title: s.gsExpenseTitle,
        body: s.gsExpenseBody,
        go: () => context.push('/add-transaction',
            extra: {'editType': 'expense'}),
      ),
    ];
    final next = steps.indexWhere((st) => !st.done);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(s.gsTitle,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tp(context))),
                ),
                Text(s.gsProgress(progress.doneCount, steps.length),
                    style:
                        TextStyle(fontSize: 13, color: AppColors.ts(context))),
                IconButton(
                  tooltip: s.gsHide,
                  icon: Icon(AppIcons.x, size: 18, color: AppColors.th(context)),
                  onPressed: () =>
                      ref.read(gettingStartedHiddenProvider.notifier).hide(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12, bottom: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.doneCount / steps.length,
                  minHeight: 6,
                  color: AppColors.accent,
                  backgroundColor: AppColors.sfv(context),
                ),
              ),
            ),
            for (var i = 0; i < steps.length; i++)
              _StepRow(
                title: steps[i].title,
                body: i == next ? steps[i].body : null,
                done: steps[i].done,
                isNext: i == next,
                onTap: steps[i].done ? null : steps[i].go,
              ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String title;
  final String? body;
  final bool done;
  final bool isNext;
  final VoidCallback? onTap;

  const _StepRow({
    required this.title,
    required this.body,
    required this.done,
    required this.isNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget mark = done
        ? Icon(AppIcons.checkCircleFill, size: 24, color: AppColors.accent)
        : Icon(AppIcons.circle,
            size: 24,
            color: isNext ? AppColors.accent : AppColors.th(context));
    return Semantics(
      checked: done,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mark,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isNext ? FontWeight.w700 : FontWeight.w600,
                              color: done
                                  ? AppColors.ts(context)
                                  : AppColors.tp(context))),
                    ),
                    if (body != null) ...[
                      const SizedBox(height: 2),
                      Text(body!,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.ts(context))),
                    ],
                  ],
                ),
              ),
              if (!done)
                Icon(AppIcons.caretRight,
                    size: 18, color: AppColors.th(context)),
            ],
          ),
        ),
      ),
    );
  }
}
