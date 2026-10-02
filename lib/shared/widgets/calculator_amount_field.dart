import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
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
                          color: AppColors.th(context),
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
    final result = await showCalculatorSheet(context, value);
    if (result != null) {
      onChanged(result);
    }
  }
}

/// Open the calculator bottom sheet directly (e.g. from a header amount).
/// Returns the confirmed amount, or null if dismissed.
Future<double?> showCalculatorSheet(BuildContext context, double initialValue) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CalculatorSheet(initialValue: initialValue),
  );
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
  bool _startNewOperand = false;

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

  // ── Calculator logic ──

  void _calcDigit(String d) {
    // Block a second decimal point in the same operand — "1.2." can't be
    // parsed and would silently evaluate to 0, showing the user a wrong total.
    if (d == '.' && !_startNewOperand && _calcDisplay.contains('.')) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_startNewOperand) {
        // After an operator: reset display to new number, keep expression building
        _calcDisplay = (d == '.') ? '0.' : d;
        _calcExpression += d;
        _startNewOperand = false;
      } else if (_calcDisplay == '0' && d != '.') {
        _calcDisplay = d;
        if (_calcExpression.isEmpty || _calcExpression == '0') {
          _calcExpression = d;
        } else {
          _calcExpression += d;
        }
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
      _startNewOperand = true;
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

  /// Format a calculator expression for display, adding thousand separators
  /// to each number token while preserving operators.
  String _fmtExprForDisplay(String expr) {
    if (expr.isEmpty) return '0';
    final buf = StringBuffer();
    final numBuf = StringBuffer();
    for (int i = 0; i < expr.length; i++) {
      final ch = expr[i];
      if ('+-×÷'.contains(ch)) {
        if (numBuf.isNotEmpty) {
          final n = double.tryParse(numBuf.toString());
          buf.write(n != null && n > 0 ? formatForDisplay(n) : numBuf);
          numBuf.clear();
        }
        buf.write(' $ch ');
      } else {
        numBuf.write(ch);
      }
    }
    if (numBuf.isNotEmpty) {
      final raw = numBuf.toString();
      final n = double.tryParse(raw);
      if (n != null && n > 0) {
        buf.write(formatForDisplay(n));
        // Keep a just-typed decimal point (and trailing zeros) visible.
        final dot = raw.indexOf('.');
        if (dot >= 0) {
          final frac = raw.substring(dot + 1);
          if (frac.isEmpty) {
            buf.write(decimalSeparatorChar);
          } else if (frac.endsWith('0') && !formatForDisplay(n).contains(decimalSeparatorChar)) {
            buf.write('$decimalSeparatorChar$frac');
          }
        }
      } else {
        buf.write(raw.replaceAll('.', decimalSeparatorChar));
      }
    }
    return buf.toString();
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
    } catch (e) {
      debugPrint('Calculator expression eval failed for "$expr": $e');
      return 0;
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    // Done needs a positive amount — or zero when clearing a value that was
    // already set.
    final canSubmit =
        _amount > 0 || (widget.initialValue > 0 && _amount == 0 && !_hasOperator);
    final display = _amount > 0 || _hasOperator
        ? _fmtExprForDisplay(_calcExpression)
        : _calcDisplay.replaceAll('.', decimalSeparatorChar);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.popup(context),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RadiusTokens.sheet)),
      ),
      // Numbers and operators are laid out left-to-right in every locale.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount display — scales down instead of truncating.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      display,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 38,
                        fontFamily: TypographyTokens.displayFamily,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.tp(context),
                      ),
                    ),
                  ),
                ),
              ),
              // Cashew selectAmount: one seamless rounded block, flush keys.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(RadiusTokens.button),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _calcRow(['7', '8', '9', '÷']),
                      _calcRow(['4', '5', '6', '×']),
                      _calcRow(['1', '2', '3', '-']),
                      _calcRow(['.', '0', '⌫', '+']),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: canSubmit ? 1 : 0.5,
                    child: FilledButton(
                      onPressed: canSubmit
                          ? () => Navigator.pop(context, _amount)
                          : null,
                      child: Text(S.of(context).commonDone),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calcRow(List<String> keys) {
    final isBlack = Theme.of(context).scaffoldBackgroundColor ==
        const Color(0xFF000000);
    return Row(
      children: [
        for (final key in keys)
          Expanded(
            child: Container(
              // Black theme: hairline seams so keys don't merge into one slab.
              margin: isBlack ? const EdgeInsets.all(0.5) : EdgeInsets.zero,
              child: Material(
                color: '+-×÷'.contains(key)
                    ? AppColors.pastel(context, AppColors.accent,
                        light: 0.75, dark: 0.7)
                    : AppColors.sfv(context),
                child: InkWell(
                  onTap: () {
                    if (key == '⌫') {
                      _calcBackspace();
                    } else if ('+-×÷'.contains(key)) {
                      _calcOp(key);
                    } else {
                      _calcDigit(key);
                    }
                  },
                  onLongPress: key == '⌫' ? _calcClear : null,
                  child: SizedBox(
                    height: 60,
                    child: Center(
                      child: key == '⌫'
                          ? Icon(Icons.backspace_rounded,
                              size: 22, color: AppColors.tp(context))
                          : Text(
                              key == '.' ? decimalSeparatorChar : key,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: AppColors.tp(context),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
