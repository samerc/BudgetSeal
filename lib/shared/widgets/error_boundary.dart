import 'package:flutter/material.dart';

/// Catches build-phase errors in child widgets and shows a friendly
/// fallback instead of a red/grey crash screen.
///
/// Wrap around any subtree that might throw during build:
/// ```dart
/// ErrorBoundary(child: SomeScreen())
/// ```
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset on navigation / dependency change so the user can retry
    _hasError = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _FallbackScreen(onRetry: () => setState(() => _hasError = false));
    }

    // Wrap child in a builder that catches build errors
    return _ErrorCatcher(
      onError: () {
        if (mounted) setState(() => _hasError = true);
      },
      child: widget.child,
    );
  }
}

class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final VoidCallback onError;
  const _ErrorCatcher({required this.child, required this.onError});

  @override
  Widget build(BuildContext context) {
    // Use ErrorWidget.builder override scoped to this subtree
    // via a custom error widget builder
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('[ErrorBoundary] Build error caught: ${details.exceptionAsString()}');
      // Schedule the state change for next frame to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) => onError());
      return const SizedBox.shrink();
    };
    return child;
  }
}

class _FallbackScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const _FallbackScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 56, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'An unexpected error occurred. Try going back or restarting the app.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
