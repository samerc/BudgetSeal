import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'api/accounts_handler.dart';
import 'api/categories_handler.dart';
import 'api/dashboard_handler.dart';
import 'api/envelopes_handler.dart';
import 'api/import_handler.dart';
import 'api/objectives_handler.dart';
import 'api/upcoming_handler.dart';
import 'api/recurring_handler.dart';
import 'api/reports_handler.dart';
import 'api/subscriptions_handler.dart';
import 'api/transactions_handler.dart';
import '../../core/providers/accent_color_provider.dart';
import '../../shared/theme/brand_palette.dart';
import '../../shared/utils/format_number.dart';
import 'web_companion_auth.dart';

/// Assembles the full shelf request handler.
Handler buildRouter(Ref ref, WebCompanionAuth auth) {
  final router = Router();

  // ── Auth (no token required) ────────────────────────────────────────────────

  router.post('/auth/pin', _pinHandler(auth));
  router.get('/auth/status', _authStatusHandler(auth));
  router.post('/auth/logout', _logoutHandler(auth));
  router.get('/auth/config', _configHandler(ref));

  // ── Static assets ───────────────────────────────────────────────────────────

  router.get('/assets/<file|[^]*>', _assetsHandler());
  // The app's own category icons and display font, so the browser matches
  // the phone and works without internet.
  router.get('/icons/<file>', _bundleFileHandler('assets/categories/'));
  router.get('/fonts/<file>', _bundleFileHandler('assets/fonts/'));
  router.get('/brand/<file>', _bundleFileHandler('assets/icon/'));

  // ── Protected API ───────────────────────────────────────────────────────────

  final api = Router();

  api.get('/dashboard', dashboardHandler(ref));

  api.get('/transactions', listTransactionsHandler(ref));
  api.post('/transactions', createTransactionHandler(ref));
  api.post('/transactions/bulk', bulkCreateTransactionsHandler(ref));
  api.get('/transactions/<id>', getTransactionHandler(ref));
  api.put('/transactions/<id>', updateTransactionHandler(ref));
  api.delete('/transactions/<id>', deleteTransactionHandler(ref));

  api.get('/categories', listCategoriesHandler(ref));
  api.post('/categories', createCategoryHandler(ref));
  api.put('/categories/<id>', updateCategoryHandler(ref));

  api.get('/accounts', listAccountsHandler(ref));
  api.post('/accounts', createAccountHandler(ref));
  api.get('/accounts/<id>', getAccountHandler(ref));
  api.put('/accounts/<id>', updateAccountHandler(ref));
  api.post('/accounts/<id>/archive', archiveAccountHandler(ref));
  api.post('/accounts/<id>/reconcile', reconcileAccountHandler(ref));

  api.get('/envelopes', listEnvelopesHandler(ref));
  api.post('/envelopes/move', moveEnvelopeMoneyHandler(ref));
  api.post('/import', importCsvHandler(ref));
  api.get('/upcoming', upcomingBillsHandler(ref));
  api.post('/recurring/<id>/post-now', recurringActionHandler(ref, post: true));
  api.post('/recurring/<id>/skip', recurringActionHandler(ref, post: false));
  api.get('/planned', listPlannedHandler(ref));
  api.post('/planned', createPlannedHandler(ref));
  api.post('/planned/post', postPlannedHandler(ref));
  api.put('/planned/<id>', updatePlannedHandler(ref));
  api.delete('/planned/<id>', deletePlannedHandler(ref));
  api.get('/objectives', listObjectivesHandler(ref));
  api.post('/objectives', createObjectiveHandler(ref));
  api.get('/objectives/<id>', getObjectiveHandler(ref));
  api.put('/objectives/<id>', updateObjectiveHandler(ref));
  api.delete('/objectives/<id>', deleteObjectiveHandler(ref));
  api.post('/objectives/<id>/pay', payObjectiveHandler(ref));
  api.post('/envelopes/<id>/fund', fundEnvelopeHandler(ref));

  api.get('/recurring', listRecurringHandler(ref));
  api.post('/recurring', createRecurringHandler(ref));
  api.put('/recurring/<id>', updateRecurringHandler(ref));
  api.delete('/recurring/<id>', deleteRecurringHandler(ref));

  api.get('/subscriptions', listSubscriptionsHandler(ref));
  api.post('/subscriptions', createSubscriptionHandler(ref));
  api.put('/subscriptions/<id>', updateSubscriptionHandler(ref));
  api.delete('/subscriptions/<id>', deleteSubscriptionHandler(ref));

  api.get('/reports/cashflow', cashflowReportHandler(ref));
  api.get('/reports/by-category', byCategoryReportHandler(ref));

  router.mount(
    '/api/',
    Pipeline().addMiddleware(authMiddleware(auth)).addHandler(api.call),
  );

  // ── SPA root ────────────────────────────────────────────────────────────────

  router.get('/', _spaRootHandler());
  router.get('/<path|[^]*>', _spaRootHandler());

  return router.call;
}

