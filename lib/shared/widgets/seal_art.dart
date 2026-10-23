import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/brand_palette.dart';

/// BudgetSeal's line illustrations: an envelope closed with the gold wax
/// seal, drawn in the theme's colours (paper = card surface, ink = accent
/// text, seal = bright accent), so they suit light, dark and every accent.

/// Empty states: an empty envelope, sealed, with two small sparkles.
class SealedEnvelopeArt extends StatelessWidget {
  final double width;
  const SealedEnvelopeArt({super.key, this.width = 180});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 170 / 200,
      child: CustomPaint(painter: _ArtPainter(_colors(context), welcome: false)),
    );
  }
}

/// The welcome screen: two notes going into an envelope, sealed, on a
/// soft gold disc.
class WelcomeArt extends StatelessWidget {
  final double width;
  const WelcomeArt({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 200 / 240,
      child: CustomPaint(painter: _ArtPainter(_colors(context), welcome: true)),
    );
  }
}

typedef _Colors = ({
  Color paper,
  Color ink,
  Color gold,
  Color ring,
  Color glow,
  Color shade,
  Color note,
});

_Colors _colors(BuildContext context) {
  final gold = AppColors.accentBright;
  return (
    paper: AppColors.sf(context),
    ink: AppColors.accentText(context),
    gold: gold,
    ring: AppColors.darkenPastel(gold, 0.22),
    glow: AppColors.pastel(context, gold, light: 0.8, dark: 0.82),
    shade: AppColors.sfv(context),
    note: AppColors.pastel(context, gold, light: 0.35, dark: 0.3),
  );
}

class _ArtPainter extends CustomPainter {
  final _Colors c;
  final bool welcome;
  _ArtPainter(this.c, {required this.welcome});

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 200×170 (empty) or 240×200 (welcome) grid, then scaled.
    final w = welcome ? 240.0 : 200.0;
    canvas.scale(size.width / w);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = c.ink;
    final fill = Paint();

    if (welcome) {
      canvas.drawCircle(const Offset(120, 110), 100, fill..color = c.glow);
      _note(canvas, const Offset(118, 69), -8, c.note, stroke);
      _note(canvas, const Offset(126, 79), 5, c.gold, stroke);
      final body = RRect.fromLTRBAndCorners(52, 92, 188, 172,
          bottomLeft: const Radius.circular(8),
          bottomRight: const Radius.circular(8));
      canvas.drawRRect(body, fill..color = c.paper);
      canvas.drawRRect(body, stroke);
      canvas.drawPath(
          Path()
            ..moveTo(54, 94)
            ..lineTo(120, 136)
            ..lineTo(186, 94),
          stroke);
      _seal(canvas, const Offset(120, 136), 20);
    } else {
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(100, 150), width: 140, height: 16),
          fill..color = c.shade);
      final body = RRect.fromLTRBR(34, 44, 166, 136, const Radius.circular(10));
      canvas.drawRRect(body, fill..color = c.paper);
      canvas.drawRRect(body, stroke);
      canvas.drawPath(
          Path()
            ..moveTo(36, 50)
            ..lineTo(100, 98)
            ..lineTo(164, 50),
          stroke);
      final faint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = c.ink.withValues(alpha: 0.3);
      canvas.drawLine(const Offset(36, 132), const Offset(84, 90), faint);
      canvas.drawLine(const Offset(164, 132), const Offset(116, 90), faint);
      _seal(canvas, const Offset(100, 98), 19);
      _sparkle(canvas, const Offset(150, 30), 8);
      _sparkle(canvas, const Offset(44, 29), 5);
    }
  }

  void _note(Canvas canvas, Offset center, double degrees, Color color,
      Paint stroke) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(degrees * math.pi / 180);
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 96, height: 58),
        const Radius.circular(6));
    canvas.drawRRect(r, Paint()..color = color);
    canvas.drawRRect(r, stroke);
    canvas.drawCircle(Offset.zero, 11, stroke);
    canvas.restore();
  }

  /// The scalloped wax seal with its ring and check (as `SealMark`).
  void _seal(Canvas canvas, Offset c0, double r) {
    const bumps = 14;
    final edge = Path();
    for (var i = 0; i <= 360; i++) {
      final a = i * math.pi / 180;
      final rr = r * (0.9 + 0.1 * math.cos(bumps * a));
      final p = c0 + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? edge.moveTo(p.dx, p.dy) : edge.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(edge..close(), Paint()..color = c.gold);
    canvas.drawCircle(
        c0,
        r * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.09
          ..color = c.ring);
    canvas.drawPath(
        Path()
          ..moveTo(c0.dx - r * 0.3, c0.dy + r * 0.02)
          ..lineTo(c0.dx - r * 0.08, c0.dy + r * 0.24)
          ..lineTo(c0.dx + r * 0.32, c0.dy - r * 0.2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.16
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = brandInk);
  }

  void _sparkle(Canvas canvas, Offset p, double r) {
    final path = Path()
      ..moveTo(p.dx, p.dy - r)
      ..lineTo(p.dx + r * 0.3, p.dy - r * 0.3)
      ..lineTo(p.dx + r, p.dy)
      ..lineTo(p.dx + r * 0.3, p.dy + r * 0.3)
      ..lineTo(p.dx, p.dy + r)
      ..lineTo(p.dx - r * 0.3, p.dy + r * 0.3)
      ..lineTo(p.dx - r, p.dy)
      ..lineTo(p.dx - r * 0.3, p.dy - r * 0.3)
      ..close();
    canvas.drawPath(path, Paint()..color = c.gold);
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.c != c || old.welcome != welcome;
}
