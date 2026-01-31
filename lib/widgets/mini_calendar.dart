import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import 'day_cell.dart';

/// 迷你月曆組件（用於日程視圖）
class MiniCalendar extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final Function(DateTime)? onDateSelected;
  final Function(DateTime)? onMonthChanged;

  const MiniCalendar({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    this.onDateSelected,
    this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final days = CalendarDateUtils.getCalendarDays(currentMonth);
    final provider = context.watch<EventProvider>();

    // 計算實際需要顯示的週數
    final weeksNeeded = _calculateWeeksNeeded(days);
    final displayDays = days.take(weeksNeeded * 7).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 月份標題
          _buildMonthHeader(),
          const SizedBox(height: 8),
          // 星期標題
          _buildWeekdayHeader(),
          const SizedBox(height: 4),
          // 日曆網格
          _buildCalendarGrid(displayDays, provider),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  int _calculateWeeksNeeded(List<DateTime> days) {
    // 找出本月最後一天在第幾週
    for (var week = 5; week >= 4; week--) {
      for (var day = 0; day < 7; day++) {
        final index = week * 7 + day;
        if (index < days.length) {
          final date = days[index];
          if (CalendarDateUtils.isInMonth(date, currentMonth)) {
            return week + 1;
          }
        }
      }
    }
    return 5;
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            CalendarDateUtils.formatYearMonth(currentMonth),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              _buildNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () {
                  final prevMonth = DateTime(
                    currentMonth.year,
                    currentMonth.month - 1,
                    1,
                  );
                  onMonthChanged?.call(prevMonth);
                },
              ),
              _buildNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: () {
                  final nextMonth = DateTime(
                    currentMonth.year,
                    currentMonth.month + 1,
                    1,
                  );
                  onMonthChanged?.call(nextMonth);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: AppColors.textSecondary, size: 22),
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: CalendarDateUtils.weekdayLabels.map((label) {
          final isWeekend = label == '六' || label == '日';
          return Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isWeekend
                      ? AppColors.textTertiary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(List<DateTime> days, EventProvider provider) {
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: weeks.map((week) {
          return SizedBox(
            height: 40,
            child: Row(
              children: week.map((date) {
                final eventColors = provider.getEventColorsForDate(date);
                final isToday = CalendarDateUtils.isToday(date);
                final isSelected = CalendarDateUtils.isSameDay(
                  date,
                  selectedDate,
                );

                return Expanded(
                  child: DayCell(
                    date: date,
                    currentMonth: currentMonth,
                    isToday: isToday,
                    isSelected: isSelected,
                    eventColors: eventColors,
                    isCompact: true,
                    onTap: () => onDateSelected?.call(date),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
