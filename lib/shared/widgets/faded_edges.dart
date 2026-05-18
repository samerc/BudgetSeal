import 'package:flutter/material.dart';

/// Wraps a scrollable child with gradient fades at the top and/or bottom edges.
///
/// Instead of content getting clipped sharply at scroll boundaries, it fades
/// out smoothly using a linear alpha gradient — gives a premium, polished feel.
///
/// Usage:
/// ```dart
/// FadedEdges(
///   child: ListView(children: [...]),
/// )
/// ```
class FadedEdges extends StatelessWidget {
  const FadedEdges({
    super.key,
    required this.child,
    this.topFade = 0.0,
    this.bottomFade = 24.0,
    this.startFade = 0.0,
    this.endFade = 0.0,
  });

  final Widget child;

  /// Fade height at top edge (0 = no fade).
  final double topFade;

  /// Fade height at bottom edge (0 = no fade).
  final double bottomFade;

  /// Fade width at start edge (0 = no fade). For horizontal lists.
  final double startFade;

  /// Fade width at end edge (0 = no fade). For horizontal lists.
  final double endFade;

  @override
  Widget build(BuildContext context) {
    if (topFade == 0 && bottomFade == 0 && startFade == 0 && endFade == 0) {
      return child;
    }

    return ShaderMask(
      shaderCallback: (Rect rect) {
        final stops = <double>[];
        final colors = <Color>[];

        if (topFade > 0 || startFade > 0) {
          final fade = topFade > 0 ? topFade : startFade;
          final ratio = (fade / (topFade > 0 ? rect.height : rect.width))
              .clamp(0.0, 0.4);
          stops.addAll([0.0, ratio]);
          colors.addAll([Colors.transparent, Colors.white]);
        } else {
          stops.add(0.0);
          colors.add(Colors.white);
        }

        if (bottomFade > 0 || endFade > 0) {
          final fade = bottomFade > 0 ? bottomFade : endFade;
          final ratio =
              (1.0 - (fade / (bottomFade > 0 ? rect.height : rect.width)))
                  .clamp(0.6, 1.0);
          stops.addAll([ratio, 1.0]);
          colors.addAll([Colors.white, Colors.transparent]);
        } else {
          stops.add(1.0);
          colors.add(Colors.white);
        }

        final isVertical = topFade > 0 || bottomFade > 0;
        return LinearGradient(
          begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
          end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: colors,
          stops: stops,
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
