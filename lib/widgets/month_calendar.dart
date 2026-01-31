import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import 'day_cell.dart';

/// 完整月曆組件
class MonthCalendar extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final Function(DateTime)? onDateSelected;
  final Function(Event)? onEventTap;

  const MonthCalendar({super.key, required this.currentMonth, required this.selectedDate, this.onDateSelected, this.onEventTap});

  @override
  Widget build(BuildContext context) {
    final days = CalendarDateUtils.getCalendarDays(currentMonth);
    final provider = context.watch<EventProvider>();
    final events = provider.getEventsForMonth(currentMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // 星期標題
          _buildWeekdayHeader(),
          const Divider(height: 1),
          // 日曆網格
          _buildCalendarGrid(days, events, provider),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: CalendarDateUtils.weekdayLabels.map((label) {
          final isWeekend = label == '六' || label == '日';
          return Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isWeekend ? AppColors.textTertiary : AppColors.textSecondary),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(List<DateTime> days, List<Event> events, EventProvider provider) {
    // 將日期分成 6 週
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }

    return Column(
      children: weeks.map((week) {
        return _buildWeekRow(week, events, provider);
      }).toList(),
    );
  }

  Widget _buildWeekRow(List<DateTime> week, List<Event> allEvents, EventProvider provider) {
    // 計算這一週的多日事件
    final multiDayEvents = _getMultiDayEventsForWeek(week, allEvents);

    // 計算每個日期格子需要的高度
    const baseCellHeight = 50.0;
    const eventRowHeight = 22.0;
    final totalEventRows = multiDayEvents.length.clamp(0, 3);
    final cellHeight = baseCellHeight + (eventRowHeight * totalEventRows);

    return SizedBox(
      height: cellHeight,
      child: Stack(
        children: [
          // 日期格子
          Row(
            children: week.map((date) {
              final eventColors = provider.getEventColorsForDate(date);
              final isToday = CalendarDateUtils.isToday(date);
              final isSelected = CalendarDateUtils.isSameDay(date, selectedDate);

              return Expanded(
                child: DayCell(date: date, currentMonth: currentMonth, isToday: isToday, isSelected: isSelected, eventColors: multiDayEvents.isEmpty ? eventColors : [], onTap: () => onDateSelected?.call(date)),
              );
            }).toList(),
          ),
          // 多日事件條
          ..._buildEventBars(week, multiDayEvents),
        ],
      ),
    );
  }

  List<_WeekEvent> _getMultiDayEventsForWeek(List<DateTime> week, List<Event> allEvents) {
    final weekStart = CalendarDateUtils.dateOnly(week.first);
    final weekEnd = CalendarDateUtils.dateOnly(week.last);

    final List<_WeekEvent> weekEvents = [];

    for (final event in allEvents) {
      final eventStart = CalendarDateUtils.dateOnly(event.startDate);
      final eventEnd = CalendarDateUtils.dateOnly(event.endDate);

      // 檢查事件是否與這一週有交集
      if (!eventEnd.isBefore(weekStart) && !eventStart.isAfter(weekEnd)) {
        // 計算在這一週的顯示範圍
        final displayStart = eventStart.isBefore(weekStart) ? weekStart : eventStart;
        final displayEnd = eventEnd.isAfter(weekEnd) ? weekEnd : eventEnd;

        // 計算 offset 和 span
        final startOffset = displayStart.difference(weekStart).inDays;
        final span = displayEnd.difference(displayStart).inDays + 1;

        weekEvents.add(_WeekEvent(event: event, startOffset: startOffset, span: span, isStart: CalendarDateUtils.isSameDay(eventStart, displayStart), isEnd: CalendarDateUtils.isSameDay(eventEnd, displayEnd)));
      }
    }

    // 按開始位置和持續時間排序
    weekEvents.sort((a, b) {
      if (a.startOffset != b.startOffset) {
        return a.startOffset.compareTo(b.startOffset);
      }
      return b.span.compareTo(a.span); // 持續時間長的在前
    });

    return weekEvents.take(3).toList(); // 最多顯示 3 個事件
  }

  List<Widget> _buildEventBars(List<DateTime> week, List<_WeekEvent> weekEvents) {
    final List<Widget> bars = [];

    for (var i = 0; i < weekEvents.length; i++) {
      final weekEvent = weekEvents[i];
      bars.add(
        Positioned(
          top: 32 + (i * 22.0),
          left: 0,
          right: 0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / 7;
              final barWidth = cellWidth * weekEvent.span - 8;
              final leftOffset = cellWidth * weekEvent.startOffset + 4;

              return Container(
                margin: EdgeInsets.only(left: leftOffset),
                width: barWidth,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.eventColors[weekEvent.event.colorIndex % AppColors.eventColors.length],
                  borderRadius: BorderRadius.horizontal(left: weekEvent.isStart ? const Radius.circular(6) : Radius.zero, right: weekEvent.isEnd ? const Radius.circular(6) : Radius.zero),
                  boxShadow: [BoxShadow(color: AppColors.eventColors[weekEvent.event.colorIndex % AppColors.eventColors.length].withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.centerLeft,
                child: Text(
                  weekEvent.event.title,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            },
          ),
        ),
      );
    }

    return bars;
  }
}

class _WeekEvent {
  final Event event;
  final int startOffset;
  final int span;
  final bool isStart;
  final bool isEnd;

  _WeekEvent({required this.event, required this.startOffset, required this.span, required this.isStart, required this.isEnd});
}
