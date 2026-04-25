import 'package:flutter/material.dart';

/// A widget that pulses (breathes) to draw attention.
///
/// Scales the child between [minScale] and [maxScale] in a repeating
/// animation. Set [active] to false to render the child statically.
class BreathingWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;
  final bool active;

  const BreathingWidget({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 1.15,
    this.duration = const Duration(milliseconds: 2500),
    this.active = true,
  });

  @override
  State<BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(BreathingWidget old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && old.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return ScaleTransition(
      scale: Tween(begin: widget.minScale, end: widget.maxScale).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}
