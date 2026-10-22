import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/design_tokens.dart';

/// The app's one confirm dialog: a question title, an optional message,
/// Cancel (outlined) and the confirm button side by side — red filled when
/// [destructive] (Delete, Discard, Remove), accent filled otherwise.
///
/// Returns true only when the user confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = true,
}) async {
  final tr = S.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: content ?? (message != null ? Text(message) : null),
      actions: [
        OutlinedButton(
          style: DialogButtons.outlined,
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel ?? tr.commonCancel),
        ),
        FilledButton(
          style: destructive ? DialogButtons.destructive : DialogButtons.filled,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
