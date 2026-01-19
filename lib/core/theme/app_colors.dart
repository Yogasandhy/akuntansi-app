/// App color palette for the accounting application
/// Modern, professional color scheme suitable for financial applications
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF1E40AF); // Deep blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);

  // Secondary accent
  static const Color secondary = Color(0xFF059669); // Emerald green for success
  static const Color secondaryLight = Color(0xFF10B981);
  static const Color secondaryDark = Color(0xFF047857);

  // Semantic colors
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  // Neutral colors
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // Background colors
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundDark = Color(0xFF111827);

  // Surface colors
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1F2937);

  // Account type colors
  static const Color assetColor = Color(0xFF0284C7); // Blue
  static const Color liabilityColor = Color(0xFFDC2626); // Red
  static const Color equityColor = Color(0xFF7C3AED); // Purple
  static const Color revenueColor = Color(0xFF059669); // Green
  static const Color expenseColor = Color(0xFFEA580C); // Orange

  // Financial indicators
  static const Color debit = Color(0xFF0284C7);
  static const Color credit = Color(0xFF059669);
  static const Color profit = Color(0xFF059669);
  static const Color loss = Color(0xFFDC2626);
}
