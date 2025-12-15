import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography System - Design Minimalista
/// Fonte: Cereal (Airbnb Design System)
class AppTypography {
  // Display styles (large headings)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  // Headline styles (section headers)
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Title styles (card titles, list items)
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body styles (main text)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  // Label styles (buttons, chips)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.2,
  );

  // Caption styles (hints, helper text)
  static const TextStyle caption = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.35,
  );

  static const TextStyle captionLight = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  // Aliases for backward compatibility (old naming conventions)
  static const TextStyle subtitleLight = titleMedium;
  static const TextStyle bodyLight = bodyMedium;

  // Button text style
  static const TextStyle button = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
    letterSpacing: 0.2,
  );

  // Input field text style
  static const TextStyle input = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Error text style
  static const TextStyle error = TextStyle(
    fontFamily: 'Cereal',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
    height: 1.3,
  );
}
