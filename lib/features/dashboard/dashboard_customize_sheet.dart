import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/dashboard_layout_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';

/// Bottom sheet for reordering and toggling dashboard sections.
void showDashboardCustomizeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.sf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
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
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.th(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context).customizeTitle,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tp(context))),
                TextButton(
                  onPressed: () {
                    notifier.reset();
                    Navigator.pop(context);
                  },
                  child: Text(S.of(context).commonReset),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              S.of(context).customizeDesc,
              style: TextStyle(fontSize: 12, color: AppColors.ts(context)),
            ),
          ),
          const SizedBox(height: 12),
          // Reorderable list
          Expanded(
            child: ReorderableListView.builder(
              scrollController: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: sections.length,
              onReorder: notifier.reorder,
              proxyDecorator: (child, _, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (_, __) => Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  ),
                );
              },
              itemBuilder: (_, i) {
                final config = sections[i];
                return Container(
                  key: ValueKey(config.section),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.bd(context)),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.drag_handle_rounded,
                      color: AppColors.th(context),
                    ),
                    title: Text(config.section.label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: config.visible
                                ? AppColors.tp(context)
                                : AppColors.th(context))),
                    subtitle: Text(config.section.description,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.ts(context))),
                    trailing: Switch.adaptive(
                      value: config.visible,
                      onChanged: (_) =>
                          notifier.toggleVisibility(config.section),
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
