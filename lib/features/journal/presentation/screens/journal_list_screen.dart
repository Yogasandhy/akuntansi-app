/// Journal list screen - Displays all journal entries with filtering
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/journal_providers.dart';
import '../../domain/models/journal_entry.dart';

class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  JournalStatus? _statusFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final journalsAsync = ref.watch(periodJournalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(periodJournalsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari transaksi...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter chips
          if (_statusFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
              ),
              child: Row(
                children: [
                  Chip(
                    label: Text(_getStatusLabel(_statusFilter!)),
                    onDeleted: () => setState(() => _statusFilter = null),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),

          // Journal list
          Expanded(
            child: journalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text('Error: $error'),
                  ],
                ),
              ),
              data: (journals) {
                // Apply filters
                var filtered = journals;
                if (_statusFilter != null) {
                  filtered = filtered
                      .where((j) => j.status == _statusFilter)
                      .toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (j) =>
                            j.description.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            (j.reference?.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ??
                                false),
                      )
                      .toList();
                }

                if (filtered.isEmpty) {
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
                        Text(
                          journals.isEmpty
                              ? 'Belum ada transaksi'
                              : 'Tidak ada transaksi yang cocok',
                          style: TextStyle(color: AppColors.neutral500),
                        ),
                        if (journals.isEmpty) ...[
                          const SizedBox(height: AppConstants.spacingMd),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/transactions/new'),
                            icon: const Icon(Icons.add),
                            label: const Text('Buat Jurnal Pertama'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final journal = filtered[index];
                    return _JournalCard(
                      journal: journal,
                      onTap: () => context.go('/transactions/${journal.uid}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/transactions/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getStatusLabel(JournalStatus status) {
    return switch (status) {
      JournalStatus.draft => 'Draft',
      JournalStatus.posted => 'Posted',
      JournalStatus.voided => 'Batal',
    };
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Semua'),
              leading: Radio<JournalStatus?>(
                value: null,
                groupValue: _statusFilter,
                onChanged: (value) {
                  setState(() => _statusFilter = null);
                  Navigator.of(context).pop();
                },
              ),
              onTap: () {
                setState(() => _statusFilter = null);
                Navigator.of(context).pop();
              },
            ),
            for (final status in JournalStatus.values)
              ListTile(
                title: Text(_getStatusLabel(status)),
                leading: Radio<JournalStatus?>(
                  value: status,
                  groupValue: _statusFilter,
                  onChanged: (value) {
                    setState(() => _statusFilter = value);
                    Navigator.of(context).pop();
                  },
                ),
                onTap: () {
                  setState(() => _statusFilter = status);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry journal;
  final VoidCallback onTap;

  const _JournalCard({required this.journal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(journal.status),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            journal.description,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusBadge(status: journal.status),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(width: AppConstants.spacingXs),
                        Text(
                          AppFormatters.dateShort(journal.date),
                          style: TextStyle(
                            color: AppColors.neutral500,
                            fontSize: 12,
                          ),
                        ),
                        if (journal.reference != null) ...[
                          const SizedBox(width: AppConstants.spacingMd),
                          Icon(
                            Icons.tag,
                            size: 14,
                            color: AppColors.neutral400,
                          ),
                          const SizedBox(width: AppConstants.spacingXs),
                          Text(
                            journal.reference!,
                            style: TextStyle(
                              color: AppColors.neutral500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(JournalStatus status) {
    return switch (status) {
      JournalStatus.draft => AppColors.warning,
      JournalStatus.posted => AppColors.success,
      JournalStatus.voided => AppColors.error,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final JournalStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      JournalStatus.draft => (AppColors.warning, 'Draft'),
      JournalStatus.posted => (AppColors.success, 'Posted'),
      JournalStatus.voided => (AppColors.error, 'Batal'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
