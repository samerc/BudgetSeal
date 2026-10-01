import 'package:flutter/foundation.dart';

/// Dispose a controller created for a dialog/bottom sheet *after* the route's
/// exit animation finishes.
///
/// `await showDialog(...)` / `showModalBottomSheet(...)` complete as soon as
/// the route starts popping, but the route keeps rebuilding its TextField for
/// the length of the reverse animation. Disposing the controller right away
/// throws "TextEditingController used after being disposed", which then
/// cascades into the `_dependents.isEmpty` assertion.
void disposeAfterRouteAnimation(ChangeNotifier controller) {
  Future.delayed(const Duration(milliseconds: 600), controller.dispose);
}
