/// Journal repository for managing journal entries and lines
library;

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/database/database_service.dart';
import '../../../../shared/database/audit_log.dart';
import '../models/journal_entry.dart';

/// Class representing a full journal with its lines
class JournalWithLines {
  final JournalEntry journal;
  final List<JournalLine> lines;

  JournalWithLines({required this.journal, required this.lines});

  /// Calculate total debit
  double get totalDebit => lines.fold(0, (sum, line) => sum + line.debit);

  /// Calculate total credit
  double get totalCredit => lines.fold(0, (sum, line) => sum + line.credit);

  /// Check if balanced
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;
}

class JournalRepository {
  static final _uuid = const Uuid();

  Isar get _db => DatabaseService.instance;

  /// Get all journal entries
  Future<List<JournalEntry>> getAll() async {
    return await _db.journalEntrys.where().sortByDateDesc().findAll();
  }

  /// Get journal entries by period
  Future<List<JournalEntry>> getByPeriod(String periodId) async {
    return await _db.journalEntrys
        .filter()
        .periodIdEqualTo(periodId)
        .sortByDateDesc()
        .findAll();
  }

  /// Get journal entries by status
  Future<List<JournalEntry>> getByStatus(JournalStatus status) async {
    return await _db.journalEntrys
        .filter()
        .statusEqualTo(status)
        .sortByDateDesc()
        .findAll();
  }

  /// Get posted journals by period
  Future<List<JournalEntry>> getPostedByPeriod(String periodId) async {
    return await _db.journalEntrys
        .filter()
        .periodIdEqualTo(periodId)
        .statusEqualTo(JournalStatus.posted)
        .sortByDateDesc()
        .findAll();
  }

  /// Get journal entry by ID
  Future<JournalEntry?> getById(String uid) async {
    return await _db.journalEntrys.filter().uidEqualTo(uid).findFirst();
  }

  /// Get journal with lines
  Future<JournalWithLines?> getWithLines(String uid) async {
    final journal = await getById(uid);
    if (journal == null) return null;

    final lines = await getLines(uid);
    return JournalWithLines(journal: journal, lines: lines);
  }

  /// Get lines for a journal
  Future<List<JournalLine>> getLines(String journalId) async {
    return await _db.journalLines
        .filter()
        .journalIdEqualTo(journalId)
        .sortByLineOrder()
        .findAll();
  }

  /// Get lines for an account (ledger)
  Future<List<JournalLine>> getLinesByAccount(String accountId) async {
    // Get all lines for this account from posted journals
    final lines = await _db.journalLines
        .filter()
        .accountIdEqualTo(accountId)
        .findAll();

    // Filter to only include lines from posted journals
    final result = <JournalLine>[];
    for (final line in lines) {
      final journal = await getById(line.journalId);
      if (journal != null && journal.status == JournalStatus.posted) {
        result.add(line);
      }
    }

    return result;
  }

  /// Create a new journal entry with lines
  Future<JournalWithLines> create({
    required DateTime date,
    required String description,
    String? reference,
    required String periodId,
    required List<
      ({
        String accountId,
        String accountCode,
        String accountName,
        double debit,
        double credit,
        String? memo,
      })
    >
    lines,
    bool postImmediately = false,
  }) async {
    final journalUid = _uuid.v4();
    final journal = JournalEntry.create(
      uid: journalUid,
      date: date,
      description: description,
      reference: reference,
      periodId: periodId,
      status: postImmediately ? JournalStatus.posted : JournalStatus.draft,
    );

    if (postImmediately) {
      journal.postedAt = DateTime.now();
    }

    final journalLines = <JournalLine>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      journalLines.add(
        JournalLine.create(
          uid: _uuid.v4(),
          journalId: journalUid,
          accountId: line.accountId,
          accountCode: line.accountCode,
          accountName: line.accountName,
          debit: line.debit,
          credit: line.credit,
          memo: line.memo,
          lineOrder: i,
        ),
      );
    }

