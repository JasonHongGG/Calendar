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
    final provider = context.watch<EventProvider>();
    final events = provider.getEventsForMonth(currentMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                style: TextStyle(
                  fontSize: 13,
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

  Widget _buildCalendarGrid(
    List<DateTime> days,
    List<Event> events,
    EventProvider provider,
  ) {
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

  Widget _buildWeekRow(
    List<DateTime> week,
    List<Event> allEvents,
    EventProvider provider,
  ) {
    // 計算並佈局這一週的事件
    final layoutEvents = _layoutEventsForWeek(week, allEvents);

    // 計算每個日期格子需要的高度
    const baseCellHeight = 32.0; // 日期數字區域高度 (從 36 縮減)
    const eventRowHeight = 18.0; // 每個事件條高度
    const eventSpacing = 2.0;

    // 最多顯示幾行事件
    final maxLane = layoutEvents.isEmpty
        ? 0
        : layoutEvents.map((e) => e.lane).reduce((a, b) => a > b ? a : b);

    // 限制最多顯示 3 到 4 行
    final visibleLanes = maxLane + 1;
    final totalEventHeight = visibleLanes * (eventRowHeight + eventSpacing);

    // 總高度
    final totalHeight = baseCellHeight + totalEventHeight + 4.0;
    // 設定一個最小高度
    final cellHeight = totalHeight < 80.0 ? 80.0 : totalHeight;

    return SizedBox(
      height: cellHeight,
      child: Stack(
        children: [
          // 日期格子背景和數字
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: week.map((date) {
              final isToday = CalendarDateUtils.isToday(date);
              final isSelected =
                  selectedDate != null &&
                  CalendarDateUtils.isSameDay(date, selectedDate!);

              return Expanded(
                child: DayCell(
                  date: date,
                  currentMonth: currentMonth,
                  isToday: isToday,
                  isSelected: isSelected,
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
                  ),
                );
              },
            ),
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
  ) {
    final List<Widget> bars = [];

    // 限定最大顯示行數
    const maxVisibleLanes = 4;

    for (final item in layouts) {
      if (item.lane >= maxVisibleLanes) continue;

      // 直接計算絕對位置和寬度
      final barWidth = (cellWidth * item.data.span) - 4;
      final leftOffset = (cellWidth * item.data.startOffset) + 2;
      final topPos = topOffset + (item.lane * (rowHeight + spacing));

      bars.add(
        Positioned(
          top: topPos,
          left: leftOffset,
          width: barWidth,
          height: rowHeight,
          child: GestureDetector(
            onTap: () => onEventTap?.call(item.data.event),
            child: Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color:
                    AppColors.eventColors[item.data.event.colorIndex %
                        AppColors.eventColors.length],
                borderRadius: BorderRadius.horizontal(
                  left: item.data.isStart
                      ? const Radius.circular(4)
                      : Radius.zero,
                  right: item.data.isEnd
                      ? const Radius.circular(4)
                      : Radius.zero,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors
                        .eventColors[item.data.event.colorIndex %
                            AppColors.eventColors.length]
                        .withValues(alpha: 0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.data.event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
      );
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
