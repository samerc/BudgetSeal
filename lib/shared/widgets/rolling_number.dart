import 'package:flutter/material.dart';

import '../utils/format_number.dart';

/// Odometer-style rolling number display for financial amounts.
///
/// Each digit scrolls independently into place — rightmost digits spin
/// fastest, leftmost slowest, creating a mechanical counter feel.
/// Non-digit characters (currency symbols, separators) crossfade in place.
///
/// Uses [formatAmount] for currency-aware formatting. Set [lazyFirstRender]
/// to skip animation on first build (default true).
class RollingNumber extends StatefulWidget {
  final double amount;
  final String? currency;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration duration;
  final Curve curve;
  final bool lazyFirstRender;
  final String? prefix;

  const RollingNumber({
    super.key,
    required this.amount,
    this.currency,
    this.style,
    this.textAlign,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeInOutCubicEmphasized,
    this.lazyFirstRender = true,
    this.prefix,
  });

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _oldText = '';
  String _newText = '';
  bool _firstBuild = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _newText = _format(widget.amount);
    _oldText = _newText;
  }

  @override
  void didUpdateWidget(RollingNumber old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount ||
        old.currency != widget.currency ||
        old.prefix != widget.prefix) {
      _oldText = _format(old.amount);
      _newText = _format(widget.amount);
      _firstBuild = false;
      _controller.duration = widget.duration;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double value) {
    final formatted = formatAmount(value, currency: widget.currency);
    if (widget.prefix != null) return '${widget.prefix}$formatted';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? Theme.of(context).textTheme.titleLarge!;

    if (_firstBuild && widget.lazyFirstRender) {
      return Text(_newText, style: style, textAlign: widget.textAlign);
    }

    // Measure digit size once per build (not per animation frame)
    final digitPainter = TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final digitHeight = digitPainter.height;
    final digitWidth = digitPainter.width;
    digitPainter.dispose();

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) {
          // Pad both strings to equal length so columns align
          final maxLen =
              _oldText.length > _newText.length ? _oldText.length : _newText.length;
          final oldPadded = _oldText.padLeft(maxLen);
          final newPadded = _newText.padLeft(maxLen);

          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.textAlign == TextAlign.end
                ? MainAxisAlignment.end
                : widget.textAlign == TextAlign.center
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
            children: List.generate(maxLen, (i) {
              final oldChar = oldPadded[i];
              final newChar = newPadded[i];

              if (oldChar == newChar) {
                // No change — render static
                return oldChar == ' '
                    ? const SizedBox.shrink()
                    : Text(newChar, style: style);
              }

              final oldIsDigit = _isDigit(oldChar);
              final newIsDigit = _isDigit(newChar);

              if (oldIsDigit && newIsDigit) {
                // Both digits — roll vertically
                return _RollingDigit(
                  oldDigit: int.parse(oldChar),
                  newDigit: int.parse(newChar),
                  progress: _animation.value,
                  style: style,
                  digitHeight: digitHeight,
                  digitWidth: digitWidth,
                );
              }

              // Non-digit transition (currency symbol, separator, sign) — crossfade
              return _CrossfadeChar(
                oldChar: oldChar,
                newChar: newChar,
                progress: _animation.value,
                style: style,
              );
            }),
          );
        },
      ),
    );
  }

  static bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}

/// A single digit that rolls vertically from [oldDigit] to [newDigit].
class _RollingDigit extends StatelessWidget {
  final int oldDigit;
  final int newDigit;
  final double progress;
  final TextStyle style;
  final double digitHeight;
  final double digitWidth;

  const _RollingDigit({
    required this.oldDigit,
    required this.newDigit,
    required this.progress,
    required this.style,
    required this.digitHeight,
    required this.digitWidth,
  });

  @override
  Widget build(BuildContext context) {

    // Determine shortest roll direction (wrap around 0↔9)
    int diff = newDigit - oldDigit;
    if (diff > 5) diff -= 10;
    if (diff < -5) diff += 10;

    final offset = diff * progress * digitHeight;

    return SizedBox(
      width: digitWidth,
      height: digitHeight,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(0, -offset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show a window of digits around the current value
              for (int step = 0; step <= diff.abs(); step++) ...[
                SizedBox(
                  height: digitHeight,
                  child: Text(
                    '${(oldDigit + (diff > 0 ? step : -step)) % 10}',
                    style: style,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Crossfade between two non-digit characters.
class _CrossfadeChar extends StatelessWidget {
  final String oldChar;
  final String newChar;
  final double progress;
  final TextStyle style;

  const _CrossfadeChar({
    required this.oldChar,
    required this.newChar,
    required this.progress,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (oldChar == ' ' && progress > 0.5) {
      return Opacity(opacity: (progress - 0.5) * 2, child: Text(newChar, style: style));
    }
    if (newChar == ' ' && progress > 0.5) {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        Opacity(
          opacity: 1.0 - progress,
          child: Text(oldChar, style: style),
        ),
        Opacity(
          opacity: progress,
          child: Text(newChar, style: style),
        ),
      ],
    );
  }
}
