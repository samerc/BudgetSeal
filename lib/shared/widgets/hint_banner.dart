import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/generated/app_localizations.dart';
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
  IconData icon = Icons.lightbulb_outline_rounded,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('hint_dismissed_$hintId') ?? false) return;
  if (!context.mounted) return;

  // Cashew openPopup layout: large centered icon, centered title + body.
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(icon, size: 56, color: AppColors.accent),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(
        body,
        textAlign: TextAlign.center,
        style: const TextStyle(height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(S.of(ctx).commonGotIt),
        ),
      ],
    ),
  );

  await prefs.setBool('hint_dismissed_$hintId', true);
}
