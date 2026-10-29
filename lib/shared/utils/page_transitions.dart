import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Slide-up transition for detail/modal-style screens.
/// Uses a smooth decelerate curve with a subtle fade overlay.
///
/// The screen stops above the system navigation bar (the strip below is the
/// page background): a list with its own `padding` gets no inset for the bar,
/// so its last rows sat behind the 3-button bar. [edgeToEdge] keeps drawing
/// under it, for a screen that pads its own bottom and paints another colour
/// there.
CustomTransitionPage<T> slideUpPage<T>({
  required Widget child,
  required GoRouterState state,
  bool edgeToEdge = false,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: edgeToEdge ? child : _AboveNavigationBar(child: child),
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

class _AboveNavigationBar extends StatelessWidget {
  const _AboveNavigationBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg(context),
      child: SafeArea(top: false, left: false, right: false, child: child),
    );
  }
}
