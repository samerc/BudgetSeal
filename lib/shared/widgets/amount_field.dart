import 'package:flutter/material.dart';

import 'calculator_amount_field.dart';

/// A drop-in amount field that opens a calculator bottom sheet instead of the
/// keyboard. Maintains the same public API as the old TextField-based widget
/// so existing call-sites keep working.
class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;
  final double fontSize;
  final String hintText;

  const AmountField({
    super.key,
    required this.controller,
    this.onChanged,
    this.fontSize = 32,
    this.hintText = '0.00',
  });

  double get _currentValue =>
      double.tryParse(controller.text.replaceAll(',', '')) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return CalculatorAmountField(
      value: _currentValue,
      fontSize: fontSize,
      hintText: hintText,
      onChanged: (newValue) {
        // Format: strip trailing .00 for round numbers, else 2 decimals.
        if (newValue == 0) {
          controller.text = '';
        } else if (newValue == newValue.roundToDouble()) {
          controller.text = newValue.toInt().toString();
        } else {
          controller.text = newValue.toStringAsFixed(2);
        }
        onChanged?.call();
      },
    );
  }
}
