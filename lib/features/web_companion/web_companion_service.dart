import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'dart:typed_data' show BytesBuilder;

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/providers/database_provider.dart';
import '../../l10n/s_lookup.dart';
import '../../core/providers/web_companion_provider.dart';
import 'api/changes_handler.dart';
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
  ChangeFeed? _changes;

  WebCompanionService(this._ref);

  Future<void> start() async {
    if (_server != null) return;

    final notifier = _ref.read(webCompanionProvider.notifier);
    notifier.setStarting();

    try {
      // Get local WiFi IP
      final ip = await _getWifiIp();
      if (ip == null) {
        notifier.setError(currentS().wcNoWifiDesc);
        return;
      }

      // Build the request handler pipeline
      _changes = ChangeFeed(_ref.read(databaseProvider));
      final handler = buildRouter(_ref, auth, _changes!);
      final pipeline = const Pipeline()
          .addMiddleware(_catchAllErrorMiddleware())
          .addMiddleware(_privateIpMiddleware())
          .addMiddleware(_bodySizeLimitMiddleware())
          .addMiddleware(_rateLimitMiddleware())
          .addMiddleware(_writeRateLimitMiddleware())
          .addMiddleware(_abuseDetectionMiddleware())
          .addMiddleware(_securityMiddleware(ip))
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
      _autoStopTimer = Timer(_autoStopDuration, () {
        stop().catchError((Object e) {
          debugPrint('[WebCompanion] Auto-stop failed: $e');
        });
      });

      // Prune expired sessions every 30 minutes
      _sessionPruneTimer = Timer.periodic(_sessionPruneDuration, (_) {
        auth.pruneExpiredSessions();
      });
    } catch (e) {
      // Usually the port is still held by a previous run; details stay in
      // the log, the user gets a sentence.
      debugPrint('[WebCompanion] Start failed: $e');
      notifier.setError(currentS().wcStartFailed);
      _server = null;
      _changes?.dispose();
      _changes = null;
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
    _changes?.dispose();
    _changes = null;

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
      // NetworkInfo().getWifiIP() queries the WiFi network interface
      // specifically — it does NOT return cellular IPs. Returns null
      // when WiFi is disconnected.
      final ip = await NetworkInfo().getWifiIP();
      if (ip == null || ip.isEmpty || ip == '0.0.0.0') return null;
      return ip;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _startForegroundService(String ip) async {
    // Request battery optimization exemption — critical on Samsung, Xiaomi,
    // OnePlus, etc. Without this, Android kills the process when screen is off
    // even with an active foreground service.
    final batteryOk =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!batteryOk) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'web_companion',
        channelName: currentS().wcForegroundChannel,
        channelDescription: currentS().wcForegroundChannelDesc,
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

    final result = await FlutterForegroundTask.startService(
      serviceId: 7432,
      serviceTypes: [ForegroundServiceTypes.dataSync],
      notificationTitle: currentS().wcTitle,
      notificationText: 'http://$ip:7432',
      callback: startCallback,
    );

    debugPrint('[WebCompanion] Foreground service start result: $result');
  }

  /// Global catch-all: wraps every request in try-catch so no unhandled
  /// exception ever returns a stack trace or internal details to the client.
  /// Logs the full error server-side via debugPrint.
  static Middleware _catchAllErrorMiddleware() {
    return (Handler inner) {
      return (Request request) async {
        try {
          return await inner(request);
        } catch (e) {
          debugPrint('[WebCompanion] Unhandled error on '
              '${request.method} ${request.requestedUri.path}: $e');
          return Response(
            500,
            body: jsonEncode({'error': 'Internal server error'}),
            headers: {'content-type': 'application/json'},
          );
        }
      };
    };
  }

  /// Rejects requests from non-private IP ranges.
  static Middleware _privateIpMiddleware() {
    return (Handler inner) {
      return (Request request) async {
        final connInfo =
            request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
        final remoteIp = connInfo?.remoteAddress.address;
        if (remoteIp == null || !_isPrivateIp(remoteIp)) {
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

  /// Rejects bodies over maxBytes (512 KB default) — by Content-Length when
  /// sent, and while reading for chunked requests that omit it.
  /// Protects against memory exhaustion from oversized request bodies.
  static Middleware _bodySizeLimitMiddleware({int maxBytes = 512 * 1024}) {
    Response tooLarge() => Response(
          413,
          body: jsonEncode({'error': 'Request body too large'}),
          headers: {'content-type': 'application/json'},
        );
    return (Handler inner) {
      return (Request request) async {
        final length = request.contentLength;
        if (length != null) {
          if (length > maxBytes) return tooLarge();
          return inner(request);
        }
        // No Content-Length (chunked): buffer up to the cap, then hand the
        // bytes on so later middleware can still read the body.
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in request.read()) {
          bytes.add(chunk);
          if (bytes.length > maxBytes) return tooLarge();
        }
        return inner(request.change(body: bytes.takeBytes()));
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

  /// Stricter rate limit for write operations (POST/PUT/DELETE).
  /// 40 per minute per IP — room for fast bulk entry from a keyboard, still
  /// blocks scripted floods.
  static Middleware _writeRateLimitMiddleware({int maxPerMinute = 40}) {
    final tracker = <String, List<DateTime>>{};
    const writeMethods = {'POST', 'PUT', 'DELETE'};
    return (Handler inner) {
      return (Request request) async {
        if (!writeMethods.contains(request.method)) return inner(request);

        final connInfo =
            request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
        final ip = connInfo?.remoteAddress.address ?? 'unknown';
        final now = DateTime.now();
        final windowStart = now.subtract(const Duration(minutes: 1));

        final hits = tracker[ip] ?? [];
        hits.removeWhere((t) => t.isBefore(windowStart));
        if (hits.length >= maxPerMinute) {
          debugPrint('[Abuse] Write rate limit hit: $ip (${hits.length} writes/min)');
          return Response(
            429,
            body: jsonEncode({
              'error': 'Too many submissions. Please wait before trying again.',
            }),
            headers: {'content-type': 'application/json'},
          );
        }
        hits.add(now);
        tracker[ip] = hits;
        return inner(request);
      };
    };
  }

  /// Attack pattern detection + honeypot field.
  ///
  /// Scans POST/PUT bodies for:
  /// - SQL injection keywords (DROP, UNION SELECT, --, etc.)
  /// - Script/HTML injection (<script>, javascript:, onerror=)
  /// - Extremely long field values (>10,000 chars per field)
  /// - Honeypot field ("website" — hidden in the SPA, bots fill it)
  ///
  /// Logs the attempt and returns 400.
  static Middleware _abuseDetectionMiddleware() {
    // Patterns that should never appear in legitimate financial data
    // No "--" or "UPDATE x SET": they match ordinary notes ("Dinner -- with
    // Sam"). Queries are parameterized anyway; this only stops probes.
    final sqlPattern = RegExp(
      r"(\bDROP\s+TABLE\b|\bUNION\s+SELECT\b|\bINSERT\s+INTO\b"
      r"|\bDELETE\s+FROM\b|;\s*DROP"
      r"|\bOR\s+1\s*=\s*1\b|\bAND\s+1\s*=\s*1\b)",
      caseSensitive: false,
    );
    final xssPattern = RegExp(
      r'(<script\b|javascript\s*:|on(error|load|click|mouseover)\s*=|<iframe\b|<img\b[^>]+onerror)',
      caseSensitive: false,
    );

    return (Handler inner) {
      return (Request request) async {
        if (request.method != 'POST' && request.method != 'PUT') {
          return inner(request);
        }

        // Read body — need to buffer it so inner handler can also read
        final bodyStr = await request.readAsString();

        // Honeypot check: reject if "website" field is present and non-empty
        if (bodyStr.isNotEmpty) {
          try {
            final parsed = jsonDecode(bodyStr);
            if (parsed is Map<String, dynamic>) {
              final honeypot = parsed['website'];
              if (honeypot != null && honeypot is String && honeypot.isNotEmpty) {
                final connInfo = request.context['shelf.io.connection_info']
                    as HttpConnectionInfo?;
                debugPrint('[Abuse] Honeypot triggered from ${connInfo?.remoteAddress.address}: website="$honeypot"');
                return Response(
                  400,
                  body: jsonEncode({'error': 'Invalid request'}),
                  headers: {'content-type': 'application/json'},
                );
              }
            }
          } catch (_) {
            // Not valid JSON — let inner handler deal with it
          }
        }

        // Attack pattern detection on raw body string
        if (bodyStr.length > 100) {
          if (sqlPattern.hasMatch(bodyStr)) {
            final connInfo = request.context['shelf.io.connection_info']
                as HttpConnectionInfo?;
            debugPrint('[Abuse] SQL injection attempt from ${connInfo?.remoteAddress.address}: ${bodyStr.substring(0, min(200, bodyStr.length))}');
            return Response(
              400,
              body: jsonEncode({'error': 'Request contains invalid characters'}),
              headers: {'content-type': 'application/json'},
            );
          }
          if (xssPattern.hasMatch(bodyStr)) {
            final connInfo = request.context['shelf.io.connection_info']
                as HttpConnectionInfo?;
            debugPrint('[Abuse] XSS attempt from ${connInfo?.remoteAddress.address}: ${bodyStr.substring(0, min(200, bodyStr.length))}');
            return Response(
              400,
              body: jsonEncode({'error': 'Request contains invalid characters'}),
              headers: {'content-type': 'application/json'},
            );
          }
        }

        // Check individual field lengths (>10K chars is abuse)
        if (bodyStr.isNotEmpty) {
          try {
            final parsed = jsonDecode(bodyStr);
            if (parsed is Map<String, dynamic>) {
              for (final entry in parsed.entries) {
                if (entry.value is String && (entry.value as String).length > 10000) {
                  debugPrint('[Abuse] Oversized field "${entry.key}": ${(entry.value as String).length} chars');
                  return Response(
                    400,
                    body: jsonEncode({'error': 'Field "${entry.key}" exceeds maximum length'}),
                    headers: {'content-type': 'application/json'},
                  );
                }
              }
            }
          } catch (_) {}
        }

        // Re-create request with buffered body so inner handler can read it
        final newRequest = Request(
          request.method,
          request.requestedUri,
          headers: request.headers,
          body: bodyStr,
          context: request.context,
        );
        return inner(newRequest);
      };
    };
  }

  /// Security and CORS middleware.
  /// Validates Origin header against the server's own IP — rejects cross-origin requests.
  /// Adds security headers and CORS headers to all responses.
  static Middleware _securityMiddleware(String serverIp) {
    final allowedOrigin = 'http://$serverIp:7432';

    return createMiddleware(
      requestHandler: (Request request) {
        if (request.method == 'OPTIONS') {
          final origin = request.headers['origin'] ?? '';
          if (origin.isNotEmpty && origin != allowedOrigin) {
            return Response.forbidden(
              jsonEncode({'error': 'Cross-origin request denied'}),
              headers: {'content-type': 'application/json', ..._securityHeaders},
            );
          }
          return Response.ok('', headers: _buildCorsHeaders(allowedOrigin));
        }
        return null;
      },
      responseHandler: (Response response) {
        // Security headers win, except a long cache a static route asked for.
        final cache = response.headers['cache-control'];
        return response.change(headers: {
          ...response.headers,
          ..._buildCorsHeaders(allowedOrigin),
          if (cache != null && cache.startsWith('public'))
            'Cache-Control': cache,
        });
      },
    );
  }

  static Map<String, String> _buildCorsHeaders(String allowedOrigin) {
    return {
      'Access-Control-Allow-Origin': allowedOrigin,
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
    'Content-Security-Policy':
        // Everything is served by the phone (fonts and Chart.js are
        // bundled) and the SPA has no inline scripts.
        "default-src 'self'; "
        "script-src 'self'; "
        "style-src 'self' 'unsafe-inline'; "
        "font-src 'self'; "
        "img-src 'self' data:; "
        "connect-src 'self'; "
        "frame-ancestors 'none'",
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
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
    // The text stays the localized title + URL set at start (this handler
    // has no localization context).
    FlutterForegroundTask.updateService();
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
