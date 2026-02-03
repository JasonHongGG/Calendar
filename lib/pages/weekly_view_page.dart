import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/event_card.dart';
import '../widgets/add_event_sheet.dart';
import '../widgets/delete_confirmation_dialog.dart';

class WeeklyViewPage extends StatefulWidget {
  const WeeklyViewPage({super.key});

  @override
  State<WeeklyViewPage> createState() => _WeeklyViewPageState();
}

class _WeeklyViewPageState extends State<WeeklyViewPage> {
  @override
  Widget build(BuildContext context) {
    // Only rebuild if selectedDate or events list changes
    final selectedDate = context.select<EventProvider, DateTime>((p) => p.selectedDate);
    // Access provider for methods (read is fine since we select what we need)
    final provider = context.read<EventProvider>();

    // 計算該週的每一天 (假設週一為第一天)
    final daysOfWeek = _getDaysInWeek(selectedDate);
    final title = CalendarDateUtils.formatDateRange(daysOfWeek.first, daysOfWeek.last);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 標題區
            _buildHeader(provider, title),
            const SizedBox(height: 10),

            // 週視圖列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: daysOfWeek.length,
                itemBuilder: (context, index) {
                  final date = daysOfWeek[index];
                  final events = provider.getEventsForDate(date);
                  return _buildDayRow(context, date, events);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(EventProvider provider, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.gradientStart.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              // 上一週
              provider.setSelectedDate(provider.selectedDate.subtract(const Duration(days: 7)));
            },
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2), padding: const EdgeInsets.all(8)),
          ),
          Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => provider.goToToday(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Text('回到今天', style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // 下一週
              provider.setSelectedDate(provider.selectedDate.add(const Duration(days: 7)));
            },
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2), padding: const EdgeInsets.all(8)),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(BuildContext context, DateTime date, List<Event> events) {
    final isToday = CalendarDateUtils.isToday(date);
    final weekday = CalendarDateUtils.formatWeekday(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左側：日期顯示
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Text(
                    weekday,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isToday ? AppColors.gradientStart : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: isToday ? AppColors.gradientStart : Colors.transparent, shape: BoxShape.circle),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isToday ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // 中間：分隔裝飾線
            Container(width: 2, color: AppColors.dividerLight, margin: const EdgeInsets.symmetric(horizontal: 12)),

            // 右側：事件列表
            Expanded(
              child: events.isEmpty
                  ? _buildEmptySlot()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: events.map((event) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EventCard(
                            event: event,
                            onTap: () => showAddEventSheet(context, editEvent: event),
                            // 使用 delete_confirmation_dialog.dart 的邏輯
                            onDelete: () => _confirmDelete(context, event),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      child: Text(
        '', // 保持空白，讓畫面更清爽
        style: TextStyle(fontSize: 13, color: AppColors.textTertiary.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Event event) async {
    final confirm = await showDeleteConfirmationDialog(context, event.title);
    if (confirm == true) {
      if (!context.mounted) return;
      context.read<EventProvider>().deleteEvent(event.id);
    }
  }

  List<DateTime> _getDaysInWeek(DateTime date) {
    // 改為週日為一週的第一天
    final daysToSubtract = date.weekday % 7;
    final sunday = date.subtract(Duration(days: daysToSubtract));
    return List.generate(7, (index) => sunday.add(Duration(days: index)));
  }
}
