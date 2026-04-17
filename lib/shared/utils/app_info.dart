/// Single source of truth for the app version string.
const appVersion = '1.0.0';

/// Build timestamp — computed at app startup, unique per build session.
final appBuildTimestamp = _formatBuildTime();

String _formatBuildTime() {
  // Uses the compilation-time constant to approximate build time.
  // For exact build time, this is close enough (within the app session).
  const buildDate = String.fromEnvironment('BUILD_DATE', defaultValue: '');
  if (buildDate.isNotEmpty) return buildDate;
  // Fallback: use the current date (first app launch after install)
  final now = DateTime.now();
  final months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[now.month]} ${now.day}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}
