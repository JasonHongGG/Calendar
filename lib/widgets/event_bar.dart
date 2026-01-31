import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 多日事件條組件
class EventBar extends StatelessWidget {
  final String title;
  final int colorIndex;
  final int startOffset; // 在一週中的起始位置 (0-6)
  final int span; // 在這一週跨越的天數
  final bool isStart; // 是否是事件的開始
  final bool isEnd; // 是否是事件的結束
  final VoidCallback? onTap;

  const EventBar({
    super.key,
    required this.title,
    required this.colorIndex,
    required this.startOffset,
    required this.span,
    this.isStart = true,
    this.isEnd = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.eventColors[colorIndex % AppColors.eventColors.length];

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
                borderRadius: BorderRadius.horizontal(
                  left: isStart ? const Radius.circular(6) : Radius.zero,
                  right: isEnd ? const Radius.circular(6) : Radius.zero,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
  final int colorIndex;
  final VoidCallback? onTap;

  const EventIndicator({
    super.key,
    required this.title,
    required this.colorIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.eventColors[colorIndex % AppColors.eventColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
