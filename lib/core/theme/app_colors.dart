import 'package:flutter/material.dart';

/// Centralized color palette for the SIREN application.
///
/// Colors follow the design guidelines defined in the workflows:
/// - Soft blues: #5C6BC0, #7986CB
/// - Soft purples: #9575CD, #B39DDB
/// - Complementary colors for background, surface, and semantic states.
///
/// **Usage:**
/// Always use colors from this class instead of hardcoding Colors.* values.
/// This ensures consistency and makes theme changes easier.
class AppColors {
  const AppColors._();

  // Primary Colors - Soft Blues
  static const Color primaryBlue = Color(0xFF5C6BC0);
  static const Color lightBlue = Color(0xFF7986CB);

  // Primary Colors - Soft Purples
  static const Color primaryPurple = Color(0xFF9575CD);
  static const Color lightPurple = Color(0xFFB39DDB);

  // Background and Surface
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color error = Color(0xFFEF5350);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFFFFC107);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Icon Colors
  static const Color iconPrimary = primaryBlue;
  static const Color iconSecondary = textSecondary;

  // Button Colors
  static const Color primaryButton = primaryPurple;
  static const Color secondaryButton = primaryBlue;
  static const Color buttonText = Color(0xFFFFFFFF);

  // Accent Colors (for special UI elements)
  static const Color accent = primaryPurple;
  static const Color accentLight = lightPurple;
}
