/// Input validators for forms
library;

class AppValidators {
  AppValidators._();

  /// Validate that a field is not empty
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName harus diisi'
          : 'Field ini harus diisi';
    }
    return null;
  }

  /// Validate that a value is a valid positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Use required validator for empty check
    }

    final number = double.tryParse(
      value.replaceAll('.', '').replaceAll(',', '.'),
    );
    if (number == null || number < 0) {
      return fieldName != null
          ? '$fieldName harus berupa angka positif'
          : 'Masukkan angka yang valid';
    }
    return null;
  }

  /// Validate account code format (e.g., "1-1000")
  static String? accountCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kode akun harus diisi';
    }

    // Pattern: digit(s)-digit(s)
    final regex = RegExp(r'^\d+-\d+$');
    if (!regex.hasMatch(value.trim())) {
      return 'Format kode akun tidak valid (contoh: 1-1000)';
    }
    return null;
  }

  /// Validate date is not in the future (for transactions)
  static String? notFutureDate(DateTime? value) {
    if (value == null) {
      return 'Tanggal harus diisi';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(value.year, value.month, value.day);

    if (dateOnly.isAfter(today)) {
      return 'Tanggal tidak boleh di masa depan';
    }
    return null;
  }

  /// Validate journal entry lines
  static String? journalLines(List<dynamic> lines) {
    if (lines.isEmpty) {
      return 'Jurnal harus memiliki minimal 2 baris';
    }
    if (lines.length < 2) {
      return 'Jurnal harus memiliki minimal 2 baris';
    }
    return null;
  }

  /// Validate journal balance (debit == credit)
  static String? journalBalance(double totalDebit, double totalCredit) {
    // Use epsilon for floating point comparison
    const epsilon = 0.01;
    if ((totalDebit - totalCredit).abs() > epsilon) {
      return 'Total debit dan kredit belum seimbang';
    }
    if (totalDebit == 0 && totalCredit == 0) {
      return 'Jurnal tidak boleh kosong';
    }
    return null;
  }

  /// Validate that a line has either debit or credit, not both
  static String? debitOrCredit(double debit, double credit, int lineNumber) {
    if (debit > 0 && credit > 0) {
      return 'Baris $lineNumber: tidak boleh mengisi debit dan kredit bersamaan';
    }
    if (debit == 0 && credit == 0) {
      return 'Baris $lineNumber: harus mengisi debit atau kredit';
    }
    return null;
  }
}
