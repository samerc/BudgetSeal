import 'dart:math';

import 'package:flutter/material.dart';

/// Animated circular progress ring with optional overspend indicator.
///
/// Draws a background track, a main progress arc, and (if progress > 1.0)
/// a second overspend ring in [overspendColor]. The [child] widget is
/// rendered centered inside the ring.
class AnimatedCircularProgress extends StatefulWidget {
  final double progress;
  final Color color;
  final Color? overspendColor;
  final Color? trackColor;
  final double strokeWidth;
  final double size;
  final Duration duration;
  final Curve curve;
  final Widget? child;

  const AnimatedCircularProgress({
    super.key,
    required this.progress,
    this.color = const Color(0xFF6366F1),
    this.overspendColor,
    this.trackColor,
    this.strokeWidth = 3.5,
    this.size = 40,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeInOutCubicEmphasized,
    this.child,
  });

  @override
  State<AnimatedCircularProgress> createState() =>
      _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.progress)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCircularProgress old) {
    super.didUpdateWidget(old);
    if ((old.progress - widget.progress).abs() > 0.001) {
      _oldProgress = old.progress;
      _animation = Tween<double>(begin: _oldProgress, end: widget.progress)
          .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackColor =
        widget.trackColor ?? Theme.of(context).dividerColor.withValues(alpha: 0.3);
    final overspendColor = widget.overspendColor ?? const Color(0xFFEF4444);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _CircularProgressPainter(
            progress: _animation.value.clamp(0.0, 3.0),
            color: widget.color,
            overspendColor: overspendColor,
            trackColor: trackColor,
            strokeWidth: widget.strokeWidth,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color overspendColor;
  final Color trackColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.overspendColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    const startAngle = -pi / 2; // 12 o'clock

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Main progress arc (0% to 100%)
    final mainProgress = progress.clamp(0.0, 1.0);
    if (mainProgress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 0.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, 2 * pi * mainProgress, false, progressPaint);
    }

    // Overspend ring (> 100%)
    if (progress > 1.0) {
      final overage = (progress - 1.0).clamp(0.0, 2.0);
      final overPaint = Paint()
        ..color = overspendColor.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 0.5
        ..strokeCap = StrokeCap.round;
      // Draw from 12 o'clock (same start), overlaying the main arc
      canvas.drawArc(rect, startAngle, 2 * pi * overage.clamp(0.0, 1.0), false, overPaint);
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.overspendColor != overspendColor;
}
