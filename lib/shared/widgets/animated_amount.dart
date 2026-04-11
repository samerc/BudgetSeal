import 'package:flutter/material.dart';

import '../utils/format_number.dart';

/// Animates a number change with a count-up/down effect.
class AnimatedAmount extends StatelessWidget {
  final double amount;
  final String? currency;
  final TextStyle? style;
  final Duration duration;

  const AnimatedAmount({
    super.key,
    required this.amount,
    this.currency,
    this.style,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amount),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => Text(
        formatAmount(value, currency: currency),
        style: style ?? Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
