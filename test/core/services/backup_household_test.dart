import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:budgetseal/core/database/app_database.dart';
import 'package:budgetseal/core/services/auto_backup_service.dart';

void main() {
  test('reads the household id from a backup file; rejects other files',
      () async {
    final dir = Directory.systemTemp.createTempSync('bs_backup_test');
    try {
      final file = File(p.join(dir.path, 'backup.db'));
      final db = AppDatabase.forTesting(NativeDatabase(file));
      await db.into(db.households).insert(HouseholdsCompanion.insert(
          id: 'hh-1', name: 'Home', createdByDeviceId: 'd'));
      await db.close();
      expect(await AutoBackupService.backupHouseholdId(file.path), 'hh-1');

      final text = File(p.join(dir.path, 'notes.db'))
        ..writeAsStringSync('not a database');
      expect(await AutoBackupService.backupHouseholdId(text.path), isNull);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
