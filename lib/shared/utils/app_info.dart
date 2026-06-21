import 'package:package_info_plus/package_info_plus.dart';

/// App version string, populated at startup from the platform package info so
/// it always matches `pubspec.yaml` and never goes stale. The default is only
/// used before [initAppInfo] runs (e.g. in tests).
String appVersion = '0.9.0';

/// Build number (the `+N` in the pubspec version), populated at startup.
String appBuildNumber = '';

/// Read the real version/build from the installed package. Call once in
/// `main()` before `runApp`.
Future<void> initAppInfo() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isNotEmpty) appVersion = info.version;
    appBuildNumber = info.buildNumber;
  } catch (_) {
    // Keep defaults if package info is unavailable.
  }
}
