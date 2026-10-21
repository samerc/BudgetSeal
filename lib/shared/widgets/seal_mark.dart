import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/brand_palette.dart';
import '../utils/haptics.dart';

/// BudgetSeal's wax seal: a scalloped disc in the bright accent with an
/// inner ring and an ink check — the seal from the app icon. Marks a fully
/// funded envelope, a fully assigned budget and a closed period.
class SealMark extends StatelessWidget {
  final double size;

  /// Ink seal with an accent check, for use on the accent itself (the gold
  /// Ready to assign banner), where a gold seal would disappear.
  final bool inverse;

  const SealMark({super.key, this.size = 20, this.inverse = false});

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.accentBright;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: inverse
            ? _SealPainter(brandInk, gold, gold.withValues(alpha: 0.45))
            : _SealPainter(gold, brandInk, AppColors.darkenPastel(gold, 0.22)),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  final Color fill;
  final Color mark;
  final Color ring;

  _SealPainter(this.fill, this.mark, this.ring);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Scalloped edge: radius rippling around the circle.
    const bumps = 14;
    final edge = Path();
    for (var i = 0; i <= 360; i++) {
      final a = i * math.pi / 180;
      final rr = r * (0.9 + 0.1 * math.cos(bumps * a));
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? edge.moveTo(p.dx, p.dy) : edge.lineTo(p.dx, p.dy);
    }
    edge.close();
    canvas.drawPath(edge, Paint()..color = fill);

    // Pressed inner ring.
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.09
        ..color = ring,
    );

    // Check.
    final check = Path()
      ..moveTo(c.dx - r * 0.3, c.dy + r * 0.02)
      ..lineTo(c.dx - r * 0.08, c.dy + r * 0.24)
      ..lineTo(c.dx + r * 0.32, c.dy - r * 0.2);
    canvas.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = mark,
    );
  }

  @override
  bool shouldRepaint(_SealPainter old) =>
      old.fill != fill || old.mark != mark || old.ring != ring;
}

/// Shows a [SealMark] while [sealed]. When [sealed] turns true while this is
/// on screen, the seal is stamped on (drops in from larger, settles with a
/// light haptic); already sealed on first build = shown still. Calm: no
/// confetti, nothing repeating.
class SealStamp extends StatefulWidget {
  final bool sealed;
  final double size;

  /// Stamp on when first built sealed (the parent saw the change happen
  /// and rebuilt into a new layout).
  final bool stampOnMount;
  final bool inverse;

  const SealStamp({
    super.key,
    required this.sealed,
    this.size = 20,
    this.stampOnMount = false,
    this.inverse = false,
  });

  @override
  State<SealStamp> createState() => _SealStampState();
}

class _SealStampState extends State<SealStamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.sealed && !widget.stampOnMount ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.sealed && widget.stampOnMount) _stamp();
  }

  void _stamp() {
    _ctrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) hapticLight();
    });
  }

  @override
  void didUpdateWidget(SealStamp old) {
    super.didUpdateWidget(old);
    if (widget.sealed && !old.sealed) {
      _stamp();
    } else if (!widget.sealed && old.sealed) {
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        if (t == 0) return SizedBox.square(dimension: widget.size);
        // Pressed down from 1.8× with a small twist, landing at 1.0.
        final eased = Curves.easeOutBack.transform(t);
        final scale = 1.8 - 0.8 * eased;
        return Opacity(
          opacity: Curves.easeOut.transform(math.min(1, t * 2)),
          child: Transform.rotate(
            angle: -0.35 * (1 - eased),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: SealMark(size: widget.size, inverse: widget.inverse),
    );
  }
}
