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
}
