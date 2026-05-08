import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/format_number.dart';

/// Animates a number change with a count-up/down effect.
///
/// Uses IntTween on cents for smooth integer stepping (no floating-point jitter).
/// With [lazyFirstRender] (default true), the first build renders statically —
/// animation only triggers on subsequent value changes.
class AnimatedAmount extends StatefulWidget {
  final double amount;
  final String? currency;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration duration;
  final Curve curve;
  final bool lazyFirstRender;
  final String? prefix;

  const AnimatedAmount({
    super.key,
    required this.amount,
    this.currency,
    this.style,
    this.textAlign,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
    this.lazyFirstRender = true,
    this.prefix,
  });

  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount> {
  bool _firstBuild = true;
  double _previousAmount = 0;

  @override
  void initState() {
    super.initState();
    _previousAmount = widget.amount;
  }

  @override
  void didUpdateWidget(AnimatedAmount old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount) {
      _previousAmount = old.amount;
      _firstBuild = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // On first build with lazyFirstRender, show static text
    if (_firstBuild && widget.lazyFirstRender) {
      return Text(
        _format(widget.amount),
        style: widget.style ?? Theme.of(context).textTheme.titleLarge,
        textAlign: widget.textAlign,
      );
    }

    final decimals = 2;
    final multiplier = pow(10, decimals).toInt();
    final beginCents = (_previousAmount * multiplier).round();
    final endCents = (widget.amount * multiplier).round();

    return TweenAnimationBuilder<int>(
      key: ValueKey('${widget.amount}_${widget.currency}'),
      tween: IntTween(begin: beginCents, end: endCents),
      duration: widget.duration,
      curve: widget.curve,
      builder: (_, cents, __) {
        final value = cents / multiplier;
        return Text(
          _format(value),
          style: widget.style ?? Theme.of(context).textTheme.titleLarge,
          textAlign: widget.textAlign,
        );
      },
    );
  }

  String _format(double value) {
    final formatted = formatAmount(value, currency: widget.currency);
    if (widget.prefix != null) return '${widget.prefix}$formatted';
    return formatted;
  }
}
