import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings
  static const TextStyle headerLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.0,
    letterSpacing: -2,
  );

  static const TextStyle headerMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyNormal = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  // Captions / Subtitles
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  // Calendar Specific
  static const TextStyle weekdayLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    // Color depends on day, handled in widget logic usually, or we can define variants
  );

  static const TextStyle dayNumber = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.0,
  );

  static const TextStyle dayNumberCompact = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.0,
  );

  static const TextStyle lunarDate = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.1,
  );
}
