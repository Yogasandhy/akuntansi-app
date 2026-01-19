/// Accounts screen - Chart of Accounts management
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../application/account_providers.dart';
import '../../domain/models/account.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAccountsAsync = ref.watch(groupedAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(groupedAccountsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: groupedAccountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppConstants.spacingMd),
              Text('Error: $error'),
              const SizedBox(height: AppConstants.spacingMd),
              ElevatedButton(
                onPressed: () => ref.invalidate(groupedAccountsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (grouped) {
          if (grouped.values.every((list) => list.isEmpty)) {
            return const Center(
              child: Text(
                'Belum ada akun. Seed default accounts terlebih dahulu.',
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            children: AccountType.values.map((type) {
              final accounts = grouped[type] ?? [];
              if (accounts.isEmpty) return const SizedBox.shrink();

              return _AccountTypeSection(
                type: type,
                accounts: accounts,
                onAccountTap: (account) {
                  context.go('/accounts/${account.uid}/ledger');
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    AccountType selectedType = AccountType.asset;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Akun Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<AccountType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Tipe Akun'),
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedType = value);
                },
              ),
              const SizedBox(height: AppConstants.spacingMd),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Kode Akun',
                  hintText: 'Contoh: 1-1001',
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Akun',
                  hintText: 'Contoh: Kas Kecil',
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.isNotEmpty &&
                    nameController.text.isNotEmpty) {
                  final repo = ref.read(accountRepositoryProvider);
                  await repo.create(
                    code: codeController.text,
                    name: nameController.text,
                    type: selectedType,
                  );
                  ref.invalidate(groupedAccountsProvider);
                  ref.invalidate(activeAccountsProvider);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(AccountType type) {
    return switch (type) {
      AccountType.asset => 'Aset',
      AccountType.liability => 'Kewajiban',
      AccountType.equity => 'Modal',
      AccountType.revenue => 'Pendapatan',
      AccountType.expense => 'Beban',
    };
  }
}

class _AccountTypeSection extends StatelessWidget {
  final AccountType type;
  final List<Account> accounts;
  final ValueChanged<Account> onAccountTap;

  const _AccountTypeSection({
    required this.type,
    required this.accounts,
    required this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: _getTypeColor(type).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusLg - 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getTypeColor(type),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  _getTypeLabel(type),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(type),
                  ),
                ),
                const Spacer(),
                Text(
                  '${accounts.length} akun',
                  style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                ),
              ],
            ),
          ),
          ...accounts.map(
            (account) => _AccountRow(
              account: account,
              onTap: () => onAccountTap(account),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(AccountType type) {
    return switch (type) {
      AccountType.asset => AppColors.assetColor,
      AccountType.liability => AppColors.liabilityColor,
      AccountType.equity => AppColors.equityColor,
      AccountType.revenue => AppColors.revenueColor,
      AccountType.expense => AppColors.expenseColor,
    };
  }

  String _getTypeLabel(AccountType type) {
    return switch (type) {
      AccountType.asset => 'Aset',
      AccountType.liability => 'Kewajiban',
      AccountType.equity => 'Modal',
      AccountType.revenue => 'Pendapatan',
      AccountType.expense => 'Beban',
    };
  }
}

class _AccountRow extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;

  const _AccountRow({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm + 4,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.neutral200)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                account.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                account.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.neutral400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
