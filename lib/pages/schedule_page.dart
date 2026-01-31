import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final currentMonth = provider.currentMonth;
    final selectedDate = provider.selectedDate;

    // 取得從選中日期開始的事件列表
    final groupedEvents = _getGroupedEvents(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // 迷你月曆
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MiniCalendar(
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
              ),
            ),
            const SizedBox(height: 16),
            // 分隔線
            Container(height: 6, color: AppColors.dividerLight),
            // 事件列表
            Expanded(
              child: groupedEvents.isEmpty
                  ? _buildEmptyState()
                  : _buildEventsList(groupedEvents),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context, selectedDate),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.gradientStart.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 48,
              color: AppColors.gradientStart.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '目前沒有安排',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '點擊右下角 + 按鈕新增事件',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(Map<DateTime, List<Event>> groupedEvents) {
    final entries = groupedEvents.entries.toList();

    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final date = entry.key;
          final events = entry.value;

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(child: _buildDateSection(date, events)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSection(DateTime date, List<Event> events) {
    final isToday = CalendarDateUtils.isToday(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期標題
        _buildDateHeader(date, isToday),
        const SizedBox(height: 16),
        // 事件列表
        if (events.isEmpty)
          _buildEmptyDateMessage(date)
        else
          ...events.map((event) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
        Text(
          '${date.day}',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.0,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(width: 12),
        // 月份與星期
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.month}月',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CalendarDateUtils.formatWeekday(date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gradientStart.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Today',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyDateMessage(DateTime date) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.dividerLight,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 10),
            const Text(
              '尚未規劃活動，點擊 + 新增事件',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
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
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientStart.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () =>
              showAddEventSheet(context, initialDate: selectedDate),
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
