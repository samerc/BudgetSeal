import 'package:flutter/material.dart';

/// Responsive layout helpers.
extension ResponsiveExt on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isSmallPhone => screenWidth < 360;
  bool get isPhone => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;

  /// Horizontal padding that scales with screen width.
  double get hPadding => isSmallPhone ? 12 : isPhone ? 16 : 24;

  /// Font scale factor for large screens.
  double get fontScale => isPhone ? 1.0 : isTablet ? 1.1 : 1.2;

  /// Max content width (centered on tablets/desktop).
  double get maxContentWidth => isPhone ? double.infinity : 600;
}

/// Wraps content with a max width for tablet/desktop.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  const ResponsiveBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (context.isPhone) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.maxContentWidth),
        child: child,
      ),
    );
  }
}
