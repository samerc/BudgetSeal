import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../../shared/theme/app_icons.dart';
import 'tappable.dart';

/// A reusable error display with an icon, message, and retry button.
/// Technical details are logged, and shown (expandable) in debug builds only.
///
/// Details are automatically sanitized to remove exception type names,
/// file paths, and stack traces. Full technical details are logged via
/// debugPrint for developer debugging.
class ErrorRetry extends StatelessWidget {
  final String? message;
  final String? details;
  final VoidCallback onRetry;

  const ErrorRetry({
    super.key,
    this.message,
    this.details,
    required this.onRetry,
  });

  /// Strip exception class names, file paths, line numbers, and stack traces
  /// from error details to avoid exposing internals to users.
  static String _sanitize(String raw) {
    // Log full details for developer debugging
    debugPrint('[ErrorRetry] $raw');

    var s = raw;
    // Strip exception type prefix: "SqliteException(1): ..." → "..."
    s = s.replaceAll(RegExp(r'^[A-Z]\w*Exception\([^)]*\):\s*'), '');
    s = s.replaceAll(RegExp(r'^[A-Z]\w*Exception:\s*'), '');
    s = s.replaceAll(RegExp(r'^[A-Z]\w*Error:\s*'), '');
    // Strip file paths and line numbers
    s = s.replaceAll(RegExp(r'(?:file:///|/[\w/]+\.dart)[:\d]*'), '');
    s = s.replaceAll(RegExp(r'package:\w+/[\w/]+\.dart[:\d]*'), '');
    // Strip "Causing statement..." SQL details
    s = s.replaceAll(RegExp(r'Causing statement.*', dotAll: true), '');
    // Strip stack trace lines
    s = s.replaceAll(RegExp(r'#\d+\s+.*', multiLine: true), '');
    // Clean up leftover whitespace
    s = s.replaceAll(RegExp(r'\n{2,}'), '\n').trim();
    // Nothing left after stripping: no details line.
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final tr = S.of(context);
    final displayMessage = message ?? tr.commonSomethingWentWrong;
    // Details are for us, not users: logged always, shown in debug only.
    final shown = details == null ? '' : _sanitize(details!);
    final showDetails = kDebugMode && shown.isNotEmpty;
    // Same layout as EmptyState (pastel circle, 18/w700 title, theme button)
    // so a failed screen looks like part of the app.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.pastel(context, AppColors.accent,
                    light: 0.82, dark: 0.75),
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.warningCircle,
                  size: 44, color: AppColors.accent),
            ),
            const SizedBox(height: 18),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.tp(context),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (showDetails) ...[
              const SizedBox(height: 8),
              _ExpandableDetails(details: shown),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 28),
              ),
              icon: const Icon(AppIcons.arrowClockwise, size: 18),
              label: Text(tr.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableDetails extends StatefulWidget {
  final String details;
  const _ExpandableDetails({required this.details});

  @override
  State<_ExpandableDetails> createState() => _ExpandableDetailsState();
}

class _ExpandableDetailsState extends State<_ExpandableDetails> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Tappable(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? S.of(context).commonHideDetails : S.of(context).commonShowDetails,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ts(context),
                  decoration: TextDecoration.underline,
                ),
              ),
              Icon(
                _expanded
                    ? AppIcons.caretUp
                    : AppIcons.caretDown,
                size: 16,
                color: AppColors.ts(context),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          Text(
            widget.details,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.ts(context).withValues(alpha: 0.7),
              height: 1.3,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
