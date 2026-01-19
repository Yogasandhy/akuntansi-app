/// Journal entry screen - Create/edit journal entries
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../accounts/application/account_providers.dart';
import '../../../accounts/domain/models/account.dart';
import '../../../periods/application/period_providers.dart';
import '../../../dashboard/application/dashboard_providers.dart';
import '../../application/journal_providers.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  final String? journalId;

  const JournalEntryScreen({super.key, this.journalId});

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool get isEditing => widget.journalId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(journalFormProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(journalFormProvider);
    final accountsAsync = ref.watch(activeAccountsProvider);
    final activePeriodAsync = ref.watch(activePeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Jurnal' : 'Jurnal Baru'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!formState.isLoading)
            TextButton(
              onPressed: formState.canSave ? () => _saveJournal(false) : null,
              child: const Text('Simpan Draft'),
            ),
          const SizedBox(width: AppConstants.spacingSm),
          if (!formState.isLoading)
            ElevatedButton(
              onPressed: formState.canSave ? () => _saveJournal(true) : null,
              child: const Text('Simpan & Posting'),
            ),
          if (formState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: activePeriodAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (period) {
          if (period == null) {
            return const Center(
              child: Text(
                'Tidak ada periode aktif. Buat periode terlebih dahulu.',
              ),
            );
          }

          return accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
            data: (accounts) => _buildForm(context, accounts, formState),
          );
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<Account> accounts,
    JournalFormState formState,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            color: Colors.white,
            child: Column(
              children: [
                // Date
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(AppFormatters.dateLong(_selectedDate)),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi *',
                    hintText: 'Contoh: Pembelian perlengkapan kantor',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    ref
                        .read(journalFormProvider.notifier)
                        .setDescription(value);
                  },
                ),
                const SizedBox(height: AppConstants.spacingMd),
                // Reference
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Referensi (opsional)',
                    hintText: 'Contoh: INV-001',
                  ),
                  onChanged: (value) {
                    ref
                        .read(journalFormProvider.notifier)
                        .setReference(value.isEmpty ? null : value);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lines section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  child: Row(
                    children: [
                      const Text(
                        'Detail Jurnal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          ref.read(journalFormProvider.notifier).addLine();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Baris'),
                      ),
                    ],
                  ),
                ),
                // Lines header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                    vertical: AppConstants.spacingSm,
                  ),
                  color: AppColors.neutral100,
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Akun',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Debit',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Kredit',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                // Lines list
                Expanded(
                  child: ListView.builder(
                    itemCount: formState.lines.length,
                    itemBuilder: (context, index) {
                      final line = formState.lines[index];
                      return _JournalLineRow(
                        line: line,
                        accounts: accounts,
                        canDelete: formState.lines.length > 2,
                        onChanged: (newLine) {
                          ref
                              .read(journalFormProvider.notifier)
                              .updateLine(index, newLine);
                        },
                        onDelete: () {
                          ref
                              .read(journalFormProvider.notifier)
                              .removeLine(index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Footer with totals
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Validation error
                if (formState.validationError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.spacingSm),
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.spacingMd,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSm,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: Text(
                            formState.validationError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Totals row
                Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppFormatters.currency(formState.totalDebit),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.debit,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppFormatters.currency(formState.totalCredit),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.credit,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm),
                // Balance indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      formState.isBalanced ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: formState.isBalanced
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Text(
                      formState.isBalanced ? 'Seimbang' : 'Belum seimbang',
                      style: TextStyle(
                        color: formState.isBalanced
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      ref.read(journalFormProvider.notifier).setDate(picked);
    }
  }

  Future<void> _saveJournal(bool post) async {
    final period = await ref.read(activePeriodProvider.future);
    if (period == null) return;

    final result = await ref
        .read(journalFormProvider.notifier)
        .save(period.uid, post: post);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            post ? 'Jurnal berhasil diposting' : 'Jurnal berhasil disimpan',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(periodJournalsProvider);
      ref.invalidate(dashboardSummaryProvider);
      context.pop();
    }
  }
}

class _JournalLineRow extends StatefulWidget {
  final JournalFormLine line;
  final List<Account> accounts;
  final bool canDelete;
  final ValueChanged<JournalFormLine> onChanged;
  final VoidCallback onDelete;

  const _JournalLineRow({
    required this.line,
    required this.accounts,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_JournalLineRow> createState() => _JournalLineRowState();
}

class _JournalLineRowState extends State<_JournalLineRow> {
  late TextEditingController _debitController;
  late TextEditingController _creditController;

  @override
  void initState() {
    super.initState();
    _debitController = TextEditingController(
      text: widget.line.debit > 0 ? widget.line.debit.toStringAsFixed(0) : '',
    );
    _creditController = TextEditingController(
      text: widget.line.credit > 0 ? widget.line.credit.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _debitController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          // Account dropdown
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: widget.line.accountId,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              hint: const Text('Pilih akun', style: TextStyle(fontSize: 12)),
              isExpanded: true,
              items: widget.accounts.map((account) {
                return DropdownMenuItem(
                  value: account.uid,
                  child: Text(
                    '${account.code} - ${account.name}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final account = widget.accounts.firstWhere(
                    (a) => a.uid == value,
                  );
                  widget.onChanged(
                    widget.line.copyWith(
                      accountId: account.uid,
                      accountCode: account.code,
                      accountName: account.name,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Debit
          Expanded(
            flex: 2,
            child: TextField(
              controller: _debitController,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                widget.onChanged(widget.line.copyWith(debit: amount));
                if (amount > 0) {
                  _creditController.clear();
                  widget.onChanged(
                    widget.line.copyWith(debit: amount, credit: 0),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Credit
          Expanded(
            flex: 2,
            child: TextField(
              controller: _creditController,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                widget.onChanged(widget.line.copyWith(credit: amount));
                if (amount > 0) {
                  _debitController.clear();
                  widget.onChanged(
                    widget.line.copyWith(debit: 0, credit: amount),
                  );
                }
              },
            ),
          ),
          // Delete button
          SizedBox(
            width: 40,
            child: widget.canDelete
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: AppColors.error,
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
