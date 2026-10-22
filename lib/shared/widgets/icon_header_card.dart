import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';
import 'settings_row.dart';

/// A section card with an icon header: the settings icon circle, a bold
/// title (and optional description), then [children]. Used by the settings
/// sub-screens (Backup, Notifications, Export, Import, Sync…) so their
/// cards share one look.
class IconHeaderCard extends StatelessWidget {
  const IconHeaderCard({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.description,
    this.children = const [],
    this.trailing,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? description;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SettingsIcon(icon: icon, color: iconColor ?? AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: SettingsRowStyle.title(context)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 10),
            Text(description!,
                style: SettingsRowStyle.subtitle(context)
                    .copyWith(height: 1.4)),
          ],
          if (children.isNotEmpty) const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
