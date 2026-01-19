/// Account ledger screen - Shows all transactions for an account
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/account_providers.dart';
import '../../../journal/application/journal_providers.dart';
import '../../../journal/domain/models/journal_entry.dart';

class AccountLedgerScreen extends ConsumerWidget {
  final String accountId;

  const AccountLedgerScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountProvider(accountId));
    final ledgerAsync = ref.watch(accountLedgerProvider(accountId));

    return Scaffold(
      appBar: AppBar(
        title: accountAsync.when(
          loading: () => const Text('Memuat...'),
          error: (e, s) => const Text('Error'),
          data: (account) => Text(account?.name ?? 'Akun tidak ditemukan'),
        ),
      ),
      body: ledgerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (lines) {
          if (lines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: AppColors.neutral300,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  const Text('Belum ada transaksi'),
                ],
              ),
            );
          }

          // Calculate running balance
          double runningBalance = 0;
          final linesWithBalance = <(JournalLine, double)>[];

          for (final line in lines) {
            runningBalance += line.debit - line.credit;
            linesWithBalance.add((line, runningBalance));
          }

          return Column(
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                color: AppColors.neutral100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      label: 'Total Debit',
                      value: AppFormatters.currency(
                        lines.fold(0.0, (sum, l) => sum + l.debit),
                      ),
                      color: AppColors.debit,
                    ),
                    _SummaryItem(
                      label: 'Total Kredit',
                      value: AppFormatters.currency(
                        lines.fold(0.0, (sum, l) => sum + l.credit),
                      ),
                      color: AppColors.credit,
                    ),
                    _SummaryItem(
                      label: 'Saldo',
                      value: AppFormatters.currency(runningBalance),
                      color: runningBalance >= 0
                          ? AppColors.profit
                          : AppColors.loss,
                    ),
                  ],
                ),
              ),
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingSm,
                ),
                color: AppColors.neutral50,
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Debit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Kredit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Saldo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              // Transactions list
              Expanded(
                child: ListView.builder(
                  itemCount: linesWithBalance.length,
                  itemBuilder: (context, index) {
                    final (line, balance) = linesWithBalance[index];
                    return _LedgerRow(line: line, balance: balance);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final JournalLine line;
  final double balance;

  const _LedgerRow({required this.line, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm + 4,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.memo ?? 'Transaksi',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              line.debit > 0 ? AppFormatters.currency(line.debit) : '-',
              style: TextStyle(
                fontSize: 12,
                color: line.debit > 0 ? AppColors.debit : AppColors.neutral400,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              line.credit > 0 ? AppFormatters.currency(line.credit) : '-',
              style: TextStyle(
                fontSize: 12,
                color: line.credit > 0
                    ? AppColors.credit
                    : AppColors.neutral400,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              AppFormatters.currency(balance),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: balance >= 0 ? AppColors.neutral700 : AppColors.loss,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
