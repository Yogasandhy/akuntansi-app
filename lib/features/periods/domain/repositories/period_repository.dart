/// Period repository for managing accounting periods
library;

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/database/database_service.dart';
import '../../../../shared/database/audit_log.dart';
import '../models/period.dart';

class PeriodRepository {
  static final _uuid = const Uuid();

  Isar get _db => DatabaseService.instance;

  /// Get all periods
  Future<List<Period>> getAll() async {
    return await _db.periods.where().sortByStartDateDesc().findAll();
  }

  /// Get active period
  Future<Period?> getActive() async {
    return await _db.periods.filter().isActiveEqualTo(true).findFirst();
  }

  /// Get period by ID
  Future<Period?> getById(String uid) async {
    return await _db.periods.filter().uidEqualTo(uid).findFirst();
  }

  /// Get period containing a date
  Future<Period?> getByDate(DateTime date) async {
    final periods = await getAll();
    for (final period in periods) {
      if (period.containsDate(date)) {
        return period;
      }
    }
    return null;
  }

  /// Create a new period
  Future<Period> create({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool setActive = false,
  }) async {
    final period = Period.create(
      uid: _uuid.v4(),
      name: name,
      startDate: startDate,
      endDate: endDate,
      isActive: setActive,
    );

    await _db.writeTxn(() async {
      // If setting as active, deactivate other periods
      if (setActive) {
        final currentActive = await _db.periods
            .filter()
            .isActiveEqualTo(true)
            .findFirst();
        if (currentActive != null) {
          currentActive.isActive = false;
          await _db.periods.put(currentActive);
        }
      }

      await _db.periods.put(period);

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.create,
        entityType: 'period',
        entityId: period.uid,
        description: 'Periode "$name" dibuat',
      );
      await _db.auditLogs.put(log);
    });

    return period;
  }

  /// Create a monthly period
  Future<Period> createMonthly({
    required DateTime date,
    bool setActive = false,
  }) async {
    final period = Period.fromMonth(
      uid: _uuid.v4(),
      date: date,
      isActive: setActive,
    );

    await _db.writeTxn(() async {
      // If setting as active, deactivate other periods
      if (setActive) {
        final currentActive = await _db.periods
            .filter()
            .isActiveEqualTo(true)
            .findFirst();
        if (currentActive != null) {
          currentActive.isActive = false;
          await _db.periods.put(currentActive);
        }
      }

      await _db.periods.put(period);

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.create,
        entityType: 'period',
        entityId: period.uid,
        description: 'Periode "${period.name}" dibuat',
      );
      await _db.auditLogs.put(log);
    });

    return period;
  }

  /// Set a period as active
  Future<Period> setActive(String uid) async {
    final period = await getById(uid);
    if (period == null) {
      throw Exception('Periode tidak ditemukan');
    }
    if (period.isClosed) {
      throw Exception('Periode yang sudah ditutup tidak dapat diaktifkan');
    }

    await _db.writeTxn(() async {
      // Deactivate all periods first
      final allPeriods = await _db.periods.where().findAll();
      for (final p in allPeriods) {
        if (p.isActive) {
          p.isActive = false;
          await _db.periods.put(p);
        }
      }

      // Activate this period
      period.isActive = true;
      await _db.periods.put(period);
    });

    return period;
  }

  /// Close a period
  Future<Period> close(String uid) async {
    final period = await getById(uid);
    if (period == null) {
      throw Exception('Periode tidak ditemukan');
    }
    if (period.isClosed) {
      throw Exception('Periode sudah ditutup');
    }

    period.isClosed = true;
    period.closedAt = DateTime.now();
    if (period.isActive) {
      period.isActive = false;
    }

    await _db.writeTxn(() async {
      await _db.periods.put(period);

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.close,
        entityType: 'period',
        entityId: period.uid,
        description: 'Periode "${period.name}" ditutup',
      );
      await _db.auditLogs.put(log);
    });

    return period;
  }

  /// Reopen a period (if needed for corrections)
  Future<Period> reopen(String uid) async {
    final period = await getById(uid);
    if (period == null) {
      throw Exception('Periode tidak ditemukan');
    }
    if (!period.isClosed) {
      throw Exception('Periode tidak dalam status tertutup');
    }

    period.isClosed = false;
    period.closedAt = null;

    await _db.writeTxn(() async {
      await _db.periods.put(period);

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.open,
        entityType: 'period',
        entityId: period.uid,
        description: 'Periode "${period.name}" dibuka kembali',
      );
      await _db.auditLogs.put(log);
    });

    return period;
  }

  /// Initialize with current month if no periods exist
  Future<Period> initializeIfEmpty() async {
    final existing = await getAll();
    if (existing.isNotEmpty) {
      // Return active or first period
      final active = await getActive();
      return active ?? existing.first;
    }

    // Create current month as active period
    return await createMonthly(date: DateTime.now(), setActive: true);
  }
}
