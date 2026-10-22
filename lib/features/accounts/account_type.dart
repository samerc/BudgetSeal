import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';

/// One look for an account type everywhere (Accounts list, Reports balance
/// sheet, search, travel): icon, color and translated name, keyed by the
/// type code stored in the db ('cash', 'bank', 'credit', 'wallet').

IconData accountTypeIcon(String type) => switch (type) {
      'bank' => AppIcons.bank,
      'credit' => AppIcons.creditCard,
      'wallet' => AppIcons.wallet,
      _ => AppIcons.money,
    };

/// Same HSL scheme as the More page icons: one saturation/lightness for
/// every type (lifted in dark mode) so the hues read in both themes.
Color accountTypeColor(String type) {
  final hue = switch (type) {
    'bank' => 212.0,
    'credit' => 24.0,
    'wallet' => 40.0,
    _ => 152.0,
  };
  return HSLColor.fromAHSL(1, hue, 0.62, AppColors.isDark ? 0.62 : 0.5)
      .toColor();
}

/// Translated name of an account type id.
String accountTypeLabel(S l, String type) => switch (type) {
      'cash' => l.acctTypeCash,
      'bank' => l.acctTypeBank,
      'credit' => l.acctTypeCredit,
      'wallet' => l.acctTypeDigital,
      _ => type,
    };

/// The pastel circle with the type's icon, used as a row's leading widget.
class AccountTypeBadge extends StatelessWidget {
  const AccountTypeBadge(this.type,
      {super.key, this.size = 36, this.muted = false});

  final String type;
  final double size;

  /// Archived accounts: grey instead of the type's hue.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.ts(context) : accountTypeColor(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.pastel(context, color, light: 0.85, dark: 0.78),
        shape: BoxShape.circle,
      ),
      child: Icon(accountTypeIcon(type), color: color, size: size * 0.45),
    );
  }
}
