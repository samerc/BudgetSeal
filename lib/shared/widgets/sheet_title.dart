import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// The title row of a bottom sheet: 18/w700, with an optional subtitle and
/// a trailing widget (e.g. a close or reset button).
///
/// Sheets start with this directly — no drag handle or spacer above it (the
/// theme sheet has none).
class SheetTitle extends StatelessWidget {
  const SheetTitle(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 12),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: TypographyTokens.sheetTitleSize,
            fontWeight: TypographyTokens.sheetTitleWeight,
            color: AppColors.tp(context),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              height: 1.35,
              color: AppColors.ts(context),
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: padding,
      child: trailing == null
          ? SizedBox(width: double.infinity, child: text)
          : Row(children: [Expanded(child: text), trailing!]),
    );
  }
}
