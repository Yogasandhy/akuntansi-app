/// Account model representing a Chart of Accounts entry
library;

import 'package:isar/isar.dart';

part 'account.g.dart';

/// Account type enum
enum AccountType {
  asset, // Aktiva (Kas, Bank, Piutang, dll)
  liability, // Kewajiban (Hutang, dll)
  equity, // Modal
  revenue, // Pendapatan
  expense, // Beban
}

@collection
class Account {
  Id id = Isar.autoIncrement;

  /// Unique identifier (UUID)
  @Index(unique: true)
  late String uid;

  /// Account code (e.g., "1-1000", "5-1100")
  @Index(unique: true)
  late String code;

  /// Account name
  late String name;

  /// Account type
  @Enumerated(EnumType.ordinal)
  late AccountType type;

  /// Parent account ID (for sub-accounts)
  String? parentId;

  /// Description/notes
  String? description;

  /// Whether the account is active
  late bool isActive;

  /// Whether this account normally has debit balance
  /// (Assets, Expenses = true; Liabilities, Equity, Revenue = false)
  late bool normalDebitBalance;

  /// Created timestamp
  late DateTime createdAt;

  /// Updated timestamp
  late DateTime updatedAt;

  Account();

  /// Factory constructor
  factory Account.create({
    required String uid,
    required String code,
    required String name,
    required AccountType type,
    String? parentId,
    String? description,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return Account()
      ..uid = uid
      ..code = code
      ..name = name
      ..type = type
      ..parentId = parentId
      ..description = description
      ..isActive = isActive
      ..normalDebitBalance =
          type == AccountType.asset || type == AccountType.expense
      ..createdAt = now
      ..updatedAt = now;
  }

  /// Get the account type label in Indonesian
  String get typeLabel {
    return switch (type) {
      AccountType.asset => 'Aset',
      AccountType.liability => 'Kewajiban',
      AccountType.equity => 'Modal',
      AccountType.revenue => 'Pendapatan',
      AccountType.expense => 'Beban',
    };
  }

  /// Get the account type prefix number
  int get typePrefix {
    return switch (type) {
      AccountType.asset => 1,
      AccountType.liability => 2,
      AccountType.equity => 3,
      AccountType.revenue => 4,
      AccountType.expense => 5,
    };
  }
}
