import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The bar pinned under a form or flow (Save, Continue, Fund…): page
/// background, a hairline on top, buttons side by side with equal width.
///
/// Use as a Scaffold's `bottomNavigationBar`. Pass [above] for a line of
/// context shown over the buttons (a total, a warning).
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.children, this.above});

  final List<Widget> children;
  final Widget? above;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.bd(context))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (above != null) ...[above!, const SizedBox(height: 10)],
                Row(
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: children[i]),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
