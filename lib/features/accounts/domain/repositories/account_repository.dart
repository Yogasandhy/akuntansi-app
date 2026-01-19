/// Account repository for managing account data
library;

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/database/database_service.dart';
import '../../../../shared/database/audit_log.dart';
import '../models/account.dart';

class AccountRepository {
  static final _uuid = const Uuid();

  Isar get _db => DatabaseService.instance;

  /// Get all accounts
  Future<List<Account>> getAll() async {
    return await _db.accounts.where().sortByCode().findAll();
  }

  /// Get all active accounts
  Future<List<Account>> getActive() async {
    return await _db.accounts
        .filter()
        .isActiveEqualTo(true)
        .sortByCode()
        .findAll();
  }

  /// Get accounts by type
  Future<List<Account>> getByType(AccountType type) async {
    return await _db.accounts
        .filter()
        .typeEqualTo(type)
        .isActiveEqualTo(true)
        .sortByCode()
        .findAll();
  }

  /// Get account by ID
  Future<Account?> getById(String uid) async {
    return await _db.accounts.filter().uidEqualTo(uid).findFirst();
  }

  /// Get account by code
  Future<Account?> getByCode(String code) async {
    return await _db.accounts.filter().codeEqualTo(code).findFirst();
  }

  /// Get sub-accounts of a parent
  Future<List<Account>> getSubAccounts(String parentId) async {
    return await _db.accounts
        .filter()
        .parentIdEqualTo(parentId)
        .sortByCode()
        .findAll();
  }

  /// Create a new account
  Future<Account> create({
    required String code,
    required String name,
    required AccountType type,
    String? parentId,
    String? description,
  }) async {
    final account = Account.create(
      uid: _uuid.v4(),
      code: code,
      name: name,
      type: type,
      parentId: parentId,
      description: description,
    );

    await _db.writeTxn(() async {
      await _db.accounts.put(account);

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.create,
        entityType: 'account',
        entityId: account.uid,
        description: 'Akun "$name" ($code) dibuat',
      );
      await _db.auditLogs.put(log);
    });

    return account;
  }

  /// Update an account
  Future<Account> update(Account account) async {
    account.updatedAt = DateTime.now();

    await _db.writeTxn(() async {
      await _db.accounts.put(account);

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.update,
        entityType: 'account',
        entityId: account.uid,
        description: 'Akun "${account.name}" (${account.code}) diubah',
      );
      await _db.auditLogs.put(log);
    });

    return account;
  }

  /// Deactivate an account (soft delete)
  Future<void> deactivate(String uid) async {
    final account = await getById(uid);
    if (account == null) return;

    account.isActive = false;
    account.updatedAt = DateTime.now();

    await _db.writeTxn(() async {
      await _db.accounts.put(account);

      // Audit log
      final log = AuditLog.create(
        action: AuditAction.delete,
        entityType: 'account',
        entityId: account.uid,
        description: 'Akun "${account.name}" (${account.code}) dinonaktifkan',
      );
      await _db.auditLogs.put(log);
    });
  }

  /// Check if account code is unique
  Future<bool> isCodeUnique(String code, {String? excludeUid}) async {
    final existing = await getByCode(code);
    if (existing == null) return true;
    if (excludeUid != null && existing.uid == excludeUid) return true;
    return false;
  }

  /// Seed default Chart of Accounts
  Future<void> seedDefaults() async {
    // Check if already seeded
    final count = await _db.accounts.count();
    if (count > 0) return;

    final defaults = [
      // Assets (1-xxxx)
      ('1-1000', 'Kas', AccountType.asset, null),
      ('1-1100', 'Bank', AccountType.asset, null),
      ('1-1200', 'Piutang Usaha', AccountType.asset, null),
      ('1-1300', 'Persediaan', AccountType.asset, null),
      ('1-2000', 'Aset Tetap', AccountType.asset, null),

      // Liabilities (2-xxxx)
      ('2-1000', 'Hutang Usaha', AccountType.liability, null),
      ('2-1100', 'Hutang Bank', AccountType.liability, null),
      ('2-1200', 'Hutang Pajak', AccountType.liability, null),

      // Equity (3-xxxx)
      ('3-1000', 'Modal', AccountType.equity, null),
      ('3-2000', 'Laba Ditahan', AccountType.equity, null),

      // Revenue (4-xxxx)
      ('4-1000', 'Pendapatan Usaha', AccountType.revenue, null),
      ('4-2000', 'Pendapatan Lain-lain', AccountType.revenue, null),

      // Expenses (5-xxxx)
      ('5-1000', 'Beban Operasional', AccountType.expense, null),
      ('5-1100', 'Beban Gaji', AccountType.expense, null),
      ('5-1200', 'Beban Sewa', AccountType.expense, null),
      ('5-1300', 'Beban Utilitas', AccountType.expense, null),
      ('5-1400', 'Beban Perlengkapan', AccountType.expense, null),
      ('5-1500', 'Beban Transportasi', AccountType.expense, null),
      ('5-9000', 'Beban Lain-lain', AccountType.expense, null),
    ];

    await _db.writeTxn(() async {
      for (final (code, name, type, parentId) in defaults) {
        final account = Account.create(
          uid: _uuid.v4(),
          code: code,
          name: name,
          type: type,
          parentId: parentId,
        );
        await _db.accounts.put(account);
      }
    });
  }
}
