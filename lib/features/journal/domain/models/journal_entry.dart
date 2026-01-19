/// Journal Entry model representing a transaction record
library;

import 'package:isar/isar.dart';

part 'journal_entry.g.dart';

/// Journal status enum
enum JournalStatus {
  draft, // Belum diposting
  posted, // Sudah diposting ke ledger
  voided, // Dibatalkan
}

@collection
class JournalEntry {
  Id id = Isar.autoIncrement;

  /// Unique identifier (UUID)
  @Index(unique: true)
  late String uid;

  /// Transaction date
  @Index()
  late DateTime date;

  /// Description/memo
  late String description;

  /// External reference number
  String? reference;

  /// Period ID this journal belongs to
  @Index()
  late String periodId;

  /// Journal status
  @Enumerated(EnumType.ordinal)
  late JournalStatus status;

  /// Created timestamp
  late DateTime createdAt;

  /// Updated timestamp
  late DateTime updatedAt;

  /// Posted timestamp
  DateTime? postedAt;

  /// Voided timestamp
  DateTime? voidedAt;

  /// Void reason
  String? voidReason;

  JournalEntry();

  /// Factory constructor
  factory JournalEntry.create({
    required String uid,
    required DateTime date,
    required String description,
    String? reference,
    required String periodId,
    JournalStatus status = JournalStatus.draft,
  }) {
    final now = DateTime.now();
    return JournalEntry()
      ..uid = uid
      ..date = date
      ..description = description
      ..reference = reference
      ..periodId = periodId
      ..status = status
      ..createdAt = now
      ..updatedAt = now;
  }

  /// Get status label in Indonesian
  String get statusLabel {
    return switch (status) {
      JournalStatus.draft => 'Draft',
      JournalStatus.posted => 'Posted',
      JournalStatus.voided => 'Batal',
    };
  }

  /// Check if this journal can be edited
  bool get canEdit => status == JournalStatus.draft;

  /// Check if this journal can be posted
  bool get canPost => status == JournalStatus.draft;

  /// Check if this journal can be voided
  bool get canVoid => status == JournalStatus.posted;
}

@collection
class JournalLine {
  Id id = Isar.autoIncrement;

  /// Unique identifier (UUID)
  @Index(unique: true)
  late String uid;

  /// Parent journal entry ID
  @Index()
  late String journalId;

  /// Account ID
  @Index()
  late String accountId;

  /// Account code (denormalized for display)
  late String accountCode;

  /// Account name (denormalized for display)
  late String accountName;

  /// Debit amount (only one of debit/credit should be > 0)
  late double debit;

  /// Credit amount
  late double credit;

  /// Line memo/description
  String? memo;

  /// Line order
  late int lineOrder;

  JournalLine();

  /// Factory constructor
  factory JournalLine.create({
    required String uid,
    required String journalId,
    required String accountId,
    required String accountCode,
    required String accountName,
    double debit = 0,
    double credit = 0,
    String? memo,
    required int lineOrder,
  }) {
    return JournalLine()
      ..uid = uid
      ..journalId = journalId
      ..accountId = accountId
      ..accountCode = accountCode
      ..accountName = accountName
      ..debit = debit
      ..credit = credit
      ..memo = memo
      ..lineOrder = lineOrder;
  }

  /// Check if this line has a debit
  bool get isDebit => debit > 0;

  /// Check if this line has a credit
  bool get isCredit => credit > 0;

  /// Get the amount (debit or credit)
  double get amount => debit > 0 ? debit : credit;
}
