import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import 'day_cell.dart';
import '../theme/calendar_layout.dart';
import '../providers/settings_provider.dart';

/// 完整月曆組件
class MonthCalendar extends StatefulWidget {
  final DateTime currentMonth;
  final DateTime? selectedDate; // 改為可空，若為 null 則不顯示選中狀態
  final Function(DateTime)? onDateSelected;
  final Function(Event)? onEventTap;

  const MonthCalendar({super.key, required this.currentMonth, this.selectedDate, this.onDateSelected, this.onEventTap});

  static final Map<String, _MonthCache> _cache = {};

  static String _cacheKey(DateTime month, int eventsVersion) {
    return '${month.year}-${month.month}-$eventsVersion';
  }

  static void prewarm(List<Event> allEvents, DateTime month, int eventsVersion) {
    final key = _cacheKey(month, eventsVersion);
    if (_cache.containsKey(key)) return;

    final days = CalendarDateUtils.getCalendarDays(month);
    final visibleWeeks = _MonthCalendarState._buildVisibleWeeksStatic(days, month);
    final monthEvents = _MonthCalendarState._getEventsForMonthStatic(allEvents, month);
    final weekLayouts = <int, List<_WeekEventLayout>>{};
    for (var i = 0; i < visibleWeeks.length; i++) {
      weekLayouts[i] = _MonthCalendarState._layoutEventsForWeekStatic(visibleWeeks[i], monthEvents);
    }

    _cache[key] = _MonthCache(days: days, visibleWeeks: visibleWeeks, monthEvents: monthEvents, weekLayouts: weekLayouts);
  }

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> with AutomaticKeepAliveClientMixin {
  String? _lastCacheKey;
  List<DateTime> _days = const [];
  List<List<DateTime>> _visibleWeeks = const [];
  List<Event> _monthEvents = const [];
  final Map<int, List<_WeekEventLayout>> _weekLayouts = {};
  bool _showEventBars = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMonth.year != widget.currentMonth.year || oldWidget.currentMonth.month != widget.currentMonth.month) {
      _showEventBars = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showEventBars = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Use select to only rebuild when the events list changes
    final allEvents = context.select<EventProvider, List<Event>>((p) => p.events);
    final eventsVersion = context.select<EventProvider, int>((p) => p.eventsVersion);
    final settings = context.watch<SettingsProvider>();

    _ensureCache(allEvents, eventsVersion);

    // MonthCalendar now only renders the grid content
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildCalendarGrid(_visibleWeeks, _monthEvents, settings, constraints.maxHeight);
      },
    );
  }

  void _ensureCache(List<Event> allEvents, int eventsVersion) {
    final cacheKey = MonthCalendar._cacheKey(widget.currentMonth, eventsVersion);
    if (_lastCacheKey == cacheKey) return;

    final cached = MonthCalendar._cache[cacheKey];
    if (cached != null) {
      _lastCacheKey = cacheKey;
      _days = cached.days;
      _visibleWeeks = cached.visibleWeeks;
      _monthEvents = cached.monthEvents;
      _weekLayouts
        ..clear()
        ..addAll(cached.weekLayouts);
      return;
    }

    _lastCacheKey = cacheKey;
    _days = CalendarDateUtils.getCalendarDays(widget.currentMonth);
    _visibleWeeks = _buildVisibleWeeks(_days);
    _monthEvents = _getEventsForMonth(allEvents, widget.currentMonth);
    _weekLayouts.clear();

    for (var i = 0; i < _visibleWeeks.length; i++) {
      _weekLayouts[i] = _layoutEventsForWeek(_visibleWeeks[i], _monthEvents);
    }

    MonthCalendar._cache[cacheKey] = _MonthCache(days: _days, visibleWeeks: _visibleWeeks, monthEvents: _monthEvents, weekLayouts: Map<int, List<_WeekEventLayout>>.from(_weekLayouts));
  }

  // Local helper to filter events, avoiding dependency on Provider instance methods
  List<Event> _getEventsForMonth(List<Event> allEvents, DateTime month) {
    return _getEventsForMonthStatic(allEvents, month);
  }

  static List<Event> _getEventsForMonthStatic(List<Event> allEvents, DateTime month) {
    final firstDay = CalendarDateUtils.getFirstDayOfMonth(month);
    final lastDay = CalendarDateUtils.getLastDayOfMonth(month);

    return allEvents.where((event) {
      final startOnly = CalendarDateUtils.dateOnly(event.startDate);
      final endOnly = CalendarDateUtils.dateOnly(event.endDate);

      return !endOnly.isBefore(firstDay) && !startOnly.isAfter(lastDay);
    }).toList();
  }

  List<List<DateTime>> _buildVisibleWeeks(List<DateTime> days) {
    return _buildVisibleWeeksStatic(days, widget.currentMonth);
  }

  static List<List<DateTime>> _buildVisibleWeeksStatic(List<DateTime> days, DateTime month) {
    final allWeeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      allWeeks.add(days.sublist(i, i + 7));
    }

    return allWeeks.where((week) {
      return week.any((date) => CalendarDateUtils.isInMonth(date, month));
    }).toList();
  }

  Widget _buildCalendarGrid(List<List<DateTime>> visibleWeeks, List<Event> events, SettingsProvider settings, double availableHeight) {
    // 計算動態高度
    // 使用 centralized layout constants
    final targetTotalHeight = availableHeight;
    // 減去分隔線的高度 (每週之間有一條線，共 visibleWeeks.length - 1 條)
    // 確保總高度 (Cells + Dividers) 準確等於 targetTotalHeight
    final totalDividerHeight = (visibleWeeks.length - 1) * 1.0;
    final cellHeight = (targetTotalHeight - totalDividerHeight) / visibleWeeks.length;

    // 計算動態最大事件行數
    // cellHeight = dayLabelHeight + events
    final availableEventSpace = cellHeight - CalendarLayout.dayLabelHeight;
    final rowHeight = settings.monthEventRowHeight;
    final rowSpacing = settings.monthEventSpacing;
    final capacity = (availableEventSpace / (rowHeight + rowSpacing)).floor();
    final safeCapacity = capacity < 1 ? 1 : capacity;
    final maxEventRows = safeCapacity;

    // 構建帶有分隔線的週列表
    final children = <Widget>[];
    for (var i = 0; i < visibleWeeks.length; i++) {
      children.add(_buildWeekRow(visibleWeeks[i], _weekLayouts[i] ?? const [], cellHeight, maxEventRows, rowHeight, rowSpacing, settings.monthEventFontSize, settings.monthEventOverflowFontSize));
      if (i < visibleWeeks.length - 1) {
        children.add(Divider(height: 1, thickness: 1, color: AppColors.divider.withValues(alpha: 0.3)));
      }
    }

    return Column(children: children);
  }

  Widget _buildWeekRow(List<DateTime> week, List<_WeekEventLayout> layoutEvents, double cellHeight, int maxRows, double rowHeight, double rowSpacing, double eventFontSize, double overflowFontSize) {
    const baseCellHeight = CalendarLayout.dayLabelHeight;

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
                  currentMonth: widget.currentMonth,
                  isToday: isToday,
                  isSelected: false, // 永遠不選中，由 Overlay 處理
                  eventColors: const [],
                  onTap: () => widget.onDateSelected?.call(date),
                ),
              );
            }).toList(),
          ),
          // 多日事件條 (渲染 layer)
          if (_showEventBars)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellWidth = constraints.maxWidth / 7;
                  return Stack(children: _buildEventBars(week, layoutEvents, baseCellHeight, rowHeight, rowSpacing, cellWidth, maxRows, eventFontSize, overflowFontSize));
                },
              ),
            ),
          // 選中框覆蓋層 (最上層，確保不被事件遮擋)
          IgnorePointer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: week.map((date) {
                final isSelected = widget.selectedDate != null && CalendarDateUtils.isSameDay(date, widget.selectedDate!);

                if (!isSelected) return const Expanded(child: SizedBox());

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1), // Match DayCell margin (1 for compact)
                    // Note: DayCell code says: margin: EdgeInsets.all(isCompact ? 1 : 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.textSecondary, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<_WeekEventLayout> _layoutEventsForWeek(List<DateTime> week, List<Event> allEvents) {
    return _layoutEventsForWeekStatic(week, allEvents);
  }

  static List<_WeekEventLayout> _layoutEventsForWeekStatic(List<DateTime> week, List<Event> allEvents) {
    final weekStart = CalendarDateUtils.dateOnly(week.first);
    final weekEnd = CalendarDateUtils.dateOnly(week.last);
    final weekEvents = <_WeekEventData>[];

    for (final event in allEvents) {
      final eventStartLocal = event.startDate.toLocal();
      final eventEndLocal = event.endDate.toLocal();

      final eventStart = CalendarDateUtils.dateOnly(eventStartLocal);
      final eventEnd = CalendarDateUtils.dateOnly(eventEndLocal);

      if (eventEnd.compareTo(weekStart) >= 0 && eventStart.compareTo(weekEnd) <= 0) {
        final displayStart = eventStart.compareTo(weekStart) < 0 ? weekStart : eventStart;
        final displayEnd = eventEnd.compareTo(weekEnd) > 0 ? weekEnd : eventEnd;

        final startOffset = displayStart.difference(weekStart).inDays;
        var span = displayEnd.difference(displayStart).inDays + 1;

        if (startOffset + span > 7) {
          span = 7 - startOffset;
        }

        weekEvents.add(_WeekEventData(event: event, startOffset: startOffset, span: span, isStart: CalendarDateUtils.isSameDay(eventStart, displayStart), isEnd: CalendarDateUtils.isSameDay(eventEnd, displayEnd), sortKey: startOffset * 100 - span));
      }
    }

    weekEvents.sort((a, b) {
      if (a.startOffset != b.startOffset) {
        return a.startOffset.compareTo(b.startOffset);
      }
      return b.span.compareTo(a.span);
    });

    final layout = <_WeekEventLayout>[];
    final lanes = <int>[];

    for (final item in weekEvents) {
      int assignedLane = -1;

      for (int i = 0; i < lanes.length; i++) {
        if (lanes[i] < item.startOffset) {
          assignedLane = i;
          lanes[i] = item.startOffset + item.span - 1;
          break;
        }
      }

      if (assignedLane == -1) {
        assignedLane = lanes.length;
        lanes.add(item.startOffset + item.span - 1);
      }

      layout.add(_WeekEventLayout(data: item, lane: assignedLane));
    }

    return layout;
  }

  List<Widget> _buildEventBars(List<DateTime> week, List<_WeekEventLayout> layouts, double topOffset, double rowHeight, double spacing, double cellWidth, int maxRows, double eventFontSize, double overflowFontSize) {
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
    Widget createEventBar(_WeekEventData data, double width, bool forceStart, bool forceEnd) {
      return IgnorePointer(
        child: Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.eventColors[data.event.colorIndex % AppColors.eventColors.length],
            borderRadius: BorderRadius.horizontal(left: (data.isStart || forceStart) ? const Radius.circular(4) : Radius.zero, right: (data.isEnd || forceEnd) ? const Radius.circular(4) : Radius.zero),
            // BoxShadow removed for performance optimization during swiping
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            data.event.title,
            style: TextStyle(color: Colors.white, fontSize: eventFontSize, fontWeight: FontWeight.bold),
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

        bars.add(Positioned(top: topPos, left: leftOffset, width: barWidth, height: rowHeight, child: createEventBar(item.data, barWidth, false, false)));
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

          bars.add(Positioned(top: topPos, left: leftOffset, width: barWidth, height: rowHeight, child: createEventBar(item.data, barWidth, currentStart == item.data.startOffset, currentStart + currentLength == item.data.startOffset + item.data.span)));
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
                style: TextStyle(color: AppColors.textPrimary, fontSize: overflowFontSize, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      }
    }

    return bars;
  }
}

class _MonthCache {
  final List<DateTime> days;
  final List<List<DateTime>> visibleWeeks;
  final List<Event> monthEvents;
  final Map<int, List<_WeekEventLayout>> weekLayouts;

  _MonthCache({required this.days, required this.visibleWeeks, required this.monthEvents, required this.weekLayouts});
}

class _WeekEventData {
  final Event event;
  final int startOffset;
  final int span;
  final bool isStart;
  final bool isEnd;
  final int sortKey;

  _WeekEventData({required this.event, required this.startOffset, required this.span, required this.isStart, required this.isEnd, required this.sortKey});
}

class _WeekEventLayout {
  final _WeekEventData data;
  final int lane;

  _WeekEventLayout({required this.data, required this.lane});
}
