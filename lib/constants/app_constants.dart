import 'package:flutter/material.dart';

/// App color palette based on UAE theme
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF006400); // Deep UAE Green
  static const Color secondary = Color(0xFFFFD700); // Gold Accent
  
  // Status Colors
  static const Color success = Color(0xFF28A745); // Savings Green
  static const Color warning = Color(0xFFFFC107); // Budget Alert
  static const Color danger = Color(0xFFDC3545); // Overspend Red
  
  // Background Colors
  static const Color background = Color(0xFFFFFFFF); // Clean White
  static const Color surface = Color(0xFFF8F9FA); // Light Gray
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  
  // Additional Colors
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE0E0E0);

  // Budget Category Colors
  static const Color needsColor = Color(0xFF4A90D9); // Blue for Needs
  static const Color wantsColor = Color(0xFFE67E22); // Orange for Wants
  static const Color savingsColor = Color(0xFF27AE60); // Green for Savings
}

/// Typography styles
class AppTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // Numbers (for balances and amounts)
  static const TextStyle numberLarge = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle numberMedium = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  
  // Labels
  static const TextStyle label = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Body Small
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}

/// UI Constants
class AppConstants {
  // Border Radius
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 8.0;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Elevation
  static const double cardElevation = 2.0;
  
  // Animation Duration
  static const Duration animationDuration = Duration(milliseconds: 300);
}
