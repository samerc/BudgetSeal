import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../core/services/household_members.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_colors.dart';

/// Settings › Members (roadmap #5): who uses this budget, each a grown-up
/// or a kid (user's decision: kids ask, grown-ups approve; a kid's phone
/// shows only their envelopes). Only a grown-up can change roles.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  Future<void> _setRole(
      BuildContext context, WidgetRef ref, User u, bool kid) async {
    final tr = S.of(context);
    final db = ref.read(databaseProvider);
    try {
      await (db.update(db.users)..where((x) => x.id.equals(u.id))).write(
          UsersCompanion(
              role: Value(kid ? kidRole : 'member'),
              lastModified: Value(DateTime.now())));
    } catch (e) {
      debugPrint('[Members] Role change failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr.commonSomethingWentWrong),
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = S.of(context);
    final members = [
      ...ref.watch(membersProvider).value ?? const <User>[]
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final iAmKid = ref.watch(amKidProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr.tileMembers)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(tr.membersIntro,
                style: TextStyle(fontSize: 13.5, color: AppColors.ts(context))),
          ),
          if (members.isEmpty)
            Text(tr.membersNone,
                style: TextStyle(color: AppColors.ts(context)))
          else
            Container(
              decoration: AppColors.card(context),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final u in members)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    // The name, then the choice (side by side they don't
                    // fit a small phone with large text).
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.deviceId == DeviceIdentity.id
                              ? tr.membersYou(u.name)
                              : u.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                                value: false, label: Text(tr.membersGrownup)),
                            ButtonSegment(
                                value: true, label: Text(tr.membersKid)),
                          ],
                          selected: {u.role == kidRole},
                          onSelectionChanged: iAmKid
                              ? null
                              : (v) => _setRole(context, ref, u, v.first),
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
          if (iAmKid)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Text(tr.membersOnlyGrownups,
                  style: TextStyle(fontSize: 13, color: AppColors.ts(context))),
            ),
        ],
      ),
    );
  }
}
