import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tactile touch wrapper modelled on Cashew's `Tappable`.
///
/// On iOS: opacity fade (no ripple). On Android: InkSparkle ripple.
/// Cards and rows use the calm defaults (no scale, no haptic) — Cashew only
/// scales and vibrates on buttons. Pass [scaleFactor] < 1 and [haptic] for
/// button-like surfaces (quick actions, keypad, templates).
///
/// Drop-in replacement for InkWell/GestureDetector on interactive surfaces.
class Tappable extends StatefulWidget {
  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.color,
    this.haptic = false,
    this.scaleFactor = 1.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;

  /// Optional background color for the ink splash layer.
  final Color? color;

  /// Whether to trigger haptic feedback on tap.
  final bool haptic;

  /// How much the widget scales down on press (1.0 = no scale, 0.95 = 5% shrink).
  final double scaleFactor;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  static final bool _isIOS = defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 230),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
    ));
    _opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.5).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.haptic) HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _handleLongPress() {
    // Long-press always gets a haptic, like Cashew.
    HapticFeedback.heavyImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null && widget.onLongPress == null;

    if (isDisabled) return widget.child;

    // iOS: opacity fade + scale, no ink ripple
    if (_isIOS) {
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _handleTap,
        onLongPress: widget.onLongPress != null ? _handleLongPress : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) => Transform.scale(
            scale: widget.scaleFactor == 1.0 ? 1.0 : _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          ),
          child: widget.child,
        ),
      );
    }

    // Android: Material ripple (InkSparkle on M3), optional scale
    final ink = Material(
      color: widget.color ?? Colors.transparent,
      borderRadius: widget.borderRadius,
      child: InkWell(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _handleTap,
        onLongPress: widget.onLongPress != null ? _handleLongPress : null,
        borderRadius: widget.borderRadius,
        splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
        child: widget.child,
      ),
    );
    if (widget.scaleFactor == 1.0) return ink;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: ink,
    );
  }
}
