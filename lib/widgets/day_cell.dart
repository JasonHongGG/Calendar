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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.all(isCompact ? 2 : 3),
        decoration: BoxDecoration(
          gradient: isToday ? AppColors.primaryGradient : null,
          color: isSelected && !isToday
              ? AppColors.gradientStart.withValues(alpha: 0.1)
              : null,
          borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
          border: isSelected && !isToday
              ? Border.all(
                  color: AppColors.gradientStart.withValues(alpha: 0.5),
                  width: 2,
                )
              : null,
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: AppColors.gradientStart.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 日期數字
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: isCompact ? 13 : 16,
                fontWeight: isToday || isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: _getTextColor(),
              ),
            ),
            // 事件指示點
            if (eventColors.isNotEmpty && !isCompact) ...[
              const SizedBox(height: 4),
              _buildEventDots(),
            ],
            if (eventColors.isNotEmpty && isCompact) ...[
              const SizedBox(height: 2),
              _buildCompactEventDots(),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTextColor() {
    if (isToday) {
      return AppColors.textOnGradient;
    }
    if (!_isInMonth) {
      return AppColors.textTertiary;
    }
    if (_isWeekend) {
      return AppColors.textSecondary;
    }
    return AppColors.textPrimary;
  }

  Widget _buildEventDots() {
    final displayColors = eventColors.take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: displayColors.map((colorIndex) {
        final color =
            AppColors.eventColors[colorIndex % AppColors.eventColors.length];
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isToday ? Colors.white.withValues(alpha: 0.8) : color,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
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
