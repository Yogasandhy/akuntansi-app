/// Settings screen - App settings and preferences
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../accounts/application/account_providers.dart';
import '../../../periods/application/period_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        children: [
          // Data section
          _SectionHeader(title: 'Data'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.account_balance_wallet,
                  title: 'Seed Akun Default',
                  subtitle: 'Buat Chart of Accounts standar',
                  onTap: () => _seedDefaultAccounts(context, ref),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.calendar_month,
                  title: 'Buat Periode Baru',
                  subtitle: 'Buat periode bulan ini',
                  onTap: () => _createPeriod(context, ref),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.refresh,
                  title: 'Refresh Data',
                  subtitle: 'Muat ulang semua data',
                  onTap: () => _refreshData(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Period section
          _SectionHeader(title: 'Periode'),
          _PeriodSection(),
          const SizedBox(height: AppConstants.spacingLg),

          // About section
          _SectionHeader(title: 'Tentang'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingMd),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akuntansi App',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Versi 1.0.0',
                            style: TextStyle(
                              color: AppColors.neutral500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  const Text(
                    'Aplikasi akuntansi offline untuk UMKM/Freelancer dengan sistem double-entry accounting.',
                    style: TextStyle(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDefaultAccounts(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(accountRepositoryProvider);
    await repo.seedDefaults();
    ref.invalidate(allAccountsProvider);
    ref.invalidate(activeAccountsProvider);
    ref.invalidate(groupedAccountsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun default berhasil dibuat'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _createPeriod(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(periodRepositoryProvider);
    await repo.initializeIfEmpty();
    ref.invalidate(allPeriodsProvider);
    ref.invalidate(activePeriodProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Periode berhasil dibuat'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _refreshData(BuildContext context, WidgetRef ref) {
    ref.invalidate(allAccountsProvider);
    ref.invalidate(activeAccountsProvider);
    ref.invalidate(groupedAccountsProvider);
    ref.invalidate(allPeriodsProvider);
    ref.invalidate(activePeriodProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data berhasil dimuat ulang'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.spacingSm,
        bottom: AppConstants.spacingSm,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.neutral500,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingSm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}

class _PeriodSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(allPeriodsProvider);
    final activePeriodAsync = ref.watch(activePeriodProvider);

    return Card(
      child: periodsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppConstants.spacingMd),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Text('Error: $e'),
        ),
        data: (periods) {
          if (periods.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppConstants.spacingMd),
              child: Text('Belum ada periode. Buat periode terlebih dahulu.'),
            );
          }

          return Column(
            children: periods.map((period) {
              final isActive = activePeriodAsync.value?.uid == period.uid;

              return InkWell(
                onTap: () async {
                  if (!isActive && !period.isClosed) {
                    final repo = ref.read(periodRepositoryProvider);
                    await repo.setActive(period.uid);
                    ref.invalidate(activePeriodProvider);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.neutral200,
                        width: periods.last == period ? 0 : 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.success
                              : period.isClosed
                              ? AppColors.neutral400
                              : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              period.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              period.statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive
                                    ? AppColors.success
                                    : AppColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingSm,
                            vertical: AppConstants.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusSm,
                            ),
                          ),
                          child: const Text(
                            'Aktif',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
