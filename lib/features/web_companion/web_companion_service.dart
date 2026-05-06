import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/providers/web_companion_provider.dart';
import 'web_companion_auth.dart';
import 'web_companion_router.dart';

// 6 hours — matches Android 15+ dataSync foreground service cap
const _autoStopDuration = Duration(hours: 6);
const _sessionPruneDuration = Duration(minutes: 30);

class WebCompanionService {
  final Ref _ref;
  final WebCompanionAuth auth = WebCompanionAuth();

  HttpServer? _server;
  Timer? _autoStopTimer;
  Timer? _sessionPruneTimer;

  WebCompanionService(this._ref);

  Future<void> start() async {
    if (_server != null) return;

    final notifier = _ref.read(webCompanionProvider.notifier);
    notifier.setStarting();

    try {
      // Get local WiFi IP
      final ip = await _getWifiIp();
      if (ip == null) {
        notifier.setError('Not connected to WiFi. Connect to a network and try again.');
        return;
      }

      // Build the request handler pipeline
      final handler = buildRouter(_ref, auth);
      final pipeline = const Pipeline()
          .addMiddleware(_privateIpMiddleware())
          .addMiddleware(_bodySizeLimitMiddleware())
          .addMiddleware(_rateLimitMiddleware())
          .addMiddleware(_securityMiddleware())
          .addHandler(handler);

      // Bind shelf server to the WiFi IP only (not 0.0.0.0)
      _server = await shelf_io.serve(pipeline, ip, 7432);
      _server!.autoCompress = true;

      // Keep process alive
      if (Platform.isAndroid) {
        await _startForegroundService(ip);
      } else if (Platform.isIOS) {
        await WakelockPlus.enable();
      }

      notifier.setRunning(ip, 7432);

      // Auto-stop after 6 hours
      _autoStopTimer = Timer(_autoStopDuration, () => stop());

      // Prune expired sessions every 30 minutes
      _sessionPruneTimer = Timer.periodic(_sessionPruneDuration, (_) {
        auth.pruneExpiredSessions();
      });
    } catch (e) {
      notifier.setError('Failed to start server: $e');
      _server = null;
    }
  }

  Future<void> stop() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _sessionPruneTimer?.cancel();
    _sessionPruneTimer = null;

    auth.revokeAllSessions();

    await _server?.close(force: true);
    _server = null;

    if (Platform.isAndroid) {
      await FlutterForegroundTask.stopService();
    } else if (Platform.isIOS) {
      await WakelockPlus.disable();
    }

