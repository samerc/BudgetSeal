import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/utils/app_info.dart';

/// Continues the Android/iOS launch screen seamlessly: same background, same
/// 144px rounded icon, dead center and not animated — so the hand-off from
/// the system splash is invisible. Only the name and version fade in.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  /// Matches the native splash icon (android/.../drawable/splash_icon.xml).
  static const double iconSize = 144;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/icon/splash_logo.png',
              width: SplashScreen.iconSize,
              height: SplashScreen.iconSize,
              filterQuality: FilterQuality.medium,
            ),
          ),
          // Name just under the icon, without moving the icon off center.
          Center(
            child: Transform.translate(
              offset: const Offset(0, SplashScreen.iconSize / 2 + 34),
              child: FadeTransition(
                opacity: fade,
                child: Text(
                  'BudgetSeal',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.tp(context),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: fade,
              child: Text(
                'v$appVersion',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.th(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
