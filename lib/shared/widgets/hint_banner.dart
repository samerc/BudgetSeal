import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/hints_provider.dart';
import '../theme/app_colors.dart';

/// A small, dismissible hint banner for first-time contextual tips.
///
/// Shows only if the hint has not been dismissed. Once dismissed via the close
/// button the hint is persisted in SharedPreferences and never shown again.
class HintBanner extends ConsumerWidget {
  final String hintId;
  final IconData icon;
  final String title;
  final String body;

  const HintBanner({
    super.key,
    required this.hintId,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissedAsync = ref.watch(hintDismissedProvider(hintId));

    return dismissedAsync.when(
      data: (dismissed) {
        if (dismissed) return const SizedBox.shrink();
        return _buildBanner(context, ref);
      },
      // While loading or on error, show nothing to avoid layout flicker.
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tp(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.ts(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.th(context),
                ),
                tooltip: 'Dismiss',
                onPressed: () async {
                  await dismissHint(hintId);
                  ref.invalidate(hintDismissedProvider(hintId));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
