/// Abstract interface for cloud storage providers.
/// Each adapter implements upload/download of the single sync file.
abstract class CloudProvider {
  /// Human-readable name (e.g. "Google Drive", "Local File").
  String get displayName;

  /// Icon name for display.
  String get iconName;

  /// Whether the user is currently authenticated/connected.
  Future<bool> get isConnected;

  /// Authenticate / connect to the provider.
  /// Returns true on success.
  Future<bool> connect();

  /// Disconnect / sign out.
  Future<void> disconnect();

  /// Upload the sync file content. Creates the file if it doesn't exist.
  Future<void> upload(String jsonContent);

  /// Download the sync file content. Returns null if no file exists.
  Future<String?> download();

  /// Check if a sync file exists on this provider.
  Future<bool> syncFileExists();

  /// Log sync (`log_sync.dart`): the log files here, name → a version
  /// that changes with the file.
  Future<Map<String, String>> listLogFiles();

  /// One log file's content, or null when it's gone.
  Future<String?> readLogFile(String name);

  /// Writes (creates or replaces) one log file.
  Future<void> writeLogFile(String name, String content);
}

/// The provider has no signed-in account (or lost it); the user has to
/// connect again.
class CloudAuthException implements Exception {
  const CloudAuthException();

  @override
  String toString() => 'CloudAuthException: not connected';
}
