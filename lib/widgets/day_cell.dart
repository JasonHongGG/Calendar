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
  bool get _isWeekend => CalendarDateUtils.isWeekend(date);

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
                gradient: isToday ? AppColors.primaryGradient : null,
                color: isSelected && !isToday
                    ? AppColors.gradientStart.withValues(alpha: 0.8) // 選中時的深色背景
                    : null,
                shape: BoxShape.circle,
                boxShadow: (isToday || isSelected)
                    ? [
                        BoxShadow(
                          color: AppColors.gradientStart.withValues(alpha: 0.3),
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
    if (_isWeekend) {
      return AppColors.textSecondary;
    }
    return AppColors.textPrimary;
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
