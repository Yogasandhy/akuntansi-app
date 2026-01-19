/// Riverpod providers for accounts feature
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/account.dart';
import '../domain/repositories/account_repository.dart';

/// Account repository provider
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

/// All accounts provider
final allAccountsProvider = FutureProvider<List<Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAll();
});

/// Active accounts provider
final activeAccountsProvider = FutureProvider<List<Account>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getActive();
});

/// Accounts by type provider
final accountsByTypeProvider =
    FutureProvider.family<List<Account>, AccountType>((ref, type) async {
      final repository = ref.watch(accountRepositoryProvider);
      return repository.getByType(type);
    });

/// Single account provider
final accountProvider = FutureProvider.family<Account?, String>((
  ref,
  uid,
) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getById(uid);
});

/// Grouped accounts (for Chart of Accounts display)
final groupedAccountsProvider = FutureProvider<Map<AccountType, List<Account>>>(
  (ref) async {
    final accounts = await ref.watch(activeAccountsProvider.future);

    final grouped = <AccountType, List<Account>>{};
    for (final type in AccountType.values) {
      grouped[type] = accounts.where((a) => a.type == type).toList();
    }

    return grouped;
  },
);