    await _db.writeTxn(() async {
      await _db.journalEntrys.put(journal);
      for (final line in journalLines) {
        await _db.journalLines.put(line);
      }

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.create,
        entityType: 'journal',
        entityId: journal.uid,
        description: 'Jurnal "$description" dibuat',
      );
      await _db.auditLogs.put(log);

      if (postImmediately) {
        final postLog = AuditLog.create(
          action: AuditAction.post,
          entityType: 'journal',
          entityId: journal.uid,
          description: 'Jurnal "$description" diposting',
        );
        await _db.auditLogs.put(postLog);
      }
    });

    return JournalWithLines(journal: journal, lines: journalLines);
  }

  /// Update a journal entry (only if draft)
  Future<JournalWithLines> update({
    required String uid,
    required DateTime date,
    required String description,
    String? reference,
    required List<
      ({
        String accountId,
        String accountCode,
        String accountName,
        double debit,
        double credit,
        String? memo,
      })
    >
    lines,
  }) async {
    final existing = await getById(uid);
    if (existing == null) {
      throw Exception('Jurnal tidak ditemukan');
    }
    if (existing.status != JournalStatus.draft) {
      throw Exception('Jurnal yang sudah diposting tidak dapat diubah');
    }

    existing.date = date;
    existing.description = description;
    existing.reference = reference;
    existing.updatedAt = DateTime.now();

    // Create new lines
    final journalLines = <JournalLine>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      journalLines.add(
        JournalLine.create(
          uid: _uuid.v4(),
          journalId: uid,
          accountId: line.accountId,
          accountCode: line.accountCode,
          accountName: line.accountName,
          debit: line.debit,
          credit: line.credit,
          memo: line.memo,
          lineOrder: i,
        ),
      );
    }

    await _db.writeTxn(() async {
      // Delete old lines
      final oldLines = await _db.journalLines
          .filter()
          .journalIdEqualTo(uid)
          .findAll();
      for (final line in oldLines) {
        await _db.journalLines.delete(line.id);
      }

      // Save updated journal and new lines
      await _db.journalEntrys.put(existing);
      for (final line in journalLines) {
        await _db.journalLines.put(line);
      }

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.update,
        entityType: 'journal',
        entityId: existing.uid,
        description: 'Jurnal "$description" diubah',
      );
      await _db.auditLogs.put(log);
    });

    return JournalWithLines(journal: existing, lines: journalLines);
  }

  /// Post a journal (change status to posted)
  Future<JournalEntry> post(String uid) async {
    final journal = await getById(uid);
    if (journal == null) {
      throw Exception('Jurnal tidak ditemukan');
    }
    if (journal.status != JournalStatus.draft) {
      throw Exception('Jurnal sudah diposting atau dibatalkan');
    }

    // Validate balance
    final lines = await getLines(uid);
    final totalDebit = lines.fold(0.0, (sum, line) => sum + line.debit);
    final totalCredit = lines.fold(0.0, (sum, line) => sum + line.credit);
    if ((totalDebit - totalCredit).abs() > 0.01) {
      throw Exception('Total debit dan kredit tidak seimbang');
    }

    journal.status = JournalStatus.posted;
    journal.postedAt = DateTime.now();
    journal.updatedAt = DateTime.now();

    await _db.writeTxn(() async {
      await _db.journalEntrys.put(journal);

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.post,
        entityType: 'journal',
        entityId: journal.uid,
        description: 'Jurnal "${journal.description}" diposting',
      );
      await _db.auditLogs.put(log);
    });

    return journal;
  }

  /// Void a journal (change status to voided)
  Future<JournalEntry> voidJournal(String uid, String reason) async {
    final journal = await getById(uid);
    if (journal == null) {
      throw Exception('Jurnal tidak ditemukan');
    }
    if (journal.status != JournalStatus.posted) {
      throw Exception(
        'Hanya jurnal yang sudah diposting yang dapat dibatalkan',
      );
    }

    journal.status = JournalStatus.voided;
    journal.voidedAt = DateTime.now();
    journal.voidReason = reason;
    journal.updatedAt = DateTime.now();

    await _db.writeTxn(() async {
      await _db.journalEntrys.put(journal);

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.void_,
        entityType: 'journal',
        entityId: journal.uid,
        description: 'Jurnal "${journal.description}" dibatalkan: $reason',
      );
      await _db.auditLogs.put(log);
    });

    return journal;
  }

  /// Delete a draft journal
  Future<void> delete(String uid) async {
    final journal = await getById(uid);
    if (journal == null) return;
    if (journal.status != JournalStatus.draft) {
      throw Exception('Hanya jurnal draft yang dapat dihapus');
    }

    await _db.writeTxn(() async {
      // Delete lines
      final lines = await _db.journalLines
          .filter()
          .journalIdEqualTo(uid)
          .findAll();
      for (final line in lines) {
        await _db.journalLines.delete(line.id);
      }

      // Delete journal
      await _db.journalEntrys.delete(journal.id);

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.delete,
        entityType: 'journal',
        entityId: journal.uid,
        description: 'Jurnal "${journal.description}" dihapus',
      );
      await _db.auditLogs.put(log);
    });
  }

  /// Get summary statistics for a period
  Future<({double totalDebit, double totalCredit, int journalCount})>
  getPeriodSummary(String periodId) async {
    final journals = await getPostedByPeriod(periodId);

    double totalDebit = 0;
    double totalCredit = 0;

    for (final journal in journals) {
      final lines = await getLines(journal.uid);
      for (final line in lines) {
        totalDebit += line.debit;
        totalCredit += line.credit;
      }
    }

    return (
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      journalCount: journals.length,
    );
  }
}
