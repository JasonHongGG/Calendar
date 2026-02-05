import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';

/// 多日事件條組件
class EventBar extends StatelessWidget {
  final String title;
  final String colorKey;
  final int startOffset; // 在一週中的起始位置 (0-6)
  final int span; // 在這一週跨越的天數
  final bool isStart; // 是否是事件的開始
  final bool isEnd; // 是否是事件的結束
  final VoidCallback? onTap;

  const EventBar({super.key, required this.title, required this.colorKey, required this.startOffset, required this.span, this.isStart = true, this.isEnd = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tone = context.select<SettingsProvider, EventColorTone>((s) => s.eventColorTone);
    final color = AppColors.eventColor(colorKey, tone: tone);
    final useDarkText = tone != EventColorTone.normal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        final barWidth = cellWidth * span - 8;
        final leftOffset = cellWidth * startOffset + 4;

        return Positioned(
          left: leftOffset,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: barWidth,
              height: 20,
              margin: const EdgeInsets.symmetric(vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.horizontal(left: isStart ? const Radius.circular(6) : Radius.zero, right: isEnd ? const Radius.circular(6) : Radius.zero),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: useDarkText ? AppColors.textPrimary : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: useDarkText ? null : [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 1.2, offset: const Offset(0, 0.6))],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 單日事件指示條（簡單版本，用於月曆格子內）
class EventIndicator extends StatelessWidget {
  final String title;
  final String colorKey;
  final VoidCallback? onTap;

  const EventIndicator({super.key, required this.title, required this.colorKey, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tone = context.select<SettingsProvider, EventColorTone>((s) => s.eventColorTone);
    final color = AppColors.eventColor(colorKey, tone: tone);
    final useDarkText = tone != EventColorTone.normal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: useDarkText ? AppColors.textPrimary : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            shadows: useDarkText ? null : [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 1.2, offset: const Offset(0, 0.6))],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
