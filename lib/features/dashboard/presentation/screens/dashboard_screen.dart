/// Dashboard screen - Main entry point showing period summary
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../application/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardSummaryProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: summaryAsync.when(
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
                onPressed: () => ref.invalidate(dashboardSummaryProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (summary) => _DashboardContent(summary: summary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text('Jurnal Baru'),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardSummary summary;

  const _DashboardContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final padding = ResponsiveUtils.getScreenPadding(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Text(
                  summary.periodName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Summary cards
          if (isMobile)
            _MobileSummaryCards(summary: summary)
          else
            _DesktopSummaryCards(summary: summary),

          const SizedBox(height: AppConstants.spacingXl),

          // Quick actions
          Text('Aksi Cepat', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppConstants.spacingMd),
          Wrap(
            spacing: AppConstants.spacingMd,
            runSpacing: AppConstants.spacingMd,
            children: [
              _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Jurnal Baru',
                onTap: () => context.go('/transactions/new'),
              ),
              _QuickActionButton(
                icon: Icons.account_balance_wallet,
                label: 'Lihat Akun',
                onTap: () => context.go('/accounts'),
              ),
              _QuickActionButton(
                icon: Icons.bar_chart,
                label: 'Laporan',
                onTap: () => context.go('/reports'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileSummaryCards extends StatelessWidget {
  final DashboardSummary summary;

  const _MobileSummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Pendapatan',
                value: AppFormatters.currency(summary.totalIncome),
                icon: Icons.trending_up,
                color: AppColors.revenueColor,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: _SummaryCard(
                title: 'Pengeluaran',
                value: AppFormatters.currency(summary.totalExpense),
                icon: Icons.trending_down,
                color: AppColors.expenseColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Laba/Rugi',
                value: AppFormatters.currency(summary.profit),
                icon: summary.profit >= 0 ? Icons.thumb_up : Icons.thumb_down,
                color: summary.profit >= 0 ? AppColors.profit : AppColors.loss,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: _SummaryCard(
                title: 'Saldo Kas',
                value: AppFormatters.currency(summary.cashBalance),
                icon: Icons.account_balance,
                color: AppColors.assetColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DesktopSummaryCards extends StatelessWidget {
  final DashboardSummary summary;

  const _DesktopSummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Pendapatan',
            value: AppFormatters.currency(summary.totalIncome),
            icon: Icons.trending_up,
            color: AppColors.revenueColor,
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(
          child: _SummaryCard(
            title: 'Pengeluaran',
            value: AppFormatters.currency(summary.totalExpense),
            icon: Icons.trending_down,
            color: AppColors.expenseColor,
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(
          child: _SummaryCard(
            title: 'Laba/Rugi',
            value: AppFormatters.currency(summary.profit),
            icon: summary.profit >= 0 ? Icons.thumb_up : Icons.thumb_down,
            color: summary.profit >= 0 ? AppColors.profit : AppColors.loss,
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(
          child: _SummaryCard(
            title: 'Saldo Kas',
            value: AppFormatters.currency(summary.cashBalance),
            icon: Icons.account_balance,
            color: AppColors.assetColor,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              title,
              style: TextStyle(color: AppColors.neutral500, fontSize: 12),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppConstants.spacingSm),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
