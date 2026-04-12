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
      final slideTween = Tween(begin: const Offset(0, 0.04), end: Offset.zero)
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
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
  );
}

/// Shared-axis transition for tab-to-content navigation.
/// Combines a horizontal slide with a fade for a Material-style feel.
CustomTransitionPage<T> sharedAxisPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween(begin: const Offset(0.03, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
      // Fade out the outgoing screen
      final secondaryFade = Tween(begin: 1.0, end: 0.92)
          .chain(CurveTween(curve: Curves.easeInOut));
      return FadeTransition(
        opacity: secondaryAnimation.drive(secondaryFade),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
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
