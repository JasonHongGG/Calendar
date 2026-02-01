import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../utils/date_utils.dart';
import 'day_cell.dart';

import 'gradient_header.dart'; // Import CalendarHeader

/// 迷你月曆組件（用於日程視圖，支持左右滑動）
class MiniCalendar extends StatefulWidget {
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
  State<MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar> {
  late PageController _pageController;
  static const int _startYear = 2020;
  static const int _startMonth = 1;

  @override
  void initState() {
    super.initState();
    final initialIndex = _calculateIndex(widget.currentMonth);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void didUpdateWidget(MiniCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller if currentMonth changes externally
    if (widget.currentMonth.year != oldWidget.currentMonth.year ||
        widget.currentMonth.month != oldWidget.currentMonth.month) {
      final targetIndex = _calculateIndex(widget.currentMonth);
      if (_pageController.hasClients &&
          _pageController.page?.round() != targetIndex) {
        _pageController.jumpToPage(targetIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _calculateIndex(DateTime date) {
    return (date.year - _startYear) * 12 + (date.month - _startMonth);
  }

  DateTime _calculateDateFromIndex(int index) {
    return DateTime(_startYear, _startMonth + index);
  }

  @override
  Widget build(BuildContext context) {
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
          // 月份標題 (使用新的 CalendarHeader)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingSmall,
            ),
            child: CalendarHeader(
              title:
                  '${widget.currentMonth.year}/${widget.currentMonth.month.toString().padLeft(2, '0')}',
              onPrevious: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              onNext: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              // Mini calendar may not need settings button
              onSettings: null,
            ),
          ),
          const SizedBox(height: AppDimens.spacingSmall),
          // 星期標題
          _buildWeekdayHeader(),
          const SizedBox(height: AppDimens.spacingTiny),
          // 可滑動的日曆網格
          SizedBox(
            height:
                250, // Fixed height for 6 rows (40*6 + margin) - Keeping as valid functional constant for now or move to CalendarLayout?
            // Let's leave 250 here or logically calculated.
            // 6 rows * 40ish = 240.
            // Check Row height in _buildCalendarGrid: height: 40.
            // 6 * 40 = 240.
            child: PageView.builder(
              controller: _pageController,
              allowImplicitScrolling: true,
              onPageChanged: (index) {
                final newMonth = _calculateDateFromIndex(index);
                // Prevent loop: Only notify if the month implies a change from the current widget state
                if (newMonth.year != widget.currentMonth.year ||
                    newMonth.month != widget.currentMonth.month) {
                  widget.onMonthChanged?.call(newMonth);
                }
              },
              itemBuilder: (context, index) {
                final monthDate = _calculateDateFromIndex(index);
                return _buildCalendarContent(monthDate);
              },
            ),
          ),
          const SizedBox(height: AppDimens.spacingSmall),
        ],
      ),
    );
  }

  Widget _buildCalendarContent(DateTime month) {
    final days = CalendarDateUtils.getCalendarDays(month);
    // Provider is needed for event colors
    // Note: We are inside a consumer context (SchedulePage passes context or we access it here)
    // Accessing provider here is fine.
    final provider = context.watch<EventProvider>();

    return _buildCalendarGrid(days, provider, month);
  }

  Widget _buildWeekdayHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSmall),
      child: Row(
        children: CalendarDateUtils.weekdayLabels.map((label) {
          final isSunday = label == '日';
          final isSaturday = label == '六';
          Color textColor;
          if (isSunday) {
            textColor = AppColors.textSunday;
          } else if (isSaturday) {
            textColor = AppColors.textSaturday;
          } else {
            textColor = AppColors.textSecondary;
          }

          return Expanded(
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.captionSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(
    List<DateTime> days,
    EventProvider provider,
    DateTime month,
  ) {
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }

    // 只顯示屬於該月份的週數，或者固定顯示 6 週以保持高度一致
    // 這裡我們只顯示實際需要的週數，但高度已由外層 SizedBox 固定，
    // 所以少的週數會留白。
    final weeksNeeded = _calculateWeeksNeeded(days, month);
    final displayWeeks = weeks.take(weeksNeeded).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSmall),
      child: Column(
        children: displayWeeks.map((week) {
          return SizedBox(
            height: 40, // Height per row
            child: Row(
              children: week.map((date) {
                final eventColors = provider.getEventColorsForDate(date);
                final isToday = CalendarDateUtils.isToday(date);
                final isSelected = CalendarDateUtils.isSameDay(
                  date,
                  widget.selectedDate,
                );

                return Expanded(
                  child: DayCell(
                    date: date,
                    currentMonth: month,
                    isToday: isToday,
                    isSelected: isSelected,
                    eventColors: eventColors,
                    isCompact: true,
                    onTap: () => widget.onDateSelected?.call(date),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  int _calculateWeeksNeeded(List<DateTime> days, DateTime month) {
    for (var week = 5; week >= 4; week--) {
      for (var day = 0; day < 7; day++) {
        final index = week * 7 + day;
        if (index < days.length) {
          final date = days[index];
          if (CalendarDateUtils.isInMonth(date, month)) {
            return week + 1;
          }
        }
      }
    }
    return 5;
  }
}
