import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';

/// 日期格子組件
class DayCell extends StatelessWidget {
  final DateTime date;
  final DateTime currentMonth;
  final bool isSelected;
  final bool isToday;
  final List<int> eventColors;
  final VoidCallback? onTap;
  final bool isCompact;

  const DayCell({
    super.key,
    required this.date,
    required this.currentMonth,
    this.isSelected = false,
    this.isToday = false,
    this.eventColors = const [],
    this.onTap,
    this.isCompact = false,
  });

  bool get _isInMonth => CalendarDateUtils.isInMonth(date, currentMonth);
  bool get _isSunday => date.weekday == DateTime.sunday;
  bool get _isSaturday => date.weekday == DateTime.saturday;

  Color get _dayColor {
    if (_isSunday) return AppColors.textSunday;
    if (_isSaturday) return AppColors.textSaturday;
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(isCompact ? 1 : 1),
        decoration: BoxDecoration(
          color: isSelected && !isToday
              ? AppColors.cardBackground
              : null, // 移除選中時的整個格子背景
          borderRadius: BorderRadius.circular(0), // 移除圓角
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // 置頂對齊
          children: [
            const SizedBox(height: 4), // 頂部間距
            // 日期數字 (含背景圓圈)
            Container(
              width: isCompact ? 22 : 26,
              height: isCompact ? 22 : 26,
              decoration: BoxDecoration(
                gradient: null, // 移除原本的漸層，改成純色
                color: isToday
                    ? _dayColor // 今天：背景為該日代表色 (紅/藍/黑)
                    : (isSelected
                          ? AppColors.gradientStart.withValues(
                              alpha: 0.8,
                            ) // 選中：深色背景
                          : null),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(
                  (isCompact ? 22.0 : 26.0) * 0.4,
                ), // 圓角約為寬度的 40%
                boxShadow: (isToday || isSelected)
                    ? [
                        BoxShadow(
                          color: (isToday ? _dayColor : AppColors.gradientStart)
                              .withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 14,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _getTextColorWithinCircle(),
                  ),
                ),
              ),
            ),
            // 事件指示點 (僅在 compact 模式顯示，因為普通模式會顯示長條)
            if (eventColors.isNotEmpty && isCompact) ...[
              const SizedBox(height: 2),
              _buildCompactEventDots(),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTextColorWithinCircle() {
    if (isToday) {
      return Colors.white;
    }
    if (isSelected) {
      return Colors.white;
    }
    // 普通狀態
    if (!_isInMonth) {
      return AppColors.textTertiary.withValues(alpha: 0.5);
    }
    // 今天和選中狀態文字白色
    if (isToday || isSelected) {
      return Colors.white;
    }
    // 其他狀態顯示該日代表色
    return _dayColor;
  }

  Widget _buildCompactEventDots() {
    final displayColors = eventColors.take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: displayColors.map((colorIndex) {
        final color =
            AppColors.eventColors[colorIndex % AppColors.eventColors.length];
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          decoration: BoxDecoration(
            color: isToday ? Colors.white.withValues(alpha: 0.8) : color,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
