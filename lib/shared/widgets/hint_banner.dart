import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';

/// Shows a one-time hint dialog. If the user has already dismissed it
/// (tracked via SharedPreferences), nothing happens.
///
/// Call from `initState` inside an `addPostFrameCallback`:
/// ```dart
/// WidgetsBinding.instance.addPostFrameCallback((_) {
///   showHintIfNeeded(context, hintId: 'x', title: 'T', body: 'B');
/// });
/// ```
///
/// Hints are queued: a second call waits until the first dialog is closed,
/// so two tabs (or a tab and the welcome) never stack dialogs.
Future<void> showHintIfNeeded(
  BuildContext context, {
  required String hintId,
  required String title,
  required String body,
  IconData icon = AppIcons.lightbulb,
}) =>
    _enqueue(() => _showHint(context,
        hintId: hintId, title: title, body: body, icon: icon));

/// Runs [task] once every hint queued so far has been closed (e.g. a system
/// permission prompt that must not appear on top of a hint).
Future<void> afterHints(Future<void> Function() task) => _enqueue(task);

Future<void> _hintQueue = Future.value();

Future<void> _enqueue(Future<void> Function() task) {
  final next = _hintQueue.then((_) => task());
  _hintQueue = next.catchError((_) {});
  return next;
}

Future<void> _showHint(
  BuildContext context, {
  required String hintId,
  required String title,
  required String body,
  required IconData icon,
}) async {
  if (!context.mounted) return;
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
