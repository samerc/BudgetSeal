import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Slide-up transition for detail/modal-style screens.
/// Uses a smooth decelerate curve with a subtle fade overlay.
CustomTransitionPage<T> slideUpPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Cashew pushRoute: 5% slide-up + fade, 300ms in / 125ms out.
      final slideTween = Tween(begin: const Offset(0, 0.05), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutExpo));
      final fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 125),
  );
}

/// Fade transition for top-level screens.
CustomTransitionPage<T> fadePage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}
