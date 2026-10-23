import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/dashboard_layout_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/sheet_title.dart';

/// Bottom sheet for reordering and toggling dashboard sections.
void showDashboardCustomizeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CustomizeSheet(),
  );
}

class _CustomizeSheet extends ConsumerWidget {
  const _CustomizeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(dashboardLayoutProvider);
    final notifier = ref.read(dashboardLayoutProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          SheetTitle(
            S.of(context).customizeTitle,
            subtitle: S.of(context).customizeDesc,
            trailing: TextButton(
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);
                final done = S.of(context).customizeResetDone;
                notifier.reset();
                Navigator.pop(context);
                messenger.showSnackBar(SnackBar(
                  content: Text(done),
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: Text(S.of(context).commonReset),
            ),
          ),
          // Reorderable list
          Expanded(
            child: ReorderableListView.builder(
              scrollController: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: sections.length,
              // onReorderItem already adjusts newIndex; reorder() expects the raw one.
              onReorderItem: (from, to) =>
                  notifier.reorder(from, to > from ? to + 1 : to),
              proxyDecorator: (child, _, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (_, __) => Material(
                    elevation: 4,
                    borderRadius: CardTokens.borderRadius,
                    child: child,
                  ),
                );
              },
              itemBuilder: (_, i) {
                final config = sections[i];
                return Container(
                  key: ValueKey(config.section),
                  margin: const EdgeInsets.only(bottom: Spacing.xs),
                  // Inside a sheet: the container color, not a card (a card
                  // is the sheet's own color in dark mode).
                  decoration: BoxDecoration(
                    color: AppColors.sfv(context),
                    borderRadius: CardTokens.borderRadius,
                  ),
                  child: Material(
                    // Transparent Material so the ripple paints above the card fill.
                    type: MaterialType.transparency,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: CardTokens.borderRadius),
                      leading: Icon(
                        AppIcons.dotsSixVertical,
                        color: AppColors.th(context),
                      ),
                      title: Text(_sectionLabel(S.of(context), config.section),
                          style: TextStyle(
                              fontSize: TypographyTokens.cardTitleSize,
                              fontWeight: TypographyTokens.cardTitleWeight,
                              color: config.visible
                                  ? AppColors.tp(context)
                                  : AppColors.th(context))),
                      subtitle: Text(_sectionDesc(S.of(context), config.section),
                          style: TextStyle(
                              fontSize: TypographyTokens.captionSize,
                              color: AppColors.ts(context))),
                      trailing: Switch.adaptive(
                        value: config.visible,
                        onChanged: (_) =>
                            notifier.toggleVisibility(config.section),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _sectionLabel(S l, DashboardSection s) => switch (s) {
      DashboardSection.budget => l.dashboardSectionBudgetLabel,
      DashboardSection.quickActions => l.dashboardSectionQuickLabel,
      DashboardSection.spending => l.dashboardSectionSpendingLabel,
      DashboardSection.money => l.dashboardSectionMoneyLabel,
      DashboardSection.activity => l.dashboardSectionActivityLabel,
    };

String _sectionDesc(S l, DashboardSection s) => switch (s) {
      DashboardSection.budget => l.dashboardSectionBudgetDesc,
      DashboardSection.quickActions => l.dashboardSectionQuickDesc,
      DashboardSection.spending => l.dashboardSectionSpendingDesc,
      DashboardSection.money => l.dashboardSectionMoneyDesc,
      DashboardSection.activity => l.dashboardSectionActivityDesc,
    };
