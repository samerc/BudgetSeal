import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';

import 'recurring_handler.dart';
import '_validation.dart';

// Subscriptions are recurring expenses with `isSubscription` set; the
// recurring handlers do the work with `subscription: true`.

// ── GET /api/subscriptions ────────────────────────────────────────────────────

Handler listSubscriptionsHandler(Ref ref) =>
    (Request request) => listRecurring(ref, subscriptions: true);

// ── POST /api/subscriptions ───────────────────────────────────────────────────

Handler createSubscriptionHandler(Ref ref) => (Request request) async {
      final body = await parseBody(request);
      if (body == null) return badRequest('Invalid JSON body');
      return createRecurring(ref, body, subscription: true);
    };

// ── PUT /api/subscriptions/:id ────────────────────────────────────────────────

Handler updateSubscriptionHandler(Ref ref) =>
    (Request request) => updateRecurring(ref, request, subscription: true);

// ── DELETE /api/subscriptions/:id ─────────────────────────────────────────────

Handler deleteSubscriptionHandler(Ref ref) =>
    (Request request) => deleteRecurring(ref, request, subscription: true);
