import 'dart:io' show Platform;

import 'package:flutter/material.dart';

/// Platform-aware animation curves and durations.
///
/// iOS: snappy, shorter transitions (200-300ms), easeInOut curves
/// Android: slightly elastic feel (400-550ms), easeInOutCubicEmphasized
abstract final class PlatformCurves {
  static bool get _isIOS {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false; // web or desktop
    }
  }

  /// Standard page transition curve.
  static Curve get page =>
      _isIOS ? Curves.easeInOut : Curves.easeInOutCubicEmphasized;

  /// Standard UI animation curve (expand/collapse, fade, scale).
  static Curve get standard =>
      _isIOS ? Curves.easeOut : Curves.easeOutCubic;

  /// Emphasis curve for important transitions.
  static Curve get emphasis =>
      _isIOS ? Curves.easeInOutCubic : Curves.easeInOutCubicEmphasized;

  /// Page transition duration.
  static Duration get pageDuration => _isIOS
      ? const Duration(milliseconds: 250)
      : const Duration(milliseconds: 400);

  /// Standard animation duration.
  static Duration get standardDuration => _isIOS
      ? const Duration(milliseconds: 200)
      : const Duration(milliseconds: 300);

  /// Emphasis animation duration (charts, progress, count-up).
  static Duration get emphasisDuration => _isIOS
      ? const Duration(milliseconds: 400)
      : const Duration(milliseconds: 550);
}
