import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Checks whether a specific hint banner has been dismissed.
///
/// Usage: `ref.watch(hintDismissedProvider('dashboard_welcome'))`
final hintDismissedProvider =
    FutureProvider.family<bool, String>((ref, hintId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hint_dismissed_$hintId') ?? false;
});

/// Permanently dismiss a hint so it never shows again.
Future<void> dismissHint(String hintId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('hint_dismissed_$hintId', true);
}