// ── Auth handlers ─────────────────────────────────────────────────────────────

Handler _pinHandler(WebCompanionAuth auth) {
  return (Request request) async {
    final body = await request.readAsString();
    Map<String, dynamic>? json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>?;
    } catch (_) {
      return _badRequest('Invalid JSON body');
    }

    final pin = json?['pin'];
    if (pin is! String || pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      return _badRequest('PIN must be a 4-digit string');
    }

    try {
      final token = await auth.submitPin(pin);
      final expiresAt =
          DateTime.now().add(const Duration(hours: 4)).toIso8601String();
      return Response.ok(
        jsonEncode({'token': token, 'expiresAt': expiresAt}),
        headers: _jsonHeaders,
      );
    } on AuthException catch (e) {
      final statusCode = e.isLockout ? 429 : 401;
      return Response(
        statusCode,
        // The browser shows its own localized text from these fields.
        body: jsonEncode({
          'error': e.message,
          'isLockout': e.isLockout,
          if (e.attemptsLeft != null) 'attemptsLeft': e.attemptsLeft,
          if (e.isLockout) 'retryInMinutes': auth.lockoutStatus.remainingMinutes,
        }),
        headers: _jsonHeaders,
      );
    }
  };
}

Handler _authStatusHandler(WebCompanionAuth auth) {
  return (Request request) {
    final token = _extractToken(request);
    final authenticated = auth.validateToken(token);
    return Response.ok(
      jsonEncode({'authenticated': authenticated}),
      headers: _jsonHeaders,
    );
  };
}

Handler _logoutHandler(WebCompanionAuth auth) {
  return (Request request) {
    final token = _extractToken(request);
    if (token != null) auth.revokeToken(token);
    return Response.ok(
      jsonEncode({'success': true}),
      headers: _jsonHeaders,
    );
  };
}

// ── Static asset handler ──────────────────────────────────────────────────────

Handler _assetsHandler() {
  return (Request request) async {
    final file = request.params['file'];
    if (file == null || !_safeName.hasMatch(file) || file.contains('..')) {
      return Response.notFound('Not found');
    }
    try {
      final data = await rootBundle.load('assets/web/$file');
      return Response.ok(
        data.buffer.asUint8List(),
        headers: {
          'content-type': _mimeFor(file),
          // Bundled libraries and fonts never change within an app version;
          // the SPA's own files must reload after an app update.
          if (file.endsWith('.woff2') || file.endsWith('.min.js'))
            'cache-control': _cacheLong,
        },
      );
    } catch (_) {
      return Response.notFound('Not found');
    }
  };
}

