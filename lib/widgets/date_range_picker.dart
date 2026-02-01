import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';

/// 日期範圍選擇器
class DateRangePicker extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime start, DateTime end) onDateRangeSelected;
  final VoidCallback? onConfirm;

  const DateRangePicker({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onDateRangeSelected,
    this.onConfirm,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSelectingEndDate = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      widget.initialStartDate.year,
      widget.initialStartDate.month,
      1,
    );
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    final days = CalendarDateUtils.getCalendarDays(_currentMonth);
    final weeksNeeded = _calculateWeeksNeeded(days);
    final displayDays = days.take(weeksNeeded * 7).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 月份導航
            _buildMonthHeader(),
            const SizedBox(height: 8),
            // 選擇提示
            _buildSelectionHint(),
            const SizedBox(height: 12),
            // 星期標題
            _buildWeekdayHeader(),
            const SizedBox(height: 8),
            // 日曆網格
            _buildCalendarGrid(displayDays),
            const SizedBox(height: 16),
            // 已選範圍顯示
            _buildSelectedRangeDisplay(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  int _calculateWeeksNeeded(List<DateTime> days) {
    for (var week = 5; week >= 4; week--) {
      for (var day = 0; day < 7; day++) {
        final index = week * 7 + day;
        if (index < days.length) {
          final date = days[index];
          if (CalendarDateUtils.isInMonth(date, _currentMonth)) {
            return week + 1;
          }
        }
      }
    }
    return 5;
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 0),
      child: Row(
        children: [
          _buildNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                  1,
                );
              });
            },
          ),
          const SizedBox(width: 4),
          Text(
            CalendarDateUtils.formatYearMonth(_currentMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          _buildNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                  1,
                );
              });
            },
          ),
          const Spacer(),
          if (widget.onConfirm != null)
            _buildConfirmButton(onTap: widget.onConfirm!)
          else
            const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }

  Widget _buildConfirmButton({required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(
        Icons.check_rounded,
        color: AppColors.gradientStart,
        size: 28,
      ),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.gradientStart.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(8),
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
          child: Icon(icon, color: AppColors.textSecondary, size: 24),
        ),
      ),
    );
  }

  Widget _buildSelectionHint() {
    String hint;
    Color color;

    if (_startDate == null) {
      hint = '請選擇開始日期';
      color = AppColors.gradientStart;
    } else if (_isSelectingEndDate) {
      hint = '請選擇結束日期';
      color = AppColors.gradientEnd;
    } else {
      hint = '點擊日期可重新選擇';
      color = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSelectingEndDate ? Icons.event : Icons.touch_app_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: CalendarDateUtils.weekdayLabels.map((label) {
          final isWeekend = label == '六' || label == '日';
          return Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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

  Widget _buildCalendarGrid(List<DateTime> days) {
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: weeks.map((week) {
          return SizedBox(
            height: 44,
            child: Row(
              children: week.map((date) {
                return Expanded(child: _buildDayCell(date));
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isInMonth = CalendarDateUtils.isInMonth(date, _currentMonth);
    final isToday = CalendarDateUtils.isToday(date);
    final isStart =
        _startDate != null && CalendarDateUtils.isSameDay(date, _startDate!);
    final isEnd =
        _endDate != null && CalendarDateUtils.isSameDay(date, _endDate!);
    final isInRange = _isInSelectedRange(date);
    final isSingleDay =
        _startDate != null &&
        _endDate != null &&
        CalendarDateUtils.isSameDay(_startDate!, _endDate!);

    return GestureDetector(
      onTap: isInMonth ? () => _onDateTap(date) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: _getDayDecoration(
          isStart: isStart,
          isEnd: isEnd,
          isInRange: isInRange,
          isSingleDay: isSingleDay,
        ),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: _getDayCircleDecoration(
              isStart: isStart,
              isEnd: isEnd,
              isToday: isToday,
              isInMonth: isInMonth,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: (isStart || isEnd || isToday)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: _getDayTextColor(
                    isStart: isStart,
                    isEnd: isEnd,
                    isToday: isToday,
                    isInMonth: isInMonth,
                    isInRange: isInRange,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration? _getDayDecoration({
    required bool isStart,
    required bool isEnd,
    required bool isInRange,
    required bool isSingleDay,
  }) {
    if (isSingleDay) return null;

    if (isStart && !isEnd) {
      return BoxDecoration(
        color: AppColors.gradientStart.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
      );
    }

    if (isEnd && !isStart) {
      return BoxDecoration(
        color: AppColors.gradientStart.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
      );
    }

    if (isInRange) {
      return BoxDecoration(
        color: AppColors.gradientStart.withValues(alpha: 0.15),
      );
    }

    return null;
  }

  BoxDecoration? _getDayCircleDecoration({
    required bool isStart,
    required bool isEnd,
    required bool isToday,
    required bool isInMonth,
  }) {
    if (isStart || isEnd) {
      return BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }

    if (isToday && isInMonth) {
      return BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gradientStart, width: 2),
      );
    }

    return null;
  }

  Color _getDayTextColor({
    required bool isStart,
    required bool isEnd,
    required bool isToday,
    required bool isInMonth,
    required bool isInRange,
  }) {
    if (isStart || isEnd) {
      return Colors.white;
    }

    if (!isInMonth) {
      return AppColors.textTertiary;
    }

    if (isInRange) {
      return AppColors.gradientStart;
    }

    if (isToday) {
      return AppColors.gradientStart;
    }

    return AppColors.textPrimary;
  }

  bool _isInSelectedRange(DateTime date) {
    if (_startDate == null || _endDate == null) return false;

    final dateOnly = CalendarDateUtils.dateOnly(date);
    final startOnly = CalendarDateUtils.dateOnly(_startDate!);
    final endOnly = CalendarDateUtils.dateOnly(_endDate!);

    return dateOnly.isAfter(startOnly) && dateOnly.isBefore(endOnly);
  }

  void _onDateTap(DateTime date) {
    setState(() {
      if (_startDate == null || !_isSelectingEndDate) {
        // 開始新的選擇
        _startDate = date;
        _endDate = date;
        _isSelectingEndDate = true;
      } else {
        // 選擇結束日期
        if (date.isBefore(_startDate!)) {
          // 如果選擇的日期在開始日期之前，重新設定
          _startDate = date;
          _endDate = date;
          _isSelectingEndDate = true;
        } else {
          _endDate = date;
          _isSelectingEndDate = false;
          // 通知父組件
          widget.onDateRangeSelected(_startDate!, _endDate!);
        }
      }
    });
  }

  Widget _buildSelectedRangeDisplay() {
    final showYear =
        _startDate != null &&
        _endDate != null &&
        _startDate!.year != _endDate!.year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gradientStart.withValues(alpha: 0.1),
              AppColors.gradientEnd.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildDateDisplay(
                label: '開始',
                date: _startDate,
                isStart: true,
                showYear: showYear,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.gradientStart.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
            Expanded(
              child: _buildDateDisplay(
                label: '結束',
                date: _endDate,
                isStart: false,
                showYear: showYear,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDisplay({
    required String label,
    required DateTime? date,
    required bool isStart,
    required bool showYear,
  }) {
    final isActive = isStart ? !_isSelectingEndDate : _isSelectingEndDate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? AppColors.gradientStart
                  : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              date != null
                  ? (showYear
                        ? CalendarDateUtils.formatYearMonthDaySlash(date)
                        : CalendarDateUtils.formatMonthDaySlash(date))
                  : '未選擇',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: date != null
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 顯示日期範圍選擇器對話框
Future<DateTimeRange?> showDateRangePickerDialog(
  BuildContext context, {
  required DateTime initialStartDate,
  required DateTime initialEndDate,
}) async {
  DateTimeRange? result;

  // Dismiss keyboard to clear view and providing more space
  FocusScope.of(context).unfocus();

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      // Remove Column wrapper to allow DateRangePicker to respect Dialog's constraints
      // enabling the internal SingleChildScrollView to work.
      child: DateRangePicker(
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
        onDateRangeSelected: (start, end) {
          result = DateTimeRange(start: start, end: end);
        },
        onConfirm: () {
          Navigator.pop(context);
        },
      ),
    ),
  );

  return result;
}
