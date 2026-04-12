import 'package:flutter/material.dart';

import 'calculator_amount_field.dart';

/// A drop-in amount field that opens a calculator bottom sheet instead of the
/// keyboard. Maintains the same public API as the old TextField-based widget
/// so existing call-sites keep working.
/// A drop-in amount field backed by a calculator bottom sheet.
/// Listens to the controller so pre-filled values always display.
class AmountField extends StatefulWidget {
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

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  double _value = 0;

  @override
  void initState() {
    super.initState();
    _syncFromController();
    widget.controller.addListener(_syncFromController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    super.dispose();
  }

  void _syncFromController() {
    final parsed =
        double.tryParse(widget.controller.text.replaceAll(',', '')) ?? 0.0;
    if (parsed != _value) {
      setState(() => _value = parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorAmountField(
      value: _value,
      fontSize: widget.fontSize,
      hintText: widget.hintText,
      onChanged: (newValue) {
        setState(() => _value = newValue);
        if (newValue == 0) {
          widget.controller.text = '';
        } else if (newValue == newValue.roundToDouble()) {
          widget.controller.text = newValue.toInt().toString();
        } else {
          widget.controller.text = newValue.toStringAsFixed(2);
        }
        widget.onChanged?.call();
      },
    );
  }
}
