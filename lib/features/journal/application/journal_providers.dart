/// Riverpod providers for journal feature
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/journal_entry.dart';
import '../domain/repositories/journal_repository.dart';
import '../../periods/application/period_providers.dart';

/// Journal repository provider
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

/// All journals provider
final allJournalsProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final repository = ref.watch(journalRepositoryProvider);
  return repository.getAll();
});

/// Journals by active period provider
final periodJournalsProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final repository = ref.watch(journalRepositoryProvider);
  final activePeriod = await ref.watch(activePeriodProvider.future);

  if (activePeriod == null) return [];

  return repository.getByPeriod(activePeriod.uid);
});

/// Journals by status provider
final journalsByStatusProvider =
    FutureProvider.family<List<JournalEntry>, JournalStatus>((
      ref,
      status,
    ) async {
      final repository = ref.watch(journalRepositoryProvider);
      return repository.getByStatus(status);
    });

/// Single journal with lines provider
final journalWithLinesProvider =
    FutureProvider.family<JournalWithLines?, String>((ref, uid) async {
      final repository = ref.watch(journalRepositoryProvider);
      return repository.getWithLines(uid);
    });

/// Lines for an account (ledger) provider
final accountLedgerProvider = FutureProvider.family<List<JournalLine>, String>((
  ref,
  accountId,
) async {
  final repository = ref.watch(journalRepositoryProvider);
  return repository.getLinesByAccount(accountId);
});

/// Period summary provider
final periodSummaryProvider =
    FutureProvider<({double totalDebit, double totalCredit, int journalCount})>(
      (ref) async {
        final repository = ref.watch(journalRepositoryProvider);
        final activePeriod = await ref.watch(activePeriodProvider.future);

        if (activePeriod == null) {
          return (totalDebit: 0.0, totalCredit: 0.0, journalCount: 0);
        }

        return repository.getPeriodSummary(activePeriod.uid);
      },
    );

/// Journal entry form state
class JournalFormLine {
  final String? accountId;
  final String accountCode;
  final String accountName;
  final double debit;
  final double credit;
  final String? memo;

  JournalFormLine({
    this.accountId,
    this.accountCode = '',
    this.accountName = '',
    this.debit = 0,
    this.credit = 0,
    this.memo,
  });

  JournalFormLine copyWith({
    String? accountId,
    String? accountCode,
    String? accountName,
    double? debit,
    double? credit,
    String? memo,
  }) {
    return JournalFormLine(
      accountId: accountId ?? this.accountId,
      accountCode: accountCode ?? this.accountCode,
      accountName: accountName ?? this.accountName,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      memo: memo ?? this.memo,
    );
  }

  bool get isValid =>
      accountId != null &&
      (debit > 0 || credit > 0) &&
      !(debit > 0 && credit > 0);
  bool get isEmpty => accountId == null && debit == 0 && credit == 0;
}

class JournalFormState {
  final DateTime date;
  final String description;
  final String? reference;
  final List<JournalFormLine> lines;
  final bool isLoading;
  final String? error;

  JournalFormState({
    DateTime? date,
    this.description = '',
    this.reference,
    List<JournalFormLine>? lines,
    this.isLoading = false,
    this.error,
  }) : date = date ?? DateTime.now(),
       lines = lines ?? [JournalFormLine(), JournalFormLine()];

  double get totalDebit => lines.fold(0, (sum, line) => sum + line.debit);
  double get totalCredit => lines.fold(0, (sum, line) => sum + line.credit);
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;
  bool get hasValidLines => lines.where((l) => l.isValid).length >= 2;
  bool get canSave =>
      isBalanced && hasValidLines && description.isNotEmpty && !isLoading;

  String? get validationError {
    if (description.isEmpty) return 'Deskripsi harus diisi';
    if (!hasValidLines) return 'Minimal 2 baris yang valid diperlukan';
    if (!isBalanced) return 'Total debit dan kredit harus seimbang';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.isEmpty && !line.isValid) {
        if (line.accountId == null) return 'Baris ${i + 1} belum memilih akun';
        if (line.debit > 0 && line.credit > 0)
          return 'Baris ${i + 1} tidak boleh mengisi debit dan kredit bersamaan';
        if (line.debit == 0 && line.credit == 0)
          return 'Baris ${i + 1} harus mengisi debit atau kredit';
      }
    }

    return null;
  }

  JournalFormState copyWith({
    DateTime? date,
    String? description,
    String? reference,
    List<JournalFormLine>? lines,
    bool? isLoading,
    String? error,
  }) {
    return JournalFormState(
      date: date ?? this.date,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      lines: lines ?? this.lines,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Journal form state notifier
class JournalFormNotifier extends StateNotifier<JournalFormState> {
  final JournalRepository repository;

  JournalFormNotifier(this.repository) : super(JournalFormState());

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void setReference(String? reference) {
    state = state.copyWith(reference: reference);
  }

  void updateLine(int index, JournalFormLine line) {
    final lines = [...state.lines];
    if (index < lines.length) {
      lines[index] = line;
      state = state.copyWith(lines: lines);
    }
  }

  void addLine() {
    final lines = [...state.lines, JournalFormLine()];
    state = state.copyWith(lines: lines);
  }

  void removeLine(int index) {
    if (state.lines.length > 2) {
      final lines = [...state.lines];
      lines.removeAt(index);
      state = state.copyWith(lines: lines);
    }
  }

  void reset() {
    state = JournalFormState();
  }

  Future<JournalWithLines?> save(String periodId, {bool post = false}) async {
    if (!state.canSave) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final validLines = state.lines
          .where((l) => l.isValid)
          .map(
            (l) => (
              accountId: l.accountId!,
              accountCode: l.accountCode,
              accountName: l.accountName,
              debit: l.debit,
              credit: l.credit,
              memo: l.memo,
            ),
          )
          .toList();

      final result = await repository.create(
        date: state.date,
        description: state.description,
        reference: state.reference,
        periodId: periodId,
        lines: validLines,
        postImmediately: post,
      );

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

/// Journal form provider
final journalFormProvider =
    StateNotifierProvider<JournalFormNotifier, JournalFormState>((ref) {
      final repository = ref.watch(journalRepositoryProvider);
      return JournalFormNotifier(repository);
    });
