import 'package:flutter/material.dart';

/// Wraps a child in a staggered fade+slide entrance animation.
/// Use inside list builders with the item index for a cascading effect.
class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration staggerDelay;
  final Duration duration;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  Widget build(BuildContext context) {
    final delay = staggerDelay * index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        // Clamp the progress to account for the stagger delay portion.
        final totalMs = (duration + delay).inMilliseconds;
        final delayMs = delay.inMilliseconds;
        final progress = totalMs > 0
            ? ((value * totalMs - delayMs) / duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 1.0;
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
