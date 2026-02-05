import 'package:flutter/material.dart';

enum EventColorTone { normal, light, lightest, lighter, palest }

/// 應用程式色彩定義
class AppColors {
  AppColors._();

  // 主漸層色彩
  static const Color gradientStart = Color(0xFF667EEA);
  static const Color gradientEnd = Color(0xFF764BA2);

  // 背景色
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundTranslucent = Color(0xD9FFFFFF); // 85% opacity

  // Glassmorphism System
  static const Color glassSurface = Color(0xB3FFFFFF); // 70% opacity white
  static const Color glassBorder = Color(0x4DFFFFFF); // 30% opacity white
  static const Color glassInput = Color(0x0D000000); // Very light grey for inputs

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

  // 事件顏色（已按色相排序）
  static const List<String> eventColorKeys = ['red', 'orange', 'yellow', 'lime', 'green', 'cyan', 'blue', 'indigo', 'purple', 'magenta', 'pink', 'grayblue'];

  // normal: 目標為色卡中間一行的亮度
  static const Map<String, Color> eventColorsNormal = {
    'red': Color(0xFFF87171), // 400
    'orange': Color(0xFFFB923C),
    'yellow': Color(0xFFFBBF24),
    'lime': Color(0xFFA3E635),
    'green': Color(0xFF34D399),
    'cyan': Color(0xFF22D3EE),
    'blue': Color(0xFF60A5FA),
    'indigo': Color(0xFF818CF8),
    'purple': Color(0xFFA78BFA),
    'magenta': Color(0xFFE879F9),
    'pink': Color(0xFFF472B6),
    'grayblue': Color(0xFF94A3B8),
  };

  // light: 比 normal 更淺一階
  static const Map<String, Color> eventColorsLight = {
    'red': Color(0xFFFCA5A5), // 300
    'orange': Color(0xFFFDBA74),
    'yellow': Color(0xFFFCD34D),
    'lime': Color(0xFFBEF264),
    'green': Color(0xFF6EE7B7),
    'cyan': Color(0xFF67E8F9),
    'blue': Color(0xFF93C5FD),
    'indigo': Color(0xFFA5B4FC),
    'purple': Color(0xFFC4B5FD),
    'magenta': Color(0xFFF0ABFC),
    'pink': Color(0xFFF9A8D4),
    'grayblue': Color(0xFFCBD5E1),
  };

  // lightest: 最淺一階
  static const Map<String, Color> eventColorsLightest = {
    'red': Color(0xFFFECACA), // 200
    'orange': Color(0xFFFED7AA),
    'yellow': Color(0xFFFDE68A),
    'lime': Color(0xFFD9F99D),
    'green': Color(0xFFA7F3D0),
    'cyan': Color(0xFFA5F3FC),
    'blue': Color(0xFFBFDBFE),
    'indigo': Color(0xFFC7D2FE),
    'purple': Color(0xFFDDD6FE),
    'magenta': Color(0xFFF5D0FE),
    'pink': Color(0xFFFBCFE8),
    'grayblue': Color(0xFFE2E8F0),
  };

  // lighter: 100
  static const Map<String, Color> eventColorsLighter = {'red': Color(0xFFFEE2E2), 'orange': Color(0xFFFFEDD5), 'yellow': Color(0xFFFEF9C3), 'lime': Color(0xFFECFCCB), 'green': Color(0xFFD1FAE5), 'cyan': Color(0xFFCFFAFE), 'blue': Color(0xFFDBEAFE), 'indigo': Color(0xFFE0E7FF), 'purple': Color(0xFFEDE9FE), 'magenta': Color(0xFFFAE8FF), 'pink': Color(0xFFFCE7F3), 'grayblue': Color(0xFFF1F5F9)};

  // palest: 50
  static const Map<String, Color> eventColorsPalest = {'red': Color(0xFFFEF2F2), 'orange': Color(0xFFFFF7ED), 'yellow': Color(0xFFFEFCF3), 'lime': Color(0xFFF7FEE7), 'green': Color(0xFFECFDF5), 'cyan': Color(0xFFECFEFF), 'blue': Color(0xFFEFF6FF), 'indigo': Color(0xFFEEF2FF), 'purple': Color(0xFFF5F3FF), 'magenta': Color(0xFFFDF4FF), 'pink': Color(0xFFFDF2F8), 'grayblue': Color(0xFFF8FAFC)};

  static const Set<String> _disabledEventColorKeys = {'lime', 'grayblue'};

  static List<String> get selectableEventColorKeys {
    final keys = <String>[];
    for (final key in eventColorKeys) {
      if (_disabledEventColorKeys.contains(key)) continue;
      keys.add(key);
    }
    return List.unmodifiable(keys);
  }

  static Color eventColor(String colorKey, {EventColorTone tone = EventColorTone.normal}) {
    final palette = switch (tone) {
      EventColorTone.normal => eventColorsNormal,
      EventColorTone.light => eventColorsLight,
      EventColorTone.lightest => eventColorsLightest,
      EventColorTone.lighter => eventColorsLighter,
      EventColorTone.palest => eventColorsPalest,
    };
    return palette[colorKey] ?? palette['red']!;
  }

  // 底部導航
  static const Color navBarBackground = Color(0xFFFFFFFF);
  static const Color navBarSelected = Color(0xFF667EEA);
  static const Color navBarUnselected = Color(0xFF94A3B8);

  // 陰影
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // 主漸層
  static const LinearGradient primaryGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gradientStart, gradientEnd]);

  // 淺色漸層（用於背景）
  static const LinearGradient lightGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)]);
}
