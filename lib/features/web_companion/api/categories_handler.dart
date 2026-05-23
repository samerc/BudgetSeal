import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/household_provider.dart';
import '_serializers.dart';
import '_validation.dart';

const _uuid = Uuid();

// ── GET /api/categories ───────────────────────────────────────────────────────

Handler listCategoriesHandler(Ref ref) {
  return (Request request) async {
    final db = ref.read(databaseProvider);
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    try {
      final categories = await (db.select(db.categories)
            ..where((c) =>
                c.householdId.equals(householdId) & c.archived.equals(false))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .get();

      return ok({'items': categories.map(categoryToJson).toList()});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── POST /api/categories ──────────────────────────────────────────────────────

Handler createCategoryHandler(Ref ref) {
  return (Request request) async {
    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final name = requireString(body, 'name');
    if (name == null) return badRequest('name is required');

    final transactionType = optString(body, 'transactionType') ?? 'expense';
    if (!['income', 'expense'].contains(transactionType)) {
      return badRequest('transactionType must be income or expense');
    }

    final colorHex = optString(body, 'colorHex') ?? '#607D8B';
    if (!RegExp(r'^#[0-9A-Fa-f]{3}([0-9A-Fa-f]{3})?$').hasMatch(colorHex)) {
      return badRequest('colorHex must be a valid hex color (e.g. #FF5733)');
    }

    final db = ref.read(databaseProvider);

    // Validate FK references
    final parentId = optString(body, 'parentId');
    if (parentId != null && await validateIdExists(db, 'categories', parentId) == null) {
      return badRequest('parentId does not exist');
    }
    final allocationId = optString(body, 'allocationId');
    if (allocationId != null && await validateIdExists(db, 'allocations', allocationId) == null) {
      return badRequest('allocationId does not exist');
    }
    final defaultAccountId = optString(body, 'defaultAccountId');
    if (defaultAccountId != null && await validateIdExists(db, 'accounts', defaultAccountId) == null) {
      return badRequest('defaultAccountId does not exist');
    }

    try {
      final id = _uuid.v4();
      await db.into(db.categories).insert(CategoriesCompanion.insert(
            id: id,
            householdId: householdId,
            name: truncate(name, kMaxNameLength),
            icon: Value(truncate(optString(body, 'icon') ?? 'category', 20)),
            colorHex: Value(colorHex),
            transactionType: Value(transactionType),
            parentId: Value(parentId),
            allocationId: Value(allocationId),
            defaultAccountId: Value(defaultAccountId),
          ));
      return created({'id': id});
    } catch (e) {
      return serverError(e);
    }
  };
}

// ── PUT /api/categories/:id ───────────────────────────────────────────────────

Handler updateCategoryHandler(Ref ref) {
  return (Request request) async {
    final id = request.params['id'];
    if (id == null || id.isEmpty) return badRequest('Missing id');

    final body = await parseBody(request);
    if (body == null) return badRequest('Invalid JSON body');

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return forbidden();

    final db = ref.read(databaseProvider);

    try {
      final existing = await (db.select(db.categories)
            ..where(
                (c) => c.id.equals(id) & c.householdId.equals(householdId)))
          .getSingleOrNull();
      if (existing == null) return notFound();

      // Validate optional enum/format fields before writing
      Value<String> colorHexValue = const Value.absent();
      if (body.containsKey('colorHex')) {
        final c = optString(body, 'colorHex') ?? existing.colorHex;
        if (!RegExp(r'^#[0-9A-Fa-f]{3}([0-9A-Fa-f]{3})?$').hasMatch(c)) {
          return badRequest('colorHex must be a valid hex color (e.g. #FF5733)');
        }
        colorHexValue = Value(c);
      }

      Value<String> txTypeValue = const Value.absent();
      if (body.containsKey('transactionType')) {
        final t = optString(body, 'transactionType') ?? existing.transactionType;
        if (!['income', 'expense'].contains(t)) {
          return badRequest('transactionType must be income or expense');
        }
        txTypeValue = Value(t);
      }

      // Validate FK references
      final allocId = body.containsKey('allocationId')
          ? optString(body, 'allocationId') : null;
      if (allocId != null && await validateIdExists(db, 'allocations', allocId) == null) {
        return badRequest('allocationId does not exist');
      }

      await (db.update(db.categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(
          name: body.containsKey('name')
              ? Value(truncate(
                  requireString(body, 'name') ?? existing.name, kMaxNameLength))
              : const Value.absent(),
          icon: body.containsKey('icon')
              ? Value(truncate(optString(body, 'icon') ?? existing.icon, 20))
              : const Value.absent(),
          colorHex: colorHexValue,
          transactionType: txTypeValue,
          allocationId: body.containsKey('allocationId')
              ? Value(allocId)
              : const Value.absent(),
          archived: body.containsKey('archived')
              ? Value(optBool(body, 'archived') ?? existing.archived)
              : const Value.absent(),
          lastModified: Value(DateTime.now()),
        ),
      );
      return ok({'id': id});
    } catch (e) {
      return serverError(e);
    }
  };
}
