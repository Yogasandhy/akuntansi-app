/// Period model representing an accounting period (month/year)
library;

import 'package:isar/isar.dart';

part 'period.g.dart';

@collection
class Period {
  Id id = Isar.autoIncrement;

  /// Unique identifier (UUID)
  @Index(unique: true)
  late String uid;

  /// Period name (e.g., "Januari 2025")
  late String name;

  /// Period start date
  late DateTime startDate;

  /// Period end date
  late DateTime endDate;

  /// Whether the period is closed
  late bool isClosed;

  /// Closed timestamp
  DateTime? closedAt;

  /// Whether this is the active period
  late bool isActive;

  /// Created timestamp
  late DateTime createdAt;

  Period();

  /// Factory constructor
  factory Period.create({
    required String uid,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool isClosed = false,
    bool isActive = false,
  }) {
    return Period()
      ..uid = uid
      ..name = name
      ..startDate = startDate
      ..endDate = endDate
      ..isClosed = isClosed
      ..isActive = isActive
      ..createdAt = DateTime.now();
  }

  /// Create a monthly period from a date
  factory Period.fromMonth({
    required String uid,
    required DateTime date,
    bool isActive = false,
  }) {
    final year = date.year;
    final month = date.month;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month

    // Format month name in Indonesian
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final name = '${months[month - 1]} $year';

    return Period.create(
      uid: uid,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
    );
  }

  /// Check if a date is within this period
  bool containsDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  /// Get status label
  String get statusLabel {
    if (isClosed) return 'Ditutup';
    if (isActive) return 'Aktif';
    return 'Terbuka';
  }
}
