/// App constants including breakpoints, spacing, and other configuration values
library;

class AppConstants {
  AppConstants._();

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // Border radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 999;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Database
  static const String databaseName = 'akuntansi_db';
  static const int databaseVersion = 1;

  // Date formats
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String dateFormatLong = 'dd MMMM yyyy';
  static const String dateFormatWithTime = 'dd/MM/yyyy HH:mm';

  // Currency
  static const String defaultCurrency = 'IDR';
  static const String defaultLocale = 'id_ID';
}
