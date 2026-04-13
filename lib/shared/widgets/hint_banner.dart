import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

/// Shows a one-time hint dialog. If the user has already dismissed it
/// (tracked via SharedPreferences), nothing happens.
///
/// Call from `initState` inside a `addPostFrameCallback`:
/// ```dart
/// WidgetsBinding.instance.addPostFrameCallback((_) {
///   showHintIfNeeded(context, hintId: 'x', title: 'T', body: 'B');
/// });
/// ```
Future<void> showHintIfNeeded(
  BuildContext context, {
  required String hintId,
  required String title,
  required String body,
  IconData icon = Icons.lightbulb_outline,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('hint_dismissed_$hintId') ?? false) return;
  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        body,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Got it'),
        ),
      ],
    ),
  );

  await prefs.setBool('hint_dismissed_$hintId', true);
}
