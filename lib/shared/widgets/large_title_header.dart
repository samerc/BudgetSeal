import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// Cashew's PageFrame header as a sliver: a large bold title that shrinks
/// into a pinned 56px bar as the page scrolls, with actions on the end.
///
/// Use as the first sliver of a tab screen's [CustomScrollView]. It pads for
/// the status bar itself, so don't wrap it in a SafeArea.
class LargeTitleHeader extends StatelessWidget {
  const LargeTitleHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.subtitle,
  });

  final String title;
  final List<Widget> actions;

  /// Small line under the expanded title (fades out as it collapses).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _Delegate(
        title: title,
        actions: actions,
        subtitle: subtitle,
        topPadding: MediaQuery.paddingOf(context).top,
        textScaler: MediaQuery.textScalerOf(context),
      ),
    );
  }
}

class _Delegate extends SliverPersistentHeaderDelegate {
  _Delegate({
    required this.title,
    required this.actions,
    required this.subtitle,
    required this.topPadding,
    required this.textScaler,
  });

  final String title;
  final List<Widget> actions;
  final String? subtitle;
  final double topPadding;
  final TextScaler textScaler;

  static const _barHeight = 56.0;
  static const _largeSize = TypographyTokens.screenTitleSize;
  static const _smallSize = 20.0;

  // Room for the large title (and subtitle) below the bar row.
  double get _expandedExtra =>
      textScaler.scale(_largeSize) * 1.25 + (subtitle != null ? textScaler.scale(13) * 1.4 + 4 : 0) + 4;

  @override
  double get minExtent => topPadding + _barHeight;

  // Without actions the empty bar row above the title is wasted space, so
  // the expanded title starts right below the status bar.
  @override
  double get maxExtent => actions.isEmpty
      ? topPadding + (16 + _expandedExtra).clamp(_barHeight, double.infinity)
      : topPadding + _barHeight + _expandedExtra;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final fontSize = lerpDouble(_largeSize, _smallSize, t)!;
    final actionsWidth = actions.length * 48.0 + 8;

    // Faint edge once content is scrolling underneath the collapsed bar.
    final edge = ((shrinkOffset - range) / 24).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        boxShadow: edge > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                      alpha: (AppColors.isDark ? 0.35 : 0.08) * edge),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.only(top: topPadding),
      child: Stack(
        children: [
          // Title: bottom-start when expanded → vertically centered in the
          // bar (clear of the actions) when collapsed.
          PositionedDirectional(
            start: 20,
            end: lerpDouble(12, actionsWidth, t),
            top: 0,
            bottom: 0,
            child: Align(
              alignment: AlignmentDirectional.lerp(
                  AlignmentDirectional.bottomStart,
                  AlignmentDirectional.centerStart,
                  t)!,
              child: Padding(
                padding: EdgeInsets.only(bottom: lerpDouble(6, 0, t)!),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.tp(context),
                        fontSize: fontSize,
                        fontFamily: TypographyTokens.displayFamily,
                        fontWeight: TypographyTokens.screenTitleWeight,
                      ),
                    ),
                    if (subtitle != null && t < 0.6)
                      Opacity(
                        opacity: (1 - t / 0.6).clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13, color: AppColors.ts(context)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Actions stay in the top bar row.
          if (actions.isNotEmpty)
            PositionedDirectional(
              top: 0,
              end: 4,
              height: _barHeight,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_Delegate old) =>
      old.title != title ||
      old.actions != actions ||
      old.subtitle != subtitle ||
      old.topPadding != topPadding ||
      old.textScaler != textScaler;
}
