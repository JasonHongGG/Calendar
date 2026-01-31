import 'package:flutter/material.dart';

/// 應用程式色彩定義
class AppColors {
  AppColors._();

  // 主漸層色彩
  static const Color gradientStart = Color(0xFF667EEA);
  static const Color gradientEnd = Color(0xFF764BA2);

  // 背景色
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundTranslucent = Color(
    0xD9FFFFFF,
  ); // 85% opacity

  // 文字色彩
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnGradient = Color(0xFFFFFFFF);

  // 分隔線
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // 事件顏色
  static const List<Color> eventColors = [
    Color(0xFF10B981), // 翡翠綠
    Color(0xFFF59E0B), // 琥珀橙
    Color(0xFFEF4444), // 珊瑚紅
    Color(0xFF8B5CF6), // 薰衣草紫
    Color(0xFF06B6D4), // 青藍
    Color(0xFFEC4899), // 玫瑰粉
    Color(0xFF3B82F6), // 皇家藍
    Color(0xFF14B8A6), // 青綠
  ];

  // 底部導航
  static const Color navBarBackground = Color(0xFFFFFFFF);
  static const Color navBarSelected = Color(0xFF667EEA);
  static const Color navBarUnselected = Color(0xFF94A3B8);

  // 陰影
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // 主漸層
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  // 淺色漸層（用於背景）
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
  );
}
