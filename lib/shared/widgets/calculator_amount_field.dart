import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/format_number.dart';

/// A read-only amount field that opens a calculator bottom sheet when tapped.
///
/// Use this instead of a standard numeric TextField for all amount inputs
/// across the app. The calculator supports basic arithmetic (+, -, *, /).
class CalculatorAmountField extends StatelessWidget {
  /// Current amount value.
  final double value;

  /// Called when the user confirms a new amount via "Done".
  final ValueChanged<double> onChanged;

  /// Optional label displayed above the amount.
  final String? label;

  /// Currency symbol to display beside the amount.
  final String? currency;

  /// Text styling for the displayed amount.
  final TextStyle? style;

  /// Hint text shown when value is 0.
  final String hintText;

  /// Font size (used when [style] is null).
  final double fontSize;

  const CalculatorAmountField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.currency,
    this.style,
    this.hintText = '0.00',
    this.fontSize = 32,
  });

  String _fmtDisplay(double v) {
    if (v == 0) return '';
    return formatForDisplay(v);
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _fmtDisplay(value);
    final effectiveStyle = style ??
        TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.tp(context),
        );

    return GestureDetector(
      onTap: () => _openCalculatorSheet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ts(context),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  displayText.isEmpty ? hintText : displayText,
                  style: displayText.isEmpty
                      ? effectiveStyle.copyWith(
                          fontWeight: FontWeight.w300,
                          color: AppColors.textHint,
                        )
                      : effectiveStyle,
                ),
              ),
              if (currency != null)
                Text(
                  currency!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ts(context),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openCalculatorSheet(BuildContext context) async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CalculatorSheet(initialValue: value),
    );
    if (result != null) {
      onChanged(result);
    }
  }
}

// ---------------------------------------------------------------------------
// Calculator bottom sheet
// ---------------------------------------------------------------------------

class _CalculatorSheet extends StatefulWidget {
  final double initialValue;
  const _CalculatorSheet({required this.initialValue});

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  String _calcDisplay = '0';
  String _calcExpression = '';
  double _amount = 0;

  /// True when the expression contains an operator (user is mid-calculation).
  bool get _hasOperator =>
      _calcExpression.contains('+') ||
      _calcExpression.contains('-') ||
      _calcExpression.contains('×') ||
      _calcExpression.contains('÷');

  @override
  void initState() {
    super.initState();
    _amount = widget.initialValue;
    if (_amount > 0) {
      _calcDisplay = _fmtCalc(_amount);
      _calcExpression = _calcDisplay;
    }
  }

  // ── Calculator logic (matches assisted_transaction_screen) ──

  void _calcDigit(String d) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_calcDisplay == '0' && d != '.') {
        _calcDisplay = d;
        _calcExpression = d;
      } else {
        _calcDisplay += d;
        _calcExpression += d;
      }
      _amount = _evalExpr(_calcExpression);
    });
  }

  void _calcOp(String op) {
    HapticFeedback.mediumImpact();
    setState(() {
      _amount = _evalExpr(_calcExpression);
      _calcDisplay = _fmtCalc(_amount);
      _calcExpression = '$_calcDisplay$op';
    });
  }

  void _calcBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_calcDisplay.length > 1) {
        _calcDisplay = _calcDisplay.substring(0, _calcDisplay.length - 1);
        if (_calcExpression.isNotEmpty) {
          _calcExpression =
              _calcExpression.substring(0, _calcExpression.length - 1);
        }
      } else {
        _calcDisplay = '0';
        _calcExpression = '';
      }
      _amount = _evalExpr(_calcExpression);
    });
  }

  void _calcClear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _calcDisplay = '0';
      _calcExpression = '';
      _amount = 0;
    });
  }

  String _fmtCalc(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  double _evalExpr(String expr) {
    if (expr.isEmpty) return 0;
    try {
      var e = expr.replaceAll('\u00D7', '*').replaceAll('\u00F7', '/');
      while (e.isNotEmpty && '+-*/'.contains(e[e.length - 1])) {
        e = e.substring(0, e.length - 1);
      }
      if (e.isEmpty) return 0;
      final parts = e.split(RegExp(r'(?=[+\-*/])|(?<=[+\-*/])'));
      double result = 0;
      String op = '+';
      for (final p in parts) {
        if ('+-*/'.contains(p)) {
          op = p;
        } else {
          final n = double.tryParse(p) ?? 0;
          result = switch (op) {
            '+' => result + n,
            '-' => result - n,
            '*' => result * n,
            '/' => n != 0 ? result / n : result,
            _ => result + n,
          };
        }
      }
      return result;
    } catch (_) {
      return 0;
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amount display
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _hasOperator ? _calcDisplay : (_amount > 0 ? formatForDisplay(_amount) : _calcDisplay),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: AppColors.tp(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Calculator keypad
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            decoration: BoxDecoration(
              color: AppColors.sfv(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _calcRow(['7', '8', '9', '\u00F7']),
                const SizedBox(height: 6),
                _calcRow(['4', '5', '6', '\u00D7']),
                const SizedBox(height: 6),
                _calcRow(['1', '2', '3', '-']),
                const SizedBox(height: 6),
                _calcRow(['.', '0', '\u232B', '+']),
              ],
            ),
          ),
          // Done button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _amount),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Done',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        final isOp = '+-\u00D7\u00F7'.contains(key);
        final isBack = key == '\u232B';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: isOp
                  ? AppColors.accent.withValues(alpha: 0.1)
                  : AppColors.sf(context),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (isBack) {
                    _calcBackspace();
                  } else if (isOp) {
                    _calcOp(key);
                  } else {
                    _calcDigit(key);
                  }
                },
                onLongPress: isBack ? _calcClear : null,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  child: isBack
                      ? Icon(Icons.backspace_outlined,
                          size: 20, color: AppColors.ts(context))
                      : Text(
                          key,
                          style: TextStyle(
                            fontSize: isOp ? 24 : 22,
                            fontWeight:
                                isOp ? FontWeight.w700 : FontWeight.w500,
                            color: isOp
                                ? AppColors.accent
                                : AppColors.tp(context),
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
