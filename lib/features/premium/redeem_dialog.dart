import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/premium_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/utils/dispose_later.dart';

/// The "Redeem code" dialog (About and Upgrade both open it). On success it
/// shows a SnackBar and calls [onRedeemed] (Upgrade closes itself).
Future<void> showRedeemDialog(BuildContext context, WidgetRef ref,
    {VoidCallback? onRedeemed}) async {
  final l = S.of(context);
  final controller = TextEditingController();
  String? errorText;

  await showDialog<void>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (sbCtx, setDialogState) => AlertDialog(
        scrollable: true,
        title: Text(l.upgradeRedeemCode),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: l.upgradeRedeemHint,
            errorText: errorText,
          ),
        ),
        actions: [
          OutlinedButton(
            style: DialogButtons.outlined,
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: DialogButtons.filled,
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              if (!isValidRedeemCode(code)) {
                setDialogState(() => errorText = l.upgradeRedeemInvalid);
                return;
              }
              try {
                await ref.read(hasPremiumProvider.notifier).redeemCode(code);
              } catch (e) {
                debugPrint('[Redeem] Failed: $e');
                setDialogState(() => errorText = l.commonSomethingWentWrong);
                return;
              }
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.upgradeRedeemSuccess),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              onRedeemed?.call();
            },
            child: Text(l.upgradeRedeemButton),
          ),
        ],
      ),
    ),
  );
  disposeAfterRouteAnimation(controller);
}
