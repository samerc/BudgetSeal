import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A reusable error display with an icon, message, and retry button.
/// Optionally shows expandable technical details.
class ErrorRetry extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback onRetry;

  const ErrorRetry({
    super.key,
    this.message = 'Something went wrong',
    this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.ts(context),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.ts(context),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              _ExpandableDetails(details: details!),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sf(context),
                foregroundColor: AppColors.tp(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
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
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? 'Hide details' : 'Show details',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ts(context),
                  decoration: TextDecoration.underline,
                ),
              ),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
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
