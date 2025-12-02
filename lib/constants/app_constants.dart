import 'package:flutter/material.dart';

/// Modern Apple-inspired color palette
class AppColors {
  // Primary Colors - iOS Blue & Neutrals
  static const Color primary = Color(0xFF007AFF); // iOS Blue
  static const Color secondary = Color(0xFF5856D6); // iOS Purple
  
  // Status Colors
  static const Color success = Color(0xFF34C759); // iOS Green
  static const Color warning = Color(0xFFFF9500); // iOS Orange
  static const Color error = Color(0xFFFF3B30); // iOS Red
  static const Color danger = Color(0xFFFF3B30); // Alias for error
  
  // Background Colors - iOS Style
  static const Color background = Color(0xFFF2F2F7); // iOS System Background
  static const Color surface = Color(0xFFFFFFFF); // Pure White Cards
  static const Color surfaceSecondary = Color(0xFFF9F9F9); // Subtle Gray
  
  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93); // iOS Secondary Text
  static const Color textTertiary = Color(0xFFC7C7CC);
  
  // Additional Colors
  static const Color cardBorder = Color(0xFFE5E5EA); // Subtle borders
  static const Color divider = Color(0xFFE5E5EA);
  static const Color accent = Color(0xFF5AC8FA); // iOS Teal

  // Budget Category Colors - Softer palette
  static const Color needsColor = Color(0xFF007AFF); // iOS Blue
  static const Color wantsColor = Color(0xFFFF9500); // iOS Orange
  static const Color savingsColor = Color(0xFF34C759); // iOS Green
}

/// Typography styles - San Francisco inspired
class AppTextStyles {
  // Large Titles (iOS Style)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    color: AppColors.textPrimary,
  );
  
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.36,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
    color: AppColors.textPrimary,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    color: AppColors.textSecondary,
  );
  
  // Numbers (for balances and amounts) - Tabular nums
  static const TextStyle numberLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  
  static const TextStyle numberMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.36,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  
  // Callout (iOS Style)
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    color: AppColors.textPrimary,
  );
  
  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    color: AppColors.textSecondary,
  );
  
  // Labels
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  // Body Small
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );
}

/// UI Constants - iOS Design System
class AppConstants {
  // Border Radius - iOS style rounded corners
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 10.0;
  static const double smallBorderRadius = 8.0;
  
  // Spacing - iOS 8-point grid
  static const double spacingXXS = 2.0;
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 40.0;
  
  // Elevation - Subtle shadows like iOS
  static const double cardElevation = 1.0;
  
  // Animation Duration
  static const Duration animationDuration = Duration(milliseconds: 300);
}
