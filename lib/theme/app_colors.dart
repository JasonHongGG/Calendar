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

  // Glassmorphism System
  static const Color glassSurface = Color(0xB3FFFFFF); // 70% opacity white
  static const Color glassBorder = Color(0x4DFFFFFF); // 30% opacity white
  static const Color glassInput = Color(
    0x0D000000,
  ); // Very light grey for inputs

  // 文字色彩
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color.fromARGB(255, 212, 215, 220);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnGradient = Color(0xFFFFFFFF);
  static const Color textSunday = Color(0xFFEF4444); // 紅色
  static const Color textSaturday = Color(0xFF3B82F6); // 藍色

  // 分隔線
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // 事件顏色
  // 事件顏色（已按色相排序）
  static const List<Color> eventColors = [
    Color(0xFFEF4444), // 紅
    Color(0xFFF97316), // 橙
    Color(0xFFF59E0B), // 金黃
    Color(0xFF84CC16), // 萊姆
    Color(0xFF10B981), // 翡翠綠
    Color(0xFF06B6D4), // 青
    Color(0xFF3B82F6), // 藍
    Color(0xFF6366F1), // 靛
    Color(0xFF8B5CF6), // 紫
    Color(0xFFD946EF), // 洋紅
    Color(0xFFEC4899), // 粉紅
    Color(0xFF64748B), // 灰藍
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