/// Serves one file from a bundled asset folder (icons, fonts), by plain
/// file name only — no paths.
Handler _bundleFileHandler(String folder) {
  return (Request request) async {
    final file = request.params['file'];
    if (file == null || !_safeName.hasMatch(file) || file.contains('..')) {
      return Response.notFound('Not found');
    }
    try {
      final data = await rootBundle.load('$folder$file');
      return Response.ok(
        data.buffer.asUint8List(),
        headers: {'content-type': _mimeFor(file), 'cache-control': _cacheLong},
      );
    } catch (_) {
      return Response.notFound('Not found');
    }
  };
}

final _safeName = RegExp(r'^[A-Za-z0-9_.()\-]+$');
const _cacheLong = 'public, max-age=604800';

// ── Config (no token: the PIN screen needs it too) ───────────────────────────

/// Language, accent colors and number format, so the browser looks and
/// reads like the phone. Nothing private.
Handler _configHandler(Ref ref) {
  return (Request request) {
    final lang = (Intl.defaultLocale ?? 'en').split(RegExp('[_-]')).first;
    final pair = accentPairById(ref.read(accentColorProvider)) ??
        brandPalette.first;
    String hex(Color c) =>
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return Response.ok(
      jsonEncode({
        'locale': const ['en', 'ar', 'fr'].contains(lang) ? lang : 'en',
        'accent': {
          'bright': hex(pair.bright),
          'deep': hex(pair.deep),
          'lightFill': hex(pair.lightFill),
          'darkFill': hex(pair.darkFill),
        },
        'number': numberFormatSpec(),
      }),
      headers: _jsonHeaders,
    );
  };
}

// ── SPA root ──────────────────────────────────────────────────────────────────

Handler _spaRootHandler() {
  return (Request request) async {
    try {
      final data = await rootBundle.load('assets/web/index.html');
      return Response.ok(
        data.buffer.asUint8List(),
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    } catch (_) {
      return Response.ok(
        _placeholderHtml,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    }
  };
}

// ── Auth middleware ────────────────────────────────────────────────────────────

/// Wraps a handler to require a valid session token.
Handler withAuth(WebCompanionAuth auth, Handler inner) {
  return (Request request) {
    final token = _extractToken(request);
    if (!auth.validateToken(token)) {
      return Response(
        401,
        body: jsonEncode({'error': 'Unauthorized'}),
        headers: _jsonHeaders,
      );
    }
    return inner(request);
  };
}

Middleware authMiddleware(WebCompanionAuth auth) {
  return (Handler inner) => withAuth(auth, inner);
}

// ── Utilities ─────────────────────────────────────────────────────────────────

String? _extractToken(Request request) {
  // Only accept Bearer token from Authorization header.
  // Cookie-based auth is intentionally not supported to prevent CSRF attacks
  // where a browser auto-sends cookies on cross-origin requests.
  final authHeader = request.headers['authorization'];
  if (authHeader != null && authHeader.startsWith('Bearer ')) {
    return authHeader.substring(7).trim();
  }
  return null;
}

Response _badRequest(String message) => Response(
      400,
      body: jsonEncode({'error': message}),
      headers: _jsonHeaders,
    );

String _mimeFor(String path) {
  if (path.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (path.endsWith('.css')) return 'text/css; charset=utf-8';
  if (path.endsWith('.html')) return 'text/html; charset=utf-8';
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.svg')) return 'image/svg+xml';
  if (path.endsWith('.ico')) return 'image/x-icon';
  if (path.endsWith('.json')) return 'application/json; charset=utf-8';
  if (path.endsWith('.woff2')) return 'font/woff2';
  if (path.endsWith('.ttf')) return 'font/ttf';
  return 'application/octet-stream';
}

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

const _placeholderHtml = '''<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>BudgetSeal Web</title>
<style>body{font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;background:#F7F5F1;}
.card{background:#fff;border-radius:16px;padding:40px;text-align:center;box-shadow:0 2px 12px rgba(0,0,0,.08);}
h1{color:#8A5E0F;margin:0 0 8px;}p{color:#6B655B;}</style></head>
<body><div class="card"><h1>BudgetSeal Web</h1><p>Loading web interface...</p></div></body>
</html>''';
