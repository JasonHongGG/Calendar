import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import 'day_cell.dart';
import '../theme/calendar_layout.dart';

/// 完整月曆組件
class MonthCalendar extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime? selectedDate; // 改為可空，若為 null 則不顯示選中狀態
  final Function(DateTime)? onDateSelected;
  final Function(Event)? onEventTap;

  const MonthCalendar({
    super.key,
    required this.currentMonth,
    this.selectedDate,
    this.onDateSelected,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final days = CalendarDateUtils.getCalendarDays(currentMonth);
    // Use select to only rebuild when the events list changes
    final allEvents = context.select<EventProvider, List<Event>>(
      (p) => p.events,
    );

    // Filter events for this specific month instance
    final events = _getEventsForMonth(allEvents, currentMonth);

    // MonthCalendar now only renders the grid content
    return _buildCalendarGrid(days, events);
  }

  // Local helper to filter events, avoiding dependency on Provider instance methods
  List<Event> _getEventsForMonth(List<Event> allEvents, DateTime month) {
    final firstDay = CalendarDateUtils.getFirstDayOfMonth(month);
    final lastDay = CalendarDateUtils.getLastDayOfMonth(month);

    return allEvents.where((event) {
      final startOnly = CalendarDateUtils.dateOnly(event.startDate);
      final endOnly = CalendarDateUtils.dateOnly(event.endDate);

      // 事件與月份有交集
      return !endOnly.isBefore(firstDay) && !startOnly.isAfter(lastDay);
    }).toList();
  }

  Widget _buildCalendarGrid(List<DateTime> days, List<Event> events) {
    // 將日期分成 6 週，但過濾掉完全不屬於當前月份的週
    final allWeeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      allWeeks.add(days.sublist(i, i + 7));
    }

    final visibleWeeks = allWeeks.where((week) {
      return week.any(
        (date) => CalendarDateUtils.isInMonth(date, currentMonth),
      );
    }).toList();

    // 計算動態高度
    // 使用 centralized layout constants
    final targetTotalHeight = CalendarLayout.monthGridTargetHeight;
    // 減去分隔線的高度 (每週之間有一條線，共 visibleWeeks.length - 1 條)
    // 確保總高度 (Cells + Dividers) 準確等於 targetTotalHeight
    final totalDividerHeight = (visibleWeeks.length - 1) * 1.0;
    final cellHeight =
        (targetTotalHeight - totalDividerHeight) / visibleWeeks.length;

    // 計算動態最大事件行數
    // cellHeight = dayLabelHeight + events
    final availableEventSpace = cellHeight - CalendarLayout.dayLabelHeight;
    final maxEventRows =
        (availableEventSpace /
                (CalendarLayout.eventRowHeight + CalendarLayout.eventSpacing))
            .floor();

    // 構建帶有分隔線的週列表
    final children = <Widget>[];
    for (var i = 0; i < visibleWeeks.length; i++) {
      children.add(
        _buildWeekRow(visibleWeeks[i], events, cellHeight, maxEventRows),
      );
      if (i < visibleWeeks.length - 1) {
        children.add(
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.divider.withValues(alpha: 0.3),
          ),
        );
      }
    }

    return Column(children: children);
  }

  Widget _buildWeekRow(
    List<DateTime> week,
    List<Event> allEvents,
    double cellHeight,
    int maxRows,
  ) {
    // 計算並佈局這一週的事件
    final layoutEvents = _layoutEventsForWeek(week, allEvents);

    const baseCellHeight = CalendarLayout.dayLabelHeight;
    const eventRowHeight = CalendarLayout.eventRowHeight;
    const eventSpacing = CalendarLayout.eventSpacing;

    return SizedBox(
      height: cellHeight,
      child: Stack(
        children: [
          // 日期格子背景和數字
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: week.map((date) {
              final isToday = CalendarDateUtils.isToday(date);
              // 移除底層 DayCell 的選中狀態，改由最上層覆蓋繪製
              // final isSelected = ...

              return Expanded(
                child: DayCell(
                  date: date,
                  currentMonth: currentMonth,
                  isToday: isToday,
                  isSelected: false, // 永遠不選中，由 Overlay 處理
                  eventColors: const [],
                  onTap: () => onDateSelected?.call(date),
                ),
              );
            }).toList(),
          ),
          // 多日事件條 (渲染 layer)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / 7;
                return Stack(
                  children: _buildEventBars(
                    week,
                    layoutEvents,
                    baseCellHeight,
                    eventRowHeight,
                    eventSpacing,
                    cellWidth,
                    maxRows,
                  ),
                );
              },
            ),
          ),
          // 選中框覆蓋層 (最上層，確保不被事件遮擋)
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: week.map((date) {
              final isSelected =
                  selectedDate != null &&
                  CalendarDateUtils.isSameDay(date, selectedDate!);

              if (!isSelected) return const Expanded(child: SizedBox());

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(
                    1,
                  ), // Match DayCell margin (1 for compact)
                  // Note: DayCell code says: margin: EdgeInsets.all(isCompact ? 1 : 1),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textSecondary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<_WeekEventLayout> _layoutEventsForWeek(
    List<DateTime> week,
    List<Event> allEvents,
  ) {
    // 確保全部轉為 Local 時間並只取日期部分，解決時區問題
    final weekStart = CalendarDateUtils.dateOnly(week.first);
    final weekEnd = CalendarDateUtils.dateOnly(week.last);
    final weekEvents = <_WeekEventData>[];

    // 1. 篩選出本週有關的事件
    for (final event in allEvents) {
      // 轉換為本地時間再取日期，避免 UTC 跨日問題
      final eventStartLocal = event.startDate.toLocal();
      final eventEndLocal = event.endDate.toLocal();

      final eventStart = CalendarDateUtils.dateOnly(eventStartLocal);
      final eventEnd = CalendarDateUtils.dateOnly(eventEndLocal);

      // 檢查交集: eventEnd >= weekStart AND eventStart <= weekEnd
      // 使用 compareTo 確保比較準確
      if (eventEnd.compareTo(weekStart) >= 0 &&
          eventStart.compareTo(weekEnd) <= 0) {
        // 計算在本週的顯示範圍
        // 使用 compareTo 判斷 displayEnd
        final displayStart = eventStart.compareTo(weekStart) < 0
            ? weekStart
            : eventStart;
        final displayEnd = eventEnd.compareTo(weekEnd) > 0 ? weekEnd : eventEnd;

        final startOffset = displayStart.difference(weekStart).inDays;
        var span = displayEnd.difference(displayStart).inDays + 1;

        // 安全檢查：確保 span 不會超出當週剩餘天數
        if (startOffset + span > 7) {
          span = 7 - startOffset;
        }

        weekEvents.add(
          _WeekEventData(
            event: event,
            startOffset: startOffset,
            span: span,
            isStart: CalendarDateUtils.isSameDay(eventStart, displayStart),
            isEnd: CalendarDateUtils.isSameDay(eventEnd, displayEnd),
            sortKey: startOffset * 100 - span,
          ),
        );
      }
    }

    // 2. 排序
    weekEvents.sort((a, b) {
      if (a.startOffset != b.startOffset) {
        return a.startOffset.compareTo(b.startOffset);
      }
      return b.span.compareTo(a.span); // 長的在前 (span 越大越前)
    });

    // 3. 分配 Lane (Packing)
    final layout = <_WeekEventLayout>[];
    // lanes[i] 紀錄第 i 行最後被占用的索引位置 (0~6)
    // 例如 lanes[0] = 2 表示第 0 行已經占用到了星期二 (index 2)，下一個事件必須從 index 3 開始才能放這行
    final lanes = <int>[];

    for (final item in weekEvents) {
      int assignedLane = -1;

      // 嘗試找到一個可以放入的 lane
      for (int i = 0; i < lanes.length; i++) {
        if (lanes[i] < item.startOffset) {
          assignedLane = i;
          lanes[i] = item.startOffset + item.span - 1; // 更新佔用截止
          break;
        }
      }

      // 如果沒找到，開啟新 lane
      if (assignedLane == -1) {
        assignedLane = lanes.length;
        lanes.add(item.startOffset + item.span - 1);
      }

      layout.add(_WeekEventLayout(data: item, lane: assignedLane));
    }

    return layout;
  }

  List<Widget> _buildEventBars(
    List<DateTime> week,
    List<_WeekEventLayout> layouts,
    double topOffset,
    double rowHeight,
    double spacing,
    double cellWidth,
    int maxRows,
  ) {
    final List<Widget> bars = [];
    // maxRows passed from arguments

    // 1. 計算每天的事件總數
    final eventCounts = List.filled(7, 0);
    for (final item in layouts) {
      for (var i = 0; i < item.data.span; i++) {
        final dayIndex = item.data.startOffset + i;
        if (dayIndex < 7) {
          eventCounts[dayIndex]++;
        }
      }
    }

    // 2. 構建事件條 Widget 的輔助函數
    Widget createEventBar(
      _WeekEventData data,
      double width,
      bool forceStart,
      bool forceEnd,
    ) {
      return IgnorePointer(
        child: Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color:
                AppColors.eventColors[data.event.colorIndex %
                    AppColors.eventColors.length],
            borderRadius: BorderRadius.horizontal(
              left: (data.isStart || forceStart)
                  ? const Radius.circular(4)
                  : Radius.zero,
              right: (data.isEnd || forceEnd)
                  ? const Radius.circular(4)
                  : Radius.zero,
            ),
            // BoxShadow removed for performance optimization during swiping
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            data.event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      );
    }

    // 3. 遍歷事件並生成 Widget
    // 第 maxRows-1 行是 "溢出顯示行" (0-indexed)
    // 例如 maxRows=3, overflowLane=2 (第3行)
    final overflowLane = maxRows - 1;

    for (final item in layouts) {
      // 超過 overflowLane 的事件，除了在該行本身可能顯示的部分，完全忽略
      if (item.lane > overflowLane) continue;

      // 如果是在溢出顯示行之前，直接顯示
      if (item.lane < overflowLane) {
        final barWidth = (cellWidth * item.data.span) - 4;
        final leftOffset = (cellWidth * item.data.startOffset) + 2;
        final topPos = topOffset + (item.lane * (rowHeight + spacing));

        bars.add(
          Positioned(
            top: topPos,
            left: leftOffset,
            width: barWidth,
            height: rowHeight,
            child: createEventBar(item.data, barWidth, false, false),
          ),
        );
      } else if (item.lane == overflowLane) {
        // 如果是在最後一行 (overflowLane)，需要檢查每一天是否 "溢出"
        // 只有在當天總事件數 <= maxRows 時，才顯示該事件的該天部分
        // 若 > maxRows，該位置留給 +N
        int currentStart = -1;
        int currentLength = 0;

        for (var i = 0; i < item.data.span; i++) {
          final dayIndex = item.data.startOffset + i;
          if (dayIndex >= 7) break;

          if (eventCounts[dayIndex] <= maxRows) {
            // 這個位置可以放事件
            if (currentStart == -1) {
              currentStart = dayIndex;
            }
            currentLength++;
          } else {
            // 這個位置溢出，必須截斷之前的段落
            if (currentStart != -1) {
              final barWidth = (cellWidth * currentLength) - 4;
              final leftOffset = (cellWidth * currentStart) + 2;
              final topPos = topOffset + (item.lane * (rowHeight + spacing));

              bars.add(
                Positioned(
                  top: topPos,
                  left: leftOffset,
                  width: barWidth,
                  height: rowHeight,
                  child: createEventBar(
                    item.data,
                    barWidth,
                    currentStart == item.data.startOffset, // forceStart
                    false, // forceEnd will be handled by next segment logic or original
                  ),
                ),
              );
              currentStart = -1;
              currentLength = 0;
            }
          }
        }
        // 處理剩餘段落
        if (currentStart != -1) {
          final barWidth = (cellWidth * currentLength) - 4;
          final leftOffset = (cellWidth * currentStart) + 2;
          final topPos = topOffset + (item.lane * (rowHeight + spacing));

          bars.add(
            Positioned(
              top: topPos,
              left: leftOffset,
              width: barWidth,
              height: rowHeight,
              child: createEventBar(
                item.data,
                barWidth,
                currentStart == item.data.startOffset,
                currentStart + currentLength ==
                    item.data.startOffset + item.data.span,
              ),
            ),
          );
        }
      }
    }

    // 4. 生成 +N 指示器
    for (var i = 0; i < 7; i++) {
      if (eventCounts[i] > maxRows) {
        // 前 (maxRows-1) 行顯示了事件，剩下都縮在第 maxRows 行
        final count = eventCounts[i] - (maxRows - 1);
        final leftOffset = (cellWidth * i) + 2;
        final topPos = topOffset + (overflowLane * (rowHeight + spacing));
        final width = cellWidth - 4;

        bars.add(
          Positioned(
            top: topPos,
            left: leftOffset,
            width: width,
            height: rowHeight,
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '+$count',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }
    }

    return bars;
  }
}

class _WeekEventData {
  final Event event;
  final int startOffset;
  final int span;
  final bool isStart;
  final bool isEnd;
  final int sortKey;

  _WeekEventData({
    required this.event,
    required this.startOffset,
    required this.span,
    required this.isStart,
    required this.isEnd,
    required this.sortKey,
  });
}

class _WeekEventLayout {
  final _WeekEventData data;
  final int lane;

  _WeekEventLayout({required this.data, required this.lane});
}
