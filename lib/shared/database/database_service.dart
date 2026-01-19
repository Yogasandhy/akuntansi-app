/// Database service for managing Isar database connection
library;

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/accounts/domain/models/account.dart';
import '../../features/journal/domain/models/journal_entry.dart';
import '../../features/periods/domain/models/period.dart';
import 'audit_log.dart';

class DatabaseService {
  static Isar? _isar;

  /// Get the Isar instance
  static Isar get instance {
    if (_isar == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _isar!;
  }

  /// Initialize the database
  static Future<void> initialize() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        AccountSchema,
        JournalEntrySchema,
        JournalLineSchema,
        PeriodSchema,
        AuditLogSchema,
      ],
      directory: dir.path,
      name: 'akuntansi_db',
    );
  }

  /// Close the database
  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  /// Clear all data (for testing or reset)
  static Future<void> clearAll() async {
    await _isar?.writeTxn(() async {
      await _isar?.clear();
    });
  }
}
