/// Audit log model for tracking changes
library;

import 'package:isar/isar.dart';

part 'audit_log.g.dart';

/// Audit action types
enum AuditAction { create, update, delete, post, void_, close, open }

@collection
class AuditLog {
  Id id = Isar.autoIncrement;

  /// Timestamp of the action
  @Index()
  late DateTime timestamp;

  /// Type of action performed
  @Enumerated(EnumType.ordinal)
  late AuditAction action;

  /// Entity type (e.g., "journal", "account", "period")
  late String entityType;

  /// Entity ID
  @Index()
  late String entityId;

  /// Description of the action
  late String description;

  /// Detailed changes in JSON format
  String? details;

  AuditLog();

  /// Factory constructor
  factory AuditLog.create({
    required AuditAction action,
    required String entityType,
    required String entityId,
    required String description,
    String? details,
  }) {
    return AuditLog()
      ..timestamp = DateTime.now()
      ..action = action
      ..entityType = entityType
      ..entityId = entityId
      ..description = description
      ..details = details;
  }

  /// Get action label in Indonesian
  String get actionLabel {
    return switch (action) {
      AuditAction.create => 'Dibuat',
      AuditAction.update => 'Diubah',
      AuditAction.delete => 'Dihapus',
      AuditAction.post => 'Diposting',
      AuditAction.void_ => 'Dibatalkan',
      AuditAction.close => 'Ditutup',
      AuditAction.open => 'Dibuka',
    };
  }
}
