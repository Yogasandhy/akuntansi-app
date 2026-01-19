/// Riverpod providers for dashboard feature
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../shared/database/database_service.dart';
import '../../accounts/domain/models/account.dart';
import '../../journal/domain/models/journal_entry.dart';
import '../../periods/application/period_providers.dart';

/// Dashboard summary data
class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  final double profit;
  final double cashBalance;
  final int transactionCount;
  final String periodName;

  DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.profit,
    required this.cashBalance,
    required this.transactionCount,
    required this.periodName,
  });
}

/// Dashboard summary provider
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final activePeriod = await ref.watch(activePeriodProvider.future);

  if (activePeriod == null) {
    return DashboardSummary(
      totalIncome: 0,
      totalExpense: 0,
      profit: 0,
      cashBalance: 0,
      transactionCount: 0,
      periodName: 'Tidak ada periode aktif',
    );
  }

  final db = DatabaseService.instance;

  // Get all posted journals in this period
  final journals = await db.journalEntrys
      .filter()
      .periodIdEqualTo(activePeriod.uid)
      .statusEqualTo(JournalStatus.posted)
      .findAll();

  double totalIncome = 0;
  double totalExpense = 0;
  double cashBalance = 0;

  // Get all revenue and expense accounts
  final revenueAccounts = await db.accounts
      .filter()
      .typeEqualTo(AccountType.revenue)
      .findAll();
  final expenseAccounts = await db.accounts
      .filter()
      .typeEqualTo(AccountType.expense)
      .findAll();
  final cashAccounts = await db.accounts
      .filter()
      .codeEqualTo('1-1000') // Kas
      .findAll();

  final revenueIds = revenueAccounts.map((a) => a.uid).toSet();
  final expenseIds = expenseAccounts.map((a) => a.uid).toSet();
  final cashIds = cashAccounts.map((a) => a.uid).toSet();

  // Calculate totals from journal lines
  for (final journal in journals) {
    final lines = await db.journalLines
        .filter()
        .journalIdEqualTo(journal.uid)
        .findAll();

    for (final line in lines) {
      // Revenue: credit increases, debit decreases
      if (revenueIds.contains(line.accountId)) {
        totalIncome += line.credit - line.debit;
      }
      // Expense: debit increases, credit decreases
      if (expenseIds.contains(line.accountId)) {
        totalExpense += line.debit - line.credit;
      }
      // Cash: debit increases, credit decreases
      if (cashIds.contains(line.accountId)) {
        cashBalance += line.debit - line.credit;
      }
    }
  }

  return DashboardSummary(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    profit: totalIncome - totalExpense,
    cashBalance: cashBalance,
    transactionCount: journals.length,
    periodName: activePeriod.name,
  );
});
