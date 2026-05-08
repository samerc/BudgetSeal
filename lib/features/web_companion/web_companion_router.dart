import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'api/accounts_handler.dart';
import 'api/categories_handler.dart';
import 'api/dashboard_handler.dart';
import 'api/envelopes_handler.dart';
import 'api/recurring_handler.dart';
import 'api/reports_handler.dart';
import 'api/subscriptions_handler.dart';
import 'api/transactions_handler.dart';
import 'web_companion_auth.dart';

/// Assembles the full shelf request handler.
Handler buildRouter(Ref ref, WebCompanionAuth auth) {
  final router = Router();

  // ── Auth (no token required) ────────────────────────────────────────────────

  router.post('/auth/pin', _pinHandler(auth));
  router.get('/auth/status', _authStatusHandler(auth));

  // ── Static assets ───────────────────────────────────────────────────────────

  router.get('/assets/<file|[^]*>', _assetsHandler());

  // ── Protected API ───────────────────────────────────────────────────────────

  final api = Router();

  api.get('/dashboard', dashboardHandler(ref));

  api.get('/transactions', listTransactionsHandler(ref));
  api.post('/transactions', createTransactionHandler(ref));
  api.get('/transactions/<id>', getTransactionHandler(ref));
  api.put('/transactions/<id>', updateTransactionHandler(ref));
  api.delete('/transactions/<id>', deleteTransactionHandler(ref));

  api.get('/categories', listCategoriesHandler(ref));
  api.post('/categories', createCategoryHandler(ref));
  api.put('/categories/<id>', updateCategoryHandler(ref));

  api.get('/accounts', listAccountsHandler(ref));
  api.post('/accounts', createAccountHandler(ref));

  api.get('/envelopes', listEnvelopesHandler(ref));
  api.post('/envelopes/<id>/fund', fundEnvelopeHandler(ref));

  api.get('/recurring', listRecurringHandler(ref));
  api.post('/recurring', createRecurringHandler(ref));
  api.put('/recurring/<id>', updateRecurringHandler(ref));
  api.delete('/recurring/<id>', deleteRecurringHandler(ref));

  api.get('/subscriptions', listSubscriptionsHandler(ref));
  api.post('/subscriptions', createSubscriptionHandler(ref));
  api.put('/subscriptions/<id>', updateSubscriptionHandler(ref));

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
        body: jsonEncode({'error': e.message, 'isLockout': e.isLockout}),
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

// ── Static asset handler ──────────────────────────────────────────────────────

Handler _assetsHandler() {
  return (Request request) async {
    final file = request.params['file'];
    if (file == null || file.isEmpty) return Response.notFound('Not found');

    if (file.contains('..') || file.contains('//')) {
      return Response.forbidden('Invalid path');
    }

    try {
      final data = await rootBundle.load('assets/web/$file');
      return Response.ok(
        data.buffer.asUint8List(),
        headers: {'content-type': _mimeFor(file)},
      );
    } catch (_) {
      return Response.notFound('Asset not found: $file');
    }
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
  return 'application/octet-stream';
}

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

const _placeholderHtml = '''<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>PocketPlan Web</title>
<style>body{font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;background:#F1F5F9;}
.card{background:#fff;border-radius:14px;padding:40px;text-align:center;box-shadow:0 2px 12px rgba(0,0,0,.08);}
h1{color:#2563EB;margin:0 0 8px;}p{color:#64748B;}</style></head>
<body><div class="card"><h1>PocketPlan Web</h1><p>Loading web interface...</p></div></body>
</html>''';
