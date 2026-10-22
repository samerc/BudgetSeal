import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';

/// Typography of a settings row (Cashew SettingsContainer): 16/w700 title,
/// 13.5 secondary description. Shared by every settings-style row and
/// switch so they read the same on every screen.
abstract final class SettingsRowStyle {
  static const double titleSize = 16;
  static const FontWeight titleWeight = FontWeight.w700;
  static const double subtitleSize = 13.5;

  /// Leading icon circle.
  static const double iconSize = 42;

  static TextStyle title(BuildContext context) => TextStyle(
      fontSize: titleSize, fontWeight: titleWeight, color: AppColors.tp(context));

  static TextStyle subtitle(BuildContext context) =>
      TextStyle(fontSize: subtitleSize, color: AppColors.ts(context));

  /// Icon color from a hue at one shared saturation/lightness, so a set of
  /// row icons reads as one family (hand-picked hex drifts muddy as pastel).
  /// [neutral] gives a near-grey of that hue (Settings, About).
  static Color hue(double hue, {bool neutral = false}) =>
      HSLColor.fromAHSL(1, hue, neutral ? 0.12 : 0.62,
              AppColors.isDark ? 0.62 : 0.5)
          .toColor();
}

/// The leading icon of a settings-style row: a 42px pastel circle.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SettingsRowStyle.iconSize,
      height: SettingsRowStyle.iconSize,
      decoration: BoxDecoration(
        color: AppColors.pastel(context, color, light: 0.82, dark: 0.7),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

/// A flat settings row on the page background: pastel icon circle, bold
/// title, secondary description, chevron when tappable. The transparent
/// Material keeps the ripple visible (a colored DecoratedBox would hide it).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: CardTokens.borderRadius),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 2, 8, 2),
        leading: SettingsIcon(icon: icon, color: iconColor),
        title: Text(title, style: SettingsRowStyle.title(context)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: SettingsRowStyle.subtitle(context)),
        trailing: trailing ??
            (onTap != null
                ? Icon(AppIcons.caretRight,
                    size: 20, color: AppColors.th(context))
                : null),
        onTap: onTap,
      ),
    );
  }
}

/// A settings row with a switch. With an [icon] it matches [SettingsRow];
/// without one (inside a card) it sits flush with the card's padding.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        shape: RoundedRectangleBorder(borderRadius: CardTokens.borderRadius),
        contentPadding: icon == null
            ? EdgeInsets.zero
            : const EdgeInsetsDirectional.fromSTEB(8, 2, 8, 2),
        secondary: icon == null
            ? null
            : SettingsIcon(icon: icon!, color: iconColor ?? AppColors.accent),
        title: Text(title, style: SettingsRowStyle.title(context)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: SettingsRowStyle.subtitle(context)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
