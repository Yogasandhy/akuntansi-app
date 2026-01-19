/// Formatters for currency, dates, and numbers
library;

import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: AppConstants.defaultLocale,
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _currencyFormatterWithDecimals =
      NumberFormat.currency(
        locale: AppConstants.defaultLocale,
        symbol: 'Rp ',
        decimalDigits: 2,
      );

  static final NumberFormat _numberFormatter = NumberFormat.decimalPattern(
    AppConstants.defaultLocale,
  );

  static final DateFormat _dateFormatter = DateFormat(
    AppConstants.dateFormatShort,
    AppConstants.defaultLocale,
  );

  static final DateFormat _dateLongFormatter = DateFormat(
    AppConstants.dateFormatLong,
    AppConstants.defaultLocale,
  );

  static final DateFormat _dateTimeFormatter = DateFormat(
    AppConstants.dateFormatWithTime,
    AppConstants.defaultLocale,
  );

  /// Format currency without decimals (for whole numbers)
  static String currency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Format currency with 2 decimal places
  static String currencyWithDecimals(double amount) {
    return _currencyFormatterWithDecimals.format(amount);
  }

  /// Format number with thousand separators
  static String number(double value) {
    return _numberFormatter.format(value);
  }

  /// Format date short (dd/MM/yyyy)
  static String dateShort(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Format date long (dd MMMM yyyy)
  static String dateLong(DateTime date) {
    return _dateLongFormatter.format(date);
  }

  /// Format date with time
  static String dateTime(DateTime date) {
    return _dateTimeFormatter.format(date);
  }

  /// Format period name (e.g., "Januari 2025")
  static String periodName(DateTime date) {
    return DateFormat('MMMM yyyy', AppConstants.defaultLocale).format(date);
  }

  /// Parse currency string back to double
  static double? parseCurrency(String value) {
    try {
      // Remove currency symbol and spaces
      String cleaned = value
          .replaceAll('Rp ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }
}
