import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../utils/date_utils.dart';
import '../widgets/mini_calendar.dart';
import '../widgets/event_card.dart';
import '../widgets/add_event_sheet.dart';
import '../widgets/delete_confirmation_dialog.dart';

/// 日程視圖頁面
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  @override
  Widget build(BuildContext context) {
    // Top-level: No watch
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 迷你月曆 (Only rebuilds when currentMonth or selectedDate changes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingNormal),
              child: Selector<EventProvider, (DateTime, DateTime)>(
                selector: (context, provider) => (provider.currentMonth, provider.selectedDate),
                builder: (context, data, child) {
                  final currentMonth = data.$1;
                  final selectedDate = data.$2;
                  final provider = context.read<EventProvider>();

                  return MiniCalendar(
                    currentMonth: currentMonth,
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      provider.setSelectedDate(date);
                      // 如果選擇的日期不在當前月份，切換到該月份
                      if (!CalendarDateUtils.isInMonth(date, currentMonth)) {
                        provider.setCurrentMonth(date);
                      }
                    },
                    onMonthChanged: (month) {
                      provider.setCurrentMonth(month);
                    },
                  );
                },
              ),
            ),
            // 分隔線
            Container(height: 6, color: AppColors.dividerLight),
            // 事件列表 (Only rebuilds when selectedDate or events list changes)
            Expanded(
              child: Selector<EventProvider, (DateTime, List<Event>)>(
                selector: (context, provider) => (provider.selectedDate, provider.events),
                shouldRebuild: (prev, next) {
                  // Rebuild only if selectedDate changed or events list reference changed
                  // (assuming immutable list or provider notifies on list change)
                  return prev.$1 != next.$1 || prev.$2 != next.$2;
                },
                builder: (context, data, child) {
                  // final selectedDate = data.$1; // Unused
                  // final allEvents = data.$2; // Unused, but selector triggers rebuild
                  // final allEvents = data.$2; // Not used directly, but triggers rebuild
                  // Access provider for helper methods
                  final provider = context.read<EventProvider>();
                  final groupedEvents = _getGroupedEvents(provider);

                  return _buildEventsList(groupedEvents);
                },
              ),
            ),
          ],
        ),
      ),
      // FAB (Selector for selectedDate)
      floatingActionButton: Selector<EventProvider, DateTime>(selector: (context, p) => p.selectedDate, builder: (context, selectedDate, child) => _buildFAB(context, selectedDate)),
    );
  }

  Map<DateTime, List<Event>> _getGroupedEvents(EventProvider provider) {
    final Map<DateTime, List<Event>> grouped = {};
    final selectedDate = provider.selectedDate;

    // 僅顯示選中日期的事件
    final eventsOnDate = provider.getEventsForDate(selectedDate);
    grouped[selectedDate] = eventsOnDate;

    return grouped;
  }

  Widget _buildEventsList(Map<DateTime, List<Event>> groupedEvents) {
    final entries = groupedEvents.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spacingNormal,
        AppDimens.spacingNormal,
        AppDimens.spacingNormal,
        100, // Bottom padding for FAB
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final date = entry.key;
        final events = entry.value;
        return _buildDateSection(date, events);
      },
    );
  }

  Widget _buildDateSection(DateTime date, List<Event> events) {
    final isToday = CalendarDateUtils.isToday(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期標題
        _buildDateHeader(date, isToday),
        const SizedBox(height: AppDimens.spacingNormal),
        // 事件列表
        if (events.isEmpty)
          _buildEmptyDateMessage(date)
        else
          ...events.map((event) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.spacingNormal),
              child: EventCard(
                event: event,
                onTap: () => showAddEventSheet(context, editEvent: event),
                onDelete: () => _confirmDelete(event),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDateHeader(DateTime date, bool isToday) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 大大的日期數字
        Text('${date.day}', style: AppTextStyles.headerLarge),
        const SizedBox(width: AppDimens.spacingMedium),
        // 月份與星期
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${date.month}月', style: AppTextStyles.headerMedium),
            const SizedBox(height: AppDimens.spacingTiny),
            Text(
              CalendarDateUtils.formatWeekday(date),
              style: AppTextStyles.bodyNormal.copyWith(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ],
        ),
        const Spacer(),
        // 今天標籤
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusXLarge),
              boxShadow: [BoxShadow(color: AppColors.gradientStart.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Text(
              'Today',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyDateMessage(DateTime date) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spacingNormal),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          border: Border.all(color: AppColors.dividerLight, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.textTertiary, size: AppDimens.iconMedium),
            const SizedBox(width: 10),
            Text('尚未規劃活動，點擊 + 新增事件', style: AppTextStyles.bodyNormal.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, DateTime selectedDate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.gradientStart.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton(
          onPressed: () => showAddEventSheet(context, initialDate: selectedDate),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  void _confirmDelete(Event event) async {
    final confirm = await showDeleteConfirmationDialog(context, event.title);

    if (confirm == true) {
      if (!mounted) return;
      context.read<EventProvider>().deleteEvent(event.id);
    }
  }
}
