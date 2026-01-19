/// Reports screen - Financial reports (P&L, Balance Sheet)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/database/database_service.dart';
import '../../../accounts/domain/models/account.dart';
import '../../../journal/domain/models/journal_entry.dart';
import '../../../periods/application/period_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final periodAsync = ref.watch(activePeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Laba Rugi'),
            Tab(text: 'Neraca'),
          ],
        ),
      ),
      body: periodAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (period) {
          if (period == null) {
            return const Center(child: Text('Tidak ada periode aktif'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _ProfitLossReport(periodId: period.uid, periodName: period.name),
              _BalanceSheetReport(
                periodId: period.uid,
                periodName: period.name,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Profit & Loss Report
class _ProfitLossReport extends StatefulWidget {
  final String periodId;
  final String periodName;

  const _ProfitLossReport({required this.periodId, required this.periodName});

  @override
  State<_ProfitLossReport> createState() => _ProfitLossReportState();
}

class _ProfitLossReportState extends State<_ProfitLossReport> {
  bool _isLoading = true;
  List<({Account account, double amount})> _revenues = [];
  List<({Account account, double amount})> _expenses = [];
  double _totalRevenue = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseService.instance;

    // Get all posted journals in period
    final journals = await db.journalEntrys
        .filter()
        .periodIdEqualTo(widget.periodId)
        .statusEqualTo(JournalStatus.posted)
        .findAll();

    // Get accounts
    final revenueAccounts = await db.accounts
        .filter()
        .typeEqualTo(AccountType.revenue)
        .findAll();
    final expenseAccounts = await db.accounts
        .filter()
        .typeEqualTo(AccountType.expense)
        .findAll();

    // Calculate amounts
    final revenueAmounts = <String, double>{};
    final expenseAmounts = <String, double>{};

    for (final journal in journals) {
      final lines = await db.journalLines
          .filter()
          .journalIdEqualTo(journal.uid)
          .findAll();

      for (final line in lines) {
        // Revenue: credit - debit
        if (revenueAccounts.any((a) => a.uid == line.accountId)) {
          revenueAmounts[line.accountId] =
              (revenueAmounts[line.accountId] ?? 0) +
              (line.credit - line.debit);
        }
        // Expense: debit - credit
        if (expenseAccounts.any((a) => a.uid == line.accountId)) {
          expenseAmounts[line.accountId] =
              (expenseAmounts[line.accountId] ?? 0) +
              (line.debit - line.credit);
        }
      }
    }

    setState(() {
      _revenues = revenueAccounts
          .where((a) => (revenueAmounts[a.uid] ?? 0) != 0)
          .map((a) => (account: a, amount: revenueAmounts[a.uid] ?? 0))
          .toList();
      _expenses = expenseAccounts
          .where((a) => (expenseAmounts[a.uid] ?? 0) != 0)
          .map((a) => (account: a, amount: expenseAmounts[a.uid] ?? 0))
          .toList();
      _totalRevenue = _revenues.fold(0, (sum, r) => sum + r.amount);
      _totalExpense = _expenses.fold(0, (sum, e) => sum + e.amount);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final profit = _totalRevenue - _totalExpense;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LAPORAN LABA RUGI',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Periode: ${widget.periodName}',
                    style: const TextStyle(color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Revenue section
          _ReportSection(
            title: 'PENDAPATAN',
            items: _revenues.map((r) => (r.account.name, r.amount)).toList(),
            total: _totalRevenue,
            color: AppColors.revenueColor,
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Expense section
          _ReportSection(
            title: 'BEBAN',
            items: _expenses.map((e) => (e.account.name, e.amount)).toList(),
            total: _totalExpense,
            color: AppColors.expenseColor,
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Profit/Loss
          Card(
            color: profit >= 0
                ? AppColors.profit.withValues(alpha: 0.1)
                : AppColors.loss.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    profit >= 0 ? 'LABA BERSIH' : 'RUGI BERSIH',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: profit >= 0 ? AppColors.profit : AppColors.loss,
                    ),
                  ),
                  Text(
                    AppFormatters.currency(profit.abs()),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: profit >= 0 ? AppColors.profit : AppColors.loss,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Balance Sheet Report
class _BalanceSheetReport extends StatefulWidget {
  final String periodId;
  final String periodName;

  const _BalanceSheetReport({required this.periodId, required this.periodName});

  @override
  State<_BalanceSheetReport> createState() => _BalanceSheetReportState();
}

class _BalanceSheetReportState extends State<_BalanceSheetReport> {
  bool _isLoading = true;
  List<({Account account, double amount})> _assets = [];
  List<({Account account, double amount})> _liabilities = [];
  List<({Account account, double amount})> _equity = [];
  double _totalAssets = 0;
  double _totalLiabilities = 0;
  double _totalEquity = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseService.instance;

    // Get all posted journals
    final journals = await db.journalEntrys
        .filter()
        .statusEqualTo(JournalStatus.posted)
        .findAll();

    // Get accounts
    final assetAccounts = await db.accounts
        .filter()
        .typeEqualTo(AccountType.asset)
        .findAll();
    final liabilityAccounts = await db.accounts
        .filter()
        .typeEqualTo(AccountType.liability)
        .findAll();
    final equityAccounts = await db.accounts
        .filter()
        .typeEqualTo(AccountType.equity)
        .findAll();

    // Calculate amounts
    final assetAmounts = <String, double>{};
    final liabilityAmounts = <String, double>{};
    final equityAmounts = <String, double>{};

    for (final journal in journals) {
      final lines = await db.journalLines
          .filter()
          .journalIdEqualTo(journal.uid)
          .findAll();

      for (final line in lines) {
        // Assets: debit - credit
        if (assetAccounts.any((a) => a.uid == line.accountId)) {
          assetAmounts[line.accountId] =
              (assetAmounts[line.accountId] ?? 0) + (line.debit - line.credit);
        }
        // Liabilities: credit - debit
        if (liabilityAccounts.any((a) => a.uid == line.accountId)) {
          liabilityAmounts[line.accountId] =
              (liabilityAmounts[line.accountId] ?? 0) +
              (line.credit - line.debit);
        }
        // Equity: credit - debit
        if (equityAccounts.any((a) => a.uid == line.accountId)) {
          equityAmounts[line.accountId] =
              (equityAmounts[line.accountId] ?? 0) + (line.credit - line.debit);
        }
      }
    }

    setState(() {
      _assets = assetAccounts
          .where((a) => (assetAmounts[a.uid] ?? 0) != 0)
          .map((a) => (account: a, amount: assetAmounts[a.uid] ?? 0))
          .toList();
      _liabilities = liabilityAccounts
          .where((a) => (liabilityAmounts[a.uid] ?? 0) != 0)
          .map((a) => (account: a, amount: liabilityAmounts[a.uid] ?? 0))
          .toList();
      _equity = equityAccounts
          .where((a) => (equityAmounts[a.uid] ?? 0) != 0)
          .map((a) => (account: a, amount: equityAmounts[a.uid] ?? 0))
          .toList();
      _totalAssets = _assets.fold(0, (sum, a) => sum + a.amount);
      _totalLiabilities = _liabilities.fold(0, (sum, l) => sum + l.amount);
      _totalEquity = _equity.fold(0, (sum, e) => sum + e.amount);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isBalanced =
        (_totalAssets - (_totalLiabilities + _totalEquity)).abs() < 0.01;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'NERACA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingSm,
                          vertical: AppConstants.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: isBalanced
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBalanced ? Icons.check_circle : Icons.warning,
                              size: 14,
                              color: isBalanced
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isBalanced ? 'Seimbang' : 'Tidak Seimbang',
                              style: TextStyle(
                                fontSize: 12,
                                color: isBalanced
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Per: ${widget.periodName}',
                    style: const TextStyle(color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Assets
          _ReportSection(
            title: 'ASET',
            items: _assets.map((a) => (a.account.name, a.amount)).toList(),
            total: _totalAssets,
            color: AppColors.assetColor,
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Liabilities
          _ReportSection(
            title: 'KEWAJIBAN',
            items: _liabilities.map((l) => (l.account.name, l.amount)).toList(),
            total: _totalLiabilities,
            color: AppColors.liabilityColor,
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Equity
          _ReportSection(
            title: 'MODAL',
            items: _equity.map((e) => (e.account.name, e.amount)).toList(),
            total: _totalEquity,
            color: AppColors.equityColor,
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Aset'),
                      Text(
                        AppFormatters.currency(_totalAssets),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Kewajiban + Modal'),
                      Text(
                        AppFormatters.currency(
                          _totalLiabilities + _totalEquity,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final List<(String name, double amount)> items;
  final double total;
  final Color color;

  const _ReportSection({
    required this.title,
    required this.items,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusLg - 1),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppConstants.spacingMd),
              child: Text(
                'Tidak ada data',
                style: TextStyle(
                  color: AppColors.neutral400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.$1),
                    Text(AppFormatters.currency(item.$2)),
                  ],
                ),
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total $title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppFormatters.currency(total),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
