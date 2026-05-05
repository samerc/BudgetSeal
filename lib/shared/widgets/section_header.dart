import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// Standardized section header used across all screens.
///
/// Renders uppercase-style text with consistent size, weight, and letter spacing.
/// Optionally shows a trailing action widget (e.g. "See all" button).
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final header = Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: TypographyTokens.sectionHeaderSize,
        fontWeight: TypographyTokens.sectionHeaderWeight,
        letterSpacing: TypographyTokens.sectionHeaderLetterSpacing,
        color: AppColors.ts(context),
      ),
    );

    final content = trailing != null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [header, trailing!],
          )
        : header;

    if (padding != null) {
      return Padding(padding: padding!, child: content);
    }
    return content;
  }
}