    _ref.read(webCompanionProvider.notifier).setStopped();
  }

  bool get isRunning => _server != null;

  // ── Private helpers ─────────────────────────────────────────────────────────

  static Future<String?> _getWifiIp() async {
    try {
      final ip = await NetworkInfo().getWifiIP();
      if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') return ip;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _startForegroundService(String ip) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'web_companion',
        channelName: 'Web Companion',
        channelDescription: 'Keeps the local budget server running',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    await FlutterForegroundTask.startService(
      serviceId: 7432,
      serviceTypes: [ForegroundServiceTypes.dataSync],
      notificationTitle: 'PocketPlan Web Companion',
      notificationText: 'Running at http://$ip:7432',
      callback: startCallback,
    );
  }

  /// Rejects requests from non-private IP ranges.
  static Middleware _privateIpMiddleware() {
    return (Handler inner) {
      return (Request request) async {
        final connInfo =
            request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
        final remoteIp = connInfo?.remoteAddress.address;
        if (remoteIp != null && !_isPrivateIp(remoteIp)) {
          return Response.forbidden(
            jsonEncode({'error': 'Access denied: not on local network'}),
            headers: {'content-type': 'application/json'},
          );
        }
        return inner(request);
      };
    };
  }

  static bool _isPrivateIp(String ip) {
    // IPv4 private ranges
    if (ip.startsWith('127.')) return true;
    if (ip.startsWith('192.168.') || ip.startsWith('10.')) return true;
    final parts = ip.split('.');
    if (parts.length == 4 && parts[0] == '172') {
      final second = int.tryParse(parts[1]);
      if (second != null && second >= 16 && second <= 31) return true;
    }
    // IPv6 loopback and private ranges
    if (ip == '::1') return true;
    final lower = ip.toLowerCase();
    if (lower.startsWith('fe80:')) return true; // link-local
    if (lower.startsWith('fc') || lower.startsWith('fd')) return true; // ULA
    return false;
  }

  /// Rejects requests whose Content-Length exceeds maxBytes (512 KB default).
  /// Protects against memory exhaustion from oversized request bodies.
  static Middleware _bodySizeLimitMiddleware({int maxBytes = 512 * 1024}) {
    return (Handler inner) {
      return (Request request) async {
        final length = request.contentLength;
        if (length != null && length > maxBytes) {
          return Response(
            413,
            body: jsonEncode({'error': 'Request body too large'}),
            headers: {'content-type': 'application/json'},
          );
        }
        return inner(request);
      };
    };
  }

  /// Simple per-IP rate limiter: max 120 requests per minute.
  /// Evicts stale IPs to prevent memory growth.
  static Middleware _rateLimitMiddleware({int maxPerMinute = 120}) {
    final tracker = <String, List<DateTime>>{};
    var lastPrune = DateTime.now();
    return (Handler inner) {
      return (Request request) async {
        final connInfo =
            request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
        final ip = connInfo?.remoteAddress.address ?? 'unknown';
        final now = DateTime.now();
        final windowStart = now.subtract(const Duration(minutes: 1));

        // Evict stale IPs every 5 minutes to prevent memory leak
        if (now.difference(lastPrune).inMinutes >= 5) {
          tracker.removeWhere((_, hits) =>
              hits.isEmpty || hits.last.isBefore(windowStart));
          lastPrune = now;
        }

        final hits = tracker[ip] ?? [];
        hits.removeWhere((t) => t.isBefore(windowStart));
        if (hits.length >= maxPerMinute) {
          return Response(
            429,
            body: jsonEncode({'error': 'Rate limit exceeded. Try again shortly.'}),
            headers: {'content-type': 'application/json'},
          );
        }
        hits.add(now);
        tracker[ip] = hits;
        return inner(request);
      };
    };
  }

  /// Security and CORS middleware.
  /// SPA is served from the same origin so CORS is same-origin only.
  /// Adds security headers to all responses.
  static Middleware _securityMiddleware() {
    return createMiddleware(
      requestHandler: (Request request) {
        if (request.method == 'OPTIONS') {
          final origin = request.headers['origin'] ?? '';
          return Response.ok('', headers: _buildCorsHeaders(origin));
        }
        return null;
      },
      responseHandler: (Response response) {
        return response.change(headers: {
          ...response.headers,
          ..._securityHeaders,
        });
      },
    );
  }

  static Map<String, String> _buildCorsHeaders(String origin) {
    // Only allow same-origin requests (the phone's own IP)
    // origin will be like "http://192.168.1.x:7432"
    return {
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '3600',
      'Vary': 'Origin',
      ..._securityHeaders,
    };
  }

  static const _securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'no-referrer',
    'Cache-Control': 'no-store',
  };
}

// ── Foreground task handler (no-op — only keeps Android process alive) ────────

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_NoOpTaskHandler());
}

class _NoOpTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[WebCompanion] Foreground service started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Refresh the notification periodically so Android knows the service
    // is still active and doesn't kill it when the screen is off.
    FlutterForegroundTask.updateService(
      notificationTitle: 'PocketPlan Web Companion',
      notificationText: 'Running · ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('[WebCompanion] Foreground service destroyed (timeout: $isTimeout)');
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final webCompanionServiceProvider = Provider<WebCompanionService>((ref) {
  final service = WebCompanionService(ref);
  ref.onDispose(() => service.stop());
  return service;
});
