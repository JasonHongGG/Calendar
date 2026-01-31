import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/gradient_header.dart';
import '../widgets/month_calendar.dart';
import '../widgets/today_events_preview.dart';
import '../widgets/add_event_sheet.dart';

/// 月視圖頁面
class MonthViewPage extends StatelessWidget {
  const MonthViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final currentMonth = provider.currentMonth;
    final selectedDate = provider.selectedDate;
    final todayEvents = provider.todayEvents;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 漸層標題
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GradientHeader(
                title: CalendarDateUtils.formatYearMonth(currentMonth),
                onPrevious: () => provider.previousMonth(),
                onNext: () => provider.nextMonth(),
                onToday: () => provider.goToToday(),
              ),
            ),
            const SizedBox(height: 20),
            // 月曆
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    MonthCalendar(
                      currentMonth: currentMonth,
                      // selectedDate: selectedDate, // 移除選中日期，不顯示選中狀態
                      // 移除 onDateSelected 以禁止選擇日期
                      // onDateSelected: (date) { ... },
                      onEventTap: (event) {
                        showAddEventSheet(
                          context,
                          editEvent: event,
                          initialDate: event.startDate,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // 今日事件預覽
                    TodayEventsPreview(
                      events: todayEvents,
                      onViewAll: () {
                        // 切換到日程頁面
                        // 這會由父層 HomePage 處理
                      },
                    ),
                    const SizedBox(height: 100), // 給 FAB 留空間
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context, selectedDate),
    );
  }

  Widget _buildFAB(BuildContext context, DateTime selectedDate) {
    return Container(
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
        onPressed: () => showAddEventSheet(context, initialDate: selectedDate),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}
