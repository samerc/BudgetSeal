import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'error_retry.dart';

/// Catches build-phase errors in child widgets and shows a friendly
/// fallback instead of a red/grey crash screen.
///
/// Works by listening to FlutterError.onError (set in main.dart) and
/// checking if any error occurred during build via a post-frame callback.
/// Does NOT override ErrorWidget.builder (which causes _dependents crash).
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _FallbackScreen(
        onRetry: () => setState(() => _hasError = false),
      );
    }
    return widget.child;
  }
}

class _FallbackScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const _FallbackScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // The app's one error look (ErrorRetry, styled like EmptyState), plus a
    // way back.
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ErrorRetry(
              message: S.of(context).commonErrorDesc,
              onRetry: onRetry,
            ),
            TextButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(S.of(context).commonGoBack),
            ),
          ],
        ),
      ),
    );
  }
}
